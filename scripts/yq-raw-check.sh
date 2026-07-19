#!/usr/bin/env bash
# yq-raw drift check: bats tests must read yq scalars through the yqs() helper in
# tests/lib/yq.bash, NEVER via a bare `yq` call.
#
# Why: yq implementations disagree on output quoting — mikefarah yq prints
# scalars raw (250m) while python-yq (a jq wrapper) JSON-quotes them ("250m"). A
# bare `$(yq …)` consumed by a numeric/string comparison silently breaks on
# whichever variant is on PATH: the cpu_millis regression in argocd-resources.bats
# hit a container yq that returned "250m", crashing the millicore arithmetic
# ("250m" * 1000 → syntax error) and red-failing CI for a reason unrelated to any
# code change. Routing every scalar read through yqs() strips the quoting once, so
# no test can depend on which yq is installed. This flags any bare yq call
# mechanically, mirroring the readme-check / securitycontext-tests-check drift guards.
#
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point YQRAW_CHECK_ROOT at a fixture tree.
ROOT="${YQRAW_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TESTS_DIR="$ROOT/tests"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

[ -d "$TESTS_DIR" ] || { echo "no tests/ dir — nothing to check"; exit 0; }

# Bare `yq` *command* invocations in tests/*.bats. We strip inline `#` comments
# first (so prose mentioning yq doesn't trip), then match yq only where it is
# actually invoked as a command — inside `$(…)`, backticks, after a pipe, or after
# bats `run` — followed by an argument. This deliberately ignores yq inside a
# string/test-title (e.g. @test "… calls yq directly"), `yqs '…'` (the trailing
# 's'), and `load lib/yq` (no trailing space). The yqs() helper lives in
# tests/lib/, not a *.bats file, so it's never scanned. sed preserves line
# numbering, so grep -n line numbers stay accurate.
inv='(\$\(|`|\|[[:space:]]*|run[[:space:]]+)yq[[:space:]]'
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  bad "bare 'yq' in a bats test — read scalars via yqs() (load lib/yq) instead:"
  printf '      %s\n' "$hit"
done < <(
  for f in "$TESTS_DIR"/*.bats; do
    [ -e "$f" ] || continue
    sed 's/#.*//' "$f" | grep -nE "$inv" | sed "s|^|${f}:|" || true
  done
)

if [ "$drift" -ne 0 ]; then
  printf '      %s\n' "→ Why: yq variants quote scalars differently ('250m' vs 250m); yqs() normalises it."
  printf '      %s\n' "→ See tests/lib/yq.bash and tests/argocd-resources.bats for the pattern."
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s bats tests read yq scalars via yqs() (no bare yq calls)\n' "$G" "$Z"
exit "$drift"
