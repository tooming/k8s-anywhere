#!/usr/bin/env bash
# PostToolUse hook: after editing an ArgoCD Application that sources a Helm chart,
# verify the pinned chart version still exists in its repo (the local companion to the
# CI helm-chart-pin-check gate). Catches a stale/typo'd targetRevision — e.g. velero
# 8.4.1 when only 8.4.0 exists — the moment it's saved, before repo-server chokes on it.
# Scoped to the edited file so it's fast (one repo, not the whole stack). Reads the
# Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say | exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0

# Only react to a YAML that declares a Helm-chart-sourced ArgoCD Application.
case "$fp" in *.yaml|*.yml) ;; *) exit 0 ;; esac
grep -q 'kind: Application' "$fp" 2>/dev/null || exit 0
grep -qE '^\s*chart:\s*\S' "$fp" 2>/dev/null || exit 0

if ! out="$(CHARTPINCHECK_FILES="$fp" bash "$ROOT/scripts/helm-chart-pin-check.sh" 2>&1)"; then
  {
    echo "A Helm-chart Application pins a version that doesn't exist in its repo — fix spec.source.targetRevision so ArgoCD repo-server can render it:"
    echo "$out"
    echo "(re-check: make helm-chart-pin-check)"
  } >&2
  exit 2
fi
exit 0
