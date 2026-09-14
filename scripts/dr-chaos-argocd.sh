#!/usr/bin/env bash
# Fault-injection drill: kill the live argocd-application-controller pod and
# assert Kubernetes' own StatefulSet controller self-heals it — closing the
# real gap docs/dora-audit-readiness.md's Q12 named ("nothing like that
# exists today... e.g. kill the single-replica ArgoCD pod and assert
# Kubernetes' own self-heal"). This is NOT an adversarial/penetration-style
# test (DORA's TLPT concept) — it's one narrow, honest fault-injection drill
# against a currently-live always-on component, scoped for what this
# single-host lab can actually demonstrate (ADR-0005: recreate-over-HA).
#
#   ./scripts/dr-chaos-argocd.sh
#
# Requires a live cluster (kubectl reachable, argocd namespace populated) —
# never runs in CI (clusterless, ADR-0001's seam); make ci only lints this
# file and exercises its non-destructive guard paths (tests/dr-guards.bats),
# same as dr-test.sh/dr-verify.sh/dr-destroy.sh.
#
# Exit 0 = the controller pod was killed and Kubernetes recreated + re-readied
# it within budget, and ArgoCD's Applications returned to Synced/Healthy.
# Exit 1 = it didn't recover in time, or setup failed (e.g. no live pod found).
set -uo pipefail

# Optionally target a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dr-chaos.sh"

T_POD="${DR_T_POD:-120}"
T_ARGO="${DR_T_ARGO:-300}"
SELECTOR="app.kubernetes.io/name=argocd-application-controller"

confirm_or_abort "$(printf '%sThis kills the live argocd-application-controller pod.%s ' "$R$B" "$Z")" \
  "chaos" "to start the drill"

dr_chaos_start
dr_chaos_kill_and_wait argocd "$SELECTOR" "$T_POD" "argocd-application-controller"

phase "3/3  VERIFY — ArgoCD Applications return to Synced/Healthy"
p_argo_healthy() {
  local json total green
  json=$(kubectl -n argocd get applications.argoproj.io -o json 2>/dev/null) || return 1
  total=$(jq '.items|length' <<<"$json" 2>/dev/null) || return 1
  [ "${total:-0}" -ge 1 ] || return 1
  green=$(jq '[.items[]|select(.status.sync.status=="Synced" and .status.health.status=="Healthy")]|length' <<<"$json")
  [ "$total" = "$green" ]
}
dr_chaos_retry "$T_ARGO" 5 p_argo_healthy || dr_chaos_fail "Applications did not return to Synced/Healthy within ${T_ARGO}s"

ELAPSED=$((SECONDS-DR_CHAOS_START))
printf '\n%s%s✅ DR CHAOS PASSED%s — argocd-application-controller self-healed in %ss.\n' "$B" "$G" "$Z" "$ELAPSED"
