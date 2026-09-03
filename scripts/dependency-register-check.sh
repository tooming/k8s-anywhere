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
# Also recognizes ONE shape of ADR-0034's `**YYYY-MM-DD** — ...` bold-text
# Re-evaluation log convention: an entry naming the exact component and a real
# version-changing action, `**YYYY-MM-DD** — <Component> chart bumped ...` or
# `**YYYY-MM-DD** — <Component> image tag bumped ...` (2026-08-24 extension).
# Deliberately narrow and component-scoped, unlike the `###`-heading shape's
# per-ADR global-latest: a naive "latest bold-date entry anywhere in the ADR"
# reading would false-flag rows like Tempo's — ADR-0034 has a
# "**2026-08-18** — table-row correction (Tempo): ..." entry that mentions
# Tempo by name but is a doc-formatting fix, not a new currency check (Tempo's
# real last check is a 2026-08-13 entry in ADR-0006, which this script already
# can't see either — see the ADR-column-only note above). Requiring the exact
# "<Component> (chart|image tag) bumped" phrasing right after the date, and
# matching it against the row's own Tool-column name, avoids exactly that
# false positive (verified against a dedicated regression fixture,
# tests/fixtures/dependency-register-check/shared-adr-no-false-positive/).
# Any bold-date entry NOT matching this exact shape (a "kept, no bump" audit,
# a doc-only correction, a multi-component summary) is silently skipped, not
# silently passed — still an honest under-count, not an overclaim (ADR-0004),
# same posture as the `###`-heading shape's own documented gaps below.
#
# Only recognizes these two shapes. A component whose ADR uses neither (e.g.
# Loki/Tempo's real history lives in ADR-0006, cited only in the register's
# own prose, never in the ADR column per the note above) gets no comparison
# at all for that ADR.
#
# SECOND, independent check (2026-08-24): the Scope note's own summary arithmetic
# ("Of the NN ADRs indexed...", "...the table's NN distinct third-party-tool
# rows") is hand-maintained prose, not derived — and it drifted for real: ADR-0036
# (External Secrets Operator) was added 2026-08-19 with its own register row, but
# the Scope note's ADR-total (35) and row-total (32) were never bumped to match,
# quietly wrong for 5 days until a 2026-08-24 gap-analysis pass cross-checked the
# prose against a real `ls docs/decisions/adr-*.md | wc -l` and a real row count.
# Three other files independently repeat the same "32" figure
# (docs/dependency-concentration.md, docs/dora-audit-readiness.md ×2) — this
# check only verifies the register's own Scope note; those three are NOT
# mechanically checked here (a future extension, same honest-gap posture as the
# rest of this script).
#
# Run by `make dependency-register-check` and the CI 'drift' gate. Exit 0 = every
# register row is at least as current as its cited ADRs' own Re-evaluation logs
# AND the Scope note's ADR/row-count arithmetic matches reality; 1 = drift found.
set -uo pipefail
ROOT="${DEPENDENCYREGISTERCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dependency-register.sh"

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

# Latest bold-entry re-evaluation date for a SPECIFIC component in a given ADR
# file (the ADR-0034 shape — see header comment). Empty if no matching entry.
latest_bold_component_date() {
  local adr_path="$1" component="$2"
  grep -oE "^\*\*[0-9]{4}-[0-9]{2}-[0-9]{2}\*\* — ${component} (chart|image tag) bumped" "$adr_path" 2>/dev/null \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1
}

while IFS=$'\t' read -r tool adr_column reviewed_column; do
  [ -n "$tool" ] || continue

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
    if [ -n "$adr_date" ] && { [ -z "$newest_adr_date" ] || [[ "$adr_date" > "$newest_adr_date" ]]; }; then
      newest_adr_date="$adr_date"
      newest_adr_name="$adr_file"
    fi

    bold_date="$(latest_bold_component_date "$adr_path" "$tool")"
    if [ -n "$bold_date" ] && { [ -z "$newest_adr_date" ] || [[ "$bold_date" > "$newest_adr_date" ]]; }; then
      newest_adr_date="$bold_date"
      newest_adr_name="$adr_file"
    fi
  done

  [ -n "$newest_adr_date" ] || continue
  if [[ "$newest_adr_date" > "$row_date" ]]; then
    bad "$tool: register row's \"Last reviewed\" cell (${row_date/0000-00-00/not dated}) is older than $newest_adr_name's own Re-evaluation log entry ($newest_adr_date) — update the row's date + summary to match"
  fi
done < <(depreg_full_rows "$REGISTER")

if [ "$checked" -eq 0 ]; then
  ok "no register row cites a real adr-NNNN-*.md file — nothing to check"
fi

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s every dependency-register.md row is at least as current as its cited ADRs'"'"' own Re-evaluation logs\n' "$G" "$Z"

# --- Scope note arithmetic check (see header comment) -------------------------
printf '\n%s== dependency-register.md Scope-note arithmetic sync ==%s\n' "$B" "$Z"

if [ -d "$ADR_DIR" ]; then
  real_adr_count="$(find "$ADR_DIR" -maxdepth 1 -name 'adr-*.md' | wc -l | tr -d ' ')"
  stated_adr_count="$(grep -oE 'Of the [0-9]+ ADRs indexed' "$REGISTER" | head -1 | grep -oE '[0-9]+')"
  if [ -n "$stated_adr_count" ]; then
    if [ "$stated_adr_count" = "$real_adr_count" ]; then
      ok "Scope note's ADR total ($stated_adr_count) matches the real adr-*.md file count"
    else
      bad "Scope note says \"Of the $stated_adr_count ADRs indexed\" but docs/decisions/ actually has $real_adr_count adr-*.md files — update the Scope note's arithmetic (and its downstream row-count math)"
    fi
  fi
else
  skip "no docs/decisions/ — skipping Scope note ADR-count check"
fi

real_row_count="$(grep -cE '^\| [A-Za-z0-9]' "$REGISTER")"
real_row_count=$((real_row_count > 0 ? real_row_count - 1 : 0)) # subtract the header row
# The source prose wraps across a line break ("...table's 33 distinct\nthird-party-tool
# rows:"), so collapse newlines to spaces before matching — a single-line grep can't
# see across that wrap.
stated_row_count="$(tr '\n' ' ' < "$REGISTER" | grep -oE "table's [0-9]+ distinct third-party-tool rows" | head -1 | grep -oE '[0-9]+')"
if [ -n "$stated_row_count" ]; then
  if [ "$stated_row_count" = "$real_row_count" ]; then
    ok "Scope note's row total ($stated_row_count) matches the real table row count"
  else
    bad "Scope note says \"the table's $stated_row_count distinct third-party-tool rows\" but the table actually has $real_row_count data rows — update the Scope note's arithmetic"
  fi
fi

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s Scope note ADR/row-count arithmetic matches reality\n' "$G" "$Z"
exit "$drift"
