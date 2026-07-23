#!/usr/bin/env bash
# PostToolUse hook: after editing tests/drift-detectors.bats, check whether a new
# @test block was appended to the frozen monolith (the local companion to the CI
# drift-detectors-tests-check 'drift' gate). New drift-check test coverage belongs
# in its own tests/drift-<scope>.bats file — appending to the shared monolith is
# what causes the recurring "unrelated PRs collide at EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits of the frozen monolith itself.
case "$fp" in
  */tests/drift-detectors.bats|tests/drift-detectors.bats) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/drift-detectors-tests-check.sh" 2>&1)"; then
  {
    echo "tests/drift-detectors.bats is FROZEN — put new drift-check test coverage in its own tests/drift-<scope>.bats file instead of appending here (prevents the recurring unrelated-PR merge conflict):"
    echo "$out"
    echo "(intentional rename/edit of an existing monolith test? run: make drift-detectors-tests-mark — re-check: make drift-detectors-tests-check)"
  } >&2
  exit 2
fi
exit 0
