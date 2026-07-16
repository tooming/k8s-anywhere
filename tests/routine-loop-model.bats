#!/usr/bin/env bats
# Recurrence guard for the 2026-07-16 operating-model change (maintainer request:
# "make every routine's goal to work until credit runs out"). Guards that the
# executor's operating model is "loop until exhausted", not "one item per run,
# then stop" — the old model's own literal phrase must not reappear.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  EXECUTOR="$REPO/routines/executor.prompt.md"
  ROADMAP="$REPO/ROADMAP.md"
}

@test "executor.prompt.md has the STEP 8 loop contract" {
  run grep -q '^STEP 8 — Loop: don.t stop after one item' "$EXECUTOR"
  [ "$status" -eq 0 ]
}

@test "executor.prompt.md's opening no longer claims exactly one item per run" {
  run grep -q 'Do exactly ONE backlog item this run' "$EXECUTOR"
  [ "$status" -eq 1 ]
}

@test "executor.prompt.md's opening states the loop goal" {
  run grep -q 'stopping only when the backlog and every fallback role are genuinely exhausted' "$EXECUTOR"
  [ "$status" -eq 0 ]
}

@test "ROADMAP.md's rule #1 no longer says One item per run" {
  run grep -qE '^1\. \*\*One item per run\.\*\*' "$ROADMAP"
  [ "$status" -eq 1 ]
}

@test "ROADMAP.md's rule #1 states one item per PR with the run continuing" {
  run grep -qE '^1\. \*\*One item per PR' "$ROADMAP"
  [ "$status" -eq 0 ]
}

@test "ROADMAP.md rule #6 no longer claims never self-merge" {
  run grep -q 'never push to `main`, never self-merge' "$ROADMAP"
  [ "$status" -eq 1 ]
}
