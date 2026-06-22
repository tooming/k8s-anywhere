#!/usr/bin/env bash
# PostToolUse hook: after editing tests/networkpolicy.bats, check whether a
# per-namespace overlay test leaked into the shared baseline file (the local
# companion to the CI networkpolicy-tests-check 'drift' gate). Per-namespace
# NetworkPolicy fan-out tests belong in their own tests/networkpolicy-<scope>.bats
# file — appending them to a shared monolith is what caused the recurring "two
# parallel fan-out PRs collide at EOF" merge conflict (#247 vs #248).
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# React only to edits of the shared baseline monolith itself.
case "$fp" in
  */tests/networkpolicy.bats|tests/networkpolicy.bats) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/networkpolicy-tests-check.sh" 2>&1)"; then
  {
    echo "tests/networkpolicy.bats is baseline-only — put per-namespace NetworkPolicy tests in their own tests/networkpolicy-<scope>.bats file instead of the shared monolith (prevents the recurring parallel-PR merge conflict):"
    echo "$out"
    echo "(re-check: make networkpolicy-tests-check)"
  } >&2
  exit 2
fi
exit 0
