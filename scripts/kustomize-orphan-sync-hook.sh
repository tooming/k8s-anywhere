#!/usr/bin/env bash
# PostToolUse hook: after editing a kustomization.yaml (or a sibling *.yaml file
# in the same directory), re-run the orphan check (the local companion to the CI
# kustomize-orphan-check 'drift' gate) — catches a file dropped from resources:
# but left on disk, or a new file added and never wired in, at edit time instead
# of waiting for the next full CI run. Reads the Claude Code hook payload on
# stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0

case "$fp" in */gitops/*) ;; *) exit 0 ;; esac
case "$fp" in *.yaml|*.yml) ;; *) exit 0 ;; esac

dir="$(dirname "$fp")"
kfile="$dir/kustomization.yaml"
[ -f "$kfile" ] || kfile="$dir/kustomization.yml"
[ -f "$kfile" ] || exit 0

if ! out="$(KUSTOMIZE_ORPHAN_CHECK_FILES="$kfile" bash "$ROOT/scripts/kustomize-orphan-check.sh" 2>&1)"; then
  {
    echo "A file in this kustomization directory isn't referenced by kustomization.yaml — either it's dead weight left behind after being dropped from resources:, or a new file that still needs wiring in:"
    echo "$out"
    echo "(re-check: make kustomize-orphan-check)"
  } >&2
  exit 2
fi
exit 0
