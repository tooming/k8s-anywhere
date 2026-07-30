#!/usr/bin/env bats
# Regression guard for scripts/stale-prs-check.sh (make stale-prs-check).
#
# This is the mechanical guard for a footgun that has already recurred three
# times in this repo's history (PR #449; PRs #914/#915; PR #921): a producing
# routine's PR goes CI-green with nothing left but the self-review-then-merge
# step, but the run ends before that step fires, and the PR sits stranded
# until a LATER session's STEP 1b happens to notice it. Before this script,
# STEP 1b was a hand-reconstructed `gh pr list --search` query every routine
# had to get right from memory; these tests assert the shared script exists,
# is wired into `make`, and degrades gracefully without `gh` (this repo's
# `make ci` sandbox has no `gh` CLI and no live GitHub state, so the tests
# only assert the no-gh fallback path — the gh-present path is exercised live
# by every routine's own STEP 1b in normal operation).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/stale-prs-check.sh"
}

@test "stale-prs-check.sh exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "stale-prs-check.sh documents its purpose (recurring stranded-PR footgun)" {
  run grep -q "self-review" "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "stale-prs-check.sh covers every agent branch prefix STEP 1b checks" {
  for prefix in auto plan arch upgrade sync chore; do
    run grep -q "$prefix" "$SCRIPT"
    [ "$status" -eq 0 ]
  done
}

@test "stale-prs-check.sh exits 0 cleanly when gh is unavailable" {
  # Point PATH at an empty directory so `command -v gh` reliably fails to
  # locate it, regardless of whether the host running this test (a CI runner
  # may ship gh at /usr/bin/gh) has one installed elsewhere on the real PATH.
  # The script's very first check is `command -v gh`, so nothing else on PATH
  # is needed once that fails.
  empty_path="$(mktemp -d)"
  bash_bin="$(command -v bash)"
  run env PATH="$empty_path" "$bash_bin" "$SCRIPT"
  rmdir "$empty_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh CLI not found"* ]]
}

@test "Makefile wires a stale-prs-check target that calls the script" {
  run grep -A1 '^stale-prs-check:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"scripts/stale-prs-check.sh"* ]]
}

@test "stale-prs-check target is declared .PHONY" {
  run grep -B1 '^stale-prs-check:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *".PHONY: stale-prs-check"* ]]
}
