#!/usr/bin/env bash
# Stop hook — the user's standing instruction is to ALWAYS commit + push after
# changes. This is the safety net so it's never forgotten: if a turn is ending with
# uncommitted changes or local commits not yet on GitHub, exit 2 feeds a reminder
# back so the work gets committed + pushed before stopping. Checks GitHub only (the
# durable remote; GitLab may be stopped). No network calls — compares against
# local github remote-tracking refs (any branch).
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

dirty="$(git status --porcelain 2>/dev/null)"
# Count commits reachable from HEAD that aren't on ANY github branch — not just
# github/main — so an unmerged feature branch already pushed to github doesn't
# false-flag (PR workflow: work reaches main via review, never a direct push).
ahead=0
if git rev-parse --verify -q github/main >/dev/null 2>&1; then
  ahead="$(git rev-list --count HEAD --not --remotes=github 2>/dev/null || echo 0)"
fi

if [ -n "$dirty" ] || [ "${ahead:-0}" -gt 0 ]; then
  {
    echo "Standing instruction: commit + push after changes — there's unsaved work:"
    [ -n "$dirty" ]            && echo "  - uncommitted changes in the working tree"
    [ "${ahead:-0}" -gt 0 ]    && echo "  - ${ahead} local commit(s) not on any github branch"
    echo "Commit with a real message, then push the branch: git push github HEAD."
    echo "(main reaches github via reviewed PR — don't push to main directly; sync gitlab main when the lab is up.)"
  } >&2
  exit 2
fi
exit 0
