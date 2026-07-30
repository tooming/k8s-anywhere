#!/usr/bin/env bash
# stale-prs-check.sh — list open agent-branch PRs that are CI-green but never
# got their self-review-then-merge step run.
#
# Every producing routine (executor, planner, architect, upgrade-drafter,
# doc-drift-author, janitor) has its own STEP 1b: "finish any stale
# self-mergeable PR from a prior run before starting new work." That step has
# silently failed to fire at least three separate times in this repo's history
# (PR #449, 2026-07-16; PRs #914/#915, 2026-07-30; PR #921, 2026-07-30) — each
# time a PR went CI-green with nothing left to do but self-review and merge,
# but the run that produced it ended before that step ran, and the PR sat open
# until a LATER session's STEP 1b happened to notice it (or, in #449's case,
# until the maintainer merged it by hand).
#
# Before this script, STEP 1b was a hand-built `gh pr list --search
# "head:auto/ head:plan/ ..."` query the acting session had to reconstruct
# correctly from memory every time, then cross-reference each result's checks
# and comments by hand. This script makes that one command: it flags exactly
# the PRs matching the "stale" pattern (agent branch prefix, all required
# checks green, no `self-reviewed` label yet) so a run can never miss one by
# mistyping the search or skipping a prefix.
#
# Usage:
#   bash scripts/stale-prs-check.sh
#
# Requirements: gh CLI, authenticated, run from inside the repo. Exits 0 and
# prints nothing found when gh is unavailable/unauthenticated (this is a
# discovery aid for interactive/routine sessions, not a make-ci gate — CI
# runners don't need to know about other open PRs).
set -uo pipefail

AGENT_PREFIXES=(auto plan arch upgrade sync chore)

if ! command -v gh &>/dev/null; then
  echo "stale-prs-check: gh CLI not found — skipping (this check needs live PR state)"
  exit 0
fi

if ! gh auth status &>/dev/null; then
  echo "stale-prs-check: gh CLI not authenticated — skipping (this check needs live PR state)"
  exit 0
fi

search_terms=""
for p in "${AGENT_PREFIXES[@]}"; do
  search_terms+="head:${p}/ "
done

mapfile -t PRS < <(gh pr list --state open --search "${search_terms}" --json number,headRefName,labels 2>/dev/null \
  | python3 -c '
import json, sys
for pr in json.load(sys.stdin):
    labels = [l["name"] for l in pr.get("labels", [])]
    print(f"{pr[\"number\"]}\t{pr[\"headRefName\"]}\t{\",\".join(labels)}")
' 2>/dev/null)

if [[ ${#PRS[@]} -eq 0 ]]; then
  echo "stale-prs-check: no open PRs on agent branch prefixes (${AGENT_PREFIXES[*]})"
  exit 0
fi

STALE=()
for line in "${PRS[@]}"; do
  [[ -z "$line" ]] && continue
  num=$(cut -f1 <<<"$line")
  branch=$(cut -f2 <<<"$line")
  labels=$(cut -f3 <<<"$line")

  if [[ ",${labels}," == *",self-reviewed,"* ]]; then
    continue
  fi

  rollup=$(gh pr view "$num" --json statusCheckRollup --jq '[.statusCheckRollup[]?.conclusion // .statusCheckRollup[]?.state] | unique | join(",")' 2>/dev/null)
  if [[ -z "$rollup" ]]; then
    continue
  fi
  if [[ "$rollup" == "SUCCESS" || "$rollup" == "success" ]]; then
    STALE+=("#${num} (${branch})")
  fi
done

echo "─────────────────────────────────────────────"
if [[ ${#STALE[@]} -eq 0 ]]; then
  echo "stale-prs-check: none — every green agent PR already carries self-reviewed (or has pending/failing checks)"
  exit 0
fi

echo "stale-prs-check: ${#STALE[@]} PR(s) are CI-green with no self-reviewed label — finish STEP 1b on these before starting new work:"
printf '  %s\n' "${STALE[@]}"
exit 0
