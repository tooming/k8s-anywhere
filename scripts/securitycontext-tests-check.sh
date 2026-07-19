#!/usr/bin/env bash
# securitycontext test drift check: tests/securitycontext.bats is FROZEN. New
# per-namespace / per-scope security-context (PSS) tests must go in their own
# tests/securitycontext-<scope>.bats file, NEVER appended to the shared monolith.
#
# Why: two parallel PSS fan-out PRs both appending a per-namespace @test block to
# the monolith's EOF (identical trailing `[ "$status" -eq 0 ]` / `}` context) is an
# unmergeable collision — it happened with #238 (external-secrets) vs #239
# (envoy-gateway-system). One scope = one file = no shared append anchor, so new
# files never conflict. This flags any change to the monolith's @test set
# mechanically, mirroring the readme-check / roadmap-check drift guards.
#
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
# Intentional renames/edits to existing monolith tests: run `make securitycontext-tests-mark`.
set -uo pipefail
# ROOT defaults to the repo; tests point SECCTX_TESTS_ROOT at a fixture tree.
ROOT="${SECCTX_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FILE="$ROOT/tests/securitycontext.bats"
SNAP="$ROOT/tests/.securitycontext-titles"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

[ -f "$FILE" ] || { echo "no tests/securitycontext.bats — nothing to check"; exit 0; }

# The frozen baseline: the sorted set of @test titles in the monolith.
titles(){ grep -oE '^@test "[^"]*"' "$1" | sort; }

if [ ! -f "$SNAP" ]; then
  bad "missing snapshot tests/.securitycontext-titles — run: make securitycontext-tests-mark"
elif ! diff -q <(titles "$FILE") "$SNAP" >/dev/null 2>&1; then
  bad "tests/securitycontext.bats is FROZEN but its @test set changed:"
  diff "$SNAP" <(titles "$FILE") | sed 's/^/      /' || true
  printf '      %s\n' "→ Add NEW per-scope tests in tests/securitycontext-<scope>.bats (not the monolith)."
  printf '      %s\n' "→ If you intentionally renamed/edited a monolith test: make securitycontext-tests-mark"
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s tests/securitycontext.bats frozen (new scopes go in securitycontext-<scope>.bats)\n' "$G" "$Z"
exit "$drift"
