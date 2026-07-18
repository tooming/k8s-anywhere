#!/usr/bin/env bash
# CI-parity drift check: every scripts/*.sh gate wired into the Makefile `ci:`
# target must also run in .github/workflows/ci.yml, and vice versa. CLAUDE.md
# states this as a binding prose rule ("kept in parity with make ci — if you add
# a check to one, add it to the other") because the local pre-push hook only
# runs the fast lint gate now — GitHub Actions' `drift`/`unit`/`manifests`/
# `terraform`/`kustomize` jobs are the actual full backstop. Nothing mechanical
# enforced that rule until this script: a PR could wire a new check into one
# side and not the other, and nothing would catch it. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point CIPARITY_ROOT at a fixture tree.
ROOT="${CIPARITY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd)" || exit 1
cd "$ROOT" || exit 1

MAKEFILE="Makefile"
WORKFLOW=".github/workflows/ci.yml"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

[ -f "$MAKEFILE" ] || { echo "no Makefile — nothing to check"; exit 0; }
[ -f "$WORKFLOW" ] || { echo "no $WORKFLOW — nothing to check"; exit 0; }

# The Makefile `ci:` target's recipe: from the line starting "ci:" to the next
# blank line (matches this repo's Makefile formatting convention throughout).
make_scripts="$(awk '/^ci:/{f=1;next} f && /^$/{exit} f' "$MAKEFILE" \
  | grep -oE 'scripts/[a-zA-Z0-9_.-]+\.sh' | sort -u)"
ci_scripts="$(grep -oE 'scripts/[a-zA-Z0-9_.-]+\.sh' "$WORKFLOW" | sort -u)"

only_in_make="$(comm -23 <(printf '%s\n' "$make_scripts") <(printf '%s\n' "$ci_scripts"))"
only_in_ci="$(comm -13 <(printf '%s\n' "$make_scripts") <(printf '%s\n' "$ci_scripts"))"

drift=0
if [ -n "$only_in_make" ]; then
  drift=1
  printf '  %s✗%s in "make ci" but never run in GitHub Actions (%s):\n' "$R" "$Z" "$WORKFLOW"
  printf '      %s\n' "$only_in_make"
fi
if [ -n "$only_in_ci" ]; then
  drift=1
  printf '  %s✗%s run in GitHub Actions (%s) but not in "make ci":\n' "$R" "$Z" "$WORKFLOW"
  printf '      %s\n' "$only_in_ci"
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s make ci and %s run the identical set of gate scripts\n' "$G" "$Z" "$WORKFLOW"
exit "$drift"
