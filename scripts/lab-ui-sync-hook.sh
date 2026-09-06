#!/usr/bin/env bash
# PostToolUse hook: after editing an IngressRoute manifest or README.md, check
# whether README.md's "Endpoints" table drifted from the routes and, if so,
# surface a reminder so it's fixed in the same change (the local companion to the
# CI lab-ui-check 'drift' gate). Reads the Claude Code hook payload on stdin; non-blocking.
# Used to also react to the Grafana "Lab UIs" dashboard panel — removed 2026-09-06
# (ADR-0041, observability stack removed with no replacement) along with grafana/.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to README.md or a gitops file that declares an IngressRoute.
case "$fp" in
  */README.md) ;;
  */gitops/*.yaml) grep -q 'kind: IngressRoute' "$fp" 2>/dev/null || exit 0 ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/lab-ui-check.sh" 2>&1)"; then
  {
    echo "README.md's Endpoints table looks stale after editing ${fp##*/} — host UIs use the :8000 front door:"
    echo "$out"
    echo "(re-check: make lab-ui-check; the table is README.md's ## Endpoints section)"
  } >&2
  exit 2
fi
exit 0
