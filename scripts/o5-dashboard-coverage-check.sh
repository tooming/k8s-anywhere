#!/usr/bin/env bash
# CHARTER Objective O5 drift check: "every Application in
# gitops/bootstrap/root-app.yaml's auto-synced set has a matching
# grafana/dashboards/lab-<name>.json ... Measured by: a drift check wired into
# make ci." That check never actually existed — O5's own CHARTER text promised
# mechanical enforcement no script provided (found live 2026-08-13 while
# gap-hunting CHARTER's Objectives for an unmet "Measured by" claim). Dashboard
# coverage itself was already complete when this check was added (verified by
# hand against every auto-synced Application before writing this script) — this
# closes the enforcement gap, not a coverage gap.
#
# Two real components can share one dashboard (e.g. kro/moto/ack-s3 all land in
# lab-cloud-control-plane.json) and a Grafana-managed self app's dashboard name
# doesn't always match its Application name 1:1. Because of that, this is an
# explicit allowlist (mirrors tests/governance.bats's STANDARD_NS pattern), not
# a name-guessing heuristic — plus a coverage-loop pass that fails if a *new*
# auto-synced, non-plumbing Application shows up in gitops/platform/ that isn't
# in the map, so a future component can't silently skip its O5 dashboard the way
# this run's gap-hunt found the check itself missing.
#
# [envoy-gateway]=envoy REMOVED 2026-09-06 (ADR-0040, supersedes Envoy Gateway/
# ADR-0008): the envoy-gateway Application and grafana/dashboards/lab-envoy.json
# are both gone — Traefik replaced it and ships with k3s, with no ArgoCD
# Application (and so no O5 dashboard obligation) of its own.
#
# Exit 0 = in sync; 1 = drift (findings printed).
set -uo pipefail
ROOT="${O5DASHCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLATFORM="$ROOT/gitops/platform"
DASHBOARDS="$ROOT/grafana/dashboards"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

# Application name -> dashboard basename (grafana/dashboards/lab-<basename>.json).
# Add a new component here (or, if it's genuinely plumbing with no metrics of its
# own — an *-extras/-networkpolicy/-config/-resources/-certificate/-schedules/
# -policies/-root-ca/-scaling companion Application, or lab-gateway's bare
# TLSStore CR — extend the exclusion pattern below) whenever a new
# auto-synced Application lands in gitops/platform/.
declare -A COMPONENT_DASHBOARD=(
  [alloy]=alloy
  [argo-rollouts]=argo-rollouts
  [argocd-extras]=argocd
  [capstone]=capstone
  [capstone-rollout]=capstone
  [cert-manager]=cert-manager
  [data-demo]=data-demo
  [demo]=demo
  [external-secrets]=external-secrets
  [garage]=garage
  [grafana]=grafana
  [keda]=keda
  [kro]=cloud-control-plane
  [ack-s3]=cloud-control-plane
  [moto]=cloud-control-plane
  [kube-state-metrics]=ksm
  [kyverno]=kyverno
  [loki]=loki
  [mimir]=mimir
  [node-exporter]=node-exporter
  [pyroscope]=pyroscope
  [rabbitmq]=rabbitmq
  [s3manager]=s3manager
  [tempo]=tempo
  [trivy-operator]=trivy
  [valkey]=valkey
  [vault]=vault
  [velero]=velero
)

# --- 1. every mapped component's dashboard file must actually exist ---
for name in "${!COMPONENT_DASHBOARD[@]}"; do
  dash="$DASHBOARDS/lab-${COMPONENT_DASHBOARD[$name]}.json"
  [ -f "$dash" ] || bad "O5: '$name' maps to lab-${COMPONENT_DASHBOARD[$name]}.json, but that dashboard doesn't exist"
done

# --- 2. coverage loop: every auto-synced, non-plumbing Application is mapped ---
# "Auto-synced" = a real (uncommented) `automated:` syncPolicy key, not a mention
# in a comment explaining why one was deliberately omitted (every on-demand
# component documents that in prose — see e.g. gitops/platform/tidb-cluster.yaml).
if [ -d "$PLATFORM" ]; then
for f in "$PLATFORM"/*.yaml; do
  [ -e "$f" ] || continue
  kind="$(grep -m1 -E '^kind:' "$f" | awk '{print $2}')"
  [ "$kind" = "Application" ] || continue
  name="$(grep -m1 -E '^\s*name:' "$f" | awk '{print $2}')"
  [ -n "$name" ] || continue
  grep -qE '^\s+automated:\s*$' "$f" || continue
  case "$name" in
    *-extras|*-networkpolicy|*-config|*-resources|*-certificate|*-schedules|*-policies|*-root-ca|*-scaling|lab-gateway)
      continue ;;
  esac
  [ -n "${COMPONENT_DASHBOARD[$name]+set}" ] || bad "O5: auto-synced Application '$name' ($f) has no dashboard mapping in this script — add one (or, if it's genuinely plumbing, extend the exclusion pattern)"
done
fi

if [ "$drift" -eq 0 ]; then
  ok "every auto-synced Application (CHARTER O5) has a matching Grafana dashboard"
fi
exit "$drift"
