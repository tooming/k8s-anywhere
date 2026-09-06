#!/usr/bin/env bash
# End-to-end capstone demonstration: asserts the pipeline is healthy within the
# CHARTER Objective O6 budget (< 900 s wall-clock).
#
# Steps:
#   1  capstone ArgoCD Application is Healthy (argocd app wait, 120 s timeout)
#   2  capstone ExternalSecret is Ready        (kubectl jsonpath poll, 30 s)
#   3  capstone HTTP endpoint returns 200      (curl http://capstone.127.0.0.1.nip.io:8000/)
#
# Step 4 (Tempo trace for the capstone service) was removed 2026-09-06 (ADR-0041,
# observability stack removed with no replacement) — Tempo no longer exists to
# query.
#
# Exit codes: 0 = all steps passed within budget; 1 = a step failed or timed out.
#
# Pre-requisites (runs against a live cluster):
#   - argocd CLI logged in  (run make argocd-password, then argocd login ...)
#   - kubectl configured to the active cluster context
#   - capstone Application deployed and IngressRoute reachable via Traefik
#
# Usage:
#   ./scripts/capstone-demo.sh
#   make capstone-demo
set -euo pipefail

BUDGET_S=900   # CHARTER Objective O6: < 15 min (900 s) total wall-clock
START=$SECONDS

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/budget-check.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dr-results-log.sh"

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
  budget_warn_if_exceeded "$total" "$BUDGET_S" "O6" || FAILED=1
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
# Summary table
# ------------------------------------------------------------------
TOTAL_ELAPSED=$(( SECONDS - START ))

printf '\n%s--- Capstone demo summary ---%s\n' "$B" "$Z"
printf '%-36s  %-10s  %s\n' "Step" "Elapsed(s)" "Status"
printf '%-36s  %-10s  %s\n' "----" "----------" "------"
for i in "${!STEP_NAMES[@]}"; do
  printf '%-36s  %-10s  %s\n' "${STEP_NAMES[$i]}" "${STEP_ELAPSED[$i]}" "${STEP_STATUS[$i]}"
done
budget_final_line "$TOTAL_ELAPSED" "$BUDGET_S" "O6" || FAILED=1

echo ""
if [ "$FAILED" -eq 0 ]; then
  printf '%s✅ CAPSTONE DEMO PASSED — all steps completed in %ds (< %ds budget).%s\n' \
    "$G$B" "$TOTAL_ELAPSED" "$BUDGET_S" "$Z"
  dr_log_result "capstone-demo.sh" "PASS" "$TOTAL_ELAPSED" "$BUDGET_S" "O6"
  exit 0
else
  printf '%s✗ CAPSTONE DEMO FAILED — see details above.%s\n' "$R$B" "$Z"
  dr_log_result "capstone-demo.sh" "FAIL" "$TOTAL_ELAPSED" "$BUDGET_S" "O6"
  exit 1
fi
