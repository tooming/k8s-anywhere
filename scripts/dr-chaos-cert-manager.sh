#!/usr/bin/env bash
# Fault-injection drill: kill the live cert-manager controller pod and assert
# Kubernetes' own Deployment controller self-heals it — closing more of the
# gap docs/dora-audit-readiness.md's Q12 named. dr-chaos-argocd.sh (2026-09-11)
# was the first instance, covering only ArgoCD's application-controller; this
# is the second of three follow-ups covering the lab's other always-on
# components (cert-manager here; Traefik and lab-demo are separate scripts).
# This is NOT an adversarial/penetration-style test (DORA's TLPT concept) —
# it's one narrow, honest fault-injection drill against a currently-live
# always-on component, scoped for what this single-host lab can actually
# demonstrate (ADR-0005: recreate-over-HA).
#
#   ./scripts/dr-chaos-cert-manager.sh
#
# Requires a live cluster (kubectl reachable, cert-manager namespace
# populated) — never runs in CI (clusterless, ADR-0001's seam); make ci only
# lints this file and exercises its non-destructive guard paths
# (tests/dr-guards.bats), same as dr-chaos-argocd.sh/dr-test.sh/dr-verify.sh/
# dr-destroy.sh.
#
# NEEDS LIVE VERIFICATION on the next cluster rebuild: the selector below
# (app.kubernetes.io/name=cert-manager) is the upstream Jetstack chart's own
# documented controller-pod label, distinct from its sibling cainjector/
# webhook pods — not yet confirmed against a real running cluster from this
# clusterless session (ADR-0004; mirrors the identical caveat already stated
# in gitops/cert-manager/networkpolicy/allow-cert-manager-webhook-from-apiserver.yaml's
# header comment for a label/behavior assumption in this same namespace).
#
# Exit 0 = the controller pod was killed and Kubernetes recreated + re-readied
# it within budget, and both the k8s-lab-ca ClusterIssuer and the
# k8s-lab-root-ca Certificate (gitops/cert-manager/root-ca/) report Ready
# again.
# Exit 1 = it didn't recover in time, or setup failed (e.g. no live pod found).
set -uo pipefail

# Optionally target a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"

T_POD="${DR_T_POD:-120}"
T_ISSUER="${DR_T_ISSUER:-300}"
SELECTOR="app.kubernetes.io/name=cert-manager"
NS="cert-manager"

confirm_or_abort "$(printf '%sThis kills the live cert-manager controller pod.%s ' "$R$B" "$Z")" \
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

BEFORE_UID=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
[ -n "$BEFORE_UID" ] || fail "no live cert-manager controller pod found (selector: $SELECTOR)"

phase "1/3  CHAOS — deleting the live cert-manager controller pod"
kubectl -n "$NS" delete pod -l "$SELECTOR" --wait=false || fail "kubectl delete pod"

phase "2/3  SELF-HEAL — waiting for Kubernetes to recreate + ready a new pod"
p_new_pod_ready() {
  local uid ready
  uid=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
  [ -n "$uid" ] && [ "$uid" != "$BEFORE_UID" ] || return 1
  ready=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$ready" = "true" ]
}
retry "$T_POD" 3 p_new_pod_ready || fail "no new Ready cert-manager controller pod within ${T_POD}s"

phase "3/3  VERIFY — root-CA issuer chain returns to Ready"
p_issuer_chain_ready() {
  local issuer_ready cert_ready
  issuer_ready=$(kubectl get clusterissuer k8s-lab-ca \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$issuer_ready" = "True" ] || return 1
  cert_ready=$(kubectl -n "$NS" get certificate k8s-lab-root-ca \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$cert_ready" = "True" ]
}
retry "$T_ISSUER" 5 p_issuer_chain_ready || fail "k8s-lab-ca ClusterIssuer / k8s-lab-root-ca Certificate did not return to Ready within ${T_ISSUER}s"

ELAPSED=$((SECONDS-START))
printf '\n%s%s✅ DR CHAOS PASSED%s — cert-manager controller self-healed in %ss.\n' "$B" "$G" "$Z" "$ELAPSED"
