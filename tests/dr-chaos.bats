#!/usr/bin/env bats
# Clusterless structural tests for the chaos/fault-injection drill (DORA Pillar 3,
# TLPT concept). No running cluster required — mirrors tests/dr-bluegreen.bats's
# shape: verify declared structure, key thresholds, and wiring without executing
# any live command.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/dr-chaos.sh"
  MAKEFILE="$REPO/Makefile"
}

# --- Script existence + permissions ------------------------------------------

@test "dr-chaos.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "dr-chaos.sh is executable" {
  [ -x "$SCRIPT" ]
}

# --- Structure -----------------------------------------------------------------

@test "dr-chaos.sh sources the shared colors lib" {
  run grep -q 'lib/colors.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh sources the shared budget-check lib" {
  run grep -q 'lib/budget-check.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh declares a BUDGET_S constant" {
  run grep -qE '^BUDGET_S=[0-9]+' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh has a DR_ASSUME_YES non-interactive confirmation guard" {
  run grep -q 'DR_ASSUME_YES' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh refuses to run non-interactively without DR_ASSUME_YES=1" {
  run grep -q 'Refusing non-interactively without DR_ASSUME_YES=1' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh targets the capstone namespace" {
  run grep -q 'NAMESPACE="capstone"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh does not depend on shuf (uses RANDOM/sed for pod selection)" {
  run grep -q 'shuf' "$SCRIPT"
  [ "$status" -ne 0 ]
}

# --- Makefile wiring -------------------------------------------------------

@test "Makefile declares a dr-chaos target" {
  run grep -qE '^dr-chaos:' "$MAKEFILE"
  [ "$status" -eq 0 ]
}

@test "dr-chaos target is NOT invoked from the up target (on-demand only)" {
  up_block=$(sed -n '/^up:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-chaos' <<<"$up_block"
}

@test "dr-chaos target is NOT invoked from the ci target (on-demand only)" {
  ci_block=$(sed -n '/^ci:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-chaos' <<<"$ci_block"
}

@test "dr-chaos target is NOT invoked from dr-test's own block (on-demand only)" {
  dr_test_block=$(sed -n '/^dr-test:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-chaos' <<<"$dr_test_block"
}
