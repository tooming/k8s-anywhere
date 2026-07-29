#!/usr/bin/env bash
# hook-scripts-coverage test drift check: tests/hook-scripts-coverage.bats is
# FROZEN. New PostToolUse/SessionStart hook-script coverage must go in its own
# tests/hook-scripts-<scope>.bats file, NEVER appended to the shared monolith.
#
# Why: the monolith's own header frames it as catch-all coverage for "hook
# scripts that had zero bats coverage" — every new hook lands its own @test
# section at the file's EOF. It had grown to 68 tests across 18 unrelated hook
# scripts, already past the size every other frozen monolith in this repo
# (tests/securitycontext.bats, tests/observability.bats,
# tests/drift-detectors.bats) had reached before hitting the exact "shared
# monolith multiple PRs append to" footgun CLAUDE.md's bugfix-recurrence rule
# calls out and got split. One hook script = one test file = no shared append
# anchor, so new files never conflict. This flags any change to the monolith's
# @test set mechanically, mirroring the drift-detectors-tests-check /
# securitycontext-tests-check / observability-tests-check drift guards.
#
# Runs in CI (the 'drift' gate) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
# Intentional renames/edits to existing monolith tests: run `make hook-scripts-coverage-tests-mark`.
# Shared check logic lives in scripts/lib/frozen-monolith-check.sh.
set -uo pipefail
# ROOT defaults to the repo; tests point HOOKCOV_TESTS_ROOT at a fixture tree.
ROOT="${HOOKCOV_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/frozen-monolith-check.sh"

frozen_monolith_check \
  "$ROOT/tests/hook-scripts-coverage.bats" \
  "$ROOT/tests/.hook-scripts-coverage-titles" \
  "hook-scripts-coverage-tests-mark" \
  "tests/hook-scripts-<scope>.bats" \
  "tests/hook-scripts-coverage.bats"
exit "$?"
