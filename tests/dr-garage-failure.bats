#!/usr/bin/env bats
# Clusterless structural tests for the Garage-failure drill (DORA Pillar 3,
# TLPT concept — a third, distinct fault-injection scenario alongside
# dr-chaos.sh's capstone pod-kill and dr-network-partition.sh's capstone
# NetworkPolicy-delete, per docs/dora-audit-readiness.md Q12's own named
# follow-up). No running cluster required — mirrors
# tests/dr-network-partition.bats's shape: verify declared structure, key
# thresholds, and wiring without executing any live command.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/dr-garage-failure.sh"
  MAKEFILE="$REPO/Makefile"
}

# --- Script existence + permissions ------------------------------------------

@test "dr-garage-failure.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "dr-garage-failure.sh is executable" {
  [ -x "$SCRIPT" ]
}

# --- Structure -----------------------------------------------------------------

@test "dr-garage-failure.sh sources the shared colors lib" {
  run grep -q 'lib/colors.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh sources the shared budget-check lib" {
  run grep -q 'lib/budget-check.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh sources the shared confirm lib" {
  run grep -q 'lib/confirm.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh sources the shared dr-results-log lib" {
  run grep -q 'lib/dr-results-log.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh uses the shared confirm_or_abort guard" {
  run grep -q 'confirm_or_abort' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh declares a BUDGET_S constant" {
  run grep -qE '^BUDGET_S=[0-9]+' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh targets the storage namespace" {
  run grep -q 'NAMESPACE="storage"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh targets the real Garage StatefulSet (matches the live manifest)" {
  # Recurrence guard: this must name a label selector that actually matches
  # the live gitops/storage/garage/statefulset.yaml shape, not an
  # invented/stale one.
  run grep -q 'LABEL_SELECTOR="app=garage"' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$REPO/gitops/storage/garage/statefulset.yaml" ]
  run grep -q 'app: garage' "$REPO/gitops/storage/garage/statefulset.yaml"
  [ "$status" -eq 0 ]
  run grep -qE '^\s*replicas:\s*1\s*$' "$REPO/gitops/storage/garage/statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure.sh calls dr_log_result on both the healed and not-healed exit paths" {
  run bash -c "grep -c 'dr_log_result \"dr-garage-failure.sh\"' '$SCRIPT'"
  [ "$output" = "2" ]
}

# --- Self-heal check targets readiness, not just phase=Running ---------------

@test "dr-garage-failure.sh polls for a ready replacement pod via a separate poll loop after the delete" {
  poll_block="$(sed -n '/^START=\$SECONDS/,/^ELAPSED=/p' "$SCRIPT")"
  [[ "$poll_block" == *"containerStatuses[0].ready"* ]]
  [[ "$poll_block" == *"metadata.name!=\${OLD_NAME}"* ]]
}

@test "dr-garage-failure.sh uses --wait=false on the pod delete (correct for a pod, unlike a NetworkPolicy delete)" {
  # A pod delete has a terminationGracePeriodSeconds window, so --wait=false
  # (matching dr-chaos.sh's own pod-delete pattern) avoids blocking here.
  # Do NOT flip this to --wait=true (dr-network-partition.bats's own
  # recurrence guard checks the opposite requirement, correctly, for its
  # NetworkPolicy object).
  delete_block="$(sed -n '/kubectl delete "\$TARGET"/,/^START=\$SECONDS/p' "$SCRIPT")"
  [[ "$delete_block" == *"--wait=false"* ]]
}

# --- Makefile wiring -------------------------------------------------------

@test "Makefile declares a dr-garage-failure target" {
  run grep -qE '^dr-garage-failure:' "$MAKEFILE"
  [ "$status" -eq 0 ]
}

@test "dr-garage-failure target is NOT invoked from the up target (on-demand only)" {
  up_block=$(sed -n '/^up:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-garage-failure' <<<"$up_block"
}

@test "dr-garage-failure target is NOT invoked from the ci target (on-demand only)" {
  ci_block=$(sed -n '/^ci:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-garage-failure' <<<"$ci_block"
}

@test "dr-garage-failure target is NOT invoked from dr-test's own block (on-demand only)" {
  dr_test_block=$(sed -n '/^dr-test:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-garage-failure' <<<"$dr_test_block"
}
