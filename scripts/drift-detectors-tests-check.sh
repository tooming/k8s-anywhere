#!/usr/bin/env bash
# drift-detectors test drift check: tests/drift-detectors.bats is FROZEN. New
# drift-check test coverage must go in its own tests/drift-<scope>.bats file,
# NEVER appended to this shared monolith.
#
# Why: tests/drift-detectors.bats grew to 24+ unrelated drift-check sections
# (readme-check, roadmap-check, ADR sync checks, helm-chart-pin-check, and more)
# with every new CI gate script appending its own @test block to the same file
# — the exact "shared monolith multiple PRs append to" footgun CLAUDE.md's
# bugfix-recurrence rule calls out, and the same collision pattern that already
# froze tests/securitycontext.bats (#238 vs #239) and tests/observability.bats.
# One drift-check script = one test file = no shared append anchor, so new
# files never conflict. This flags any change to the monolith's @test set
# mechanically, mirroring the securitycontext-tests-check / observability-tests-check
# drift guards.
#
# Runs in CI (the 'drift' gate) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
# Intentional renames/edits to existing monolith tests: run `make drift-detectors-tests-mark`.
# Shared check logic lives in scripts/lib/frozen-monolith-check.sh.
set -uo pipefail
# ROOT defaults to the repo; tests point DRIFTDET_TESTS_ROOT at a fixture tree.
ROOT="${DRIFTDET_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/frozen-monolith-check.sh"

frozen_monolith_check \
  "$ROOT/tests/drift-detectors.bats" \
  "$ROOT/tests/.drift-detectors-titles" \
  "drift-detectors-tests-mark" \
  "tests/drift-<scope>.bats" \
  "tests/drift-detectors.bats"
exit "$?"
