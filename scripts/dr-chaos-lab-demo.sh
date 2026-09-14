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
source "$(dirname "${BASH_SOURCE[0]}")/lib/dr-chaos.sh"

T_POD="${DR_T_POD:-120}"
T_CONTENT="${DR_T_CONTENT:-60}"
SELECTOR="app=hello"
NS="lab-demo"
EXPECT="Hello from GitOps"

confirm_or_abort "$(printf '%sThis kills the live lab-demo (hello) pod.%s ' "$R$B" "$Z")" \
  "chaos" "to start the drill"

dr_chaos_start
dr_chaos_kill_and_wait "$NS" "$SELECTOR" "$T_POD" "lab-demo (hello)"

phase "3/3  VERIFY — the new pod serves the real lab-demo-hello content again"
p_content_ok() {
  kubectl -n "$NS" exec "$DR_CHAOS_NEW_POD_NAME" -c hello -- cat /usr/share/nginx/html/index.html 2>/dev/null \
    | grep -q "$EXPECT"
}
dr_chaos_retry "$T_CONTENT" 3 p_content_ok || dr_chaos_fail "new pod $DR_CHAOS_NEW_POD_NAME did not serve the expected content within ${T_CONTENT}s"

ELAPSED=$((SECONDS-DR_CHAOS_START))
printf '\n%s%s✅ DR CHAOS PASSED%s — lab-demo self-healed in %ss.\n' "$B" "$G" "$Z" "$ELAPSED"
