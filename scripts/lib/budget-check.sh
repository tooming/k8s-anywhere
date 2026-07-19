# Shared wall-clock budget check/report helpers — sourced, not executed.
# scripts/dr-restore.sh (CHARTER Objective O3) and scripts/capstone-demo.sh
# (Objective O6) each hand-rolled near-identical "did we blow the budget"
# printf/exit logic; consolidated here so a future format tweak only needs
# one edit, mirroring the colors.sh / hook-payload.sh extraction precedent.
# Callers must source scripts/lib/colors.sh first ($R/$G/$B/$Z).

# budget_warn_if_exceeded <elapsed_s> <budget_s> <objective_tag>
# Mid-run check: prints a "BUDGET EXCEEDED" warning if elapsed > budget.
# Returns 1 if exceeded (caller sets its own FAILED flag), 0 otherwise.
budget_warn_if_exceeded() {
  local elapsed="$1" budget="$2" tag="$3"
  if [ "$elapsed" -gt "$budget" ]; then
    printf '\n%s✗ BUDGET EXCEEDED: %ds elapsed > %ds budget (%s).%s\n' \
      "$R$B" "$elapsed" "$budget" "$tag" "$Z"
    return 1
  fi
  return 0
}

# budget_final_line <elapsed_s> <budget_s> <objective_tag>
# End-of-run report: prints the "Total elapsed" line, then an "OVER BUDGET"
# line if exceeded. Returns 1 if exceeded, 0 otherwise.
budget_final_line() {
  local elapsed="$1" budget="$2" tag="$3"
  printf '\n  Total elapsed: %ds  (budget: %ds)\n' "$elapsed" "$budget"
  if [ "$elapsed" -gt "$budget" ]; then
    printf '  %s✗ OVER BUDGET (Objective %s requires < %ds)%s\n' "$R$B" "$tag" "$budget" "$Z"
    return 1
  fi
  return 0
}
