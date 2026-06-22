#!/usr/bin/env bash
# PostToolUse hook: after editing a bats test, nudge if it introduces a bare `yq`
# call (the local companion to the CI yq-raw-check 'drift' gate). yq variants
# quote scalars differently ('250m' vs 250m), so a bare `$(yq …)` consumed by a
# comparison silently breaks depending on which yq is on PATH — read scalars via
# yqs() from tests/lib/yq.bash instead.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# React only to edits of bats test files.
case "$fp" in
  *.bats) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/yq-raw-check.sh" 2>&1)"; then
  {
    echo "A bats test calls a bare 'yq' — read scalars via yqs() (load lib/yq) instead. yq variants quote scalars differently ('250m' vs 250m), which silently breaks numeric/string comparisons depending on the installed yq:"
    echo "$out"
    echo "(re-check: make yq-raw-check)"
  } >&2
  exit 2
fi
exit 0
