#!/usr/bin/env bash
# PostToolUse hook: after editing tests/drift-detectors.bats, check whether a new
# @test block was appended to the frozen monolith (the local companion to the CI
# drift-detectors-tests-check 'drift' gate). New drift-check test coverage belongs
# in its own tests/drift-<scope>.bats file — appending to the shared monolith is
# what causes the recurring "unrelated PRs collide at EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
# Shared hook logic lives in scripts/lib/frozen-monolith-sync-hook.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/frozen-monolith-sync-hook.sh"

frozen_monolith_sync_hook \
  "tests/drift-detectors.bats" \
  "scripts/drift-detectors-tests-check.sh" \
  "drift-detectors-tests-mark" \
  "tests/drift-<scope>.bats" \
  "$ROOT"
exit "$?"
