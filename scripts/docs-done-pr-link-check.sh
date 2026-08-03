#!/usr/bin/env bash
# docs/done/ PR-link check: every docs/done/*.md file's "## PR" section must be
# backfilled with the real PR link before merge — never left on the "(filled in
# after PR creation)"-style placeholder every routine writes into its own initial
# commit (the number isn't known until `gh pr create`/`create_pull_request`
# returns, so the placeholder is legitimate on first push). A 38-file backfill
# (2026-07-28) found the placeholder had NEVER once been resolved after the PR
# actually opened, going back to 2026-07-11 — every routine's own STEP 6/STEP 8
# leaves a dead, permanently-unresolved cross-reference behind by default, with
# nothing forcing a return trip once the real number is known. This makes it
# mechanical: CI reruns on every push to a PR, and self-review only requires the
# LATEST run green before merge — so a routine has the same opportunity every
# other gate here relies on (push the placeholder, open the PR, push the
# backfill, watch this check turn green, then self-review/merge).
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point DOCSDONEPRCHECK_ROOT at a fixture tree.
ROOT="${DOCSDONEPRCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

DIR="$ROOT/docs/done"
if [ ! -d "$DIR" ]; then
  echo "no docs/done/ directory — nothing to check"
  exit 0
fi

# Every placeholder shape seen in the wild: an HTML comment, a bare parenthetical,
# or a parenthetical citing the branch name.
hits="$(grep -lE '^(<!--\s*filled in after PR creation\s*-->|\(filled in after PR creation\)|\(filled in once the PR is opened.*\))\s*$' "$DIR"/*.md 2>/dev/null || true)"
if [ -n "$hits" ]; then
  bad "docs/done/ file(s) still carry the unresolved '## PR' placeholder — backfill the real PR link before merging (push a follow-up commit once \`gh pr create\`/create_pull_request returns the number):"
  printf '%s\n' "$hits" | sed 's/^/      /'
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s every docs/done/ file has a real PR link (no unresolved placeholder)\n' "$G" "$Z"
exit "$drift"
