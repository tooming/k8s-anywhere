#!/usr/bin/env bash
# prune-stale-branches.sh — delete remote PR branches that can never be an active
# open PR, so the fleet stays small and `make rebase-prs` only ever deals with
# real, open work.
#
# Two provably-safe classes are deleted:
#   1. MERGED   — the branch tip is an ancestor of <remote>/main, i.e. all its
#                 commits are already in main (its PR was merged). Work is preserved.
#   2. UNRELATED— the branch has NO common ancestor with main (orphan history).
#                 A normal PR is cut from main and always shares history, so an
#                 unrelated branch cannot be a valid mergeable open PR.
# Anything that shares history with main AND has commits not yet in main is a
# plausible OPEN PR and is ALWAYS kept — never deleted.
#
# Usage:
#   bash scripts/prune-stale-branches.sh          # dry-run: list what would be deleted
#   bash scripts/prune-stale-branches.sh --push   # actually delete them on the remote
#
# Env: PRUNE_ROOT=<dir> runs against a fixture repo (used by the bats guard).
#
# NOT `set -e`: like rebase-open-prs.sh, this must process the whole fleet without
# one branch aborting the run.
set -uo pipefail

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
# Keep this list in sync with rebase-open-prs.sh's identical fallback regex — every
# agent/PR prefix in docs/WAYS-OF-WORKING.md's "Branch prefix signals origin" list
# (auto/ plan/ arch/ upgrade/ sync/ digest/ chore/) plus claude/ copilot/. A missing
# prefix here means that role's merged/orphaned branches never get pruned.
mapfile -t BRANCHES < <(
  git branch -r \
    | grep -E "${REMOTE}/(auto|arch|chore|claude|copilot|plan|upgrade|sync|digest)/" \
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
