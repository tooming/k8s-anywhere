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

T_POD="${DR_T_POD:-120}"
T_ARGO="${DR_T_ARGO:-300}"
SELECTOR="app.kubernetes.io/name=argocd-application-controller"

confirm_or_abort "$(printf '%sThis kills the live argocd-application-controller pod.%s ' "$R$B" "$Z")" \
  "chaos" "to start the drill"

START=$SECONDS
fail(){ printf '\n%s%sDR CHAOS FAILED%s at: %s  (elapsed %ss)\n' "$B" "$R" "$Z" "$1" "$((SECONDS-START))"; exit 1; }

# retry <timeout_s> <interval_s> <predicate-fn> : 0 if predicate succeeds in time
retry() {
  local to=$1 iv=$2 fn=$3 end
  end=$((SECONDS + to))
  while :; do
    "$fn" && return 0
    [ "$SECONDS" -ge "$end" ] && return 1
    sleep "$iv"
  done
}

BEFORE_UID=$(kubectl -n argocd get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
[ -n "$BEFORE_UID" ] || fail "no live argocd-application-controller pod found (selector: $SELECTOR)"

phase "1/3  CHAOS — deleting the live argocd-application-controller pod"
kubectl -n argocd delete pod -l "$SELECTOR" --wait=false || fail "kubectl delete pod"

phase "2/3  SELF-HEAL — waiting for Kubernetes to recreate + ready a new pod"
p_new_pod_ready() {
  local uid ready
  uid=$(kubectl -n argocd get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
  [ -n "$uid" ] && [ "$uid" != "$BEFORE_UID" ] || return 1
  ready=$(kubectl -n argocd get pod -l "$SELECTOR" -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$ready" = "true" ]
}
retry "$T_POD" 3 p_new_pod_ready || fail "no new Ready argocd-application-controller pod within ${T_POD}s"

phase "3/3  VERIFY — ArgoCD Applications return to Synced/Healthy"
p_argo_healthy() {
  local json total green
  json=$(kubectl -n argocd get applications.argoproj.io -o json 2>/dev/null) || return 1
  total=$(jq '.items|length' <<<"$json" 2>/dev/null) || return 1
  [ "${total:-0}" -ge 1 ] || return 1
  green=$(jq '[.items[]|select(.status.sync.status=="Synced" and .status.health.status=="Healthy")]|length' <<<"$json")
  [ "$total" = "$green" ]
}
retry "$T_ARGO" 5 p_argo_healthy || fail "Applications did not return to Synced/Healthy within ${T_ARGO}s"

ELAPSED=$((SECONDS-START))
printf '\n%s%s✅ DR CHAOS PASSED%s — argocd-application-controller self-healed in %ss.\n' "$B" "$G" "$Z" "$ELAPSED"
