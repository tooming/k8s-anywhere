#!/usr/bin/env bash
# Routines AUTHOR guard — close the live-vs-repo drift footgun structurally.
#
# THE GAP (confirmed 2026-06-24, repaired in #263): routines-check.sh only diffs
# each routines/*.prompt.md against the .routines-applied snapshot. It does NOT —
# and CANNOT, there is no claude.ai token in CI — verify the LIVE trigger carries
# that content. The autonomous executor (trigger trig_01CRtpmaS1scBQL74xKqmfvS)
# runs in the cloud with allowed_tools=[Bash,Read,Write,Edit,Glob,Grep]: it has NO
# RemoteTrigger tool, so it CANNOT apply a routine change to the live trigger. When
# it edits its own prompt and runs `make routines-mark-applied`, routines-check
# stays green but the live trigger silently drifts from the repo. That is exactly
# how #251's JANITOR rung + the docs/done STEP 6 went missing from the live trigger.
#
# THE STRUCTURAL FIX (removes the footgun, not just detects it): forbid
# executor-authored commits from touching routine files at all. Only INTERACTIVE
# Claude Code sessions — which DO have RemoteTrigger and so can actually apply +
# `make routines-mark-applied` in the same session (CLAUDE.md "Routines:
# edit-then-apply is one atomic step") — may change routines/*.prompt.md or
# routines.yaml. If the executor needs a routine change, it opens an issue for a
# human, the same way it defers any other out-of-tier work.
#
# DETECTION (no claude.ai token needed): the executor always lands on a branch with
# routines.yaml's `branch_prefix` (auto/), and commits as the cloud identity
# "Claude <noreply@anthropic.com>". Either signal marks the change executor-authored.
# If an executor-authored change touches a routine file -> fail. Interactive
# sessions (any other branch + a human commit author) pass, since they CAN apply.
#
# Mirrors the readme-check / roadmap-check / routines-check drift guards:
# scripts/<thing>-check.sh + `make routines-author-check` in `make ci` + bats
# coverage in tests/drift-detectors.bats. Also runs in the GitHub Actions drift job
# (the real gate on a pushed auto/* PR — see .github/workflows/ci.yml).
#
# Exit 0 = clean; 1 = an executor-authored change touched a routine file.
#
# Test/CI seams (so the logic is unit-testable without a live git history):
#   ROUTINES_AUTHOR_ROOT     repo root override (fixtures)
#   ROUTINES_AUTHOR_BRANCH   branch under test (else GITHUB_HEAD_REF / GITHUB_REF_NAME / git)
#   ROUTINES_AUTHOR_FILES    newline-separated changed files (else `git diff` vs main)
#   ROUTINES_AUTHOR_IS_CLOUD =1 forces the cloud-author signal on (else derived from git)
set -uo pipefail
ROOT="${ROUTINES_AUTHOR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLOUD_ID="Claude <noreply@anthropic.com>"   # the executor's commit identity
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

# Files whose content must be applied to a live trigger to take effect.
is_routine(){ case "$1" in routines/*.prompt.md|routines.yaml) return 0;; *) return 1;; esac; }

# The executor's branch prefix, read from routines.yaml (don't hardcode "auto/").
prefix="$(awk '
  /^[[:space:]]*branch_prefix:/ {
    for (i = 1; i <= NF; i++) if ($i == "branch_prefix:") { print $(i+1); exit }
  }' "$ROOT/routines.yaml" 2>/dev/null | tr -d "\"'")"
prefix="${prefix:-auto/}"

# Branch under test: explicit override (tests) -> GH PR head -> GH ref -> git HEAD.
branch="${ROUTINES_AUTHOR_BRANCH:-${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)}}}"

# Merge-base with main, used both to list changed files and to read their authors.
base=""
for ref in origin/main github/main main; do
  base="$(git -C "$ROOT" merge-base "$ref" HEAD 2>/dev/null || true)"
  [ -n "$base" ] && break
done

# Changed files: explicit override (tests) -> committed diff vs the merge-base.
if [ -n "${ROUTINES_AUTHOR_FILES+x}" ]; then
  changed="$ROUTINES_AUTHOR_FILES"
elif [ -n "$base" ]; then
  changed="$(git -C "$ROOT" diff --name-only "$base" HEAD 2>/dev/null || true)"
else
  changed=""   # degraded (no main ref / shallow clone): nothing committed to judge
fi

# Which protected routine files did this change touch?
touched=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  is_routine "$f" && touched+=("$f")
done <<EOF
$changed
EOF

# Is this an executor-authored change? Either signal is sufficient.
executor_branch=0
case "$branch" in "$prefix"*) executor_branch=1;; esac

cloud_author=0
[ "${ROUTINES_AUTHOR_IS_CLOUD:-0}" = "1" ] && cloud_author=1
# Derive from git only when we have real history (not the file-injection test path).
if [ "$cloud_author" -eq 0 ] && [ -z "${ROUTINES_AUTHOR_FILES+x}" ] && [ -n "$base" ]; then
  for f in "${touched[@]:-}"; do
    [ -z "$f" ] && continue
    a="$(git -C "$ROOT" log -1 --pretty='%an <%ae>' "$base"..HEAD -- "$f" 2>/dev/null || true)"
    [ "$a" = "$CLOUD_ID" ] && cloud_author=1
  done
fi

if [ "${#touched[@]}" -gt 0 ] && { [ "$executor_branch" -eq 1 ] || [ "$cloud_author" -eq 1 ]; }; then
  why="branch '$branch' matches the executor prefix '$prefix'"
  [ "$cloud_author" -eq 1 ] && why="commit author is the cloud identity ($CLOUD_ID)"
  bad "an executor-authored change ($why) modifies routine file(s):"
  for f in "${touched[@]}"; do printf '      • %s\n' "$f"; done
  printf '      %s\n' "The autonomous executor has NO RemoteTrigger tool, so it CANNOT apply this to"
  printf '      %s\n' "the live claude.ai trigger — routines-check would stay green while the live"
  printf '      %s\n' "trigger silently drifts (the #251/#263 failure)."
  printf '      %s\n' "→ Change routine files ONLY from an interactive Claude Code session, which"
  printf '        %s\n' "applies them via \`RemoteTrigger update\` + \`make routines-mark-applied\`."
  printf '      %s\n' "→ From an autonomous run, open an issue for a human instead of editing them."
fi

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m no executor-authored routine edits (live-trigger drift guard)\n'
exit "$drift"
