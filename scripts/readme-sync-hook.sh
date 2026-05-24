#!/usr/bin/env bash
# PostToolUse hook: after an Edit/Write to the Makefile or a gitops/platform
# Application, check whether README.md has drifted and, if so, surface the findings
# so the README is kept in sync *in the same change*. Reads the Claude Code hook
# JSON payload on stdin; non-blocking (the tool already ran).
#   exit 0 = nothing to say   |   exit 2 = stderr is shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# Only react to edits of the README's sources of truth.
case "$fp" in
  *Makefile|*/gitops/platform/*.yaml) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/readme-check.sh" 2>&1)"; then
  {
    echo "README.md looks stale after editing ${fp##*/} — keep it in sync in this change:"
    echo "$out"
    echo "(re-check with: make readme-check)"
  } >&2
  exit 2
fi
exit 0
