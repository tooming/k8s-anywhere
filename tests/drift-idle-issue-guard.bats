#!/usr/bin/env bats
# Tests for scripts/idle-issue-guard-check.sh — split out of the now-frozen
# tests/drift-detectors.bats monolith (see that file's header comment) into its
# own scope, per the drift-detectors-tests-check convention: new drift-check
# coverage goes in its own tests/drift-<scope>.bats file.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- idle-issue-guard-check ---------------------------------------------------
# ROADMAP rule #9 (revised 2026-07-14): "executor/session idle — no work" is a
# forbidden outcome, full stop — every run ships a PR instead. This guard used
# to require fallback-chain evidence before allowing an idle issue through;
# idle issues piled up anyway (#52, #56, #57, #76, #89, #121, #262, #390, #398)
# so the maintainer ended the pattern outright — the guard now blocks any idle
# declaration unconditionally, evidence or not.
@test "idle-issue-guard-check: passes on an unrelated issue title/body" {
  run env IDLEGUARD_TITLE="fix flaky test" IDLEGUARD_BODY="unrelated body" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-check: FAILS on an idle claim with no fallback-chain evidence" {
  run env IDLEGUARD_TITLE="executor idle — needs work" IDLEGUARD_BODY="nothing to build this run" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden"* ]]
}

@test "idle-issue-guard-check: FAILS even when make ci + CHARTER evidence is present (idle is blocked unconditionally now)" {
  run env IDLEGUARD_TITLE="executor idle — needs work" \
      IDLEGUARD_BODY="ran make ci locally, all green. Cross-checked CHARTER.md Objectives against ROADMAP.md's checked items, no ungroomed gap found." \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden"* ]]
}

@test "idle-issue-guard-check: passes when closing an idle issue, even though the closing body discusses 'idle'" {
  # Regression: closing issue #398 with a body explaining the new no-idle-issues
  # policy ("idle issues ... are now forbidden ...") re-tripped the same guard
  # it was satisfying, since "idle" appears as a standalone word outside any
  # hyphenated compound. Closing is the resolution, not the violation.
  run env IDLEGUARD_TITLE="executor idle — needs work" \
      IDLEGUARD_BODY="closing this per your feedback: idle issues are now a forbidden outcome, not a gated-but-acceptable one." \
      IDLEGUARD_STATE="closed" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-check: does not self-trigger on a comment merely discussing the guard" {
  # Regression: a [self-review] comment on the PR introducing this guard tripped
  # the check just for naming its own script (idle-issue-guard-check.sh contains
  # "idle") and for saying "idle-titled". Discussing the feature must not read
  # as an idle/no-work claim. (add_issue_comment has no title field.)
  run env IDLEGUARD_TITLE="" \
      IDLEGUARD_BODY="Added scripts/idle-issue-guard-check.sh and scripts/idle-issue-guard-hook.sh, wired as a PostToolUse hook that nudges when an idle-titled issue/comment is missing evidence." \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

# The `[self-review]`-prefix bypass that used to live here (2026-07-16 —
# 2026-09-23) was removed once WAYS-OF-WORKING.md §4 dropped the
# `[self-review]` PR-comment-and-label step entirely (issue #1632): no comment
# carries that marker anymore, so the exemption became unreachable, and the
# false-positive shape it guarded against ("idle cycle" / "idle issue" as
# standalone prose in a self-review comment) can't recur since self-review is
# no longer written up as a PR comment at all. See
# scripts/idle-issue-guard-check.sh's own history comment for the reasoning.

@test "idle-issue-guard-check: still FAILS an idle declaration in plain prose" {
  run env IDLEGUARD_TITLE="executor idle — needs work" \
      IDLEGUARD_BODY="no actionable work found this run" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden"* ]]
}
