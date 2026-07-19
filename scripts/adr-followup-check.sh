#!/usr/bin/env bash
# Stale-follow-up-note check: a governance doc's prose must never carry an unchecked
# "Follow-up: ..." promise — it already went stale twice undetected: ADR-0006 carried
# "Follow-up: wire both bootstraps into `make up`/DR" long after both bootstraps were
# actually wired in, and CHARTER.md carried an equivalent "A follow-up wires ..." note
# for KEDA long after that work shipped too — both only caught by a manual gap-analysis
# pass. A promise written in prose has no mechanism forcing anyone to re-check it; track
# follow-up work as a GitHub issue or a ROADMAP item instead, which does. This flags the
# literal string mechanically (case-sensitive on the capitalized "Follow-up:", which is
# the consistent style both prior instances used) so the same silent-drift class can't
# recur, across every governance doc that carries binding prose, not just ADRs.
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point ADRFOLLOWUPCHECK_ROOT at a fixture tree.
ROOT="${ADRFOLLOWUPCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

targets=()
[ -d "$ROOT/docs/decisions" ] && targets+=("$ROOT"/docs/decisions/adr-*.md)
[ -f "$ROOT/CHARTER.md" ] && targets+=("$ROOT/CHARTER.md")
[ -f "$ROOT/docs/WAYS-OF-WORKING.md" ] && targets+=("$ROOT/docs/WAYS-OF-WORKING.md")

if [ "${#targets[@]}" -eq 0 ]; then
  echo "no ADRs/CHARTER.md/WAYS-OF-WORKING.md found — nothing to check"
  exit 0
fi

hits="$(grep -ln 'Follow-up:' "${targets[@]}" 2>/dev/null || true)"
if [ -n "$hits" ]; then
  bad "Governance doc(s) contain an unchecked 'Follow-up:' promise — resolve it now (verify + remove the note) or track it as a GitHub issue/ROADMAP item instead of unchecked prose:"
  printf '%s\n' "$hits" | sed 's/^/      /'
fi

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m no ADR/CHARTER/WAYS-OF-WORKING doc carries a stale unchecked "Follow-up:" promise\n'
exit "$drift"
