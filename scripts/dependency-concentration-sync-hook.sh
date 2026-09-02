#!/usr/bin/env bash
# PostToolUse hook: after editing docs/dependency-register.md or
# docs/dependency-concentration.md, re-run the dependency-concentration-sync-check
# (the local companion to the CI 'drift' gate) so an org crossing from one row to
# two-or-more (or vice versa) is caught immediately, not on a later manual
# gap-analysis pass — see scripts/dependency-concentration-sync-check.sh's header
# for the "no mechanical drift guard yet" gap this closes. Mirrors the existing
# dependency-register-sync-hook.sh pattern for the same class of self-tracking-doc
# drift. Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */docs/dependency-register.md|docs/dependency-register.md) ;;
  */docs/dependency-concentration.md|docs/dependency-concentration.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/dependency-concentration-sync-check.sh" 2>&1)"; then
  {
    echo "docs/dependency-concentration.md is no longer in sync with docs/dependency-register.md's org row-counts — fix:"
    echo "$out"
    echo "(re-check: make dependency-concentration-sync-check)"
  } >&2
  exit 2
fi
exit 0
