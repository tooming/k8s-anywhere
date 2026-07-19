#!/usr/bin/env bash
# ADR stale-follow-up-note check: an ADR's `## Decision` prose must never carry an
# unchecked "Follow-up: ..." promise — it already went stale once undetected
# (ADR-0006 carried "Follow-up: wire both bootstraps into `make up`/DR" long after
# both bootstraps were actually wired in, only caught by a manual gap-analysis pass).
# A promise written in prose has no mechanism forcing anyone to re-check it; track
# follow-up work as a GitHub issue or a ROADMAP item instead, which does. This flags
# the literal string mechanically so the same silent-drift class can't recur.
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point ADRFOLLOWUPCHECK_ROOT at a fixture tree.
ROOT="${ADRFOLLOWUPCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DIR="$ROOT/docs/decisions"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -d "$DIR" ] || { echo "no docs/decisions/ — nothing to check"; exit 0; }

hits="$(grep -rln 'Follow-up:' "$DIR"/adr-*.md 2>/dev/null || true)"
if [ -n "$hits" ]; then
  bad "ADR(s) contain an unchecked 'Follow-up:' promise — resolve it now (verify + remove the note) or track it as a GitHub issue/ROADMAP item instead of unchecked prose:"
  printf '%s\n' "$hits" | sed 's/^/      /'
fi

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m no ADR carries a stale unchecked "Follow-up:" promise\n'
exit "$drift"
