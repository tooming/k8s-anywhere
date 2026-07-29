#!/usr/bin/env bash
# PostToolUse hook: after editing tests/securitycontext.bats, check whether a new
# @test block was appended to the frozen monolith (the local companion to the CI
# securitycontext-tests-check 'drift' gate). New per-scope PSS tests belong in their
# own tests/securitycontext-<scope>.bats file — appending to the shared monolith is
# what causes the recurring "two parallel PSS PRs collide at EOF" merge conflict.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
# Shared hook logic lives in scripts/lib/frozen-monolith-sync-hook.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/frozen-monolith-sync-hook.sh"

frozen_monolith_sync_hook \
  "tests/securitycontext.bats" \
  "scripts/securitycontext-tests-check.sh" \
  "securitycontext-tests-mark" \
  "tests/securitycontext-<scope>.bats" \
  "$ROOT"
exit "$?"
