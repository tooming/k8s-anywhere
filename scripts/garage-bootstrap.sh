#!/usr/bin/env bash
# Idempotent Garage bootstrap: assign layout -> create key + buckets -> store the
# S3 access key in Vault (ESO then syncs it to the garage-s3 Secret for Mimir).
# Safe to re-run. Used by `make garage-bootstrap` and the DR flow (docs/DR.md).
set -euo pipefail

SNS=storage
VNS=vault

# Optionally target a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
KCTX="${KCTX:-}"
kubectl() { command kubectl ${KCTX:+--context "$KCTX"} "$@"; }

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

# access key: ensure it exists, then ALWAYS ensure its creds are in Vault. (A
# mid-run failure can leave the key created but not yet pushed; `key info
# --show-secret` lets us recover it idempotently.) Garage v2.3 redacts the
# secret from `key create`, so always re-read it via `key info --show-secret`.
# ESO syncs secret/garage/s3 -> the garage-s3 Secret that Mimir/Loki/Tempo use.
if ! g key info mimir-key >/dev/null 2>&1; then
  echo "[garage] creating access key mimir-key"
  g key create mimir-key >/dev/null 2>&1
fi
KEYOUT=$(g key info --show-secret mimir-key 2>/dev/null || true)
# Garage output has varied across versions; prefer labelled fields first, then
# fall back to legacy Garage-formatted key patterns.
KID=$(printf '%s\n' "$KEYOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(access[ _-]?key([ _-]?id)?|key[ _-]?id)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
KSEC=$(printf '%s\n' "$KEYOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(secret[ _-]?access[ _-]?key|secret[ _-]?key)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
[ -n "$KID" ] || KID=$(printf '%s' "$KEYOUT" | grep -oiE 'GK[0-9a-f]{20,}' | head -1 || true)
[ -n "$KSEC" ] || KSEC=$(printf '%s' "$KEYOUT" | grep -oiE '[0-9a-f]{64}' | head -1 || true)
[[ "$(echo "$KSEC" | tr '[:upper:]' '[:lower:]')" == redacted* || "$KSEC" == "*" ]] && KSEC=""
if [ -n "$KID" ] && [ -n "$KSEC" ]; then
  TOKEN=$(kubectl -n "$VNS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
  kubectl -n "$VNS" exec vault-0 -- env VAULT_TOKEN="$TOKEN" vault kv put secret/garage/s3 access-key-id="$KID" secret-access-key="$KSEC" >/dev/null
  echo "[garage] ensured secret/garage/s3 in Vault (key $KID)"
else
  echo "[garage] ERROR: could not resolve mimir-key id/secret"; exit 1
fi

# buckets + permissions
for b in mimir mimir-ruler loki tempo pyroscope; do
  g bucket create "$b" >/dev/null 2>&1 || true
  g bucket allow --read --write "$b" --key mimir-key >/dev/null 2>&1 || true
done

# inkless key + bucket (on-demand; created at bootstrap so make inkless-up works
# immediately without a separate garage step). Stores the key at secret/inkless/s3.
if ! g key info inkless-key >/dev/null 2>&1; then
  echo "[garage] creating access key inkless-key"
  g key create inkless-key >/dev/null 2>&1
fi
IKOUT=$(g key info --show-secret inkless-key 2>/dev/null || true)
IKID=$(printf '%s\n' "$IKOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(access[ _-]?key([ _-]?id)?|key[ _-]?id)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
IKSEC=$(printf '%s\n' "$IKOUT" | awk -F': *' '
  BEGIN { IGNORECASE = 1 }
  $1 ~ /^(secret[ _-]?access[ _-]?key|secret[ _-]?key)$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }' | tr -d '"' || true)
[ -n "$IKID" ]  || IKID=$(printf '%s'  "$IKOUT" | grep -oiE 'GK[0-9a-f]{20,}' | head -1 || true)
[ -n "$IKSEC" ] || IKSEC=$(printf '%s' "$IKOUT" | grep -oiE '[0-9a-f]{64}'     | head -1 || true)
[[ "$(echo "$IKSEC" | tr '[:upper:]' '[:lower:]')" == redacted* || "$IKSEC" == "*" ]] && IKSEC=""
if [ -n "$IKID" ] && [ -n "$IKSEC" ]; then
  TOKEN=$(kubectl -n "$VNS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
  kubectl -n "$VNS" exec vault-0 -- env VAULT_TOKEN="$TOKEN" vault kv put secret/inkless/s3 access-key-id="$IKID" secret-access-key="$IKSEC" >/dev/null
  echo "[garage] ensured secret/inkless/s3 in Vault (key $IKID)"
else
  echo "[garage] WARNING: could not resolve inkless-key id/secret — secret/inkless/s3 not written"
fi
g bucket create inkless >/dev/null 2>&1 || true
g bucket allow --read --write inkless --key inkless-key >/dev/null 2>&1 || true

# secret/garage/s3 was just (re)written above; nudge ESO so the garage-s3
# ExternalSecrets (Mimir/Loki/Tempo + storage) pick it up now instead of waiting
# for their refreshInterval. Best-effort.
kubectl annotate externalsecret -A --all force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true

echo "[garage] bootstrap complete (buckets: mimir, mimir-ruler, loki, tempo, pyroscope, inkless)"
