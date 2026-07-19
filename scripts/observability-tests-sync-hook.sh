#!/usr/bin/env bash
# PostToolUse hook: after editing tests/observability.bats, check whether a new
# @test block was appended to the frozen monolith (the local companion to the CI
# observability-tests-check 'drift' gate). New per-component tests belong in their
# own tests/observability-<scope>.bats file — appending to the shared monolith is
# what causes the recurring "two parallel PRs collide at EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits of the frozen monolith itself.
case "$fp" in
  */tests/observability.bats|tests/observability.bats) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/observability-tests-check.sh" 2>&1)"; then
  {
    echo "tests/observability.bats is FROZEN — put new per-component/per-dashboard tests in their own tests/observability-<scope>.bats file instead of appending here (prevents the recurring parallel-PR merge conflict):"
    echo "$out"
    echo "(intentional rename/edit of an existing monolith test? run: make observability-tests-mark — re-check: make observability-tests-check)"
  } >&2
  exit 2
fi
exit 0
