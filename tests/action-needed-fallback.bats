#!/usr/bin/env bats
# Recurrence guard: a routine's "never end empty-handed" fallback must open/refresh
# an `[Action needed]` PR, never file a GitHub issue.
#
# scripts/idle-issue-guard-check.sh (wired as a PostToolUse hook on
# mcp__github__issue_write/mcp__github__add_issue_comment in .claude/settings.json)
# unconditionally blocks any GitHub issue/comment whose title/body carries the
# standalone word "idle" (ROADMAP rule #9: idle declarations are forbidden outright).
# Every routine's fallback issue title used that word ("executor idle — needs work",
# "planner... executor idle — needs work", etc.), which made the issue-based fallback
# dead code: executing a routine's own documented last resort immediately tripped the
# guard telling it to undo the very action it just took. See
# docs/done/2026-07-19-action-needed-pr-fallback.md for the verified finding.
#
# Scope: this guard currently covers executor.prompt.md + planner.prompt.md — the two
# roles executor.prompt.md STEP 6b's fallback chain actually reaches. The remaining
# five routine prompts (janitor, triager, doc-drift-author, upgrade-drafter,
# learning-post-writer) are a tracked ROADMAP follow-up, not yet covered here — see
# ROADMAP.md's "Now / next" list.

setup() {
  REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "executor.prompt.md never files a GitHub issue as its fallback deliverable" {
  run grep -c "issue create\|issue_write" "$REPO/routines/executor.prompt.md"
  [ "$status" -ne 0 ] || [ "$output" = "0" ]
}

@test "executor.prompt.md's fallback opens an [Action needed] PR" {
  run grep -c '\[Action needed\]' "$REPO/routines/executor.prompt.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "planner.prompt.md never files a GitHub issue as its no-op deliverable" {
  run grep -c "issue create\|issue_write" "$REPO/routines/planner.prompt.md"
  [ "$status" -ne 0 ] || [ "$output" = "0" ]
}

@test "planner.prompt.md's no-op opens an [Action needed] PR" {
  run grep -c '\[Action needed\]' "$REPO/routines/planner.prompt.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
