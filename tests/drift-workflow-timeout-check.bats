#!/usr/bin/env bats
# Tests for scripts/workflow-timeout-check.sh — a new drift-check scope, per the
# drift-detectors-tests-check convention (tests/drift-detectors.bats itself is
# frozen; new scopes go in their own tests/drift-<scope>.bats file). Closes the
# gap where 5 of 6 .github/workflows/*.yml files had jobs missing an explicit
# timeout-minutes (ci.yml's own PR #648 incident/comment established this as a
# recognized failure mode, but it was never propagated to sibling workflows).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/workflow-timeout-check"
}

@test "workflow-timeout-check: passes when every job has timeout-minutes" {
  run env WORKFLOWTIMEOUTCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/workflow-timeout-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every .github/workflows"* ]]
}

@test "workflow-timeout-check: fails when a job is missing timeout-minutes" {
  run env WORKFLOWTIMEOUTCHECK_ROOT="$FIX/drift" bash "$REPO/scripts/workflow-timeout-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"'bar' has no timeout-minutes"* ]]
}

@test "workflow-timeout-check: passes on the real repo's .github/workflows/" {
  run bash "$REPO/scripts/workflow-timeout-check.sh"
  [ "$status" -eq 0 ]
}

@test "workflow-timeout-check: also scans .forgejo/workflows/ when present, no .github/workflows/" {
  run env WORKFLOWTIMEOUTCHECK_ROOT="$FIX/forgejo-only-in-sync" bash "$REPO/scripts/workflow-timeout-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *".forgejo/workflows"* ]]
}

@test "workflow-timeout-check: fails on a .forgejo/workflows/ job missing timeout-minutes" {
  run env WORKFLOWTIMEOUTCHECK_ROOT="$FIX/forgejo-only-drift" bash "$REPO/scripts/workflow-timeout-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"'foo' has no timeout-minutes"* ]]
}
