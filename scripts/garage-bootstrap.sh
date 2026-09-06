#!/usr/bin/env bash
# Idempotent Garage bootstrap: assign layout -> create the velero-key access key +
# bucket -> store its S3 credentials in Vault (ESO then syncs them to the
# cloud-credentials Secret Velero consumes).
# Safe to re-run. Used by `make garage-bootstrap` and the DR flow (docs/DR.md).
set -euo pipefail

SNS=storage
VNS=vault

# Optionally target a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"

g() { kubectl -n "$SNS" exec sts/garage -- /garage "$@"; }

# garage-0 is created by ArgoCD and only schedules once its garage-secrets Secret
# exists (ESO syncs it from Vault, which vault-bootstrap must have set up first).
# From scratch that whole chain takes minutes, so wait for the pod to be CREATED,
# then Running, then responsive.
WAIT="${GARAGE_WAIT:-600}"
echo "[garage] waiting up to ${WAIT}s for garage-0 to be created by ArgoCD..."
end=$((SECONDS + WAIT))
until kubectl -n "$SNS" get pod garage-0 >/dev/null 2>&1; do
  [ "$SECONDS" -ge "$end" ] && { echo "[garage] ERROR: garage-0 never appeared (is Vault bootstrapped + ESO syncing garage-secrets?)"; exit 1; }
  sleep 5
done
kubectl -n "$SNS" wait --for=jsonpath='{.status.phase}'=Running pod/garage-0 --timeout="${WAIT}s" >/dev/null 2>&1 || true
for _ in $(seq 1 60); do g status >/dev/null 2>&1 && break; sleep 3; done

# layout (only if this node has no role yet)
if g status 2>/dev/null | grep -q 'NO ROLE ASSIGNED'; then
  NODE=$(g node id -q 2>/dev/null | cut -d@ -f1)
  echo "[garage] assigning layout to $NODE"
  g layout assign -z dc1 -c 5G "$NODE"
  g layout apply --version 1
fi

# The mimir-key access key + secret/garage/s3 Vault write + mimir/mimir-ruler/
# loki/tempo/pyroscope bucket creation this script used to also do here were
# removed 2026-09-06 (ADR-0041, observability stack removed with no
# replacement) — Mimir/Loki/Tempo/Pyroscope and their Garage buckets are gone.

# velero key + bucket (always-on; created at bootstrap so the velero Application works
# immediately once the cloud-credentials Secret is rendered by ESO). Stores creds at
# secret/velero/s3 (same Vault-path pattern as garage/s3).
if ! g key info velero-key >/dev/null 2>&1; then
  echo "[garage] creating access key velero-key"
  g key create velero-key >/dev/null 2>&1
fi
VKOUT=$(g key info --show-secret velero-key 2>/dev/null || true)
VKID=$(printf '%s\n' "$VKOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(access[ _-]?key([ _-]?id)?|key[ _-]?id)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
VKSEC=$(printf '%s\n' "$VKOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(secret[ _-]?access[ _-]?key|secret[ _-]?key)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
[ -n "$VKID" ]  || VKID=$(printf '%s'  "$VKOUT" | grep -oiE 'GK[0-9a-f]{20,}' | head -1 || true)
[ -n "$VKSEC" ] || VKSEC=$(printf '%s' "$VKOUT" | grep -oiE '[0-9a-f]{64}'     | head -1 || true)
[[ "$(echo "$VKSEC" | tr '[:upper:]' '[:lower:]')" == redacted* || "$VKSEC" == "*" ]] && VKSEC=""
if [ -n "$VKID" ] && [ -n "$VKSEC" ]; then
  TOKEN=$(kubectl -n "$VNS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
  kubectl -n "$VNS" exec vault-0 -- env VAULT_TOKEN="$TOKEN" vault kv put secret/velero/s3 access-key-id="$VKID" secret-access-key="$VKSEC" >/dev/null
  echo "[garage] ensured secret/velero/s3 in Vault (key $VKID)"
else
  echo "[garage] WARNING: could not resolve velero-key id/secret — secret/velero/s3 not written"
fi
g bucket create velero >/dev/null 2>&1 || true
g bucket allow --read --write velero --key velero-key >/dev/null 2>&1 || true

# harbor key + bucket (on-demand; created at bootstrap so make harbor-up works
# immediately without a separate garage step). Stores the key at secret/harbor/s3.
# ESO renders harbor-s3-creds Secret from this Vault path; registry reads credentials
# via REGISTRY_STORAGE_S3_ACCESSKEY / REGISTRY_STORAGE_S3_SECRETKEY env vars.
if ! g key info harbor-key >/dev/null 2>&1; then
  echo "[garage] creating access key harbor-key"
  g key create harbor-key >/dev/null 2>&1
fi
HKOUT=$(g key info --show-secret harbor-key 2>/dev/null || true)
HKID=$(printf '%s\n' "$HKOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(access[ _-]?key([ _-]?id)?|key[ _-]?id)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
HKSEC=$(printf '%s\n' "$HKOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(secret[ _-]?access[ _-]?key|secret[ _-]?key)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
[ -n "$HKID" ]  || HKID=$(printf '%s'  "$HKOUT" | grep -oiE 'GK[0-9a-f]{20,}' | head -1 || true)
[ -n "$HKSEC" ] || HKSEC=$(printf '%s' "$HKOUT" | grep -oiE '[0-9a-f]{64}'     | head -1 || true)
[[ "$(echo "$HKSEC" | tr '[:upper:]' '[:lower:]')" == redacted* || "$HKSEC" == "*" ]] && HKSEC=""
if [ -n "$HKID" ] && [ -n "$HKSEC" ]; then
  TOKEN=$(kubectl -n "$VNS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
  kubectl -n "$VNS" exec vault-0 -- env VAULT_TOKEN="$TOKEN" vault kv put secret/harbor/s3 access-key-id="$HKID" secret-access-key="$HKSEC" >/dev/null
  echo "[garage] ensured secret/harbor/s3 in Vault (key $HKID)"
else
  echo "[garage] WARNING: could not resolve harbor-key id/secret — secret/harbor/s3 not written"
fi
g bucket create harbor-registry >/dev/null 2>&1 || true
g bucket allow --read --write harbor-registry --key harbor-key >/dev/null 2>&1 || true

echo "[garage] bootstrap complete (buckets: velero, harbor-registry)"
