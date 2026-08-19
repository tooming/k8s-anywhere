#!/usr/bin/env bash
# prune-stale-branches.sh — delete remote PR branches that can never be an active
# open PR, so the fleet stays small and `make rebase-prs` only ever deals with
# real, open work.
#
# Three classes are deleted:
#   1. MERGED   — the branch tip is an ancestor of <remote>/main, i.e. all its
#                 commits are already in main (its PR was merged). Work is preserved.
#   2. UNRELATED— the branch has NO common ancestor with main (orphan history).
#                 A normal PR is cut from main and always shares history, so an
#                 unrelated branch cannot be a valid mergeable open PR.
#   3. ORPHANED — shares history with main and has commits not yet in main (so
#                 classes 1/2 above always kept it as "plausible open PR"), but
#                 no open PR actually references it AND its tip commit is older
#                 than $ORPHAN_AGE_S. Found live 2026-08-19: auto/pr-creation-
#                 diagnostic-test (pushed 2026-07-24) and auto/action-needed-
#                 cycle13-doc-precision-lane-slowing (pushed 2026-08-07) both
#                 sat on the remote for weeks — a session pushed the branch, PR
#                 creation itself then failed or was skipped, and nothing ever
#                 caught it because "shares history + has unique commits" is
#                 necessary but not sufficient for "is a live open PR". This
#                 class is best-effort — it needs `gh`, authenticated, same as
#                 stale-prs-check.sh — and time-gated so a branch pushed moments
#                 before its PR is created (the normal push-then-create-PR gap
#                 in every producing routine's own STEP 6) is never misclassified.
# Anything else — shares history with main, has unique commits, AND either gh
# is unavailable or an open PR (or a too-recent tip) covers it — is kept.
#
# Usage:
#   bash scripts/prune-stale-branches.sh          # dry-run: list what would be deleted
#   bash scripts/prune-stale-branches.sh --push   # actually delete them on the remote
#
# Env: PRUNE_ROOT=<dir> runs against a fixture repo (used by the bats guard).
#      ORPHAN_AGE_S=<seconds> overrides the class-3 age gate (default 86400 = 24h).
#
# NOT `set -e`: like rebase-open-prs.sh, this must process the whole fleet without
# one branch aborting the run.
set -uo pipefail

# Every agent/PR prefix in docs/WAYS-OF-WORKING.md's "Branch prefix signals
# origin" list. Shared by the branch-discovery regex and (when gh is
# available) the open-PR search below — one list, so a missing prefix can
# never make one query see a branch the other doesn't (recurrence guard,
# see tests/prune-stale-branches.bats).
PREFIXES=(auto arch chore claude copilot plan upgrade sync digest)

PUSH=false
[[ "${1:-}" == "--push" ]] && PUSH=true

if [[ -n "${PRUNE_ROOT:-}" ]]; then cd "$PRUNE_ROOT" || exit 1; fi
ROOT=$(git rev-parse --show-toplevel) || { echo "not in a git repo" >&2; exit 1; }
cd "$ROOT" || exit 1

REMOTE=$(git for-each-ref --format='%(upstream:remotename)' refs/heads/main 2>/dev/null | head -1)
[[ -z "$REMOTE" ]] && REMOTE=$(git remote -v | grep 'github\.com' | awk '{print $1}' | head -1)
REMOTE=${REMOTE:-origin}

git fetch "$REMOTE" --prune -q || { echo "fetch from $REMOTE failed" >&2; exit 1; }
MAIN=$(git rev-parse "$REMOTE/main") || { echo "$REMOTE/main not found" >&2; exit 1; }
echo "$REMOTE/main HEAD: ${MAIN:0:12}"

# Only branches under the bot/PR prefixes are ever candidates. main is excluded.
# Keep this in sync with rebase-open-prs.sh's identical fallback regex. A missing
# prefix in PREFIXES above means that role's merged/orphaned branches never get
# pruned — and, now, never get open-PR-checked for class 3 either.
prefix_alt=$(IFS='|'; echo "${PREFIXES[*]}")
mapfile -t BRANCHES < <(
  git branch -r \
    | grep -E "${REMOTE}/(${prefix_alt})/" \
    | sed "s|.*${REMOTE}/||" \
    | sort
)

DELETE=()
KEEP=()
for b in "${BRANCHES[@]}"; do
  if ! git merge-base "$REMOTE/$b" "$MAIN" &>/dev/null; then
    DELETE+=("$b"); echo "[stale:unrelated] $b"
  elif git merge-base --is-ancestor "$REMOTE/$b" "$MAIN" 2>/dev/null; then
    DELETE+=("$b"); echo "[stale:merged]    $b"
  else
    KEEP+=("$b")    # shares history + has unique commits → plausible open PR
  fi
done

# Class 3 — ORPHANED: reclassify any KEEP branch that gh confirms has no open
# PR AND whose tip is old enough that this isn't the normal push-then-create-PR
# gap. Best-effort: skipped entirely (KEEP unchanged) when gh is unavailable or
# unauthenticated — never treat "gh has nothing to say" as "no open PR exists".
ORPHAN_AGE_S="${ORPHAN_AGE_S:-86400}"
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  search_terms=""
  for p in "${PREFIXES[@]}"; do search_terms+="head:${p}/ "; done
  declare -A OPEN_PR_BRANCHES=()
  while IFS= read -r ref; do
    [[ -n "$ref" ]] && OPEN_PR_BRANCHES["$ref"]=1
  done < <(gh pr list --state open --search "${search_terms}" --json headRefName --jq '.[].headRefName' 2>/dev/null)

  now=$(date +%s)
  STILL_KEEP=()
  for b in "${KEEP[@]}"; do
    if [[ -z "${OPEN_PR_BRANCHES[$b]:-}" ]]; then
      tip_ts=$(git log -1 --format=%ct "$REMOTE/$b" 2>/dev/null || echo "$now")
      age=$(( now - tip_ts ))
      if [[ "$age" -ge "$ORPHAN_AGE_S" ]]; then
        DELETE+=("$b"); echo "[stale:orphaned]  $b (no open PR, ${age}s old)"
        continue
      fi
    fi
    STILL_KEEP+=("$b")
  done
  KEEP=("${STILL_KEEP[@]}")
fi

echo ""
echo "─────────────────────────────────────────────"
echo "Stale (deletable): ${#DELETE[@]}    Active (kept): ${#KEEP[@]}"

if [[ ${#DELETE[@]} -eq 0 ]]; then
  echo "Nothing to prune."
  exit 0
fi

if [[ "$PUSH" == "false" ]]; then
  echo "(dry-run — re-run with --push to delete the ${#DELETE[@]} stale branch(es))"
  exit 0
fi

# Delete in batches to keep the number of pushes (and pre-push hook runs) low.
# Branch deletion changes no repo content, so --no-verify (skip the make-ci
# pre-push gate) is correct here — there is nothing to validate.
failed=0
batch=()
flush() {
  [[ ${#batch[@]} -eq 0 ]] && return 0
  if git push "$REMOTE" --no-verify --delete "${batch[@]}" 2>/dev/null; then
    printf '  → deleted: %s\n' "${batch[*]}"
  else
    echo "  ✗ batch delete failed; retrying individually"
    for one in "${batch[@]}"; do
      git push "$REMOTE" --no-verify --delete "$one" 2>/dev/null \
        && echo "    → deleted $one" \
        || { echo "    ✗ could not delete $one"; failed=$((failed+1)); }
    done
  fi
  batch=()
}
for b in "${DELETE[@]}"; do
  batch+=("$b")
  [[ ${#batch[@]} -ge 25 ]] && flush
done
flush

echo ""
echo "Deleted ${#DELETE[@]} stale branch(es); failures: ${failed}"
[[ "$failed" -eq 0 ]]
