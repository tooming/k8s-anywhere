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
set -uo pipefail
# ROOT defaults to the repo; tests point DRIFTDET_TESTS_ROOT at a fixture tree.
ROOT="${DRIFTDET_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FILE="$ROOT/tests/drift-detectors.bats"
SNAP="$ROOT/tests/.drift-detectors-titles"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

[ -f "$FILE" ] || { echo "no tests/drift-detectors.bats — nothing to check"; exit 0; }

# The frozen baseline: the sorted set of @test titles in the monolith.
titles(){ grep -oE '^@test "[^"]*"' "$1" | sort; }

if [ ! -f "$SNAP" ]; then
  bad "missing snapshot tests/.drift-detectors-titles — run: make drift-detectors-tests-mark"
elif ! diff -q <(titles "$FILE") "$SNAP" >/dev/null 2>&1; then
  bad "tests/drift-detectors.bats is FROZEN but its @test set changed:"
  diff "$SNAP" <(titles "$FILE") | sed 's/^/      /' || true
  printf '      %s\n' "→ Add NEW drift-check coverage in tests/drift-<scope>.bats (not the monolith)."
  printf '      %s\n' "→ If you intentionally renamed/edited a monolith test: make drift-detectors-tests-mark"
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s tests/drift-detectors.bats frozen (new drift checks go in drift-<scope>.bats)\n' "$G" "$Z"
exit "$drift"
