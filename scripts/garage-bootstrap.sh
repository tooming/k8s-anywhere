#!/usr/bin/env bash
# Idempotent Garage bootstrap: assign layout -> create key + buckets -> store the
# S3 access key in Vault (ESO then syncs it to the garage-s3 Secret for Mimir).
# Safe to re-run. Used by `make garage-bootstrap` and the DR flow (docs/DR.md).
set -euo pipefail

SNS=storage
VNS=vault
g() { kubectl -n "$SNS" exec sts/garage -- /garage "$@"; }

echo "[garage] waiting for garage-0..."
kubectl -n "$SNS" wait --for=jsonpath='{.status.phase}'=Running pod/garage-0 --timeout=180s >/dev/null 2>&1 || true
for _ in $(seq 1 30); do g status >/dev/null 2>&1 && break; sleep 3; done

# layout (only if this node has no role yet)
if g status 2>/dev/null | grep -q 'NO ROLE ASSIGNED'; then
  NODE=$(g node id -q 2>/dev/null | cut -d@ -f1)
  echo "[garage] assigning layout to $NODE"
  g layout assign -z dc1 -c 5G "$NODE"
  g layout apply --version 1
fi

# access key (create once) + push to Vault so ESO can sync garage-s3
if ! g key info mimir-key >/dev/null 2>&1; then
  echo "[garage] creating access key mimir-key"
  KEYOUT=$(g key create mimir-key 2>/dev/null)
  KID=$(printf '%s' "$KEYOUT" | grep -oE 'GK[0-9a-f]{20,}' | head -1)
  KSEC=$(printf '%s' "$KEYOUT" | grep -oiE '[0-9a-f]{64}' | head -1)
  TOKEN=$(kubectl -n "$VNS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
  kubectl -n "$VNS" exec vault-0 -- env VAULT_TOKEN="$TOKEN" vault kv put secret/garage/s3 access-key-id="$KID" secret-access-key="$KSEC" >/dev/null
fi

# buckets + permissions
for b in mimir mimir-ruler loki tempo; do
  g bucket create "$b" >/dev/null 2>&1 || true
  g bucket allow --read --write "$b" --key mimir-key >/dev/null 2>&1 || true
done
echo "[garage] bootstrap complete (buckets: mimir, mimir-ruler, loki)"
