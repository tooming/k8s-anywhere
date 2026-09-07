#!/usr/bin/env bats
# Regression coverage for scripts/bats-shellcheck-duplication-check.sh — split
# into its own scope per the drift-detectors-tests-check convention (new
# drift-check coverage goes in its own tests/drift-<scope>.bats file, never
# appended to the frozen tests/drift-detectors.bats monolith).
#
# Found live 2026-09-07: tests/forgejo-repo-secret.bats added its own one-off
# `run shellcheck --severity=warning "$SCRIPT"` assertion — fully redundant
# with make lint's repo-wide shellcheck coverage of scripts/*.sh, and missing
# that gate's skip-when-uninstalled guard, so it hard-failed make ci in any
# sandbox without shellcheck on PATH instead of skipping like every other
# tool-dependent check in this repo. This guard closes the class.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/bats-shellcheck-duplication-check"
}

@test "bats-shellcheck-duplication-check: passes on an in-sync fixture" {
  run env BATS_SHELLCHECK_DUP_ROOT="$FIX/in-sync" bash "$REPO/scripts/bats-shellcheck-duplication-check.sh"
  [ "$status" -eq 0 ]
}

@test "bats-shellcheck-duplication-check: FAILS when a bats test invokes shellcheck directly" {
  run env BATS_SHELLCHECK_DUP_ROOT="$FIX/drift" bash "$REPO/scripts/bats-shellcheck-duplication-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"sample.bats"* ]]
}

@test "bats-shellcheck-duplication-check: passes on the real repo's tests/ (forgejo-repo-secret.bats fixed)" {
  run bash "$REPO/scripts/bats-shellcheck-duplication-check.sh"
  [ "$status" -eq 0 ]
}
