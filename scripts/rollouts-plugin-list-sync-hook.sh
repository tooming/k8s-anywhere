#!/usr/bin/env bash
# PostToolUse hook: after editing an ArgoCD Application, verify any Argo Rollouts
# controller.trafficRouterPlugins / metricProviderPlugins value is still a YAML list,
# not a "|" block-scalar string (which double-encodes and crashloops the controller:
# "cannot unmarshal string into Go value of type []types.PluginItem"). Local companion
# to the `make rollouts-plugin-list-check` gate. Scoped to the edited file so it's fast.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say | exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0

# tests/fixtures/ holds deliberately-broken examples for the drift detectors — skip.
case "$fp" in */tests/fixtures/*) exit 0 ;; esac
case "$fp" in *.yaml|*.yml) ;; *) exit 0 ;; esac
grep -q 'kind: Application' "$fp" 2>/dev/null || exit 0
grep -qE 'trafficRouterPlugins|metricProviderPlugins' "$fp" 2>/dev/null || exit 0

if ! out="$(ROLLOUTS_PLUGIN_CHECK_FILES="$fp" bash "$ROOT/scripts/rollouts-plugin-list-check.sh" 2>&1)"; then
  {
    echo "An Argo Rollouts plugin value is a string, not a YAML list — the controller will crashloop unmarshaling []types.PluginItem. Make it a sequence (- name: …):"
    echo "$out"
    echo "(re-check: make rollouts-plugin-list-check)"
  } >&2
  exit 2
fi
exit 0
