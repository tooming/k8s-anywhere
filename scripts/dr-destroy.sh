#!/usr/bin/env bash
# The "disaster" half of the DR drill: tear the lab down to a clean slate so that
# `make up` has to rebuild it entirely from code. See docs/DR.md.
#
# Scopes (how much to wipe — bigger = more faithful, slower to rebuild):
#   cluster  destroy the k3d cluster only (ArgoCD, Vault, Garage, all workloads,
#            the in-cluster repo secret). GitLab + Colima survive. Fast (~3-5 min
#            rebuild). Exercises full secret regeneration (new Vault + Garage keys).
#   full     (default) cluster + GitLab container & volumes. The git source itself
#            is rebuilt and the repo re-pushed. Colima survives (image cache kept).
#   machine  full + delete the Colima VM (clean-machine simulation; re-pulls all
#            images). Slowest.
#
# State is local + throwaway (infra/live/local/root.hcl), so once a layer's real
# resources are gone we clear its tfstate to force a clean greenfield `make up`.
set -uo pipefail

SCOPE="${1:-${DR_SCOPE:-full}}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE="$REPO_DIR/infra/live/local"
CLUSTER_NAME="k8s-lab"

case "$SCOPE" in cluster|full|machine) ;; *) echo "unknown SCOPE '$SCOPE' (cluster|full|machine)" >&2; exit 2;; esac

if [ -t 1 ]; then R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else R=; Y=; B=; Z=; fi
step(){ printf '%s[destroy:%s]%s %s\n' "$Y" "$SCOPE" "$Z" "$1"; }

# confirmation (dr-test sets DR_ASSUME_YES=1 after its own single prompt)
if [ "${DR_ASSUME_YES:-0}" != "1" ]; then
  printf '%sThis DESTROYS the lab (scope=%s) so it can be rebuilt from scratch.%s\n' "$R$B" "$SCOPE" "$Z"
  if [ -t 0 ]; then
    read -r -p "Type 'destroy' to continue: " ans
    [ "$ans" = "destroy" ] || { echo "aborted."; exit 1; }
  else
    echo "Refusing non-interactively without DR_ASSUME_YES=1." >&2; exit 1
  fi
fi

tg_destroy(){ # best-effort terragrunt destroy of a unit
  local unit="$1"
  [ -d "$LIVE/$unit" ] || return 0
  ( cd "$LIVE/$unit" && terragrunt destroy -auto-approve ) >/dev/null 2>&1 || true
}
clear_state(){ # force greenfield for a unit whose real resources are now gone
  rm -f "$LIVE/$1/terraform.tfstate" "$LIVE/$1/terraform.tfstate.backup" 2>/dev/null || true
}

# --- 1. Cluster (and everything running in it) -------------------------------
step "destroying k3d cluster '$CLUSTER_NAME' (ArgoCD, Vault, Garage, all workloads)"
tg_destroy cluster
k3d cluster delete "$CLUSTER_NAME" >/dev/null 2>&1 || true
clear_state cluster
clear_state argocd   # ArgoCD lived in the cluster -> gone -> greenfield its state

# --- 2. GitLab (full + machine) ---------------------------------------------
if [ "$SCOPE" = "full" ] || [ "$SCOPE" = "machine" ]; then
  step "wiping GitLab container + volumes (the git source is rebuilt from scratch)"
  ( cd "$REPO_DIR/gitlab" && docker compose down -v ) >/dev/null 2>&1 || true
  rm -f "$REPO_DIR/gitlab/.gitlab-token"
  clear_state gitlab   # GitLab project/token + repo secret gone -> greenfield
else
  step "keeping GitLab (scope=cluster); its repo secret is recreated by 'make up'"
fi

# --- 3. Colima VM (machine only) --------------------------------------------
if [ "$SCOPE" = "machine" ]; then
  step "deleting Colima VM (clean-machine simulation; images will be re-pulled)"
  colima delete --force >/dev/null 2>&1 || true
fi

printf '%s[destroy:%s] done — lab torn down. Rebuild with: make up%s\n' "$B" "$SCOPE" "$Z"
