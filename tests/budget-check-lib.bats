#!/usr/bin/env bats
# Clusterless structural + functional tests for scripts/lib/budget-check.sh —
# the shared wall-clock budget-check/report snippet extracted from
# near-identical inline copies in scripts/dr-restore.sh (Objective O3) and
# scripts/capstone-demo.sh (Objective O6) (janitor cleanup, mirrors the
# earlier scripts/lib/colors.sh / scripts/lib/hook-payload.sh extractions).
# Guards against the duplicate pattern creeping back in as new
# budget-timed scripts get added.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  source "$REPO/scripts/lib/colors.sh"
  source "$REPO/scripts/lib/budget-check.sh"
}

@test "scripts/lib/budget-check.sh exists" {
  [ -f "$REPO/scripts/lib/budget-check.sh" ]
}

@test "budget-check.sh defines budget_warn_if_exceeded() and budget_final_line()" {
  run grep -q "^budget_warn_if_exceeded()" "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
  run grep -q "^budget_final_line()" "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
}

@test "budget-check.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
}

@test "budget_warn_if_exceeded() is silent and returns 0 when under budget" {
  run budget_warn_if_exceeded 100 600 "O3"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "budget_warn_if_exceeded() prints BUDGET EXCEEDED and returns 1 when over budget" {
  run budget_warn_if_exceeded 700 600 "O3"
  [ "$status" -eq 1 ]
  [[ "$output" == *"BUDGET EXCEEDED"* ]]
  [[ "$output" == *"700"* ]]
  [[ "$output" == *"600"* ]]
  [[ "$output" == *"O3"* ]]
}

@test "budget_final_line() prints Total elapsed and returns 0 when under budget" {
  run budget_final_line 100 600 "O3"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total elapsed: 100s"* ]]
  [[ "$output" != *"OVER BUDGET"* ]]
}

@test "budget_final_line() prints OVER BUDGET and returns 1 when over budget" {
  run budget_final_line 700 600 "O6"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Total elapsed: 700s"* ]]
  [[ "$output" == *"OVER BUDGET"* ]]
  [[ "$output" == *"O6"* ]]
}

# --- recurrence guard: no timed script re-inlines the duplicated pattern -----
# Every scripts/*.sh that enforces a wall-clock BUDGET_S must source
# lib/budget-check.sh rather than re-declaring its own "elapsed > budget"
# printf/exit logic inline.
@test "every script defining BUDGET_S sources lib/budget-check.sh" {
  hits=""
  for f in "$REPO"/scripts/*.sh; do
    grep -q '^BUDGET_S=' "$f" || continue
    grep -q 'lib/budget-check\.sh' "$f" || hits="$hits $f"
  done
  [ -z "$hits" ]
}

@test "dr-restore.sh and capstone-demo.sh both source lib/budget-check.sh" {
  run grep -q 'lib/budget-check.sh' "$REPO/scripts/dr-restore.sh"
  [ "$status" -eq 0 ]
  run grep -q 'lib/budget-check.sh' "$REPO/scripts/capstone-demo.sh"
  [ "$status" -eq 0 ]
}
