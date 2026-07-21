#!/usr/bin/env bash
# PostToolUse hook: after editing an ADR under docs/decisions/ or a
# manifest under gitops/, re-run both self-tracking ADR sync checks (the
# local companions to the CI adr-chart-version-sync-check and
# adr-image-pin-sync-check 'drift' gates) so a version bump that forgets to
# update a self-tracking ADR note — or an ADR edit that drifts from the live
# pin — is caught immediately, not on a later manual gap-analysis pass (see
# scripts/adr-chart-version-sync-check.sh's header for the PR #616
# recurrence this guards against; scripts/adr-image-pin-sync-check.sh covers
# the same recurrence class for ADRs that pin a plain container image tag
# inline instead of a Helm chart targetRevision, e.g. ADR-0009/RabbitMQ).
# Reads the Claude Code hook payload on stdin; non-blocking.
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

fail=0
msg=""

if ! out="$(bash "$ROOT/scripts/adr-chart-version-sync-check.sh" 2>&1)"; then
  fail=1
  msg+="An ADR's self-tracking 'Chart + version' note no longer matches its live gitops pin — update the ADR's Chart + version note (and Re-evaluation log) to match:
$out
(re-check: make adr-chart-version-sync-check)
"
fi

if ! out="$(bash "$ROOT/scripts/adr-image-pin-sync-check.sh" 2>&1)"; then
  fail=1
  msg+="An ADR's self-tracking 'pinned official image' note no longer matches its live manifest tag — update the ADR's Decision prose (and Re-evaluation log) to match:
$out
(re-check: make adr-image-pin-sync-check)
"
fi

if [ "$fail" -eq 1 ]; then
  printf '%s' "$msg" >&2
  exit 2
fi
exit 0
