#!/usr/bin/env bash
# rebase-open-prs.sh — rebase every open PR branch onto <remote>/main.
#
# For PRs with clean histories (no content conflicts) this is fully automatic.
# For PRs with conflicts the rebase is aborted and the branch left unchanged;
# those need manual resolution.
#
# Usage:
#   bash scripts/rebase-open-prs.sh          # dry-run: show what would happen
#   bash scripts/rebase-open-prs.sh --push   # rebase + force-push updated branches
#
# Requirements: git, git-remote access to the GitHub remote, optional: gh CLI for PR list
# Falls back to listing remote branches matching auto/* arch/* chore/* if gh is unavailable.

set -euo pipefail

PUSH=false
if [[ "${1:-}" == "--push" ]]; then
  PUSH=true
fi

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

# Auto-detect the GitHub remote: prefer the upstream of main, then the first
# remote whose URL contains github.com, then fall back to "origin".
REMOTE=$(git for-each-ref --format='%(upstream:remotename)' refs/heads/main 2>/dev/null | head -1)
if [[ -z "$REMOTE" ]]; then
  REMOTE=$(git remote -v | grep 'github\.com' | awk '{print $1}' | head -1)
fi
REMOTE=${REMOTE:-origin}

git fetch "$REMOTE" --prune -q

MAIN_HEAD=$(git rev-parse "$REMOTE/main")
echo "$REMOTE/main HEAD: ${MAIN_HEAD:0:12}"
echo ""

# Collect open PR branches
# Prefer gh CLI; fall back to listing remote branches
if command -v gh &>/dev/null; then
  mapfile -t BRANCHES < <(
    gh pr list --state open --base main --json headRefName --jq '.[].headRefName' 2>/dev/null
  )
else
  # Enumerate remote branches under known prefixes
  mapfile -t BRANCHES < <(
    git branch -r \
      | grep -E "${REMOTE}/(auto|arch|chore|claude|copilot)/" \
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

for branch in "${BRANCHES[@]}"; do
  remote_ref="${REMOTE}/${branch}"

  if ! git rev-parse "$remote_ref" &>/dev/null; then
    echo "[skip] $branch — remote ref not found"
    continue
  fi

  merge_base=$(git merge-base "$remote_ref" "$REMOTE/main")

  if [[ "$merge_base" == "$MAIN_HEAD" ]]; then
    echo "[ok]   $branch — already up to date"
    SKIPPED+=("$branch")
    continue
  fi

  behind=$(git log --oneline "${merge_base}..${REMOTE}/main" | wc -l | tr -d ' ')
  echo "[rebase] $branch — ${behind} commit(s) behind main"

  if [[ "$PUSH" == "false" ]]; then
    continue
  fi

  # Create temp worktree to avoid touching the working tree
  tmpdir=$(mktemp -d)
  trap 'rm -rf -- "$tmpdir"' EXIT

  git worktree add --detach "$tmpdir" "$remote_ref" -q 2>/dev/null

  pushd "$tmpdir" >/dev/null
  if git rebase "$REMOTE/main" -q 2>/dev/null; then
    new_sha=$(git rev-parse HEAD)
    popd >/dev/null
    git push "$REMOTE" "refs/heads/${branch}" --force-with-lease \
      --force-if-includes 2>/dev/null \
      || git push "$REMOTE" "${new_sha}:refs/heads/${branch}" --force 2>&1
    echo "  → pushed rebased ${branch} (${new_sha:0:12})"
    UPDATED+=("$branch")
  else
    git rebase --abort 2>/dev/null || true
    popd >/dev/null
    echo "  ✗ conflict — manual rebase required for $branch"
    CONFLICTS+=("$branch")
  fi

  git worktree remove --force "$tmpdir" 2>/dev/null || true
  trap - EXIT
done

echo ""
echo "─────────────────────────────────────────────"
if [[ "$PUSH" == "true" ]]; then
  echo "Updated:   ${#UPDATED[@]}"
  echo "Conflicts: ${#CONFLICTS[@]}"
fi
echo "Already OK: ${#SKIPPED[@]}"

if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  echo ""
  echo "Branches needing manual rebase:"
  printf '  %s\n' "${CONFLICTS[@]}"
  exit 1
fi
