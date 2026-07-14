#!/usr/bin/env bash
# PostToolUse hook: after creating/updating a GitHub issue or posting an issue
# comment, if the text claims the executor/session is idle ("no work to do"),
# verify it documents the full-fallback-chain evidence idle-issue-guard-check.sh
# requires. Reads the Claude Code hook JSON payload on stdin; non-blocking (the
# tool already ran — the issue/comment exists either way).
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
title="$(printf '%s' "$payload" | jq -r '.tool_input.title // empty' 2>/dev/null || true)"
body="$(printf '%s' "$payload" | jq -r '.tool_input.body // empty' 2>/dev/null || true)"

[ -n "$title$body" ] || exit 0

if ! out="$(IDLEGUARD_TITLE="$title" IDLEGUARD_BODY="$body" bash "$ROOT/scripts/idle-issue-guard-check.sh" 2>&1)"; then
  {
    echo "$out"
    echo "(the issue/comment is already posted — amend it: mcp__github__issue_write method=update, or add a follow-up comment, with the missing evidence)"
  } >&2
  exit 2
fi
exit 0
