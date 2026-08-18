#!/usr/bin/env bats
# Clusterless structural tests for the network-partition drill (DORA Pillar 3,
# TLPT concept — a second, distinct fault-injection scenario from dr-chaos.sh's
# pod-kill, per docs/dora-audit-readiness.md Q12's own named follow-up). No
# running cluster required — mirrors tests/dr-chaos.bats's shape: verify
# declared structure, key thresholds, and wiring without executing any live
# command.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/dr-network-partition.sh"
  MAKEFILE="$REPO/Makefile"
}

# --- Script existence + permissions ------------------------------------------

@test "dr-network-partition.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "dr-network-partition.sh is executable" {
  [ -x "$SCRIPT" ]
}

# --- Structure -----------------------------------------------------------------

@test "dr-network-partition.sh sources the shared colors lib" {
  run grep -q 'lib/colors.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh sources the shared budget-check lib" {
  run grep -q 'lib/budget-check.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh sources the shared confirm lib" {
  run grep -q 'lib/confirm.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh sources the shared dr-results-log lib" {
  run grep -q 'lib/dr-results-log.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh uses the shared confirm_or_abort guard" {
  run grep -q 'confirm_or_abort' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh declares a BUDGET_S constant" {
  run grep -qE '^BUDGET_S=[0-9]+' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh targets the capstone namespace" {
  run grep -q 'NAMESPACE="capstone"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition.sh targets the real ingress-allow NetworkPolicy (matches the live manifest)" {
  # Recurrence guard: this must name a NetworkPolicy that actually exists
  # under gitops/apps/capstone/networkpolicy/, not an invented/stale name.
  run grep -q 'POLICY="allow-capstone-ingress-from-gateway"' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$REPO/gitops/apps/capstone/networkpolicy/allow-capstone-ingress-from-gateway.yaml" ]
}

@test "dr-network-partition.sh calls dr_log_result on both the healed and not-healed exit paths" {
  run bash -c "grep -c 'dr_log_result \"dr-network-partition.sh\"' '$SCRIPT'"
  [ "$output" = "2" ]
}

# --- Self-heal check targets the object, not just delete success -------------

@test "dr-network-partition.sh polls for the NetworkPolicy's re-existence via a separate poll loop after the delete" {
  poll_block="$(sed -n '/^START=\$SECONDS/,/^ELAPSED=/p' "$SCRIPT")"
  [[ "$poll_block" == *"kubectl get networkpolicy \"\$POLICY\""* ]]
}

@test "dr-network-partition.sh does NOT use --wait=false on the NetworkPolicy delete (recurrence guard, found in self-review 2026-08-18)" {
  # --wait=false returns as soon as the delete request is *accepted*, not
  # *completed* -- the self-heal poll's first iteration could then still see
  # the not-yet-deleted object and report a false-positive instant pass.
  # Unlike dr-chaos.sh's pod delete (which legitimately uses --wait=false to
  # avoid blocking for terminationGracePeriodSeconds), a NetworkPolicy has no
  # grace period, so the default --wait=true (confirmed-gone before
  # returning) is both correct and effectively instant here.
  delete_block="$(sed -n '/kubectl delete networkpolicy/,/^START=\$SECONDS/p' "$SCRIPT")"
  [[ "$delete_block" != *"--wait=false"* ]]
}

# --- Makefile wiring -------------------------------------------------------

@test "Makefile declares a dr-network-partition target" {
  run grep -qE '^dr-network-partition:' "$MAKEFILE"
  [ "$status" -eq 0 ]
}

@test "dr-network-partition target is NOT invoked from the up target (on-demand only)" {
  up_block=$(sed -n '/^up:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-network-partition' <<<"$up_block"
}

@test "dr-network-partition target is NOT invoked from the ci target (on-demand only)" {
  ci_block=$(sed -n '/^ci:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-network-partition' <<<"$ci_block"
}

@test "dr-network-partition target is NOT invoked from dr-test's own block (on-demand only)" {
  dr_test_block=$(sed -n '/^dr-test:/,/^$/p' "$MAKEFILE")
  ! grep -q 'dr-network-partition' <<<"$dr_test_block"
}
