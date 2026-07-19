#!/usr/bin/env bats
# Recurrence guard for the 2026-07-16 operating-model change (maintainer request:
# "make every routine's goal to work until credit runs out", then corrected same-day:
# an idle cycle must NOT be a voluntary stopping point either — the only legitimate
# way a run ends is being cut off by its own resource limits). Guards that the
# executor's operating model reflects the corrected version, not the old
# one-item-per-run model, and not the intermediate "idle ends the run" version.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  EXECUTOR="$REPO/routines/executor.prompt.md"
  ROADMAP="$REPO/ROADMAP.md"
}

@test "executor.prompt.md has the corrected STEP 8 loop contract" {
  run grep -q '^STEP 8 — Loop: keep going until the run itself ends' "$EXECUTOR"
  [ "$status" -eq 0 ]
}

@test "executor.prompt.md's opening no longer claims exactly one item per run" {
  run grep -q 'Do exactly ONE backlog item this run' "$EXECUTOR"
  [ "$status" -eq 1 ]
}

@test "executor.prompt.md's opening states resource cutoff as the only stop condition" {
  run grep -q 'that is the .only. thing that ends a run' "$EXECUTOR"
  [ "$status" -eq 0 ]
}

@test "executor.prompt.md STEP 8 states an idle cycle is not a reason to stop" {
  run grep -qF 'not a cycle whose honest outcome was an `[Action needed]` PR either' "$EXECUTOR"
  [ "$status" -eq 0 ]
}

@test "executor.prompt.md STEP 8 states exactly one legitimate way the run ends" {
  run grep -q 'exactly one legitimate way this run ends' "$EXECUTOR"
  [ "$status" -eq 0 ]
}

@test "executor.prompt.md STEP 6b does not tell the run to stop after filing the idle issue" {
  run grep -q 'this cycle is genuinely done — see STEP 8 for whether to stop or try once more' "$EXECUTOR"
  [ "$status" -eq 1 ]
}

@test "ROADMAP.md's rule #1 no longer says One item per run" {
  run grep -qE '^1\. \*\*One item per run\.\*\*' "$ROADMAP"
  [ "$status" -eq 1 ]
}

@test "ROADMAP.md's rule #1 states one item per PR with the run continuing" {
  run grep -qE '^1\. \*\*One item per PR' "$ROADMAP"
  [ "$status" -eq 0 ]
}

@test "ROADMAP.md's rule #1 states there is no voluntary stopping point" {
  run grep -q 'no voluntary stopping point short of running out' "$ROADMAP"
  [ "$status" -eq 0 ]
}

@test "ROADMAP.md rule #6 no longer claims never self-merge" {
  run grep -q 'never push to `main`, never self-merge' "$ROADMAP"
  [ "$status" -eq 1 ]
}
