#!/usr/bin/env bash
# PostToolUse hook: after editing docs/decisions/context.md or a gitops manifest,
# re-run the context.md version-sync check (the local companion to the CI
# context-doc-version-sync-check 'drift' gate) so a chart/image bump that forgets
# to update context.md's hand-maintained prose citations (Grafana image tag,
# Pyroscope chart version, KRO chart version) is caught immediately, not on a
# later manual gap-analysis pass — see scripts/context-doc-version-sync-check.sh's
# header for the 2026-07-28 recurrence (Grafana/Pyroscope/KRO all quietly stale)
# this guards against. Mirrors the existing adr-chart-version-sync-hook.sh pattern
# for the same class of self-tracking-doc drift. Reads the Claude Code hook
# payload on stdin; non-blocking.
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

if ! out="$(bash "$ROOT/scripts/context-doc-version-sync-check.sh" 2>&1)"; then
  {
    echo "docs/decisions/context.md's prose version citation no longer matches its live gitops pin — update context.md to match:"
    echo "$out"
    echo "(re-check: make context-doc-version-sync-check)"
  } >&2
  exit 2
fi
exit 0
