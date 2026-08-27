#!/usr/bin/env bats
# Recurrence guard: a routine's "never end empty-handed" fallback must never file a
# GitHub issue. PR-producing routines open/refresh an `[Action needed]` PR instead;
# label-only/no-PR routines (triager, learning-post-writer) accept a genuine no-op.
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
# All seven routine prompts are covered: executor, planner, janitor,
# doc-drift-author, and upgrade-drafter get the `[Action needed]` PR mechanism;
# triager and learning-post-writer (both PR-less by design) accept a no-op instead.
#
# Carve-out: a `[Manual step]` issue (label `manual-step`) is NOT a fallback
# deliverable — it is a follow-up to work that already shipped in a PR (a
# post-merge `terraform apply`, secret rotation, infra change CI can't
# exercise), cross-linked from that PR. It can never be an idle/no-work
# declaration and never substitutes for shipping, so `issue create` is allowed
# on lines that also carry the `manual-step` label.

setup() {
  REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

no_issue_create() {
  # Offending = an `issue create` / `issue_write` call that is NOT the allowed
  # `manual-step` post-merge follow-up issue.
  run bash -c "grep -E 'issue create|issue_write' '$REPO/routines/$1' | grep -v 'manual-step' || true"
  [ -z "$output" ]
}

has_action_needed() {
  run grep -c '\[Action needed\]' "$REPO/routines/$1"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "executor.prompt.md never files a GitHub issue as its fallback deliverable" {
  no_issue_create executor.prompt.md
}

@test "executor.prompt.md's fallback opens an [Action needed] PR" {
  has_action_needed executor.prompt.md
}

@test "planner.prompt.md never files a GitHub issue as its no-op deliverable" {
  no_issue_create planner.prompt.md
}

@test "planner.prompt.md's no-op opens an [Action needed] PR" {
  has_action_needed planner.prompt.md
}

@test "janitor.prompt.md never files a GitHub issue as its fallback deliverable" {
  no_issue_create janitor.prompt.md
}

@test "janitor.prompt.md's fallback opens an [Action needed] PR" {
  has_action_needed janitor.prompt.md
}

@test "doc-drift-author.prompt.md never files a GitHub issue as its fallback deliverable" {
  no_issue_create doc-drift-author.prompt.md
}

@test "doc-drift-author.prompt.md's fallback opens an [Action needed] PR" {
  has_action_needed doc-drift-author.prompt.md
}

@test "upgrade-drafter.prompt.md never files a GitHub issue as its fallback deliverable" {
  no_issue_create upgrade-drafter.prompt.md
}

@test "upgrade-drafter.prompt.md's fallback opens an [Action needed] PR" {
  has_action_needed upgrade-drafter.prompt.md
}

@test "triager.prompt.md never files a GitHub issue for its no-op case" {
  no_issue_create triager.prompt.md
}

@test "triager.prompt.md never opens a PR (labels-only by design)" {
  run grep -c "gh pr create" "$REPO/routines/triager.prompt.md"
  [ "$status" -ne 0 ] || [ "$output" = "0" ]
}

@test "learning-post-writer.prompt.md never files a GitHub issue for its no-op case" {
  no_issue_create learning-post-writer.prompt.md
}
