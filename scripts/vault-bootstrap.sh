#!/usr/bin/env bash
# Idempotent Vault bootstrap: init (if needed) -> store keys -> unseal -> enable
# KV v2 -> write the lab's secrets -> enable Kubernetes auth + eso role.
# Safe to re-run. Used by `make vault-bootstrap` and the DR flow (docs/DR.md).
set -euo pipefail

NS=vault

# Optionally target a specific cluster (e.g. KCTX=k3d-k8s-lab-green to bootstrap
# the green cluster). Unset = current context, so blue's `make up` path is unchanged.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"

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

# No KV secrets to seed here any more. This block used to write secret/garage/server,
# secret/capstone/app, secret/harbor/admin, secret/harbor/registry, secret/kargo/admin,
# secret/argo-rollouts/dashboard, and secret/gitlab/bootstrap — every one of those
# consumers (Garage, capstone, Harbor, Kargo, Argo Rollouts, GitLab/Forgejo) was
# removed entirely 2026-09-06/2026-09-07, no replacement. gitops/secrets/ now holds
# only clustersecretstore.yaml (the Vault connection config itself, no KV path to
# seed) — no live ExternalSecret in the repo references a secret/* path any more.
# The `kv-v2` engine stays enabled (below) so it's ready the moment a future
# component needs it.
# Kubernetes auth + read policy + ESO role
if ! v auth list 2>/dev/null | grep -q '^kubernetes/'; then
  echo "[vault] enabling kubernetes auth + eso role"
  v auth enable kubernetes
  v write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc:443
  printf 'path "secret/data/*" { capabilities = ["read"] }\n' | v policy write eso-read -
  # audience MUST equal the SA token's aud — k3s issues `https://kubernetes.default.svc.cluster.local`;
  # the bare `https://kubernetes.default.svc` is rejected by k8s TokenReview ("invalid audience"),
  # which leaves the whole ESO ClusterSecretStore not-ready (and breaks garage-bootstrap in `make up`).
  v write auth/kubernetes/role/eso bound_service_account_names=external-secrets bound_service_account_namespaces=external-secrets audience=https://kubernetes.default.svc.cluster.local policies=eso-read ttl=1h
fi

# Vault is now usable by ESO. On a cold bootstrap the ESO controller cached a
# failing Vault client (Vault was sealed when it started) and would otherwise wait
# out its ~5min store requeue — stalling any ExternalSecret that needs it (a real
# incident when this restart step didn't exist, back when Garage was the affected
# consumer). Restart the controller so the ClusterSecretStore re-validates, then
# force every ExternalSecret to re-sync now. Best-effort; never fail bootstrap.
if kubectl -n external-secrets get deploy external-secrets >/dev/null 2>&1; then
  echo "[vault] kicking External Secrets to re-validate against the ready Vault"
  kubectl -n external-secrets rollout restart deployment >/dev/null 2>&1 || true
  kubectl -n external-secrets rollout status deploy/external-secrets --timeout=120s >/dev/null 2>&1 || true
  kubectl annotate externalsecret -A --all force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
fi
echo "[vault] bootstrap complete"
