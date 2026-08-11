# Shared DR/capstone-demo results-history logger — sourced, not executed.
# docs/dora-audit-readiness.md Q13's gap: pass/fail is enforced by exit codes
# (CI-style) but there was no historical log of *past* run results over time —
# only whether today's run passed, not whether e.g. the 10-minute RTO is
# trending up as the lab grows. This closes that gap the same way
# scripts/lib/budget-check.sh consolidated the near-identical inline
# budget-check logic: one shared function, called from every DR/capstone-demo
# script's pass AND fail exit path, so a future format tweak needs one edit.

# dr_log_result <script_name> <status> <elapsed_s> <budget_s> <objective_tag>
# Appends one row to docs/dr-results-log.md, creating the file with a header
# on first write if it doesn't exist yet. <status> must be the literal string
# PASS or FAIL — callers report their own real outcome, never a fabricated one
# (ADR-0004). The log path can be overridden via DR_RESULTS_LOG (used by
# tests/dr-results-log.bats to log to a scratch file instead of the real one).
dr_log_result() {
  local script_name="$1" status="$2" elapsed_s="$3" budget_s="$4" objective_tag="$5"
  local log="${DR_RESULTS_LOG:-}"
  if [ -z "$log" ]; then
    log="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docs/dr-results-log.md"
  fi

  if [ ! -f "$log" ]; then
    {
      printf '# DR / capstone-demo results log\n\n'
      printf 'Auto-appended by `scripts/lib/dr-results-log.sh` — one row per real run of a\n'
      printf 'DR/capstone-demo script, pass or fail. See [docs/DR.md](DR.md). Never hand-edited\n'
      printf 'or backfilled with invented data (ADR-0004) — an empty table below the header\n'
      printf 'means no real run has happened yet, not that the mechanism is missing.\n\n'
      printf '| Date (UTC) | Script | Status | Elapsed (s) | Budget (s) | Objective |\n'
      printf '|------------|--------|--------|--------------|------------|-----------|\n'
    } > "$log"
  fi

  printf '| %s | %s | %s | %s | %s | %s |\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$script_name" "$status" "$elapsed_s" "$budget_s" "$objective_tag" \
    >> "$log"
}
