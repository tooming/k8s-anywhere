#!/usr/bin/env bash
# PostToolUse hook: after editing the Makefile or .github/workflows/ci.yml,
# check the two still run the identical set of scripts/*-check.sh gates (the
# local companion to the CI ci-parity-check 'drift' gate). Reads the Claude
# Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# React only to edits of the Makefile or the CI workflow.
case "$fp" in
  */Makefile|Makefile|*/.github/workflows/ci.yml|.github/workflows/ci.yml) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/ci-parity-check.sh" 2>&1)"; then
  {
    echo "make ci and .github/workflows/ci.yml no longer run the same set of gate scripts -- add the missing one to whichever side is short (CLAUDE.md: 'kept in parity with make ci'):"
    echo "$out"
    echo "(re-check: make ci-parity-check)"
  } >&2
  exit 2
fi
exit 0
