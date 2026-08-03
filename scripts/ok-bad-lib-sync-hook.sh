#!/usr/bin/env bash
# PostToolUse hook: after editing a scripts/*.sh file, check whether it just
# defined its own local, drift-setting `bad()` instead of sourcing the shared
# `ok()`/`bad()` pair in scripts/lib/colors.sh (the local companion to the CI
# ok-bad-lib-check 'drift' gate — see scripts/ok-bad-lib-check.sh's header for
# the duplication this guards against).
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */scripts/*.sh|scripts/*.sh) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/ok-bad-lib-check.sh" 2>&1)"; then
  printf 'A scripts/*.sh file defines its own drift-setting bad() instead of sourcing scripts/lib/colors.sh — source it instead:\n%s\n(re-check: make ok-bad-lib-check)\n' "$out" >&2
  exit 2
fi
exit 0
