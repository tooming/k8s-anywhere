#!/usr/bin/env bash
# PostToolUse hook: after editing a file under docs/done/, re-run the PR-link
# check (the local companion to the CI docs-done-pr-link-check 'drift' gate) so
# a docs/done/ entry that still carries the "(filled in after PR creation)"-style
# placeholder is flagged immediately — the nudge this hook class exists for is
# exactly the return-trip-after-PR-creation step every routine's own prompt
# currently has no mechanism to remember (see scripts/docs-done-pr-link-check.sh's
# header for the 38-file backfill this guards against recurring).
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */docs/done/*|docs/done/*) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/docs-done-pr-link-check.sh" 2>&1)"; then
  {
    echo "This docs/done/ entry still carries the unresolved '## PR' placeholder — once \`gh pr create\`/create_pull_request returns the PR number, push a follow-up commit replacing it with the real link:"
    echo "$out"
    echo "(re-check: make docs-done-pr-link-check)"
  } >&2
  exit 2
fi
exit 0
