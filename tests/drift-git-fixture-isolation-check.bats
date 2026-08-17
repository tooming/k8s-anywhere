#!/usr/bin/env bats
# Regression coverage for scripts/git-fixture-isolation-check.sh — split into its
# own scope per the drift-detectors-tests-check convention (new drift-check
# coverage goes in its own tests/drift-<scope>.bats file, never appended to the
# frozen tests/drift-detectors.bats monolith).
#
# Found live 2026-08-17: the check's original detection regex couldn't tell "a
# bats test actually runs `git clone`/`git init`" apart from "a bats test greps a
# file's *content* for that string" — tests/forgejo-ci.bats's real
# `grep -q 'git clone --no-checkout' "$WF"` (asserting a workflow YAML file
# contains that shell command as text, never executing git itself) tripped the
# check as a false positive and broke `make ci` on `main`. Fixed by excluding any
# matching line that also contains `grep` (a content search, not a fixture build).
# This file guards that fix from regressing.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

@test "git-fixture-isolation-check: does not flag a test that only greps for a git-clone string (real-world regression, tests/forgejo-ci.bats)" {
  run env GITFIX_CHECK_ROOT="$FIX/git-fixture-isolation-check/in-sync" bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"grep-only.bats"* ]]
}
