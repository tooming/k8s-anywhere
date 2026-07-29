#!/usr/bin/env bash
# PostToolUse hook: after editing tests/hook-scripts-coverage.bats, check whether
# a new @test block was appended to the frozen monolith (the local companion to
# the CI hook-scripts-coverage-tests-check 'drift' gate). New hook-script test
# coverage belongs in its own tests/hook-scripts-<scope>.bats file — appending
# to the shared monolith is what causes the recurring "unrelated PRs collide at
# EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits of the frozen monolith itself.
case "$fp" in
  */tests/hook-scripts-coverage.bats|tests/hook-scripts-coverage.bats) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/hook-scripts-coverage-tests-check.sh" 2>&1)"; then
  {
    echo "tests/hook-scripts-coverage.bats is FROZEN — put new hook-script test coverage in its own tests/hook-scripts-<scope>.bats file instead of appending here (prevents the recurring unrelated-PR merge conflict):"
    echo "$out"
    echo "(intentional rename/edit of an existing monolith test? run: make hook-scripts-coverage-tests-mark — re-check: make hook-scripts-coverage-tests-check)"
  } >&2
  exit 2
fi
exit 0
