#!/usr/bin/env bats
# Recurrence guard for the 2026-07-16 incident: PR #449 went CI-green with
# nothing left to do but merge, but the scheduled follow-up turn that was
# supposed to post the [self-review] comment and merge it silently produced no
# action, leaving the PR to be merged by hand. Every PR-producing routine now
# carries a STEP 1b that checks for — and finishes — any such stale
# self-mergeable PR bearing its own branch prefix before starting new work.
# This test asserts that recovery step is present so a future edit can't
# silently drop it.

setup() {
  ROUTINES="$(cd "$BATS_TEST_DIRNAME/../routines" && pwd)"
}

# (prompt file, its branch prefix)
ROUTINE_PREFIXES="executor:auto planner:plan architect:arch upgrade-drafter:upgrade doc-drift-author:sync janitor:chore"

@test "every PR-producing routine prompt has a STEP 1b stale-PR-recovery step" {
  for pair in $ROUTINE_PREFIXES; do
    file="${pair%%:*}"
    run grep -q '^STEP 1b — Finish any stale self-mergeable' "$ROUTINES/$file.prompt.md"
    [ "$status" -eq 0 ] || { echo "missing STEP 1b in $file.prompt.md"; return 1; }
  done
}

@test "each routine's STEP 1b checks its own branch prefix" {
  for pair in $ROUTINE_PREFIXES; do
    file="${pair%%:*}"
    prefix="${pair##*:}"
    run grep -q "head:$prefix/" "$ROUTINES/$file.prompt.md"
    [ "$status" -eq 0 ] || { echo "$file.prompt.md: STEP 1b does not check head:$prefix/"; return 1; }
  done
}

@test "executor's STEP 1b also sweeps every fallback role's branch prefix" {
  # The executor is the only routine on an actual cron (WAYS-OF-WORKING.md §1),
  # so it's the one guaranteed to eventually recover a stranded fallback-role
  # PR (plan/*, arch/*, upgrade/*, sync/*, chore/*), not just its own auto/*.
  for prefix in auto plan arch upgrade sync chore; do
    run grep -q "head:$prefix/" "$ROUTINES/executor.prompt.md"
    [ "$status" -eq 0 ] || { echo "executor.prompt.md STEP 1b missing head:$prefix/ sweep"; return 1; }
  done
}

@test "STEP 1b names the incident it guards against, so it isn't mistaken for churn" {
  for pair in $ROUTINE_PREFIXES; do
    file="${pair%%:*}"
    run grep -q 'PR #449' "$ROUTINES/$file.prompt.md"
    [ "$status" -eq 0 ] || { echo "$file.prompt.md: STEP 1b doesn't cite the PR #449 precedent"; return 1; }
  done
}
