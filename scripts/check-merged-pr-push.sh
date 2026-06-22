#!/usr/bin/env bash
# check-merged-pr-push.sh — exit 1 (block) if <branch> is the head of an
# already-MERGED pull request. Pushing more commits onto a merged PR's branch is
# almost always a mistake: the work lands on a closed PR, is never reviewed or
# merged, and leaves a stray commit on a dead branch (exactly the slip this guard
# exists to prevent). Exit 0 (allow) otherwise.
#
# Degrades gracefully: if gh is missing or unauthenticated (e.g. a cloud exec
# environment) it cannot enforce and exits 0 — the GitHub repo setting
# "Automatically delete head branches" on merge is the universal backstop, since
# a deleted branch can't be pushed to in the first place.
#
# Usage: check-merged-pr-push.sh <branch>
# Test hook: GH_BIN overrides the gh binary (the bats guard points it at a stub).
set -uo pipefail

branch="${1:?usage: check-merged-pr-push.sh <branch>}"
GH="${GH_BIN:-gh}"

command -v "$GH" >/dev/null 2>&1 || exit 0   # no gh here — cannot enforce

# Count merged PRs whose head ref is this branch.
count="$("$GH" pr list --head "$branch" --state merged --json number --jq 'length' 2>/dev/null)" || exit 0
[[ "$count" =~ ^[0-9]+$ ]] || exit 0

if [[ "$count" -gt 0 ]]; then
  echo "branch '$branch' is the head of a MERGED pull request — refusing to push." >&2
  echo "Open a NEW branch + PR for follow-up work instead of reusing a merged one." >&2
  exit 1
fi
exit 0
