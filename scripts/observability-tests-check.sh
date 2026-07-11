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
set -uo pipefail
# ROOT defaults to the repo; tests point OBSV_TESTS_ROOT at a fixture tree.
ROOT="${OBSV_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FILE="$ROOT/tests/observability.bats"
SNAP="$ROOT/tests/.observability-titles"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -f "$FILE" ] || { echo "no tests/observability.bats — nothing to check"; exit 0; }

# The frozen baseline: the sorted set of @test titles in the monolith.
titles(){ grep -oE '^@test "[^"]*"' "$1" | sort; }

if [ ! -f "$SNAP" ]; then
  bad "missing snapshot tests/.observability-titles — run: make observability-tests-mark"
elif ! diff -q <(titles "$FILE") "$SNAP" >/dev/null 2>&1; then
  bad "tests/observability.bats is FROZEN but its @test set changed:"
  diff "$SNAP" <(titles "$FILE") | sed 's/^/      /' || true
  printf '      %s\n' "→ Add NEW per-component tests in tests/observability-<scope>.bats (not the monolith)."
  printf '      %s\n' "→ If you intentionally renamed/edited a monolith test: make observability-tests-mark"
fi

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m tests/observability.bats frozen (new scopes go in observability-<scope>.bats)\n'
exit "$drift"
