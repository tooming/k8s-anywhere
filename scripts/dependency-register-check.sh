#!/usr/bin/env bash
# docs/dependency-register.md's own "Keeping this in sync" section names the exact
# failure mode this guard closes: "this file's 'Last reviewed' column should be
# updated in the same PR when it touches a row here, but nothing currently fails
# `make ci` if it drifts." That gap was real, not hypothetical — a 2026-08-12
# executor sweep found three rows (Inkless, TiDB Operator, cert-manager) whose
# "Last reviewed" cell predated their own ADR's latest Re-evaluation log entry
# (docs/done/2026-08-12-dependency-register-log-drift-fix.md), and a 2026-08-24
# gap-analysis pass found a fourth: the k3s row cited only ADR-0027's decision
# date ("not dated in ADR") while ADR-0030 — the ADR that actually governs k3s's
# version currency — already had a newer, real Re-evaluation log entry. Both were
# only caught by a human/agent happening to cross-reference by hand. This script
# makes that recurrence impossible: for every register row, it discovers every
# `adr-NNNN-*.md` file cited in the row's ADR column (no hardcoded list — a new
# citation just needs the exact `adr-NNNN-<slug>.md` filename to appear somewhere
# in the row, same "cite the real path" convention every register row already
# follows) and asserts the row's stated "Last reviewed" date is not older than
# that ADR's own latest `### YYYY-MM-DD` Re-evaluation log heading.
#
# Deliberately does NOT flag a row whose cited ADR has no `## Re-evaluation log`
# section at all (e.g. ADR-0001, ADR-0027 alone) — nothing to compare against,
# and a one-time decision-date citation is not drift by itself. Only scans the
# ADR COLUMN (not the whole row) for `adr-NNNN-*.md` citations — the "Last
# reviewed" cell's own prose sometimes cross-references a different, SHARED
# ADR purely for narrative context (e.g. the Loki/Tempo rows cite ADR-0034 in
# their ADR column but say "see ADR-0006's own Re-evaluation log" in prose,
# since ADR-0006 predates the LGTMP consolidation and still carries their real
# per-component bump history) — scanning the whole row for that would compare
# against ADR-0006's newest entry for ANY of its several components (most
# recently Grafana), not specifically Loki's or Tempo's, and false-flag a row
# that is actually current. Restricting to the ADR column avoids that.
#
# Also only recognizes the `### YYYY-MM-DD — ...` dated-heading Re-evaluation
# log convention (ADR-0006, ADR-0008, ADR-0019, ADR-0030, and most others use
# it) — ADR-0034's log instead uses `**YYYY-MM-DD** — ...` bold-text entries,
# which this check does not parse, so Mimir/Loki/Tempo/Pyroscope/Alloy/KSM/
# node-exporter rows citing ADR-0034 alone get no comparison at all (silently
# skipped, not silently passed) until a future pass teaches this script that
# second convention too — noted here rather than overclaimed (ADR-0004).
#
# Run by `make dependency-register-check` and the CI 'drift' gate. Exit 0 = every
# register row is at least as current as its cited ADRs' own Re-evaluation logs;
# 1 = drift found.
set -uo pipefail
ROOT="${DEPENDENCYREGISTERCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

REGISTER="$ROOT/docs/dependency-register.md"
ADR_DIR="$ROOT/docs/decisions"

if [ ! -f "$REGISTER" ]; then
  echo "no docs/dependency-register.md — nothing to check"
  exit 0
fi

drift=0
checked=0

printf '%s== dependency-register.md Last-reviewed sync ==%s\n' "$B" "$Z"

# Latest Re-evaluation log date for a given ADR file, empty if it has no such
# section. `### YYYY-MM-DD ...` headings appear only under `## Re-evaluation log`
# in this repo's ADR convention, so a plain grep across the whole file (not just
# text after the section header) is safe and avoids an awk range-match subtlety.
latest_reeval_date() {
  grep -oE '^### [0-9]{4}-[0-9]{2}-[0-9]{2}' "$1" 2>/dev/null \
    | awk '{print $2}' | sort | tail -1
}

while IFS= read -r row; do
  [ -n "$row" ] || continue
  tool="$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')"
  adr_column="$(printf '%s' "$row" | awk -F'|' '{print $5}')"
  reviewed_column="$(printf '%s' "$row" | awk -F'|' '{print $6}')"

  # Every real ADR file basename cited in the ADR column specifically (not the
  # whole row — see header comment on why). De-duplicated, order preserved.
  mapfile -t adr_files < <(printf '%s' "$adr_column" | grep -oE 'adr-[0-9]{4}-[a-z0-9-]+\.md' | sort -u)
  [ "${#adr_files[@]}" -gt 0 ] || continue

  # The row's own stated "Last reviewed" date: the first YYYY-MM-DD in that
  # column. Absent (e.g. "not dated in ADR") sorts before any real date
  # lexically once defaulted to the epoch, so it's always flagged if any
  # cited ADR has a real log entry — exactly the k3s bug this closes.
  row_date="$(printf '%s' "$reviewed_column" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
  row_date="${row_date:-0000-00-00}"

  checked=1
  newest_adr_date=""
  newest_adr_name=""
  for adr_file in "${adr_files[@]}"; do
    adr_path="$ADR_DIR/$adr_file"
    [ -f "$adr_path" ] || continue
    adr_date="$(latest_reeval_date "$adr_path")"
    [ -n "$adr_date" ] || continue
    if [ -z "$newest_adr_date" ] || [[ "$adr_date" > "$newest_adr_date" ]]; then
      newest_adr_date="$adr_date"
      newest_adr_name="$adr_file"
    fi
  done

  [ -n "$newest_adr_date" ] || continue
  if [[ "$newest_adr_date" > "$row_date" ]]; then
    bad "$tool: register row's \"Last reviewed\" cell (${row_date/0000-00-00/not dated}) is older than $newest_adr_name's own Re-evaluation log entry ($newest_adr_date) — update the row's date + summary to match"
  fi
done < <(grep -E '^\| [A-Za-z0-9]' "$REGISTER")

if [ "$checked" -eq 0 ]; then
  ok "no register row cites a real adr-NNNN-*.md file — nothing to check"
fi

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s every dependency-register.md row is at least as current as its cited ADRs'"'"' own Re-evaluation logs\n' "$G" "$Z"
exit "$drift"
