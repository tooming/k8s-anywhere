#!/usr/bin/env bats
# Structural coverage for scripts/idle-issue-guard-hook.sh — the PostToolUse
# hook itself, not scripts/idle-issue-guard-check.sh (already covered by
# tests/drift-idle-issue-guard.bats via direct IDLEGUARD_* env-var calls). The
# hook is the thin JSON-payload adapter in front of the check script: it reads
# .tool_input.title/.tool_input.body/.tool_input.state from stdin, forwards
# them as IDLEGUARD_TITLE/IDLEGUARD_BODY/IDLEGUARD_STATE, and on a block
# appends a "close it" reminder to the check script's own output before
# exiting 2. None of that adapter logic (the jq field paths, the env-var
# wiring, the appended reminder) was exercised by any existing test — a wrong
# jq path or a dropped field would silently stop the hook from ever firing,
# with make ci never catching it (make ci only exercises idle-issue-guard-
# check.sh directly, never through this hook). New hook-script coverage goes
# in its own tests/hook-scripts-<scope>.bats file per the frozen
# tests/hook-scripts-coverage.bats convention — this is that file for this
# one hook, found via an executor-fallback coverage sweep (no scope match in
# any existing tests/hook-scripts-*.bats or tests/drift-*.bats file).
#
# Fully hermetic: no cluster, no network, no GitHub access required — the
# check script the hook delegates to is pure string matching.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_issue_payload() {
  # $1=title $2=body $3=state (optional)
  jq -n --arg t "$1" --arg b "$2" --arg s "${3:-}" \
    '{tool_input: ({title: $t, body: $b} + (if $s == "" then {} else {state: $s} end))}'
}

mk_comment_payload() {
  # add_issue_comment has no title field
  jq -n --arg b "$1" '{tool_input: {body: $b}}'
}

@test "idle-issue-guard-hook: empty payload exits 0" {
  run bash "$REPO/scripts/idle-issue-guard-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-hook: unrelated issue title/body exits 0, no output" {
  run bash "$REPO/scripts/idle-issue-guard-hook.sh" <<<"$(mk_issue_payload "fix flaky test" "unrelated body")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "idle-issue-guard-hook: an idle declaration exits 2 with the BLOCKED reminder" {
  run bash "$REPO/scripts/idle-issue-guard-hook.sh" <<<"$(mk_issue_payload "executor idle — needs work" "nothing to build this run")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"forbidden"* ]]
}

@test "idle-issue-guard-hook: appends the 'close it' follow-up instruction on block (adapter-specific, not in the check script's own output)" {
  run bash "$REPO/scripts/idle-issue-guard-hook.sh" <<<"$(mk_issue_payload "executor idle — needs work" "nothing to build this run")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"the issue/comment is already posted"* ]]
  [[ "$output" == *"mcp__github__issue_write"* ]]
}

@test "idle-issue-guard-hook: state=closed exits 0 even though title/body discuss idle (forwards .tool_input.state correctly)" {
  run bash "$REPO/scripts/idle-issue-guard-hook.sh" <<<"$(mk_issue_payload "closing idle issue" "closing this idle issue per the new policy" "closed")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "idle-issue-guard-hook: a [self-review] comment (no title field) exits 0 even though the body discusses idle cycles" {
  run bash "$REPO/scripts/idle-issue-guard-hook.sh" <<<"$(mk_comment_payload "[self-review] fixed the idle-cycle detection bug this PR was about")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
