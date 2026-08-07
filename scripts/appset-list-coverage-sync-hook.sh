#!/usr/bin/env bash
# PostToolUse hook: after editing networkpolicy-appset.yaml, governance-appset.yaml,
# a standalone gitops/platform/*-networkpolicy.yaml Application, or adding/removing a
# gitops/**/networkpolicy/ or gitops/governance/<ns>/ leaf dir, check whether the
# appset list-generators drifted out of sync and, if so, surface a reminder so it's
# fixed in the same change (the local companion to the CI appset-list-coverage-check
# 'drift' gate). Reads the Claude Code hook payload on stdin; non-blocking. Mirrors
# envoy-egress-allowlist-sync-hook.sh's shape exactly.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */networkpolicy-appset.yaml|*/governance-appset.yaml) ;;
  */gitops/platform/*-networkpolicy.yaml) ;;
  */gitops/*/networkpolicy/*.yaml) ;;
  */gitops/governance/*/*.yaml) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/appset-list-coverage-check.sh" 2>&1)"; then
  {
    echo "ApplicationSet list-generator coverage looks stale after editing ${fp##*/} — add the missing gitPath entry to networkpolicy-appset.yaml or governance-appset.yaml (gitops/platform/), or its manifests will never be deployed:"
    echo "$out"
    echo "(re-check: make appset-list-coverage-check)"
  } >&2
  exit 2
fi
exit 0
