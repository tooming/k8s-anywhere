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
set -uo pipefail
# ROOT defaults to the repo; tests point HOOKCOV_TESTS_ROOT at a fixture tree.
ROOT="${HOOKCOV_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FILE="$ROOT/tests/hook-scripts-coverage.bats"
SNAP="$ROOT/tests/.hook-scripts-coverage-titles"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

[ -f "$FILE" ] || { echo "no tests/hook-scripts-coverage.bats — nothing to check"; exit 0; }

# The frozen baseline: the sorted set of @test titles in the monolith.
titles(){ grep -oE '^@test "[^"]*"' "$1" | sort; }

if [ ! -f "$SNAP" ]; then
  bad "missing snapshot tests/.hook-scripts-coverage-titles — run: make hook-scripts-coverage-tests-mark"
elif ! diff -q <(titles "$FILE") "$SNAP" >/dev/null 2>&1; then
  bad "tests/hook-scripts-coverage.bats is FROZEN but its @test set changed:"
  diff "$SNAP" <(titles "$FILE") | sed 's/^/      /' || true
  printf '      %s\n' "→ Add NEW hook-script coverage in tests/hook-scripts-<scope>.bats (not the monolith)."
  printf '      %s\n' "→ If you intentionally renamed/edited a monolith test: make hook-scripts-coverage-tests-mark"
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s tests/hook-scripts-coverage.bats frozen (new hook coverage goes in hook-scripts-<scope>.bats)\n' "$G" "$Z"
exit "$drift"
