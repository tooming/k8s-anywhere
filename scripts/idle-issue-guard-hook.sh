#!/usr/bin/env bash
# PostToolUse hook: after creating/updating a GitHub issue or posting an issue
# comment, if the text claims the executor/session is idle ("no work to do"),
# flag it — idle-issue-guard-check.sh now blocks this outcome unconditionally
# (ROADMAP rule #9, revised 2026-07-14: every run ships a PR, idle issues are
# forbidden). Reads the Claude Code hook JSON payload on stdin; non-blocking in
# the sense that the tool already ran — the issue/comment exists either way,
# this just tells the agent to undo it.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
title="$(printf '%s' "$payload" | jq -r '.tool_input.title // empty' 2>/dev/null || true)"
body="$(printf '%s' "$payload" | jq -r '.tool_input.body // empty' 2>/dev/null || true)"
state="$(printf '%s' "$payload" | jq -r '.tool_input.state // empty' 2>/dev/null || true)"

[ -n "$title$body" ] || exit 0

if ! out="$(IDLEGUARD_TITLE="$title" IDLEGUARD_BODY="$body" IDLEGUARD_STATE="$state" bash "$ROOT/scripts/idle-issue-guard-check.sh" 2>&1)"; then
  {
    echo "$out"
    echo "(the issue/comment is already posted — close it: mcp__github__issue_write method=update, state=closed, state_reason=not_planned, then go build one of the fallback-chain items instead)"
  } >&2
  exit 2
fi
exit 0
