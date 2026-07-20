#!/usr/bin/env bash
# PostToolUse hook: after editing an ADR under docs/decisions/ or an
# ArgoCD Application manifest under gitops/, re-run the ADR chart-version
# sync check (the local companion to the CI adr-chart-version-sync-check
# 'drift' gate) so a chart-version bump that forgets to update a
# self-tracking ADR note — or an ADR edit that drifts from the live pin —
# is caught immediately, not on a later manual gap-analysis pass (see
# scripts/adr-chart-version-sync-check.sh's header for the PR #616
# recurrence this guards against). Reads the Claude Code hook payload on
# stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */docs/decisions/*|docs/decisions/*) ;;
  */gitops/*|gitops/*) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/adr-chart-version-sync-check.sh" 2>&1)"; then
  {
    echo "An ADR's self-tracking 'Chart + version' note no longer matches its live gitops pin — update the ADR's Chart + version note (and Re-evaluation log) to match:"
    echo "$out"
    echo "(re-check: make adr-chart-version-sync-check)"
  } >&2
  exit 2
fi
exit 0
