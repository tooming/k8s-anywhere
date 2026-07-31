#!/usr/bin/env bats
# Regression guard for scripts/rebase-open-prs.sh.
#
# The fleet-rebase must process EVERY open PR branch independently — one branch
# that can't be rebased (unrelated history / conflict) must never abort the whole
# run. The original `set -e` version died on the first no-common-ancestor branch
# (`git merge-base` exit 1), so the bulk of rebasable branches were never caught
# up and merge conflicts silently accumulated across the fleet.
#
# These build a throwaway git fixture (bare remote + clone) with an unrelated-
# history branch that sorts BEFORE a still-rebasable branch, then assert the
# script reaches the later branch and exits cleanly. If the loop ever aborts early
# again, the rebasable branch won't be reported and these fail.

setup() {
  # Isolate from the GIT_* env git exports when `make ci` runs from inside a hook
  # (e.g. pre-push). Without this, the fixture's `git` commands below resolve to
  # the real repo via the inherited GIT_DIR/GIT_WORK_TREE instead of the throwaway
  # clone, and every test fails. Guarded by scripts/git-fixture-isolation-check.sh.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_NAMESPACE
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/rebase-open-prs.sh"
  WORK="$(mktemp -d)"
}

teardown() {
  rm -rf "$WORK"
}

# Build a fixture repo. Branch names are chosen so the orphan (unrelated history)
# sorts BEFORE the rebasable branch:
#   auto/aaa-unrelated  — orphan, no common ancestor with main
#   auto/zzz-rebasable  — one commit behind main, cleanly rebasable
make_fixture() {
  git init -q --bare "$WORK/remote.git"
  git clone -q "$WORK/remote.git" "$WORK/clone"
  cd "$WORK/clone"
  git config user.email t@example.com
  git config user.name tester

  echo base > a.txt
  git add -A && git commit -qm "init"
  git push -q origin HEAD:refs/heads/main
  git branch -q --set-upstream-to=origin/main 2>/dev/null || true

  # rebasable branch off the first commit
  git checkout -q -b auto/zzz-rebasable
  echo work > b.txt
  git add -A && git commit -qm "feature work"
  git push -q origin auto/zzz-rebasable

  # advance main so the rebasable branch is behind
  git checkout -q main
  echo more >> a.txt
  git add -A && git commit -qm "advance main"
  git push -q origin main

  # unrelated-history branch (orphan) — the case that crashed the old script
  git checkout -q --orphan auto/aaa-unrelated
  git rm -rqf . 2>/dev/null || true
  echo orphan > u.txt
  git add -A && git commit -qm "orphan root"
  git push -q origin auto/aaa-unrelated

  # leave the clone on main, tracking origin/main
  git checkout -q main
  git fetch -q origin
  git reset -q --hard origin/main
}

@test "rebase-open-prs: an unrelated-history branch does not abort the run (dry-run)" {
  make_fixture
  run env REBASE_PRS_NO_GH=1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  # the orphan is recognised and skipped, NOT crashed on
  [[ "$output" == *"auto/aaa-unrelated"* ]]
  [[ "$output" == *"unrelated history"* ]]
}

@test "rebase-open-prs: still reaches a rebasable branch that sorts after the unrelated one" {
  make_fixture
  run env REBASE_PRS_NO_GH=1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  # zzz-rebasable sorts AFTER aaa-unrelated; if the loop aborted early it would be
  # missing. It must be reported as behind main.
  [[ "$output" == *"auto/zzz-rebasable"* ]]
  [[ "$output" == *"[rebase] auto/zzz-rebasable"* ]]
}

@test "rebase-open-prs: reports an accurate summary line" {
  make_fixture
  run env REBASE_PRS_NO_GH=1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Unrelated:  1"* ]]
}

@test "rebase-open-prs: exits 0 cleanly when there are no PR branches" {
  git init -q --bare "$WORK/remote.git"
  git clone -q "$WORK/remote.git" "$WORK/clone"
  cd "$WORK/clone"
  git config user.email t@example.com
  git config user.name tester
  echo base > a.txt
  git add -A && git commit -qm "init"
  git push -q origin HEAD:refs/heads/main
  git branch -q --set-upstream-to=origin/main 2>/dev/null || true
  run env REBASE_PRS_NO_GH=1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No open PR branches found"* ]]
}

# Recurrence guard: PR #936 (a sync/* branch) fell behind main undetected for the
# rest of a run because this script's no-gh fallback branch-discovery regex only
# matched auto/arch/chore/claude/copilot — every other agent prefix in
# docs/WAYS-OF-WORKING.md's "Branch prefix signals origin" list (plan/ upgrade/
# sync/ digest/) was silently invisible to it. Assert every prefix is discovered.
@test "rebase-open-prs: discovers every agent branch prefix from WAYS-OF-WORKING.md, not just auto/arch/chore" {
  git init -q --bare "$WORK/remote.git"
  git clone -q "$WORK/remote.git" "$WORK/clone"
  cd "$WORK/clone"
  git config user.email t@example.com
  git config user.name tester
  echo base > a.txt
  git add -A && git commit -qm "init"
  git push -q origin HEAD:refs/heads/main
  git branch -q --set-upstream-to=origin/main 2>/dev/null || true

  for prefix in plan upgrade sync digest; do
    git checkout -q -b "${prefix}/behind-test" main
    echo "$prefix" > "${prefix}.txt" && git add -A && git commit -qm "${prefix} work"
    git push -q origin "${prefix}/behind-test"
    git checkout -q main
  done
  echo more >> a.txt
  git add -A && git commit -qm "advance main"
  git push -q origin main

  run env REBASE_PRS_NO_GH=1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  for prefix in plan upgrade sync digest; do
    [[ "$output" == *"[rebase] ${prefix}/behind-test"* ]]
  done
}
