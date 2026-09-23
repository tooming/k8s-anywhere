#!/usr/bin/env bash
# Portable command timeout — sourced, not executed.
#
# GNU coreutils' `timeout` is not on a stock macOS (Homebrew coreutils installs it
# as `gtimeout`). A bare `timeout N cmd` there fails with "command not found" —
# which a caller that treats any non-zero exit as "the command timed out / failed"
# (scripts/dependency-maintenance-check.sh's `timeout 20 git clone`) silently turns
# into a wrong answer for every input. run_with_timeout makes that case work
# instead of merely fail loudly: `timeout`, else `gtimeout`, else a perl `alarm`
# (perl ships with macOS and with every Linux that has git).
#
# Usage: run_with_timeout SECONDS COMMAND [ARGS...]
# Returns the command's own exit status; on timeout GNU `timeout` returns 124 and
# the perl fallback is killed by SIGALRM (142). Callers should only test for
# non-zero, not for a specific timeout status. The perl fallback exec()s the
# command, so the alarm applies to the command itself, not to a wrapper.
run_with_timeout() {
  local secs="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
  else
    perl -e 'alarm shift; exec @ARGV or exit 127' "$secs" "$@"
  fi
}
