#!/usr/bin/env bats
# Tests for scripts/appset-list-coverage-check.sh — a new drift-check scope, per
# the drift-detectors-tests-check convention (tests/drift-detectors.bats itself is
# frozen; new scopes go in their own tests/drift-<scope>.bats file). A preventative
# guard for the same "hardcoded list drifts from the real thing it enumerates"
# footgun shape as scripts/envoy-egress-allowlist-check.sh, applied to
# networkpolicy-appset.yaml and governance-appset.yaml's list-generators.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/appset-list-coverage-check"
}

@test "appset-list-coverage-check: passes when both appsets cover their real dirs" {
  run env APPSETCOVERAGE_ROOT="$FIX/in-sync" bash "$REPO/scripts/appset-list-coverage-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every networkpolicy/ and governance/"* ]]
}

@test "appset-list-coverage-check: fails when a networkpolicy dir is uncovered" {
  run env APPSETCOVERAGE_ROOT="$FIX/drift-networkpolicy" bash "$REPO/scripts/appset-list-coverage-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gitops/foo/networkpolicy"* ]]
}

@test "appset-list-coverage-check: fails when a governance dir is uncovered" {
  run env APPSETCOVERAGE_ROOT="$FIX/drift-governance" bash "$REPO/scripts/appset-list-coverage-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gitops/governance/foo"* ]]
}

@test "appset-list-coverage-check: passes on the real repo's appsets + gitops tree" {
  run bash "$REPO/scripts/appset-list-coverage-check.sh"
  [ "$status" -eq 0 ]
}
