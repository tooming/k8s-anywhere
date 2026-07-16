#!/usr/bin/env bash
# PostToolUse hook: after editing any *.md file, check that internal markdown
# links still resolve (the local companion to the CI markdown-links-check
# 'drift' gate). Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# React only to edits of *.md files.
case "$fp" in
  *.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/markdown-links-check.sh" 2>&1)"; then
  {
    echo "A markdown edit left a broken internal link — fix the path or remove the link:"
    echo "$out"
    echo "(re-check: make markdown-links-check)"
  } >&2
  exit 2
fi
exit 0
