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

@test "dr-chaos.sh sources the shared confirm lib" {
  run grep -q 'lib/confirm.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh uses the shared confirm_or_abort guard" {
  run grep -q 'confirm_or_abort' "$SCRIPT"
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

# --- Self-heal check correctness (2026-08-13 bugfix recurrence guards) --------
# The original self-heal poll counted the just-deleted pod as still healthy
# (status.phase stays Running throughout a pod's termination grace period —
# "Terminating" is a kubectl display-only label, not a real phase value), and
# only checked phase=Running rather than actual container readiness — both let
# the drill report instant false-positive "self-heal confirmed" results. These
# guard the fix without needing a live cluster.

@test "dr-chaos.sh excludes the deleted pod's own name from the self-heal field-selector" {
  run grep -q 'metadata.name!=\${OLD_NAME}' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh captures the deleted pod's bare name before deleting it" {
  run grep -q 'OLD_NAME="\${TARGET#pod/}"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh checks actual container readiness, not just pod phase" {
  run grep -q 'status.containerStatuses\[0\].ready' "$SCRIPT"
  [ "$status" -eq 0 ]
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
