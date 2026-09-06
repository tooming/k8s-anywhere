#!/usr/bin/env bash
# PostToolUse hook: after editing docs/dependency-concentration.md,
# docs/dependency-register.md, or docs/dependency-exit-runbooks.md, re-run the
# dependency-exit-runbooks-sync-check (the local companion to the CI 'drift' gate)
# so a concentration group or register row without a matching runbook mention is
# caught immediately, not on a later manual gap-analysis pass — see
# scripts/dependency-exit-runbooks-sync-check.sh's header for the "no mechanical
# drift guard yet" gap this closes (both the original concentration-group half and
# the register-single-tool-row half added 2026-09-06 after that second gap
# recurred once already). docs/dependency-register.md was added to this hook's
# watch list in that same change — the whole point of phase 2 is to catch a new
# register row landing with no runbook entry, which by definition means editing
# register.md, not exit-runbooks.md itself. Mirrors the existing
# dependency-concentration-sync-hook.sh pattern for the same class of
# self-tracking-doc drift. Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */docs/dependency-concentration.md|docs/dependency-concentration.md) ;;
  */docs/dependency-register.md|docs/dependency-register.md) ;;
  */docs/dependency-exit-runbooks.md|docs/dependency-exit-runbooks.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/dependency-exit-runbooks-sync-check.sh" 2>&1)"; then
  {
    echo "docs/dependency-exit-runbooks.md is missing a section/mention for a docs/dependency-concentration.md group or docs/dependency-register.md row — fix:"
    echo "$out"
    echo "(re-check: make dependency-exit-runbooks-sync-check)"
  } >&2
  exit 2
fi
exit 0
