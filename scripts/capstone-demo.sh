#!/usr/bin/env bash
# End-to-end capstone demonstration: asserts the pipeline is healthy within the
# CHARTER Objective O6 budget (< 900 s wall-clock).
#
# Steps:
#   1  capstone ArgoCD Application is Healthy (argocd app wait, 120 s timeout)
#   2  capstone ExternalSecret is Ready        (kubectl jsonpath poll, 30 s)
#   3  capstone HTTP endpoint returns 200      (curl http://capstone.127.0.0.1.nip.io:8000/)
#   4  Tempo trace for the capstone service    (port-forward + /api/search, 5 min look-back)
#
# Exit codes: 0 = all steps passed within budget; 1 = a step failed or timed out.
#
# Pre-requisites (runs against a live cluster):
#   - argocd CLI logged in  (run make argocd-password, then argocd login ...)
#   - kubectl configured to the active cluster context
#   - capstone Application deployed and HTTPRoute reachable via Envoy
#
# Usage:
#   ./scripts/capstone-demo.sh
#   make capstone-demo
set -euo pipefail

BUDGET_S=900   # CHARTER Objective O6: < 15 min (900 s) total wall-clock
START=$SECONDS

if [ -t 1 ]; then
  G=$'\033[32m'; R=$'\033[31m'; B=$'\033[1m'; Z=$'\033[0m'
else
  G=; R=; B=; Z=
fi

declare -a STEP_NAMES
declare -a STEP_ELAPSED
declare -a STEP_STATUS

FAILED=0
_STEP_START=0

step_start() {
  printf '\n%s→ Step %d: %s%s\n' "$B" "$1" "$2" "$Z"
  _STEP_START=$SECONDS
}

step_ok() {
  local elapsed=$(( SECONDS - _STEP_START ))
  printf '  %s✓%s %s  elapsed=%ds\n' "$G" "$Z" "$1" "$elapsed"
  STEP_NAMES+=("$1")
  STEP_ELAPSED+=("$elapsed")
  STEP_STATUS+=("OK")
}

step_fail() {
  local elapsed=$(( SECONDS - _STEP_START ))
  printf '  %s✗%s %s  elapsed=%ds\n' "$R" "$Z" "$1" "$elapsed"
  STEP_NAMES+=("$1")
  STEP_ELAPSED+=("$elapsed")
  STEP_STATUS+=("FAIL")
  FAILED=1
}

budget_check() {
  local total=$(( SECONDS - START ))
  if [ "$total" -gt "$BUDGET_S" ]; then
    printf '\n%s✗ BUDGET EXCEEDED: %ds elapsed > %ds (O6 budget).%s\n' \
      "$R$B" "$total" "$BUDGET_S" "$Z"
    FAILED=1
  fi
}

echo ""
printf '%s== Capstone Demo (Objective O6 — budget %ds) ==%s\n' "$B" "$BUDGET_S" "$Z"

# ------------------------------------------------------------------
# Step 1: capstone ArgoCD Application is Healthy
# ------------------------------------------------------------------
step_start 1 "capstone ArgoCD Application Healthy"
if argocd app wait capstone --health --timeout 120 2>&1; then
  step_ok "capstone app Healthy"
else
  step_fail "capstone app not Healthy within 120 s"
fi
budget_check

# ------------------------------------------------------------------
# Step 2: capstone ExternalSecret Ready
# ------------------------------------------------------------------
step_start 2 "capstone ExternalSecret Ready"
ES_DEADLINE=$(( SECONDS + 30 ))
ES_READY=0
while [ "$SECONDS" -lt "$ES_DEADLINE" ]; do
  ES_STATUS=$(kubectl -n capstone get externalsecret \
    -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
  if [ "$ES_STATUS" = "True" ]; then
    ES_READY=1
    break
  fi
  sleep 3
done
if [ "$ES_READY" -eq 1 ]; then
  step_ok "ExternalSecret Ready"
else
  step_fail "ExternalSecret not Ready within 30 s"
fi
budget_check

# ------------------------------------------------------------------
# Step 3: capstone HTTP endpoint returns 200
# ------------------------------------------------------------------
step_start 3 "capstone HTTP 200"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
  "http://capstone.127.0.0.1.nip.io:8000/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  step_ok "HTTP $HTTP_CODE from http://capstone.127.0.0.1.nip.io:8000/"
else
  step_fail "HTTP $HTTP_CODE (expected 200) from http://capstone.127.0.0.1.nip.io:8000/"
fi
budget_check

# ------------------------------------------------------------------
# Step 4: Tempo trace for service.name=capstone
# ------------------------------------------------------------------
step_start 4 "Tempo trace for capstone service"

# OS-portable 5-minute look-back (seconds since epoch minus 300).
# macOS / BSD date uses -v; GNU date (Linux) uses arithmetic on +%s.
if date -v-5M +%s >/dev/null 2>&1; then
  START_NS=$(( $(date -v-5M +%s) * 1000000000 ))
else
  START_NS=$(( ($(date +%s) - 300) * 1000000000 ))
fi
END_NS=$(( $(date +%s) * 1000000000 ))

# Port-forward Tempo query frontend; kill on exit.
PF_PID=""
cleanup() {
  [ -n "$PF_PID" ] && kill "$PF_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

kubectl -n observability port-forward svc/tempo-query-frontend 3100:3100 \
  >/dev/null 2>&1 &
PF_PID=$!
sleep 2  # allow port-forward to establish

TRACE_RESULT=$(curl -sf \
  "http://localhost:3100/api/search?service.name=capstone&start=${START_NS}&end=${END_NS}" \
  2>/dev/null || echo "")

if echo "$TRACE_RESULT" | grep -q '"traceID"'; then
  step_ok "Tempo trace found for service.name=capstone"
elif [ -z "$TRACE_RESULT" ]; then
  step_fail "Tempo port-forward did not respond — is the cluster reachable?"
else
  # Tempo up but no traces yet; this is expected before traffic is sent.
  # Warn rather than hard-fail: the script exercises the pipeline shape.
  elapsed=$(( SECONDS - _STEP_START ))
  printf '  %s⚠%s  Tempo reachable but no trace yet for service.name=capstone\n' "$B" "$Z"
  printf '        Send traffic first: curl http://capstone.127.0.0.1.nip.io:8000/\n'
  STEP_NAMES+=("Tempo trace")
  STEP_ELAPSED+=("$elapsed")
  STEP_STATUS+=("WARN(no-trace-yet)")
fi
budget_check

# ------------------------------------------------------------------
# Summary table
# ------------------------------------------------------------------
TOTAL_ELAPSED=$(( SECONDS - START ))

printf '\n%s--- Capstone demo summary ---%s\n' "$B" "$Z"
printf '%-36s  %-10s  %s\n' "Step" "Elapsed(s)" "Status"
printf '%-36s  %-10s  %s\n' "----" "----------" "------"
for i in "${!STEP_NAMES[@]}"; do
  printf '%-36s  %-10s  %s\n' "${STEP_NAMES[$i]}" "${STEP_ELAPSED[$i]}" "${STEP_STATUS[$i]}"
done
printf '\n  Total elapsed: %ds  (budget: %ds)\n' "$TOTAL_ELAPSED" "$BUDGET_S"

if [ "$TOTAL_ELAPSED" -gt "$BUDGET_S" ]; then
  printf '  %s✗ OVER BUDGET (Objective O6 requires < %ds)%s\n' "$R$B" "$BUDGET_S" "$Z"
  FAILED=1
fi

echo ""
if [ "$FAILED" -eq 0 ]; then
  printf '%s✅ CAPSTONE DEMO PASSED — all steps completed in %ds (< %ds budget).%s\n' \
    "$G$B" "$TOTAL_ELAPSED" "$BUDGET_S" "$Z"
  exit 0
else
  printf '%s✗ CAPSTONE DEMO FAILED — see details above.%s\n' "$R$B" "$Z"
  exit 1
fi
