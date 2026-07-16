#!/usr/bin/env bash
# Ensure the lab's stable FRONT DOOR is up on :8000, pointing at the active cluster's
# Envoy load balancer. The front door is the lab's canonical entry point: every UI is
# reached via it (http://<name>.127.0.0.1.nip.io:8000) regardless of which cluster
# (blue/green) currently backs the lab. That's what keeps the Lab UIs URLs correct
# across a blue/green cutover. Idempotent. See docs/DR.md, ADR-0005.
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER="${1:-${FRONTDOOR_CLUSTER:-}}"

if [ -z "$CLUSTER" ]; then
  running="$(k3d cluster list --no-headers 2>/dev/null | awk '{print $1}')"
  n="$(printf '%s\n' "$running" | grep -c .)"
  if printf '%s\n' "$running" | grep -qx k8s-lab; then
    CLUSTER=k8s-lab                                   # prefer blue (the normal primary)
  elif [ "$n" -eq 1 ] && [ -n "$running" ]; then
    CLUSTER="$(printf '%s\n' "$running" | head -1)"   # exactly one cluster -> use it
  else
    echo "[frontdoor] can't auto-pick a cluster; pass one: frontdoor-ensure.sh <cluster>" >&2
    printf '%s\n' "$running" | sed 's/^/  running: /' >&2
    exit 1
  fi
fi

LB="k3d-$CLUSTER-serverlb"; NET="k3d-$CLUSTER"
docker inspect "$LB" >/dev/null 2>&1 || { echo "[frontdoor] $LB not found — is cluster '$CLUSTER' running?" >&2; exit 1; }
bash "$ROOT_DIR/scripts/bluegreen-frontdoor.sh" up "$NET" "$LB"
echo "[frontdoor] canonical entry http://localhost:8000 (and https://localhost:8443) -> cluster '$CLUSTER'"
