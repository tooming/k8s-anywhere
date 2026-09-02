#!/usr/bin/env bash
# PostToolUse hook: after editing docs/dependency-concentration.md or
# docs/dependency-exit-runbooks.md, re-run the dependency-exit-runbooks-sync-check
# (the local companion to the CI 'drift' gate) so a concentration group without a
# matching runbook section is caught immediately, not on a later manual
# gap-analysis pass — see scripts/dependency-exit-runbooks-sync-check.sh's header
# for the "no mechanical drift guard yet" gap this closes. Mirrors the existing
# dependency-concentration-sync-hook.sh pattern for the same class of
# self-tracking-doc drift. Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */docs/dependency-concentration.md|docs/dependency-concentration.md) ;;
  */docs/dependency-exit-runbooks.md|docs/dependency-exit-runbooks.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/dependency-exit-runbooks-sync-check.sh" 2>&1)"; then
  {
    echo "docs/dependency-exit-runbooks.md is missing a section for a docs/dependency-concentration.md group — fix:"
    echo "$out"
    echo "(re-check: make dependency-exit-runbooks-sync-check)"
  } >&2
  exit 2
fi
exit 0
