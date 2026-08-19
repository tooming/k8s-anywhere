#!/usr/bin/env bats
# Guard for scripts/prune-stale-branches.sh.
#
# The prune deletes only branches that can never be an active open PR:
#   - MERGED   (tip is an ancestor of main), or
#   - UNRELATED (no common ancestor with main — orphan history).
# A branch that shares history with main AND has commits not yet in main is a
# plausible OPEN PR and must NEVER be marked for deletion. These build a fixture
# with one of each and assert the classification — the safety property that keeps
# the prune from nuking live work.

setup() {
  # Isolate from the GIT_* env git exports when `make ci` runs from inside a hook
  # (e.g. pre-push). Without this, the fixture's `git` commands below resolve to
  # the real repo via the inherited GIT_DIR/GIT_WORK_TREE instead of the throwaway
  # clone, and every test fails. Guarded by scripts/git-fixture-isolation-check.sh.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_NAMESPACE
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/prune-stale-branches.sh"
  WORK="$(mktemp -d)"
}
teardown() { rm -rf "$WORK"; }

# Fixture branches:
#   auto/merged    — fully merged into main (tip is an ancestor of main)
#   auto/unrelated — orphan history, no common ancestor with main
#   auto/active    — shares history with main, has a commit not in main (open PR)
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

  # merged: a branch whose commits all land in main (push it, then merge into main)
  git checkout -q -b auto/merged
  echo m > m.txt && git add -A && git commit -qm "merged work"
  git push -q origin auto/merged
  git checkout -q main
  git merge -q --no-ff auto/merged -m "merge auto/merged"
  git push -q origin main

  # active: shares history with (the now-advanced) main but has its own commit
  git checkout -q -b auto/active origin/main
  echo act > act.txt && git add -A && git commit -qm "active open work"
  git push -q origin auto/active

  # unrelated: orphan root, no common ancestor
  git checkout -q --orphan auto/unrelated
  git rm -rqf . 2>/dev/null || true
  echo u > u.txt && git add -A && git commit -qm "orphan"
  git push -q origin auto/unrelated

  git checkout -q main
  git fetch -q origin
  git reset -q --hard origin/main
}

@test "prune: marks a merged branch as stale" {
  make_fixture
  run env PRUNE_ROOT="$WORK/clone" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[stale:merged]    auto/merged"* ]]
}

@test "prune: marks an unrelated-history branch as stale" {
  make_fixture
  run env PRUNE_ROOT="$WORK/clone" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[stale:unrelated] auto/unrelated"* ]]
}

@test "prune: NEVER marks an active open-PR branch for deletion (safety)" {
  make_fixture
  run env PRUNE_ROOT="$WORK/clone" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  # auto/active must not appear on any [stale:*] line
  ! grep -qE '^\[stale:[a-z]+\] +auto/active' <<<"$output"
  [[ "$output" == *"Active (kept): 1"* ]]
}

@test "prune: dry-run deletes nothing and says so" {
  make_fixture
  run env PRUNE_ROOT="$WORK/clone" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  # both stale branches still exist on the remote
  cd "$WORK/clone" && git fetch -q origin
  run git rev-parse --verify origin/auto/merged
  [ "$status" -eq 0 ]
}

@test "prune: --push deletes the stale branches but keeps the active one" {
  make_fixture
  run env PRUNE_ROOT="$WORK/clone" bash "$SCRIPT" --push
  [ "$status" -eq 0 ]
  cd "$WORK/clone" && git fetch -q --prune origin
  run git rev-parse --verify origin/auto/merged
  [ "$status" -ne 0 ]    # gone
  run git rev-parse --verify origin/auto/unrelated
  [ "$status" -ne 0 ]    # gone
  run git rev-parse --verify origin/auto/active
  [ "$status" -eq 0 ]    # kept
}

# --- Class 3: ORPHANED (no open PR + old enough) ---------------------------
# Recurrence guard: auto/pr-creation-diagnostic-test (pushed 2026-07-24) and
# auto/action-needed-cycle13-doc-precision-lane-slowing (pushed 2026-08-07)
# both sat on the remote for weeks with commits not in main and no open PR —
# the classes-1/2 heuristic above always classified "shares history + has
# unique commits" as "plausible open PR" with no way to tell a genuinely
# abandoned push (PR creation failed/skipped) from a real in-flight one. These
# assert the gh-backed reclassification and its two safety nets: a too-recent
# tip is never caught (the normal push-then-create-PR gap), and a branch gh
# confirms has a real open PR is never caught regardless of age.

make_stub_gh() {
  # $1: file listing "open PR" branch names, one per line (may be empty)
  cat > "$WORK/gh" <<STUB
#!/usr/bin/env bash
if [[ "\$1" == "auth" ]]; then exit 0; fi
if [[ "\$1" == "pr" && "\$2" == "list" ]]; then cat "$1"; exit 0; fi
exit 1
STUB
  chmod +x "$WORK/gh"
}

# Same shape as auto/active in make_fixture, but reused standalone here so
# each orphan test controls gh's stubbed response independently.
make_orphan_fixture() {
  git init -q --bare "$WORK/remote.git"
  git clone -q "$WORK/remote.git" "$WORK/clone"
  cd "$WORK/clone"
  git config user.email t@example.com
  git config user.name tester
  echo base > a.txt
  git add -A && git commit -qm "init"
  git push -q origin HEAD:refs/heads/main

  git checkout -q -b auto/orphan-candidate origin/main
  echo o > o.txt && git add -A && git commit -qm "orphaned work"
  git push -q origin auto/orphan-candidate

  git checkout -q main
}

@test "prune: no-open-PR branch past the age gate is reclassified orphaned when gh is available" {
  make_orphan_fixture
  echo -n > "$WORK/open_prs.txt"   # gh reports zero open PRs
  make_stub_gh "$WORK/open_prs.txt"
  run env PATH="$WORK:$PATH" PRUNE_ROOT="$WORK/clone" ORPHAN_AGE_S=0 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[stale:orphaned]  auto/orphan-candidate"* ]]
}

@test "prune: no-open-PR branch within the age gate is kept (push-then-create-PR grace window)" {
  make_orphan_fixture
  echo -n > "$WORK/open_prs.txt"   # gh reports zero open PRs
  make_stub_gh "$WORK/open_prs.txt"
  # default ORPHAN_AGE_S (86400s) — a branch pushed moments ago must survive
  run env PATH="$WORK:$PATH" PRUNE_ROOT="$WORK/clone" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  ! grep -qE '^\[stale:[a-z]+\] +auto/orphan-candidate' <<<"$output"
  [[ "$output" == *"Active (kept): 1"* ]]
}

@test "prune: a branch gh confirms has a real open PR is never reclassified orphaned, even past the age gate" {
  make_orphan_fixture
  echo "auto/orphan-candidate" > "$WORK/open_prs.txt"
  make_stub_gh "$WORK/open_prs.txt"
  run env PATH="$WORK:$PATH" PRUNE_ROOT="$WORK/clone" ORPHAN_AGE_S=0 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  ! grep -qE '^\[stale:[a-z]+\] +auto/orphan-candidate' <<<"$output"
  [[ "$output" == *"Active (kept): 1"* ]]
}

@test "prune: without gh available, class-3 reclassification is skipped entirely (git-only fallback unchanged)" {
  make_orphan_fixture
  # deliberately no stub gh on PATH
  run env PRUNE_ROOT="$WORK/clone" ORPHAN_AGE_S=0 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  ! grep -qE '^\[stale:[a-z]+\] +auto/orphan-candidate' <<<"$output"
  [[ "$output" == *"Active (kept): 1"* ]]
}

# Recurrence guard: PR #936 (a sync/* branch) fell behind main undetected for the
# rest of a run because this script's branch-discovery regex only matched
# auto/arch/chore/claude/copilot — every other agent prefix in
# docs/WAYS-OF-WORKING.md's "Branch prefix signals origin" list (plan/ upgrade/
# sync/ digest/) was silently invisible to it. Assert every prefix is recognised.
@test "prune: recognises every agent branch prefix from WAYS-OF-WORKING.md, not just auto/arch/chore" {
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
    git checkout -q -b "${prefix}/merged-test" origin/main
    echo "$prefix" > "${prefix}.txt" && git add -A && git commit -qm "${prefix} work"
    git push -q origin "${prefix}/merged-test"
    git checkout -q main
    git merge -q --no-ff "${prefix}/merged-test" -m "merge ${prefix}/merged-test"
    git push -q origin main
  done
  git fetch -q origin
  git reset -q --hard origin/main

  run env PRUNE_ROOT="$WORK/clone" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  for prefix in plan upgrade sync digest; do
    [[ "$output" == *"[stale:merged]    ${prefix}/merged-test"* ]]
  done
}
