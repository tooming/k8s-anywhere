#!/usr/bin/env bash
# Stop hook — enforces the standing rules: commit + push + open a PR.
# Exits 2 (feeds a reminder back) when the session ends with uncommitted
# changes, unpushed commits, or a feature branch pushed but no open PR.
# No network calls for the commit/push checks — compares against local
# github remote-tracking refs. gh pr view is only called when everything
# else is clean and commits exist over github/main.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ "$branch" = "main" ] && exit 0

dirty="$(git status --porcelain 2>/dev/null)"
# Count commits reachable from HEAD that aren't on ANY github branch — not just
# github/main — so an unmerged feature branch already pushed to github doesn't
# false-flag (PR workflow: work reaches main via review, never a direct push).
ahead=0
if git rev-parse --verify -q github/main >/dev/null 2>&1; then
  ahead="$(git rev-list --count HEAD --not --remotes=github 2>/dev/null || echo 0)"
fi

# If commits are pushed, check whether an open PR exists for this branch.
no_pr=0
if [ "${ahead:-0}" -eq 0 ] && command -v gh >/dev/null 2>&1; then
  has_commits_over_main="$(git rev-list --count github/main..HEAD 2>/dev/null || echo 0)"
  if [ "${has_commits_over_main:-0}" -gt 0 ]; then
    pr_state="$(gh pr view --json state -q .state 2>/dev/null || echo '')"
    # MERGED means the work is done — no action needed.
    [ "$pr_state" != "OPEN" ] && [ "$pr_state" != "MERGED" ] && no_pr=1
  fi
fi

if [ -n "$dirty" ] || [ "${ahead:-0}" -gt 0 ] || [ "$no_pr" -eq 1 ]; then
  {
    echo "Standing instruction: commit + push + open a PR after every change:"
    [ -n "$dirty" ]           && echo "  - uncommitted changes in the working tree"
    [ "${ahead:-0}" -gt 0 ]   && echo "  - ${ahead} local commit(s) not on any github branch"
    [ "$no_pr" -eq 1 ]        && echo "  - branch is pushed but has no open PR — run: gh pr create"
    echo "Commit with a real message, then push the branch: git push github HEAD."
    echo "(main reaches github via reviewed PR — don't push to main directly; sync gitlab main when the lab is up.)"
  } >&2
  exit 2
fi
exit 0
