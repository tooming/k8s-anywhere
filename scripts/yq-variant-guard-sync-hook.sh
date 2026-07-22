#!/usr/bin/env bash
# PostToolUse hook: after editing a scripts/*.sh file, nudge if it calls
# mikefarah-only yq syntax (eval-all/eval/ea) without guarding it via
# require_mikefarah_yq — the local companion to the CI yq-variant-guard-check
# 'drift' gate. Other yq variants on PATH (e.g. python-yq) don't recognise those
# subcommands and exit non-zero; a script consuming that via `2>/dev/null`
# silently sees zero results instead of erroring, reporting a false "nothing to
# check". require_mikefarah_yq (scripts/lib/yq-variant.sh) makes that loud
# instead: hard-fail in CI, honest skip locally.
# Reads the Claude Code hook payload on stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to edits of scripts/*.sh files.
case "$fp" in
  */scripts/*.sh|scripts/*.sh) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/yq-variant-guard-check.sh" 2>&1)"; then
  {
    echo "A scripts/*.sh file calls mikefarah-only yq syntax (eval-all/eval/ea) without guarding it — source scripts/lib/yq-variant.sh and call require_mikefarah_yq before the first such invocation. Other yq variants silently no-op on eval-all instead of erroring:"
    echo "$out"
    echo "(re-check: make yq-variant-guard-check)"
  } >&2
  exit 2
fi
exit 0
