#!/usr/bin/env bash
# PostToolUse hook: after editing an ADR, CHARTER.md, or docs/WAYS-OF-WORKING.md,
# check whether an unchecked "Follow-up: ..." promise crept back into its prose (the
# local companion to the CI adr-followup-check 'drift' gate). A promise written in
# prose has no mechanism forcing anyone to re-check it — track follow-up work as a
# GitHub issue or a ROADMAP item instead. Reads the Claude Code hook payload on
# stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits under docs/decisions/, or to CHARTER.md / docs/WAYS-OF-WORKING.md.
case "$fp" in
  */docs/decisions/*|docs/decisions/*) ;;
  */CHARTER.md|CHARTER.md) ;;
  */docs/WAYS-OF-WORKING.md|docs/WAYS-OF-WORKING.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/adr-followup-check.sh" 2>&1)"; then
  {
    echo "This governance doc carries an unchecked 'Follow-up: ...' promise — resolve it now (verify + remove the note) or track it as a GitHub issue/ROADMAP item instead of unchecked prose:"
    echo "$out"
    echo "(re-check: make adr-followup-check)"
  } >&2
  exit 2
fi
exit 0
