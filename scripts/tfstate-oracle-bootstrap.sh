#!/usr/bin/env bash
# Idempotent bootstrap for the oracle backend's off-cluster Terraform-state Garage
# (infra/tfstate-oracle): a SEPARATE Always Free AMD Micro instance from the one
# infra/modules/oracle-k3s-cluster creates — see ADR-0027's "Terraform state" section
# for why it must be separate (the same causal-ordering constraint ADR-0007 solved
# for local/: the state backend must exist before the Terraform it backs can apply,
# so it can't live on a VM that Terraform apply itself creates).
#
# NEVER Terraform-managed, by design (mirrors scripts/tfstate-bootstrap.sh). Run via
# `make tfstate-oracle-up`, ahead of any `terragrunt apply` under infra/live/oracle/.
#
# UNVERIFIED against a real OCI account/tenancy as of authoring — no OCI credentials
# exist in this environment. Review before running against a real tenancy.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT/infra/tfstate-oracle"
ENV_FILE="$STATE_DIR/.env"

: "${OCI_COMPARTMENT_ID:?set OCI_COMPARTMENT_ID (the compartment to create resources in)}"
: "${OCI_TENANCY_ID:?set OCI_TENANCY_ID}"
: "${OCI_SSH_PUBLIC_KEY_PATH:?set OCI_SSH_PUBLIC_KEY_PATH (path to a public key for instance access)}"
: "${OCI_SSH_PRIVATE_KEY_PATH:?set OCI_SSH_PRIVATE_KEY_PATH (matching private key, for the SSH bootstrap steps below)}"

command -v oci >/dev/null 2>&1 || { echo "[tfstate-oracle] oci CLI not found — install and 'oci setup config' first" >&2; exit 1; }

AD="$(oci iam availability-domain list --compartment-id "$OCI_TENANCY_ID" --query 'data[0].name' --raw-output)"

# --- secrets: generate once, persist locally (never committed — see .gitignore) ---
mkdir -p "$STATE_DIR"
if [ ! -f "$ENV_FILE" ]; then
  echo "[tfstate-oracle] generating Garage secrets"
  {
    echo "GARAGE_RPC_SECRET=$(openssl rand -hex 32)"
    echo "GARAGE_ADMIN_TOKEN=$(openssl rand -hex 32)"
    echo "GARAGE_ACCESS_KEY_ID=$(openssl rand -hex 10)"
    echo "GARAGE_SECRET_ACCESS_KEY=$(openssl rand -hex 20)"
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
fi
# shellcheck disable=SC1090
. "$ENV_FILE"

# --- networking: idempotent create-if-absent (separate CIDR from the k3s cluster's
#     10.20.0.0/16, so both can coexist if ever run in the same compartment) ---
VCN_ID="$(oci network vcn list --compartment-id "$OCI_COMPARTMENT_ID" --display-name tfstate-oracle-vcn --query 'data[0].id' --raw-output 2>/dev/null || true)"
if [ -z "$VCN_ID" ] || [ "$VCN_ID" = "null" ]; then
  echo "[tfstate-oracle] creating VCN"
  VCN_ID="$(oci network vcn create --compartment-id "$OCI_COMPARTMENT_ID" --display-name tfstate-oracle-vcn --cidr-block 10.21.0.0/16 --dns-label tfstateoracle --query 'data.id' --raw-output --wait-for-state AVAILABLE)"
fi

IGW_ID="$(oci network internet-gateway list --compartment-id "$OCI_COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name tfstate-oracle-igw --query 'data[0].id' --raw-output 2>/dev/null || true)"
if [ -z "$IGW_ID" ] || [ "$IGW_ID" = "null" ]; then
  echo "[tfstate-oracle] creating internet gateway"
  IGW_ID="$(oci network internet-gateway create --compartment-id "$OCI_COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name tfstate-oracle-igw --is-enabled true --query 'data.id' --raw-output --wait-for-state AVAILABLE)"
fi

RT_ID="$(oci network vcn get --vcn-id "$VCN_ID" --query 'data."default-route-table-id"' --raw-output)"
oci network route-table update --rt-id "$RT_ID" --route-rules "[{\"destination\":\"0.0.0.0/0\",\"destinationType\":\"CIDR_BLOCK\",\"networkEntityId\":\"$IGW_ID\"}]" --force >/dev/null

SL_ID="$(oci network security-list list --compartment-id "$OCI_COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name tfstate-oracle-sl --query 'data[0].id' --raw-output 2>/dev/null || true)"
if [ -z "$SL_ID" ] || [ "$SL_ID" = "null" ]; then
  echo "[tfstate-oracle] creating security list (SSH 22 + Garage S3 API 3900)"
  SL_ID="$(oci network security-list create --compartment-id "$OCI_COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name tfstate-oracle-sl \
    --egress-security-rules '[{"destination":"0.0.0.0/0","protocol":"all"}]' \
    --ingress-security-rules '[{"source":"0.0.0.0/0","protocol":"6","tcpOptions":{"destinationPortRange":{"min":22,"max":22}}},{"source":"0.0.0.0/0","protocol":"6","tcpOptions":{"destinationPortRange":{"min":3900,"max":3900}}}]' \
    --query 'data.id' --raw-output --wait-for-state AVAILABLE)"
fi

SUBNET_ID="$(oci network subnet list --compartment-id "$OCI_COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name tfstate-oracle-subnet --query 'data[0].id' --raw-output 2>/dev/null || true)"
if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "null" ]; then
  echo "[tfstate-oracle] creating subnet"
  SUBNET_ID="$(oci network subnet create --compartment-id "$OCI_COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name tfstate-oracle-subnet --cidr-block 10.21.0.0/24 --dns-label tfstate --security-list-ids "[\"$SL_ID\"]" --route-table-id "$RT_ID" --query 'data.id' --raw-output --wait-for-state AVAILABLE)"
fi

# --- instance: create-if-absent ---
INSTANCE_ID="$(oci compute instance list --compartment-id "$OCI_COMPARTMENT_ID" --display-name tfstate-oracle --lifecycle-state RUNNING --query 'data[0].id' --raw-output 2>/dev/null || true)"
if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "null" ]; then
  echo "[tfstate-oracle] rendering garage.toml + cloud-init user-data"
  GARAGE_TOML="$(sed -e "s/__RPC_SECRET__/${GARAGE_RPC_SECRET}/" -e "s/__ADMIN_TOKEN__/${GARAGE_ADMIN_TOKEN}/" "$STATE_DIR/garage.toml.tpl")"
  GARAGE_TOML_B64="$(printf '%s' "$GARAGE_TOML" | base64 -w0)"
  USER_DATA_FILE="$(mktemp)"
  sed "s#__GARAGE_TOML_B64__#${GARAGE_TOML_B64}#" "$STATE_DIR/cloud-init.yaml.tpl" > "$USER_DATA_FILE"

  IMAGE_ID="$(oci compute image list --compartment-id "$OCI_COMPARTMENT_ID" --operating-system "Canonical Ubuntu" --operating-system-version "22.04" --shape VM.Standard.E2.1.Micro --sort-by TIMECREATED --sort-order DESC --query 'data[0].id' --raw-output)"

  echo "[tfstate-oracle] launching instance (VM.Standard.E2.1.Micro, Always Free AMD Micro)"
  INSTANCE_ID="$(oci compute instance launch \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --availability-domain "$AD" \
    --display-name tfstate-oracle \
    --shape VM.Standard.E2.1.Micro \
    --image-id "$IMAGE_ID" \
    --subnet-id "$SUBNET_ID" \
    --assign-public-ip true \
    --ssh-authorized-keys-file "$OCI_SSH_PUBLIC_KEY_PATH" \
    --user-data-file "$USER_DATA_FILE" \
    --query 'data.id' --raw-output --wait-for-state RUNNING)"
  rm -f "$USER_DATA_FILE"
fi

PUBLIC_IP="$(oci compute instance list-vnics --instance-id "$INSTANCE_ID" --query 'data[0]."public-ip"' --raw-output)"

echo "[tfstate-oracle] waiting for cloud-init + Garage to come up on $PUBLIC_IP"
ssh_opts=(-o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$OCI_SSH_PRIVATE_KEY_PATH")
ready=0
for _ in $(seq 1 60); do
  ssh "${ssh_opts[@]}" "ubuntu@$PUBLIC_IP" 'docker exec tfstate-garage /garage status' >/dev/null 2>&1 && { ready=1; break; }
  sleep 5
done
# The loop above is already bounded (300s), but silently falling through to the
# layout/key/bucket steps below on failure just skips them without explanation (the
# `if`/`!` conditions that follow are exempt from `set -e`, so a still-unreachable
# instance doesn't abort here -- it looked like success until a much later, confusing
# failure). Fail loudly and immediately instead.
if [ "$ready" -ne 1 ]; then
  echo "[tfstate-oracle] ERROR: $PUBLIC_IP did not become reachable with a running tfstate-garage container within 300s -- check the OCI console's instance serial console for boot/cloud-init failures" >&2
  exit 1
fi

g() { ssh "${ssh_opts[@]}" "ubuntu@$PUBLIC_IP" "docker exec tfstate-garage /garage $*"; }

if g status 2>/dev/null | grep -q 'NO ROLE'; then
  NODE="$(g node id -q 2>/dev/null | cut -d@ -f1)"
  echo "[tfstate-oracle] assigning layout to $NODE"
  g layout assign -z dc1 -c 1G "$NODE"
  g layout apply --version 1
fi

if ! g key info tfstate >/dev/null 2>&1; then
  echo "[tfstate-oracle] importing generated S3 key"
  g key import --yes -n tfstate "$GARAGE_ACCESS_KEY_ID" "$GARAGE_SECRET_ACCESS_KEY"
fi

g bucket create tfstate >/dev/null 2>&1 || true
g bucket allow --read --write tfstate --key tfstate >/dev/null 2>&1 || true

{
  echo "GARAGE_RPC_SECRET=$GARAGE_RPC_SECRET"
  echo "GARAGE_ADMIN_TOKEN=$GARAGE_ADMIN_TOKEN"
  echo "GARAGE_ACCESS_KEY_ID=$GARAGE_ACCESS_KEY_ID"
  echo "GARAGE_SECRET_ACCESS_KEY=$GARAGE_SECRET_ACCESS_KEY"
  echo "TFSTATE_ORACLE_ENDPOINT=http://$PUBLIC_IP:3900"
} > "$ENV_FILE"
chmod 600 "$ENV_FILE"

echo "[tfstate-oracle] bootstrap complete (bucket: tfstate, endpoint http://$PUBLIC_IP:3900)"
echo "[tfstate-oracle] source $ENV_FILE before terragrunt apply under infra/live/oracle/ (also export as AWS_ACCESS_KEY_ID=\$GARAGE_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY=\$GARAGE_SECRET_ACCESS_KEY, matching infra/live/local/root.hcl's convention)"
