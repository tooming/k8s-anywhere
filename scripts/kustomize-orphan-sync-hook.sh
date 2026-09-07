#!/usr/bin/env bash
# PostToolUse hook: after editing a kustomization.yaml (or a sibling *.yaml file
# in the same directory), re-run the orphan check (the local companion to the CI
# kustomize-orphan-check 'drift' gate) — catches a file dropped from resources:
# but left on disk, or a new file added and never wired in, at edit time instead
# of waiting for the next full CI run. If the directory has no kustomization.yaml
# at all, instead check whether the *whole directory* (pass 2 of that script) is
# still referenced from anywhere in the repo's live wiring — catches the
# gitops/argo-rollouts/ class: files left behind, unreferenced, after the last
# thing pointing at their directory was removed. Reads the Claude Code hook
# payload on stdin; non-blocking.
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

# A bogus path that can never exist — used to disable whichever pass isn't
# relevant to this invocation (kustomize-orphan-check.sh's KFILES/CHECK_DIRS
# loops both silently skip entries that don't exist on disk).
NOTHING="$ROOT/.kustomize-orphan-sync-hook-nothing-matches-this"

# KUSTOMIZE_ORPHAN_SYNC_HOOK_CHECK_ROOT lets tests point pass 2's search scope
# (KUSTOMIZE_ORPHAN_CHECK_ROOT) at an isolated fixture tree instead of this
# real repo, without changing which script file actually runs. Unset in normal
# use, so CHECK_ROOT defaults to $ROOT exactly as before this variable existed.
CHECK_ROOT="${KUSTOMIZE_ORPHAN_SYNC_HOOK_CHECK_ROOT:-$ROOT}"

if [ -f "$kfile" ]; then
  if ! out="$(KUSTOMIZE_ORPHAN_CHECK_FILES="$kfile" KUSTOMIZE_ORPHAN_CHECK_DIRS="$NOTHING" \
    bash "$ROOT/scripts/kustomize-orphan-check.sh" 2>&1)"; then
    {
      echo "A file in this kustomization directory isn't referenced by kustomization.yaml — either it's dead weight left behind after being dropped from resources:, or a new file that still needs wiring in:"
      echo "$out"
      echo "(re-check: make kustomize-orphan-check)"
    } >&2
    exit 2
  fi
  exit 0
fi

# No kustomization.yaml in this directory — scope to pass 2 only (pass 1 is
# disabled via a KUSTOMIZE_ORPHAN_CHECK_FILES value that matches nothing).
if ! out="$(KUSTOMIZE_ORPHAN_CHECK_FILES="$NOTHING" KUSTOMIZE_ORPHAN_CHECK_DIRS="$dir" \
  KUSTOMIZE_ORPHAN_CHECK_ROOT="$CHECK_ROOT" bash "$ROOT/scripts/kustomize-orphan-check.sh" 2>&1)"; then
  {
    echo "This directory has no kustomization.yaml, and nothing in the repo's live wiring (an Application/ApplicationSet path:, a sibling kustomization's relative resource path, or the Makefile) references it any more:"
    echo "$out"
    echo "(re-check: make kustomize-orphan-check)"
  } >&2
  exit 2
fi
exit 0
