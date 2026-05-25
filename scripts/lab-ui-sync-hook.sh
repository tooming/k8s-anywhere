#!/usr/bin/env bash
# PostToolUse hook: after editing an HTTPRoute manifest or the stack-health
# dashboard, check whether the "Lab UIs" panel drifted from the routes and, if so,
# surface a reminder so it's fixed in the same change (the local companion to the
# CI lab-ui-check 'drift' gate). Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# React only to the dashboard itself, or a gitops file that declares an HTTPRoute.
case "$fp" in
  *stack-health.yaml) ;;
  */gitops/*.yaml) grep -q 'kind: HTTPRoute' "$fp" 2>/dev/null || exit 0 ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/lab-ui-check.sh" 2>&1)"; then
  {
    echo "Lab UIs panel looks stale after editing ${fp##*/} — update the Lab UIs table (panel 10) in stack-health.yaml; host UIs use the :8000 front door:"
    echo "$out"
    echo "(re-check: make lab-ui-check; the panel is in gitops/observability/dashboards/stack-health.yaml)"
  } >&2
  exit 2
fi
exit 0
