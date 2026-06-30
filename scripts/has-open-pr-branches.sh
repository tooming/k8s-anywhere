#!/usr/bin/env bash
# has-open-pr-branches.sh — exit 0 if at least one remote PR branch exists to
# rebase, exit 1 if the only remote branch is main (nothing to do).
#
# This is a FAST, PURELY LOCAL guard for the post-merge hook. It reads only the
# remote-tracking refs that `git pull` just refreshed — no network call — so the
# common case (fresh clone, or all PRs merged, leaving only main) short-circuits
# instantly instead of paying a `git fetch` + `gh pr list` + per-branch rebase.
#
# Its job is only to answer "is there ANY chance rebase-open-prs.sh has work?",
# so it deliberately OVER-APPROXIMATES: any non-main remote branch counts. It
# does NOT filter by branch-name prefix on purpose — that prefix list lives in
# rebase-open-prs.sh and would silently drift out of sync here, and the failure
# mode of a too-narrow guard (wrongly skipping a real PR branch) is the bug we
# must never ship. Running rebase-open-prs.sh redundantly is cheap and safe;
# skipping a real PR branch is not.
set -uo pipefail

ROOT=$(git rev-parse --show-toplevel) || exit 1
cd "$ROOT" || exit 1

# Detect the GitHub remote the same way rebase-open-prs.sh does: prefer main's
# upstream remote, then any remote whose URL is github.com, then "origin".
REMOTE=$(git for-each-ref --format='%(upstream:remotename)' refs/heads/main 2>/dev/null | head -1)
if [[ -z "$REMOTE" ]]; then
  REMOTE=$(git remote -v | grep 'github\.com' | awk '{print $1}' | head -1)
fi
REMOTE=${REMOTE:-origin}

# Any remote-tracking branch under $REMOTE/ other than main/HEAD means there is
# potentially a PR branch to rebase.
# Exclude main, the bare remote name, and the remote's HEAD symref — whose short
# forms are "$REMOTE/main", "$REMOTE", and "$REMOTE/HEAD" respectively.
if git for-each-ref --format='%(refname:short)' "refs/remotes/${REMOTE}" 2>/dev/null \
     | grep -vxE "${REMOTE}(/(main|HEAD))?" \
     | grep -q .; then
  exit 0
fi
exit 1
