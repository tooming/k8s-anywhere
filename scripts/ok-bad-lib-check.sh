#!/usr/bin/env bash
# ok-bad-lib drift check: no scripts/*.sh may define its own local, drift-setting
# `bad()` — every script using the `drift`-variable convention must instead
# source the shared `ok()`/`bad()` pair in scripts/lib/colors.sh.
#
# Why: after auto/scripts-drift-var-rename standardized every drift-tracking
# script's failure-flag variable to `drift`, ~19 scripts still each carried
# their own byte-identical `ok()`/`bad()` copy (found in the same duplication
# sweep as scripts/lib/yq.sh, issue #957) — this guard makes that recurrence
# impossible, mirroring the yqs-lib-check.sh pattern.
#
# Deliberately does NOT flag a `bad()` with no side effect (e.g.
# argocd-crd-ssa-check.sh, helm-chart-pin-check.sh, lab-health-check.sh,
# rollouts-plugin-list-check.sh) — those track
# failure via their own separately-managed `fail` variable instead, and
# forcing them onto the shared drift-setting `bad()` would add an incidental
# unused `drift` variable to their scope. Only a `bad()` matching the exact
# drift-setting shape is in scope for this guard.
#
# Static + offline — pure grep, no network, no cluster.
# Run by `make ok-bad-lib-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = no script defines its own drift-setting ok()/bad(); 1 = one does.
set -uo pipefail

# ROOT defaults to the repo; tests point OKBADLIB_ROOT at a fixture tree.
ROOT="${OKBADLIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIPTS_DIR="$ROOT/scripts"
drift=0
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

[ -d "$SCRIPTS_DIR" ] || { echo "no scripts/ dir — nothing to check"; exit 0; }

# Matches only the drift-setting shape (trailing "drift=1"), regardless of
# brace/space style ("bad(){", "bad() {", "bad()  {") — never a no-side-effect
# bad() (those are intentionally out of scope, see header). ok() is never
# checked independently: it has no side effect and so can never behaviorally
# diverge the way a copy-pasted bad() can, and the 4 scripts intentionally
# keeping their own no-side-effect bad() also keep their own paired ok() —
# flagging ok() alone would wrongly catch those.
bad_pattern='^bad\(\)[[:space:]]*\{[[:space:]]*printf .* drift=1; ?\}$'

for f in "$SCRIPTS_DIR"/*.sh; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  grep -qE "$bad_pattern" "$f" || continue
  bad "$base defines its own drift-setting bad() — source scripts/lib/colors.sh instead (the one shared copy)"
done

[ "$drift" -eq 0 ] && printf '  %s✓%s no script defines its own drift-setting ok()/bad() (all source scripts/lib/colors.sh)\n' "$G" "$Z"
exit "$drift"
