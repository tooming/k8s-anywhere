#!/usr/bin/env bash
# Bring up the GREEN cluster for the blue/green DR drill: a second k3d cluster on
# its own host ports, with its own ArgoCD syncing the always-available SERVING tier
# (lab-gateway, demo) from the SAME Forgejo repo (ADR-0035). Blue is never
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
# SCOPE: "serving" (default) plants the light serving-tier subset; "full" plants the
# whole app-of-apps, then bootstraps green's Vault+Garage and verifies green end-to-end.
SCOPE="${1:-serving}"
if [ "$SCOPE" = "full" ]; then
  GREEN_ROOT="${GREEN_ROOT:-$ROOT_DIR/gitops/bootstrap/root-app.yaml}"
else
  GREEN_ROOT="${GREEN_ROOT:-$ROOT_DIR/gitops/bluegreen/green-root.yaml}"
fi

g() { kubectl --context "$GCTX" "$@"; }

# 1. cluster (idempotent). Keep the current kube-context on BLUE (don't switch).
if k3d cluster list 2>/dev/null | grep -q "^${GREEN}[[:space:]]"; then
  echo "[green] cluster $GREEN already exists"
else
  echo "[green] creating k3d cluster $GREEN (api $API_PORT, http $HTTP_PORT, https $HTTPS_PORT)..."
  # No --k3s-arg '--disable=traefik...' here (ADR-0040, supersedes Envoy
  # Gateway/ADR-0008) -- k3s's bundled Traefik is green's ingress controller too,
  # same as blue.
  k3d cluster create "$GREEN" \
    --servers 1 --agents 1 \
    --api-port "$API_PORT" \
    --port "$HTTP_PORT:80@loadbalancer" \
    --port "$HTTPS_PORT:443@loadbalancer" \
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

# 3. GitLab repo credential: green needs blue's (Terraform-made) repo secret to clone
#    the private repo. Copy it once; skip if green already has it — e.g. during a
#    promote-after-retire, where blue is already gone but green kept the secret.
if g -n argocd get secret repo-gitlab-gitops >/dev/null 2>&1; then
  echo "[green] repo secret already present on green"
elif kubectl --context "$BLUE_CTX" -n argocd get secret repo-gitlab-gitops >/dev/null 2>&1; then
  echo "[green] copying GitLab repo secret from blue..."
  kubectl --context "$BLUE_CTX" -n argocd get secret repo-gitlab-gitops -o json \
    | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.managedFields,.metadata.namespace,.status)' \
    | g apply -n argocd -f -
else
  echo "[green] ERROR: green has no repo secret and blue is unreachable"; exit 1
fi

# 4. plant the green app-of-apps (from local disk, like bootstrap/root-app)
echo "[green] planting green app-of-apps: $GREEN_ROOT"
g apply -f "$GREEN_ROOT"

# 5. wait for the canary (ArgoCD UI) to actually serve through green's gateway
echo "[green] waiting for ArgoCD server..."
g -n argocd rollout status deploy/argocd-server --timeout=300s >/dev/null 2>&1 || true
echo "[green] waiting up to ${CANARY_WAIT}s for the canary to serve via green :$HTTP_PORT (Traefik's IngressRoute must sync first)..."
end=$((SECONDS + CANARY_WAIT))
while :; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 4 -H 'Host: argocd.127.0.0.1.nip.io' "http://localhost:$HTTP_PORT/" 2>/dev/null || echo 000)
  [ "$code" = "200" ] && { echo "[green] canary serving on :$HTTP_PORT (HTTP 200)"; break; }
  [ "$SECONDS" -ge "$end" ] && { echo "[green] ERROR: canary not serving on :$HTTP_PORT within ${CANARY_WAIT}s (last code $code)"; exit 1; }
  sleep 5
done
echo "[green] serving tier up (canary :$HTTP_PORT = 200)."

# FULL scope: finish green like `make up` finishes blue — bootstrap green's Vault +
# Garage (KCTX targets green), then verify green end-to-end. Now green is a complete,
# verified environment, ready to take over from blue.
if [ "$SCOPE" = "full" ]; then
  echo "[green] promoting to FULL: bootstrapping green Vault..."
  KCTX="$GCTX" bash "$ROOT_DIR/scripts/vault-bootstrap.sh"
  echo "[green] bootstrapping green Garage..."
  KCTX="$GCTX" bash "$ROOT_DIR/scripts/garage-bootstrap.sh"
  echo "[green] verifying green (full end-to-end health)..."
  KCTX="$GCTX" bash "$ROOT_DIR/scripts/dr-verify.sh"
  echo "[green] FULL stack up + verified."
fi
echo "[green] up ($SCOPE)."
