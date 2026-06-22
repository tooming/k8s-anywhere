#!/usr/bin/env bash
# networkpolicy test structural guard: tests/networkpolicy.bats holds ONLY the
# SHARED baseline-template tests. Every per-namespace NetworkPolicy fan-out test
# lives in its own tests/networkpolicy-<scope>.bats file.
#
# Why: the ADR-0016 fan-out runs as a swarm of parallel per-namespace PRs (kro,
# external-secrets, vault, tidb, storage, observability, …). When two of them each
# append a @test block to one shared monolith's EOF, the merge is an unmergeable
# collision — it happened with #247 (external-secrets) vs #248 (kro). The monolith
# was therefore SPLIT: one scope = one file = no shared append anchor, so new files
# never conflict. Shared overlay paths live in tests/lib/networkpolicy-paths.bash.
#
# This guard makes the split impossible to silently undo: it fails if a
# per-namespace overlay test (a "namespace overlay" section header, or a use of a
# per-namespace $<NS>_NP path var) reappears inside the shared baseline file.
# Detection over a snapshot so there is nothing to "re-mark" on every legit edit.
#
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point NETPOL_TESTS_ROOT at a fixture tree.
ROOT="${NETPOL_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FILE="$ROOT/tests/networkpolicy.bats"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -f "$FILE" ] || { echo "no tests/networkpolicy.bats — nothing to check"; exit 0; }

# Signal 1: a per-namespace overlay section header in the shared baseline file.
if grep -nE '^# ---.*namespace overlay' "$FILE" >/dev/null 2>&1; then
  bad "tests/networkpolicy.bats contains a per-namespace overlay section — move it to tests/networkpolicy-<scope>.bats:"
  grep -nE '^# ---.*namespace overlay' "$FILE" | sed 's/^/      /'
fi

# Signal 2: a per-namespace path var ($DATA_NP, $VAULT_NP, … — anything *_NP). The
# baseline only references $POLICIES; per-namespace tests belong in per-scope files.
if grep -nE '\$[A-Z][A-Z0-9_]*_NP\b' "$FILE" >/dev/null 2>&1; then
  bad "tests/networkpolicy.bats references a per-namespace overlay path var (\$<NS>_NP) — move that test to tests/networkpolicy-<scope>.bats:"
  grep -nE '\$[A-Z][A-Z0-9_]*_NP\b' "$FILE" | sed 's/^/      /'
fi

if [ "$drift" -ne 0 ]; then
  printf '      %s\n' "→ One scope = one file = no shared EOF for parallel fan-out PRs to collide on."
  printf '      %s\n' "→ Copy an existing tests/networkpolicy-<scope>.bats (e.g. networkpolicy-kro.bats) as the template."
fi

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m tests/networkpolicy.bats is baseline-only (per-namespace tests live in networkpolicy-<scope>.bats)\n'
exit "$drift"
