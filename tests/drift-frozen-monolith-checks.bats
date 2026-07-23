#!/usr/bin/env bats
# Tests for the "frozen monolith" drift-check scripts — split out of the
# now-frozen tests/drift-detectors.bats monolith (see that file's header
# comment) into their own scope, per the drift-detectors-tests-check
# convention: new drift-check coverage goes in its own tests/drift-<scope>.bats
# file. Grouped together here (rather than three separate files) because all
# three check scripts share one job: verifying a *different* frozen monolith
# (tests/securitycontext.bats, tests/observability.bats,
# tests/networkpolicy.bats respectively) hasn't grown a new appended @test.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- securitycontext-tests-check ---------------------------------------------
@test "securitycontext-tests-check: passes when the monolith matches its snapshot" {
  run env SECCTX_TESTS_ROOT="$FIX/securitycontext-tests-check/in-sync" bash "$REPO/scripts/securitycontext-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "securitycontext-tests-check: fails when a new @test is appended to the frozen monolith" {
  run env SECCTX_TESTS_ROOT="$FIX/securitycontext-tests-check/drift" bash "$REPO/scripts/securitycontext-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FROZEN"* ]]
}

@test "securitycontext-tests-check: passes on the real repo tests/securitycontext.bats" {
  run bash "$REPO/scripts/securitycontext-tests-check.sh"
  [ "$status" -eq 0 ]
}

# --- observability-tests-check -----------------------------------------------
@test "observability-tests-check: passes when the monolith matches its snapshot" {
  run env OBSV_TESTS_ROOT="$FIX/observability-tests-check/in-sync" bash "$REPO/scripts/observability-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "observability-tests-check: fails when a new @test is appended to the frozen monolith" {
  run env OBSV_TESTS_ROOT="$FIX/observability-tests-check/drift" bash "$REPO/scripts/observability-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FROZEN"* ]]
}

@test "observability-tests-check: passes on the real repo tests/observability.bats" {
  run bash "$REPO/scripts/observability-tests-check.sh"
  [ "$status" -eq 0 ]
}

# --- networkpolicy-tests-check -----------------------------------------------
@test "networkpolicy-tests-check: passes when the monolith is baseline-only" {
  run env NETPOL_TESTS_ROOT="$FIX/networkpolicy-tests-check/in-sync" bash "$REPO/scripts/networkpolicy-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-tests-check: fails when a per-namespace overlay test leaks into the monolith" {
  run env NETPOL_TESTS_ROOT="$FIX/networkpolicy-tests-check/drift" bash "$REPO/scripts/networkpolicy-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"namespace overlay"* ]]
}

@test "networkpolicy-tests-check: passes on the real repo tests/networkpolicy.bats" {
  run bash "$REPO/scripts/networkpolicy-tests-check.sh"
  [ "$status" -eq 0 ]
}
