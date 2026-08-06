#!/usr/bin/env bash
# PostToolUse hook: after editing a Rollout or AnalysisTemplate manifest, verify no
# step-gating AnalysisTemplate metric sets `interval` without `count` (Argo Rollouts
# rejects that combo as "runs indefinitely" and the controller crashloops reconciling
# it — see scripts/analysistemplate-step-count-check.sh for the full story). Local
# companion to `make analysistemplate-step-count-check`. Runs a full repo scan (not
# file-scoped like the plugin-list hook) because the bug is cross-file: editing either
# the Rollout's steps or the AnalysisTemplate's metrics alone can introduce it.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say | exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0

# tests/fixtures/ holds deliberately-broken examples for the drift detectors — skip.
case "$fp" in */tests/fixtures/*) exit 0 ;; esac
case "$fp" in *.yaml|*.yml) ;; *) exit 0 ;; esac
grep -qE 'kind: Rollout|kind: AnalysisTemplate' "$fp" 2>/dev/null || exit 0

if ! out="$(bash "$ROOT/scripts/analysistemplate-step-count-check.sh" 2>&1)"; then
  {
    echo "A step-gating AnalysisTemplate has a metric with 'interval' but no 'count' — Argo Rollouts rejects this as \"runs indefinitely\" on every reconcile and the controller crashloops. Add a count (how many measurements before the step completes), or move the metric to a background analysis instead:"
    echo "$out"
    echo "(re-check: make analysistemplate-step-count-check)"
  } >&2
  exit 2
fi
exit 0
