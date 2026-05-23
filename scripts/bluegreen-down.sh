#!/usr/bin/env bash
# Tear down the blue/green DR apparatus: remove the front-door proxy and the GREEN
# cluster, restoring the normal single-environment (blue-only) state. Blue is never
# touched. Run this to reclaim the RAM green used. See docs/DR.md.
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GREEN="${GREEN_CLUSTER:-k8s-lab-green}"
BLUE_CTX="${BLUE_CTX:-k3d-k8s-lab}"

echo "[bluegreen] removing front door..."
bash "$ROOT_DIR/scripts/bluegreen-frontdoor.sh" down || true

echo "[bluegreen] deleting green cluster $GREEN..."
k3d cluster delete "$GREEN" 2>/dev/null || true

# make sure the current kube-context points back at blue
kubectl config use-context "$BLUE_CTX" >/dev/null 2>&1 || true
echo "[bluegreen] done — blue-only state restored (blue was never touched)."
