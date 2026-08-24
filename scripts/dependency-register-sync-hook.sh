#!/usr/bin/env bash
# PostToolUse hook: after editing an ADR (docs/decisions/) or
# docs/dependency-register.md itself, re-run the dependency-register-check
# (the local companion to the CI dependency-register-check 'drift' gate) so an
# ADR's Re-evaluation log gaining a newer entry than the register's own
# "Last reviewed" cell is caught immediately, not on a later manual
# gap-analysis pass — see scripts/dependency-register-check.sh's header for
# the recurrence this guards against (three rows fixed 2026-08-12, three more
# fixed 2026-08-24 including the k3s row this guard itself was born from).
# Mirrors the existing context-doc-version-sync-hook.sh pattern for the same
# class of self-tracking-doc drift. Reads the Claude Code hook payload on
# stdin; non-blocking.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */docs/decisions/*|docs/decisions/*) ;;
  */docs/dependency-register.md|docs/dependency-register.md) ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/dependency-register-check.sh" 2>&1)"; then
  {
    echo "docs/dependency-register.md's 'Last reviewed' cell no longer matches its cited ADR's own Re-evaluation log — update the row to match:"
    echo "$out"
    echo "(re-check: make dependency-register-check)"
  } >&2
  exit 2
fi
exit 0
