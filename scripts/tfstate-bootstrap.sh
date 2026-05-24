#!/usr/bin/env bash
# Idempotent bootstrap for the off-cluster Terraform-state Garage (infra/tfstate):
# assign layout -> import the fixed lab S3 key -> create the `tfstate` bucket + grant.
# Deterministic key import means the creds match the AWS_* env the Makefile exports,
# so Terraform's s3 backend authenticates without any creds-plumbing. Safe to re-run.
set -euo pipefail

CID="${TFSTATE_CONTAINER:-tfstate-garage}"
AKID="${AWS_ACCESS_KEY_ID:?set AWS_ACCESS_KEY_ID (Makefile exports the lab default)}"
ASEC="${AWS_SECRET_ACCESS_KEY:?set AWS_SECRET_ACCESS_KEY (Makefile exports the lab default)}"

g() { docker exec "$CID" /garage "$@"; }

# wait until the node is responsive over RPC
for _ in $(seq 1 60); do g status >/dev/null 2>&1 && break; sleep 2; done

# layout: assign this single node a role once
if g status 2>/dev/null | grep -q 'NO ROLE'; then
  NODE=$(g node id -q 2>/dev/null | cut -d@ -f1)
  echo "[tfstate] assigning layout to $NODE"
  g layout assign -z dc1 -c 1G "$NODE"
  g layout apply --version 1
fi

# access key: import the fixed lab creds (idempotent — skip if already present)
if ! g key info tfstate >/dev/null 2>&1; then
  echo "[tfstate] importing fixed S3 key (id $AKID)"
  g key import --yes -n tfstate "$AKID" "$ASEC"
fi

# bucket + permissions
g bucket create tfstate >/dev/null 2>&1 || true
g bucket allow --read --write tfstate --key tfstate >/dev/null 2>&1 || true

echo "[tfstate] bootstrap complete (bucket: tfstate, endpoint http://localhost:3900)"
