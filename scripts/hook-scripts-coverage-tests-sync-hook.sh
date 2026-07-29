#!/usr/bin/env bash
# PostToolUse hook: after editing tests/hook-scripts-coverage.bats, check whether
# a new @test block was appended to the frozen monolith (the local companion to
# the CI hook-scripts-coverage-tests-check 'drift' gate). New hook-script test
# coverage belongs in its own tests/hook-scripts-<scope>.bats file — appending
# to the shared monolith is what causes the recurring "unrelated PRs collide at
# EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
# Shared hook logic lives in scripts/lib/frozen-monolith-sync-hook.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/frozen-monolith-sync-hook.sh"

frozen_monolith_sync_hook \
  "tests/hook-scripts-coverage.bats" \
  "scripts/hook-scripts-coverage-tests-check.sh" \
  "hook-scripts-coverage-tests-mark" \
  "tests/hook-scripts-<scope>.bats" \
  "$ROOT"
exit "$?"
