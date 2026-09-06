#!/usr/bin/env bash
# Restore every stateful namespace from its latest Velero backup and verify
# completion within the CHARTER Objective O3 budget (< 10 min / 600 s).
#
# Usage:
#   ./scripts/dr-restore.sh [data capstone vault observability]
#
# The namespaces list defaults to the four documented in ADR-0021 §"Scope &
# exceptions" (observability added 2026-07-29 once its own Schedule landed —
# see the ADR's Re-evaluation log; tidb removed 2026-09-06 when TiDB was
# removed from the lab entirely). Each namespace is restored
# sequentially (Kopia FS-restore is I/O-bound; parallel restores would
# saturate the single-node disk and likely overshoot the budget).
#
# Exit codes: 0 = all restores completed within budget; 1 = at least one restore
# failed or incomplete, or total wall-clock exceeded 600 s.
set -uo pipefail

NAMESPACES=("${@:-data capstone vault observability}")
# Flatten a single-element array that was passed as one space-delimited string
if [ "${#NAMESPACES[@]}" -eq 1 ]; then
  read -r -a NAMESPACES <<< "${NAMESPACES[0]}"
fi

BUDGET_S=600   # CHARTER Objective O3: < 10 min total wall-clock

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/budget-check.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dr-results-log.sh"

START=$SECONDS
FAILED=0

declare -a RESULTS_NS
declare -a RESULTS_ELAPSED
declare -a RESULTS_STATUS

echo ""
printf '%s== Velero DR Restore (Objective O3 — budget %ds) ==%s\n' "$B" "$BUDGET_S" "$Z"
printf '  Namespaces: %s\n\n' "${NAMESPACES[*]}"

for NS in "${NAMESPACES[@]}"; do
  SCHEDULE="${NS}-daily"
  RESTORE_NAME="dr-restore-${NS}-$(date +%s)"
  printf '  → restoring %s from schedule %s ...\n' "$NS" "$SCHEDULE"

  NS_START=$SECONDS

  # Run velero restore; capture output for phase extraction
  if velero restore create "$RESTORE_NAME" \
      --from-schedule "$SCHEDULE" \
      --wait 2>&1; then
    # velero --wait exits 0 only when the restore reaches a terminal phase.
    # Confirm phase is Completed (not PartiallyFailed / Failed).
    PHASE=$(velero restore get "$RESTORE_NAME" \
              -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    NS_ELAPSED=$(( SECONDS - NS_START ))
    if [ "$PHASE" = "Completed" ]; then
      printf '    %s✓%s %s  phase=%s  elapsed=%ds\n' "$G" "$Z" "$NS" "$PHASE" "$NS_ELAPSED"
      RESULTS_STATUS+=("OK")
    else
      printf '    %s✗%s %s  phase=%s  elapsed=%ds\n' "$R" "$Z" "$NS" "$PHASE" "$NS_ELAPSED"
      RESULTS_STATUS+=("FAIL(phase=$PHASE)")
      FAILED=1
    fi
  else
    NS_ELAPSED=$(( SECONDS - NS_START ))
    printf '    %s✗%s %s  velero restore create failed  elapsed=%ds\n' "$R" "$Z" "$NS" "$NS_ELAPSED"
    RESULTS_STATUS+=("FAIL(create-error)")
    FAILED=1
  fi

  RESULTS_NS+=("$NS")
  RESULTS_ELAPSED+=("$NS_ELAPSED")

  # Check cumulative budget after each restore
  TOTAL_ELAPSED=$(( SECONDS - START ))
  # Continue to restore remaining namespaces so the table is complete,
  # but the exit code is already 1.
  budget_warn_if_exceeded "$TOTAL_ELAPSED" "$BUDGET_S" "O3" || FAILED=1
done

TOTAL_ELAPSED=$(( SECONDS - START ))

# Print summary table
printf '\n%s--- Restore summary ---%s\n' "$B" "$Z"
printf '%-16s  %-10s  %s\n' "Namespace" "Elapsed(s)" "Status"
printf '%-16s  %-10s  %s\n' "---------" "----------" "------"
for i in "${!RESULTS_NS[@]}"; do
  printf '%-16s  %-10s  %s\n' "${RESULTS_NS[$i]}" "${RESULTS_ELAPSED[$i]}" "${RESULTS_STATUS[$i]}"
done
budget_final_line "$TOTAL_ELAPSED" "$BUDGET_S" "O3" || FAILED=1

echo ""
if [ "$FAILED" -eq 0 ]; then
  printf '%s✅ DR RESTORE PASSED — all namespaces restored in %ds (< %ds budget).%s\n' \
    "$G$B" "$TOTAL_ELAPSED" "$BUDGET_S" "$Z"
  dr_log_result "dr-restore.sh" "PASS" "$TOTAL_ELAPSED" "$BUDGET_S" "O3"
  exit 0
else
  printf '%s✗ DR RESTORE FAILED — see details above.%s\n' "$R$B" "$Z"
  dr_log_result "dr-restore.sh" "FAIL" "$TOTAL_ELAPSED" "$BUDGET_S" "O3"
  exit 1
fi
