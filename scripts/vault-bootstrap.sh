#!/usr/bin/env bash
# Idempotent Vault bootstrap: init (if needed) -> store keys -> unseal -> enable
# KV v2 -> write the lab's secrets -> enable Kubernetes auth + eso role.
# Safe to re-run. Used by `make vault-bootstrap` and the DR flow (docs/DR.md).
set -euo pipefail

NS=vault
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# vault-0 is created by ArgoCD only AFTER the root app-of-apps is planted, so from
# a cold/from-scratch bootstrap it can take a few minutes to appear. Wait for it to
# be CREATED, then Running, then responsive — don't assume it already exists.
WAIT="${VAULT_WAIT:-600}"
echo "[vault] waiting up to ${WAIT}s for vault-0 to be created by ArgoCD..."
end=$((SECONDS + WAIT))
until kubectl -n "$NS" get pod vault-0 >/dev/null 2>&1; do
  [ "$SECONDS" -ge "$end" ] && { echo "[vault] ERROR: vault-0 never appeared (is the 'vault' ArgoCD app syncing?)"; exit 1; }
  sleep 5
done
echo "[vault] vault-0 exists; waiting for it to reach Running..."
kubectl -n "$NS" wait --for=jsonpath='{.status.phase}'=Running pod/vault-0 --timeout="${WAIT}s" >/dev/null 2>&1 || true
# `vault status` EXITS 2 when uninitialized/sealed, so never pipe it into grep
# under `set -o pipefail` (the exit-2 makes the pipeline "fail" even on a match,
# silently skipping init/unseal). Capture JSON with `|| true` and parse with jq.
vstatus() { kubectl -n "$NS" exec vault-0 -- vault status -format=json 2>/dev/null || true; }
for _ in $(seq 1 60); do [ -n "$(vstatus)" ] && break; sleep 3; done

# init (only if not initialized)
if [ "$(vstatus | jq -r '.initialized // empty' 2>/dev/null)" != "true" ]; then
  echo "[vault] initializing (1 key share)..."
  INIT=$(kubectl -n "$NS" exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json)
  kubectl -n "$NS" create secret generic vault-keys \
    --from-literal=unseal-key="$(echo "$INIT" | jq -r '.unseal_keys_b64[0]')" \
    --from-literal=root-token="$(echo "$INIT" | jq -r '.root_token')" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

UNSEAL=$(kubectl -n "$NS" get secret vault-keys -o jsonpath='{.data.unseal-key}' | base64 -d)
TOKEN=$(kubectl -n "$NS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
v() { kubectl -n "$NS" exec -i vault-0 -- env VAULT_TOKEN="$TOKEN" vault "$@"; }

# unseal if sealed (the in-cluster vault-unsealer also does this continuously)
if [ "$(vstatus | jq -r '.sealed // empty' 2>/dev/null)" = "true" ]; then
  echo "[vault] unsealing..."
  kubectl -n "$NS" exec vault-0 -- vault operator unseal "$UNSEAL" >/dev/null
fi

# KV v2
v secrets list 2>/dev/null | grep -q '^secret/' || { echo "[vault] enabling kv-v2"; v secrets enable -path=secret kv-v2; }

# secrets (generate if absent). These must exist for ESO to render the k8s
# Secrets the workloads need — every remoteRef in gitops/secrets/ must be seeded
# here or by garage-bootstrap, or a from-scratch rebuild stalls.
#   secret/garage/server -> garage-secrets (Garage server)         [here]
#   secret/aws/moto       -> ack-aws-creds (ACK->moto, dummy creds) [here]
#   secret/garage/s3      -> garage-s3 (Mimir/Loki/Tempo)           [garage-bootstrap]
v kv get secret/garage/server >/dev/null 2>&1 || { echo "[vault] writing secret/garage/server"; v kv put secret/garage/server rpc-secret="$(openssl rand -hex 32)" admin-token="$(openssl rand -hex 16)" >/dev/null; }
v kv get secret/aws/moto >/dev/null 2>&1 || { echo "[vault] writing secret/aws/moto (dummy creds; moto ignores them)"; v kv put secret/aws/moto access-key-id=test secret-access-key=test >/dev/null; }
if [ -s "$ROOT_DIR/gitlab/.gitlab-token" ]; then v kv put secret/gitlab/bootstrap token="$(cat "$ROOT_DIR/gitlab/.gitlab-token")" >/dev/null; fi

# Kubernetes auth + read policy + ESO role
if ! v auth list 2>/dev/null | grep -q '^kubernetes/'; then
  echo "[vault] enabling kubernetes auth + eso role"
  v auth enable kubernetes
  v write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc:443
  printf 'path "secret/data/*" { capabilities = ["read"] }\n' | v policy write eso-read -
  v write auth/kubernetes/role/eso bound_service_account_names=external-secrets bound_service_account_namespaces=external-secrets policies=eso-read ttl=1h
fi

# Vault is now usable by ESO. On a cold bootstrap the ESO controller cached a
# failing Vault client (Vault was sealed when it started) and would otherwise wait
# out its ~5min store requeue — stalling garage-secrets/ack-aws-creds and thus
# Garage/ACK. Restart the controller so the ClusterSecretStore re-validates, then
# force every ExternalSecret to re-sync now. Best-effort; never fail bootstrap.
if kubectl -n external-secrets get deploy external-secrets >/dev/null 2>&1; then
  echo "[vault] kicking External Secrets to re-validate against the ready Vault"
  kubectl -n external-secrets rollout restart deployment >/dev/null 2>&1 || true
  kubectl -n external-secrets rollout status deploy/external-secrets --timeout=120s >/dev/null 2>&1 || true
  kubectl annotate externalsecret -A --all force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
fi
echo "[vault] bootstrap complete"
