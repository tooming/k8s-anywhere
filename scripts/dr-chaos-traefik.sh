#!/usr/bin/env bash
# Fault-injection drill: kill the live Traefik pod (kube-system, bundled with
# k3s per ADR-0040) and assert Kubernetes' own Deployment controller
# self-heals it — closing more of the gap docs/dora-audit-readiness.md's Q12
# named. dr-chaos-argocd.sh (2026-09-11) and dr-chaos-cert-manager.sh
# (2026-09-12) were the first two instances; this is the third of three
# follow-ups covering the lab's other always-on components (Traefik here;
# lab-demo is the last, separate script). This is NOT an adversarial/
# penetration-style test (DORA's TLPT concept) — it's one narrow, honest
# fault-injection drill against a currently-live always-on component, scoped
# for what this single-host lab can actually demonstrate (ADR-0005:
# recreate-over-HA).
#
#   ./scripts/dr-chaos-traefik.sh
#
# Requires a live cluster (kubectl reachable, kube-system namespace populated,
# the k3d load-balancer port :8080 reachable) — never runs in CI (clusterless,
# ADR-0001's seam); make ci only lints this file and exercises its
# non-destructive guard paths (tests/dr-guards.bats), same as
# dr-chaos-argocd.sh/dr-chaos-cert-manager.sh/dr-test.sh/dr-verify.sh/
# dr-destroy.sh.
#
# Exit 0 = the Traefik pod was killed and Kubernetes recreated + re-readied it
# within budget, and the lab's own HTTP front door answers again.
# Exit 1 = it didn't recover in time, or setup failed (e.g. no live pod found).
set -uo pipefail

# Optionally target a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"

T_POD="${DR_T_POD:-120}"
T_HTTP="${DR_T_HTTP:-180}"
SELECTOR="app.kubernetes.io/name=traefik"
NS="kube-system"
# Same URL lab-health-check.sh's own UI_PROBES already probes through the
# Traefik front door — reused rather than inventing a second endpoint.
PROBE_URL="${DR_PROBE_URL:-http://argocd.127.0.0.1.nip.io:8080/healthz}"

confirm_or_abort "$(printf '%sThis kills the live Traefik pod.%s ' "$R$B" "$Z")" \
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
[ -n "$BEFORE_UID" ] || fail "no live Traefik pod found (selector: $SELECTOR)"

phase "1/3  CHAOS — deleting the live Traefik pod"
kubectl -n "$NS" delete pod -l "$SELECTOR" --wait=false || fail "kubectl delete pod"

phase "2/3  SELF-HEAL — waiting for Kubernetes to recreate + ready a new pod"
p_new_pod_ready() {
  local uid ready
  uid=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
  [ -n "$uid" ] && [ "$uid" != "$BEFORE_UID" ] || return 1
  ready=$(kubectl -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$ready" = "true" ]
}
retry "$T_POD" 3 p_new_pod_ready || fail "no new Ready Traefik pod within ${T_POD}s"

phase "3/3  VERIFY — the lab's HTTP front door answers again"
p_http_ok() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 6 "$PROBE_URL" 2>/dev/null)
  case "$code" in 2*|3*|401|403) return 0 ;; *) return 1 ;; esac
}
retry "$T_HTTP" 3 p_http_ok || fail "$PROBE_URL did not answer within ${T_HTTP}s"

ELAPSED=$((SECONDS-START))
printf '\n%s%s✅ DR CHAOS PASSED%s — Traefik self-healed in %ss.\n' "$B" "$G" "$Z" "$ELAPSED"
