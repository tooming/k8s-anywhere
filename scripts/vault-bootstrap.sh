#!/usr/bin/env bash
# Idempotent Vault bootstrap: init (if needed) -> store keys -> unseal -> enable
# KV v2 -> write the lab's secrets -> enable Kubernetes auth + eso role.
# Safe to re-run. Used by `make vault-bootstrap` and the DR flow (docs/DR.md).
set -euo pipefail

NS=vault
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[vault] waiting for vault-0 to exist..."
kubectl -n "$NS" wait --for=jsonpath='{.status.phase}'=Running pod/vault-0 --timeout=180s >/dev/null 2>&1 || true
for _ in $(seq 1 40); do kubectl -n "$NS" exec vault-0 -- vault status >/dev/null 2>&1 && break; rc=$?; [ "$rc" = "2" ] && break; sleep 3; done

# init (only if not initialized)
if kubectl -n "$NS" exec vault-0 -- vault status 2>/dev/null | grep -qE '^Initialized\s+false'; then
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
if kubectl -n "$NS" exec vault-0 -- vault status 2>/dev/null | grep -qE '^Sealed\s+true'; then
  echo "[vault] unsealing..."
  kubectl -n "$NS" exec vault-0 -- vault operator unseal "$UNSEAL" >/dev/null
fi

# KV v2
v secrets list 2>/dev/null | grep -q '^secret/' || { echo "[vault] enabling kv-v2"; v secrets enable -path=secret kv-v2; }

# secrets (generate Garage server creds if absent; capture gitlab token if present)
v kv get secret/garage/server >/dev/null 2>&1 || { echo "[vault] writing secret/garage/server"; v kv put secret/garage/server rpc-secret="$(openssl rand -hex 32)" admin-token="$(openssl rand -hex 16)" >/dev/null; }
if [ -s "$ROOT_DIR/gitlab/.gitlab-token" ]; then v kv put secret/gitlab/bootstrap token="$(cat "$ROOT_DIR/gitlab/.gitlab-token")" >/dev/null; fi

# Kubernetes auth + read policy + ESO role
if ! v auth list 2>/dev/null | grep -q '^kubernetes/'; then
  echo "[vault] enabling kubernetes auth + eso role"
  v auth enable kubernetes
  v write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc:443
  printf 'path "secret/data/*" { capabilities = ["read"] }\n' | v policy write eso-read -
  v write auth/kubernetes/role/eso bound_service_account_names=external-secrets bound_service_account_namespaces=external-secrets policies=eso-read ttl=1h
fi
echo "[vault] bootstrap complete"
