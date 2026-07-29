#!/usr/bin/env bash
# observability test drift check: tests/observability.bats is FROZEN. New
# per-component / per-dashboard tests must go in their own
# tests/observability-<scope>.bats file, NEVER appended to the shared monolith.
#
# Why: multiple ROADMAP items routinely say "Extend tests/observability.bats with
# N assertions". When two parallel PRs both append a @test block to the monolith's
# EOF (identical trailing `[ "$status" -eq 0 ]` / `}` context) the merge is
# unmergeable — the same collision pattern that already froze securitycontext.bats
# (#238 vs #239) and networkpolicy.bats (#247 vs #248). One scope = one file =
# no shared append anchor, so new files never conflict.
#
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
# Intentional renames/edits to existing monolith tests: run `make observability-tests-mark`.
# Shared check logic lives in scripts/lib/frozen-monolith-check.sh.
set -uo pipefail
# ROOT defaults to the repo; tests point OBSV_TESTS_ROOT at a fixture tree.
ROOT="${OBSV_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/frozen-monolith-check.sh"

frozen_monolith_check \
  "$ROOT/tests/observability.bats" \
  "$ROOT/tests/.observability-titles" \
  "observability-tests-mark" \
  "tests/observability-<scope>.bats" \
  "tests/observability.bats"
exit "$?"
