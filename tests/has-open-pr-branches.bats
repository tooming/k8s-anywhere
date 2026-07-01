#!/usr/bin/env bats
# Unit tests for scripts/has-open-pr-branches.sh — the fast local guard the
# post-merge hook uses to avoid running the network-heavy `make rebase-prs` on
# every `git pull` when there is nothing to rebase. Hermetic: each test builds a
# throwaway repo + bare "github" remote in BATS_TEST_TMPDIR, so it never touches
# the real repo or the network.
#
# Invariants under test:
#   - only main on the remote        -> exit 1 (nothing to do; hook short-circuits)
#   - a PR branch present            -> exit 0 (hook runs the rebase)
#   - over-approximation is on purpose: ANY non-main remote branch counts, so the
#     guard can never wrongly skip a real PR branch (the bug it must avoid).

setup() {
  # git exports GIT_DIR/GIT_WORK_TREE into hooks; make ci runs from pre-push, so
  # leaking them here would redirect fixture commits into the real repo.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_NAMESPACE

  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/has-open-pr-branches.sh"

  WORK="$BATS_TEST_TMPDIR/work"
  REMOTE_DIR="$BATS_TEST_TMPDIR/remote.git"

  git init -q --bare "$REMOTE_DIR"
  git init -q "$WORK"
  cd "$WORK"
  git config user.email t@example.com
  git config user.name t
  git checkout -q -b main
  git commit -q --allow-empty -m init
  # Name the remote "github" (not "origin") to exercise remote auto-detection.
  git remote add github "$REMOTE_DIR"
  git push -q -u github main
  git fetch -q github
}

@test "no open PR branches: only main on remote -> exit 1" {
  cd "$WORK"
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "open PR branch present -> exit 0" {
  cd "$WORK"
  git push -q github main:refs/heads/auto/feature-x
  git fetch -q github
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "over-approximate: any non-main remote branch counts (never skip work)" {
  cd "$WORK"
  git push -q github main:refs/heads/some-random-branch
  git fetch -q github
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}
