#!/usr/bin/env bash
# Bring up the GREEN cluster for the blue/green DR drill: a second k3d cluster on
# its own host ports, with its own ArgoCD syncing the always-available SERVING tier
# (envoy-gateway, lab-gateway, demo) from the SAME GitLab repo. Blue is never
# touched (different cluster, ports, and docker network). See docs/DR.md.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GREEN="${GREEN_CLUSTER:-k8s-lab-green}"
GCTX="k3d-$GREEN"
BLUE_CTX="${BLUE_CTX:-k3d-k8s-lab}"
HTTP_PORT="${GREEN_HTTP_PORT:-8082}"
HTTPS_PORT="${GREEN_HTTPS_PORT:-8444}"
API_PORT="${GREEN_API_PORT:-6446}"
ARGOCD_CHART_VERSION="${ARGOCD_CHART_VERSION:-9.5.15}"
ARGOCD_VALUES="$ROOT_DIR/infra/modules/argocd/values.yaml"
CANARY_WAIT="${GREEN_CANARY_WAIT:-600}"

g() { kubectl --context "$GCTX" "$@"; }

# 1. cluster (idempotent). Keep the current kube-context on BLUE (don't switch).
if k3d cluster list 2>/dev/null | grep -q "^$GREEN[[:space:]]"; then
  echo "[green] cluster $GREEN already exists"
else
  echo "[green] creating k3d cluster $GREEN (api $API_PORT, http $HTTP_PORT, https $HTTPS_PORT)..."
  k3d cluster create "$GREEN" \
    --servers 1 --agents 1 \
    --api-port "$API_PORT" \
    --port "$HTTP_PORT:80@loadbalancer" \
    --port "$HTTPS_PORT:443@loadbalancer" \
    --k3s-arg '--disable=traefik@server:*' \
    --kubeconfig-switch-context=false \
    --wait
fi

echo "[green] waiting for nodes Ready..."
g wait --for=condition=Ready nodes --all --timeout=180s >/dev/null

# 2. ArgoCD (the same chart/values as blue's bootstrap)
echo "[green] installing ArgoCD (helm $ARGOCD_CHART_VERSION)..."
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null 2>&1 || true
helm --kube-context "$GCTX" upgrade --install argocd argo/argo-cd \
  --version "$ARGOCD_CHART_VERSION" -n argocd --create-namespace \
  -f "$ARGOCD_VALUES" --wait --timeout 600s

# 3. GitLab repo credential: copy blue's (Terraform-made) repo secret so green's
#    ArgoCD can clone the same private repo. Strip instance-specific metadata.
echo "[green] copying GitLab repo secret from blue..."
kubectl --context "$BLUE_CTX" -n argocd get secret repo-gitlab-gitops -o json \
  | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.managedFields,.metadata.namespace,.status)' \
  | g apply -n argocd -f -

# 4. plant the green app-of-apps (from local disk, like bootstrap/root-app)
echo "[green] planting green app-of-apps (serving-tier subset)..."
g apply -f "$ROOT_DIR/gitops/bluegreen/green-root.yaml"

# 5. wait for the canary (ArgoCD UI) to actually serve through green's gateway
echo "[green] waiting for ArgoCD server..."
g -n argocd rollout status deploy/argocd-server --timeout=300s >/dev/null 2>&1 || true
echo "[green] waiting up to ${CANARY_WAIT}s for the canary to serve via green :$HTTP_PORT (Envoy gateway + route must sync first)..."
end=$((SECONDS + CANARY_WAIT))
while :; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 4 -H 'Host: argocd.127.0.0.1.nip.io' "http://localhost:$HTTP_PORT/" 2>/dev/null || echo 000)
  [ "$code" = "200" ] && { echo "[green] canary serving on :$HTTP_PORT (HTTP 200)"; break; }
  [ "$SECONDS" -ge "$end" ] && { echo "[green] ERROR: canary not serving on :$HTTP_PORT within ${CANARY_WAIT}s (last code $code)"; exit 1; }
  sleep 5
done
echo "[green] up."
