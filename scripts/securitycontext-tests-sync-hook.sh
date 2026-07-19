#!/usr/bin/env bash
# PostToolUse hook: after editing tests/securitycontext.bats, check whether a new
# @test block was appended to the frozen monolith (the local companion to the CI
# securitycontext-tests-check 'drift' gate). New per-scope PSS tests belong in their
# own tests/securitycontext-<scope>.bats file — appending to the shared monolith is
# what causes the recurring "two parallel PSS PRs collide at EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits of the frozen monolith itself.
case "$fp" in
  */tests/securitycontext.bats|tests/securitycontext.bats) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/securitycontext-tests-check.sh" 2>&1)"; then
  {
    echo "tests/securitycontext.bats is FROZEN — put new per-namespace/per-scope PSS tests in their own tests/securitycontext-<scope>.bats file instead of appending here (prevents the recurring parallel-PR merge conflict):"
    echo "$out"
    echo "(intentional rename/edit of an existing monolith test? run: make securitycontext-tests-mark — re-check: make securitycontext-tests-check)"
  } >&2
  exit 2
fi
exit 0
