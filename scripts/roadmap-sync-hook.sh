#!/usr/bin/env bash
# PostToolUse hook: after editing ROADMAP.md, check whether an inline `**Planner
# note (DATE …)**` block crept back in (the local companion to the CI roadmap-check
# 'drift' gate). Per-run narrative belongs in docs/backlog/, one dated file per run —
# inlining it is what causes the recurring "Now / next" merge conflicts. Reads the
# Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits of ROADMAP.md itself.
case "$fp" in
  */ROADMAP.md|ROADMAP.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/roadmap-check.sh" 2>&1)"; then
  {
    echo "ROADMAP.md has an inline planner note — move the per-run narrative to docs/backlog/YYYY-MM-DD-<slug>.md and link it from the item(s) instead (binding rule: Conflict-free editing):"
    echo "$out"
    echo "(re-check: make roadmap-check)"
  } >&2
  exit 2
fi
exit 0
