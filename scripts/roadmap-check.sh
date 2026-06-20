#!/usr/bin/env bash
# ROADMAP drift check: per-run planner narrative must live in docs/backlog/ (one
# dated file per run), NEVER inline in ROADMAP.md. Two planner runs both appending
# a `**Planner note (DATE …)**` block to the same anchor in "Now / next" is what
# causes merge conflicts (it happened twice — PRs #209 and #236). This flags it
# mechanically so the rule can't be quietly re-violated by remembering to follow it.
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
#
# Matches a real dated note (`**Planner note (2026-…`) — NOT the binding rule's own
# `**Planner note (…)**` references, which use an ellipsis, not a date.
set -uo pipefail
# ROOT defaults to the repo; tests point ROADMAPCHECK_ROOT at a fixture tree.
ROOT="${ROADMAPCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FILE="$ROOT/ROADMAP.md"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -f "$FILE" ] || { echo "no ROADMAP.md — nothing to check"; exit 0; }

# A dated inline planner note: `**Planner note (` immediately followed by a year digit.
hits="$(grep -nE '\*\*Planner note \([0-9]' "$FILE" || true)"
if [ -n "$hits" ]; then
  bad "ROADMAP.md contains inline planner note(s) — move per-run narrative to docs/backlog/YYYY-MM-DD-<slug>.md (binding rule: Conflict-free editing):"
  printf '%s\n' "$hits" | sed 's/^/      /'
fi

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m ROADMAP.md has no inline planner notes (per-run narrative is in docs/backlog/)\n'
exit "$drift"
