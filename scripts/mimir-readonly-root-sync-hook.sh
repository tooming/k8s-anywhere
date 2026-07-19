#!/usr/bin/env bash
# PostToolUse hook: after editing a mimir manifest, verify every write path in
# mimir.yaml still lands on a writable volume (Mimir runs readOnlyRootFilesystem:true,
# so a path on the read-only root crashes it on boot — e.g. the activity tracker's
# default ./metrics-activity.log did, for days). Local companion to the
# `make mimir-readonly-root-check` gate. Reads the hook payload on stdin; non-blocking.
#   exit 0 = nothing to say | exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0

# tests/fixtures/ holds deliberately-broken examples for the drift detectors — skip.
case "$fp" in */tests/fixtures/*) exit 0 ;; esac
# Only react to edits under the mimir manifest dir.
case "$fp" in */gitops/observability/mimir/*) ;; *) exit 0 ;; esac

if ! out="$(bash "$ROOT/scripts/mimir-readonly-root-check.sh" 2>&1)"; then
  {
    echo "A Mimir write path lands on the read-only root filesystem — Mimir will CrashLoopBackOff on boot. Point it at a writable mount (/data, /tmp):"
    echo "$out"
    echo "(re-check: make mimir-readonly-root-check)"
  } >&2
  exit 2
fi
exit 0
