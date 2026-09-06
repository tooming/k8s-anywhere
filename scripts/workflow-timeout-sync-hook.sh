#!/usr/bin/env bash
# PostToolUse hook: after editing a .github/workflows/*.yml or .forgejo/workflows/*.yml
# file, check whether every job still sets an explicit timeout-minutes and, if not,
# surface a reminder so it's fixed in the same change (the local companion to the CI
# workflow-timeout-check 'drift' gate). Reads the Claude Code hook payload on
# stdin; non-blocking. Mirrors readme-sync-hook.sh's shape.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */.github/workflows/*.yml|*/.github/workflows/*.yaml) ;;
  */.forgejo/workflows/*.yml|*/.forgejo/workflows/*.yaml) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/workflow-timeout-check.sh" 2>&1)"; then
  {
    echo "A job in ${fp##*/} is missing timeout-minutes — without one, GitHub Actions' 360-minute default applies on a hang (see ci.yml's own header comment, PR #648):"
    echo "$out"
    echo "(re-check: make workflow-timeout-check)"
  } >&2
  exit 2
fi
exit 0
