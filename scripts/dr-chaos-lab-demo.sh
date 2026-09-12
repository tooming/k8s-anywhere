#!/usr/bin/env bash
# Fault-injection drill: kill the live lab-demo (`hello`) pod and assert
# Kubernetes' own Deployment controller self-heals it — closing the rest of
# the gap docs/dora-audit-readiness.md's Q12 named. dr-chaos-argocd.sh
# (2026-09-11), dr-chaos-cert-manager.sh, and dr-chaos-traefik.sh
# (both 2026-09-12) were the first three instances; this is the fourth and
# last, covering every always-on component. This is NOT an adversarial/
# penetration-style test (DORA's TLPT concept) — it's one narrow, honest
# fault-injection drill against a currently-live always-on component, scoped
# for what this single-host lab can actually demonstrate (ADR-0005:
# recreate-over-HA).
#
#   ./scripts/dr-chaos-lab-demo.sh
#
# Requires a live cluster (kubectl reachable, lab-demo namespace populated) —
# never runs in CI (clusterless, ADR-0001's seam); make ci only lints this
# file and exercises its non-destructive guard paths (tests/dr-guards.bats),
# same as the three prior dr-chaos-*.sh scripts.
#
# Recovery predicate differs from the other three dr-chaos-*.sh scripts:
# lab-demo has no Service or IngressRoute (confirmed directly against
# gitops/apps/demo/ — no Service manifest exists, and deployment.yaml's own
# header comment says so explicitly), so there is no HTTP front-door URL to
# probe the way dr-chaos-traefik.sh does. Instead this execs into the new pod
# and reads the ConfigMap-mounted index.html directly, verifying it still
# serves lab-demo-hello's real content — a stronger check than pod-Ready
# alone (confirms the volume mount actually re-attached, not just that the
# container started).
#
# Exit 0 = the pod was killed and Kubernetes recreated + re-readied it within
# budget, and the new pod serves the real lab-demo-hello content again.
# Exit 1 = it didn't recover in time, or setup failed (e.g. no live pod found).
set -uo pipefail

# Optionally target a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"

T_POD="${DR_T_POD:-120}"
T_CONTENT="${DR_T_CONTENT:-60}"
SELECTOR="app=hello"
NS="lab-demo"
EXPECT="Hello from GitOps"

confirm_or_abort "$(printf '%sThis kills the live lab-demo (hello) pod.%s ' "$R$B" "$Z")" \
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
[ -n "$BEFORE_UID" ] || fail "no live lab-demo (hello) pod found (selector: $SELECTOR)"

phase "1/3  CHAOS — deleting the live lab-demo (hello) pod"
kubectl -n "$NS" delete pod -l "$SELECTOR" --wait=false || fail "kubectl delete pod"

phase "2/3  SELF-HEAL — waiting for Kubernetes to recreate + ready a new pod"
NEW_POD=""
p_new_pod_ready() {
  local uid ready name
  name=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  uid=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
  [ -n "$uid" ] && [ "$uid" != "$BEFORE_UID" ] || return 1
  ready=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$ready" = "true" ] || return 1
  NEW_POD="$name"
}
retry "$T_POD" 3 p_new_pod_ready || fail "no new Ready lab-demo (hello) pod within ${T_POD}s"

phase "3/3  VERIFY — the new pod serves the real lab-demo-hello content again"
p_content_ok() {
  kubectl -n "$NS" exec "$NEW_POD" -c hello -- cat /usr/share/nginx/html/index.html 2>/dev/null \
    | grep -q "$EXPECT"
}
retry "$T_CONTENT" 3 p_content_ok || fail "new pod $NEW_POD did not serve the expected content within ${T_CONTENT}s"

ELAPSED=$((SECONDS-START))
printf '\n%s%s✅ DR CHAOS PASSED%s — lab-demo self-healed in %ss.\n' "$B" "$G" "$Z" "$ELAPSED"
