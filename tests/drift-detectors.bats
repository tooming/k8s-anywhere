#!/usr/bin/env bats
# Tests for the drift detectors themselves — readme-check.sh and lab-ui-check.sh
# gate correctness via the PostToolUse hooks, so they need their own proof that
# they (a) pass on an in-sync tree and (b) actually FAIL on real drift. Each script
# takes a ROOT override, so we point it at golden fixture trees under tests/fixtures.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- readme-check ------------------------------------------------------------
@test "readme-check: passes on an in-sync fixture" {
  run env READMECHECK_ROOT="$FIX/readme-check/in-sync" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 0 ]
}

@test "readme-check: fails when README names a make target that doesn't exist" {
  run env READMECHECK_ROOT="$FIX/readme-check/drift" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bogus"* ]]
}

# --- lab-ui-check ------------------------------------------------------------
@test "lab-ui-check: passes when the panel matches the HTTPRoutes" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/in-sync" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 0 ]
}

@test "lab-ui-check: fails when a routed UI is missing from the panel" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/drift" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING from the Lab UIs panel"* ]]
}

@test "lab-ui-check: fails when a panel URL uses a non-front-door port" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/port-drift" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"front-door port :8000"* ]]
}

# --- roadmap-check -----------------------------------------------------------
@test "roadmap-check: passes when ROADMAP has no inline planner note" {
  run env ROADMAPCHECK_ROOT="$FIX/roadmap-check/in-sync" bash "$REPO/scripts/roadmap-check.sh"
  [ "$status" -eq 0 ]
}

@test "roadmap-check: fails on an inline dated planner note" {
  run env ROADMAPCHECK_ROOT="$FIX/roadmap-check/drift" bash "$REPO/scripts/roadmap-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"inline planner note"* ]]
}

@test "roadmap-check: passes on the real repo ROADMAP.md" {
  run bash "$REPO/scripts/roadmap-check.sh"
  [ "$status" -eq 0 ]
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

# --- yq-raw-check ------------------------------------------------------------
@test "yq-raw-check: passes when no bats test calls yq directly" {
  run env YQRAW_CHECK_ROOT="$FIX/yq-raw-check/in-sync" bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 0 ]
}

@test "yq-raw-check: fails when a bats test uses a bare yq call" {
  run env YQRAW_CHECK_ROOT="$FIX/yq-raw-check/drift" bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bare 'yq'"* ]]
}

@test "yq-raw-check: passes on the real repo tests/" {
  run bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 0 ]
}

# --- git-fixture-isolation-check ---------------------------------------------
@test "git-fixture-isolation-check: passes when a fixture test unsets GIT_DIR" {
  run env GITFIX_CHECK_ROOT="$FIX/git-fixture-isolation-check/in-sync" bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 0 ]
}

@test "git-fixture-isolation-check: fails when a git-fixture test never unsets GIT_DIR" {
  run env GITFIX_CHECK_ROOT="$FIX/git-fixture-isolation-check/drift" bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"never unsets GIT_DIR"* ]]
}

@test "git-fixture-isolation-check: passes on the real repo tests/" {
  run bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 0 ]
}
