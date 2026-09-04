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
#
# SECOND, broader check (2026-09-04): the first check above only matches the
# EXACT placeholder wordings caught so far — an allowlist blocking specific
# phrasings, not requiring a real reference. That gap was real: an 80-file
# audit found dozens more still carried a branch name only (`auto/foo-bar`),
# prose describing "this session's branch" without ever naming the PR, or a
# differently-worded still-unresolved placeholder (`PR to be filled in.`,
# `<!-- filled in after opening the PR -->`, literal `#NNN`/`pull/TBD`
# template placeholders never substituted) — every one of these slipped past
# the narrow first check for years. This second pass flips the logic to an
# allowlist: for every docs/done/*.md file that HAS a "## PR" heading (files
# without one predate the convention entirely — see docs/done/README.md's own
# filename-convention note — and are out of scope), the section's content
# must contain either a real `github.com/.../pull/NNN` URL or a bare `#NNN`
# token; anything else fails. `docs/done/README.md` itself is excluded — it's
# the convention's own documentation, and its "## PR" section is a literal
# `PR #NNN — ...` example by design, not a real delivery record.
#
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

# Second pass: any file with a "## PR" heading whose section doesn't contain a
# real reference (URL or bare #NNN) — catches every wording the first check's
# narrow allowlist doesn't name explicitly.
unresolved=()
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  [ "$(basename "$f")" = "README.md" ] && continue
  grep -q '^## PR$' "$f" || continue
  section="$(awk '/^## PR$/{found=1; next} found{print}' "$f")"
  if ! printf '%s' "$section" | grep -qE 'github\.com/[^ ]+/pull/[0-9]+|(^|[^0-9])#[0-9]+([^0-9]|$)'; then
    unresolved+=("$f")
  fi
done
if [ "${#unresolved[@]}" -gt 0 ]; then
  bad "docs/done/ file(s) have a '## PR' section with no real PR reference (neither a github.com/.../pull/NNN URL nor a bare #NNN) — backfill the real PR link:"
  printf '      %s\n' "${unresolved[@]}"
  drift=1
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s every docs/done/ file has a real PR link (no unresolved placeholder)\n' "$G" "$Z"
exit "$drift"
