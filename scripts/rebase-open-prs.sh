#!/usr/bin/env bash
# rebase-open-prs.sh — rebase every open PR branch onto <remote>/main.
#
# For PRs with clean histories (no content conflicts) this is fully automatic.
# For PRs with conflicts the rebase is aborted and the branch left unchanged;
# those need manual resolution. Branches with NO common ancestor (unrelated
# history — old/orphaned bot branches) cannot be rebased onto main at all and are
# skipped. CRUCIAL: a single unrebasable branch must NEVER abort the whole fleet —
# every branch is processed independently and failures are isolated. (Regression:
# the previous `set -e` version died on the FIRST no-common-ancestor branch via
# `git merge-base` exit 1, so the bulk of rebasable branches were never caught up
# and conflicts silently accumulated. Guarded by tests/rebase-open-prs.bats.)
#
# Usage:
#   bash scripts/rebase-open-prs.sh          # dry-run: show what would happen
#   bash scripts/rebase-open-prs.sh --push   # rebase + force-push updated branches
#
# Env:
#   REBASE_PRS_NO_GH=1   # skip the gh CLI; enumerate remote branches by prefix
#                        # (used by the test harness; also handy when gh is unauthed)
#
# Requirements: git, git-remote access to the GitHub remote, optional: gh CLI for PR list.
# Falls back to listing remote branches matching every agent/PR prefix in
# docs/WAYS-OF-WORKING.md's "Branch prefix signals origin" list (auto/ plan/ arch/
# upgrade/ sync/ digest/ chore/) plus claude/ copilot/. Missing a prefix here means
# that role's open PRs are silently never rebased when gh is unavailable — this
# exact gap (sync/* missing) let PR #936 fall behind main undetected for the rest
# of a run. Keep this list in sync with prune-stale-branches.sh's identical regex.
#
# NOTE: intentionally NOT `set -e`. This script's whole job is to keep going across
# many branches, most of which may fail to rebase; aborting on the first failure is
# the bug this script exists to avoid. We use `set -uo pipefail` and handle the
# exit status of every fallible command explicitly.
set -uo pipefail

PUSH=false
if [[ "${1:-}" == "--push" ]]; then
  PUSH=true
fi

ROOT=$(git rev-parse --show-toplevel) || { echo "not in a git repo" >&2; exit 1; }
cd "$ROOT" || exit 1

# Auto-detect the GitHub remote: prefer the upstream of main, then the first
# remote whose URL contains github.com, then fall back to "origin".
REMOTE=$(git for-each-ref --format='%(upstream:remotename)' refs/heads/main 2>/dev/null | head -1)
if [[ -z "$REMOTE" ]]; then
  REMOTE=$(git remote -v | grep 'github\.com' | awk '{print $1}' | head -1)
fi
REMOTE=${REMOTE:-origin}

git fetch "$REMOTE" --prune -q || { echo "fetch from $REMOTE failed" >&2; exit 1; }

MAIN_HEAD=$(git rev-parse "$REMOTE/main") || { echo "$REMOTE/main not found" >&2; exit 1; }
echo "$REMOTE/main HEAD: ${MAIN_HEAD:0:12}"
echo ""

# Collect open PR branches. Prefer gh CLI; fall back to listing remote branches.
# Declare the array first: under `set -u`, ${#BRANCHES[@]} on an unset array is an
# unbound-variable error, which would skip the fallback when gh is absent.
BRANCHES=()
if [[ -z "${REBASE_PRS_NO_GH:-}" ]] && command -v gh &>/dev/null; then
  mapfile -t BRANCHES < <(
    gh pr list --state open --base main --json headRefName --jq '.[].headRefName' 2>/dev/null
  )
fi
# Fallback (no gh, gh failed, or gh returned nothing): enumerate by prefix.
if [[ "${#BRANCHES[@]}" -eq 0 ]]; then
  mapfile -t BRANCHES < <(
    git branch -r \
      | grep -E "${REMOTE}/(auto|arch|chore|claude|copilot|plan|upgrade|sync|digest)/" \
      | sed "s|.*${REMOTE}/||" \
      | sort
  )
fi

if [[ ${#BRANCHES[@]} -eq 0 ]]; then
  echo "No open PR branches found."
  exit 0
fi

echo "Branches to check (${#BRANCHES[@]}):"
printf '  %s\n' "${BRANCHES[@]}"
echo ""

UPDATED=()
SKIPPED=()
CONFLICTS=()
UNRELATED=()

# process_branch <branch> — rebase one branch onto $REMOTE/main, isolated so any
# failure stays local to this branch. Invoked as `process_branch X || true` so a
# non-zero return can never abort the loop. Mutates the result arrays in place.
process_branch() {
  local branch="$1"
  local remote_ref="${REMOTE}/${branch}"

  if ! git rev-parse "$remote_ref" &>/dev/null; then
    echo "[skip] $branch — remote ref not found"
    return 0
  fi

  local merge_base
  if ! merge_base=$(git merge-base "$remote_ref" "$REMOTE/main" 2>/dev/null); then
    echo "[skip] $branch — no common ancestor with $REMOTE/main (unrelated history)"
    UNRELATED+=("$branch")
    return 0
  fi

  if [[ "$merge_base" == "$MAIN_HEAD" ]]; then
    echo "[ok]   $branch — already up to date"
    SKIPPED+=("$branch")
    return 0
  fi

  local behind
  behind=$(git log --oneline "${merge_base}..${REMOTE}/main" 2>/dev/null | wc -l | tr -d ' ')
  echo "[rebase] $branch — ${behind} commit(s) behind main"

  if [[ "$PUSH" == "false" ]]; then
    return 0
  fi

  local tmpdir
  tmpdir=$(mktemp -d) || { echo "  ✗ mktemp failed for $branch"; CONFLICTS+=("$branch"); return 0; }

  if ! git worktree add --detach "$tmpdir" "$remote_ref" -q 2>/dev/null; then
    echo "  ✗ could not create worktree for $branch — skipped"
    rm -rf -- "$tmpdir"
    CONFLICTS+=("$branch")
    return 0
  fi

  if git -C "$tmpdir" rebase "$REMOTE/main" -q 2>/dev/null; then
    local new_sha
    new_sha=$(git -C "$tmpdir" rev-parse HEAD)
    if git push "$REMOTE" "${new_sha}:refs/heads/${branch}" --force-with-lease --force-if-includes 2>/dev/null \
       || git push "$REMOTE" "${new_sha}:refs/heads/${branch}" --force 2>/dev/null; then
      echo "  → pushed rebased ${branch} (${new_sha:0:12})"
      UPDATED+=("$branch")
    else
      echo "  ✗ rebased but push failed for $branch"
      CONFLICTS+=("$branch")
    fi
  else
    git -C "$tmpdir" rebase --abort 2>/dev/null || true
    echo "  ✗ conflict — manual rebase required for $branch"
    CONFLICTS+=("$branch")
  fi

  git worktree remove --force "$tmpdir" 2>/dev/null || true
  rm -rf -- "$tmpdir" 2>/dev/null || true
  return 0
}

for branch in "${BRANCHES[@]}"; do
  process_branch "$branch" || echo "  ✗ unexpected error processing $branch (continuing)"
done

echo ""
echo "─────────────────────────────────────────────"
if [[ "$PUSH" == "true" ]]; then
  echo "Updated:   ${#UPDATED[@]}"
  echo "Conflicts: ${#CONFLICTS[@]}"
fi
echo "Already OK: ${#SKIPPED[@]}"
echo "Unrelated:  ${#UNRELATED[@]} (no common ancestor — cannot rebase onto main)"

if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  echo ""
  echo "Branches needing manual rebase:"
  printf '  %s\n' "${CONFLICTS[@]}"
  exit 1
fi
exit 0
