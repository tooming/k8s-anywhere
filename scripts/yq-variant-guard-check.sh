#!/usr/bin/env bash
# yq-variant-guard drift check: any scripts/*.sh calling mikefarah/yq-only syntax
# (`yq eval-all`, `yq eval`, `yq ea`) MUST also call require_mikefarah_yq (from
# scripts/lib/yq-variant.sh) before doing so.
#
# Why: other yq implementations on PATH (e.g. python-yq, a jq wrapper) don't
# recognise `eval-all`/`eval`/`ea` as a subcommand and exit non-zero. A script that
# pipes that failure through `2>/dev/null` sees zero results and reports a false
# "nothing to check" instead of erroring — helm-chart-pin-check.sh,
# argocd-crd-ssa-check.sh, and rollouts-plugin-list-check.sh all hit exactly this
# in an environment where a non-mikefarah yq is on PATH, silently no-opping
# instead of catching real drift (see scripts/lib/yq-variant.sh for the full
# writeup). require_mikefarah_yq() makes that failure loud: hard-fail in CI,
# honest skip locally. This guard makes the recurrence impossible: no new script
# can add a raw eval-all/eval/ea call without also wiring the guard (fix + guard,
# per CLAUDE.md's bugfix-prevents-recurrence rule).
#
# Static + offline — pure grep, no network, no cluster.
# Run by `make yq-variant-guard-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = every mikefarah-only-syntax script is guarded; 1 = one isn't.
set -uo pipefail

# ROOT defaults to the repo; tests point YQVARIANTGUARD_ROOT at a fixture tree.
ROOT="${YQVARIANTGUARD_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIPTS_DIR="$ROOT/scripts"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

[ -d "$SCRIPTS_DIR" ] || { echo "no scripts/ dir — nothing to check"; exit 0; }

# Mikefarah-only subcommands: `yq eval-all`, `yq eval`, `yq ea` (never a bare
# scalar read like `yq '.foo' file`, which every variant supports).
pattern='(^|[^a-zA-Z_-])yq (eval-all|eval|ea) '

for f in "$SCRIPTS_DIR"/*.sh; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  grep -qE "$pattern" "$f" || continue
  grep -q 'require_mikefarah_yq' "$f" || \
    bad "$base uses mikefarah-only yq syntax (eval-all/eval/ea) but never calls require_mikefarah_yq — source scripts/lib/yq-variant.sh and call it before the first such invocation"
done

[ "$drift" -eq 0 ] && printf '  %s✓%s every mikefarah-only-syntax script calls require_mikefarah_yq\n' "$G" "$Z"
exit "$drift"
