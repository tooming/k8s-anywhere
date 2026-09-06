#!/usr/bin/env bash
# Dependency exit-runbooks sync check — closes BOTH "no mechanical drift guard
# yet" gaps docs/dependency-exit-runbooks.md's own "Keeping this in sync" section
# named (the register -> concentration.md half is a separate script,
# scripts/dependency-concentration-sync-check.sh):
#
# Phase 1 (concentration-group half, guarded since 2026-09-02/03): a new group
# appearing in docs/dependency-concentration.md (Q16, an org crossing from 1 to
# 2+ rows) should get a matching "## `github.com/ORG`" runbook section here.
#
# Phase 2 (register single-tool-row half, added 2026-09-06 after this exact gap
# recurred: a 2026-09-03 "coverage is complete" claim covering 11 single-tool
# rows went stale within three days as 13 more register rows landed with no
# matching runbook entry, undetected until a manual re-sweep): every Tool-column
# name in docs/dependency-register.md's table must appear somewhere in
# dependency-exit-runbooks.md — either as its own "**Name**" single-tool heading
# or listed by name in a concentration-group section header (e.g. "6 tools
# (Grafana, Mimir, ...)"). A plain substring match, not a heading-shape parse:
# simpler than mirroring exactly how a tool is covered (group vs. individual),
# and correct either way, since every real coverage shape mentions the tool's
# own name in this file somewhere.
#
# Both phases are mechanical, deterministic, network-free.
#
# Run by `make dependency-exit-runbooks-sync-check`, wired into `make ci`.
# Exit 0 = both phases clean; 1 = drift in either.
set -uo pipefail

ROOT="${DEPRUNBOOKCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONCENTRATION="$ROOT/docs/dependency-concentration.md"
REGISTER="$ROOT/docs/dependency-register.md"
RUNBOOKS="$ROOT/docs/dependency-exit-runbooks.md"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

[ -f "$CONCENTRATION" ] || { bad "docs/dependency-concentration.md not found"; exit 1; }
[ -f "$REGISTER" ] || { bad "docs/dependency-register.md not found"; exit 1; }
[ -f "$RUNBOOKS" ] || { bad "docs/dependency-exit-runbooks.md not found"; exit 1; }

drift=0

# --- Phase 1: every concentration-group org has a matching runbook section ---

# Extract every "**`github.com/ORG`" group-header org from concentration.md's own
# established shape (see docs/dependency-concentration.md's "Findings, worst-first"
# section — each real concentration group starts a line this way).
declare -a ORGS=()
while IFS= read -r org; do
  [ -n "$org" ] || continue
  ORGS+=("$org")
done < <(grep -oE '\*\*`github\.com/[A-Za-z0-9_.-]+`' "$CONCENTRATION" | sed -E 's/^\*\*`github\.com\///; s/`$//')

if [ "${#ORGS[@]}" -eq 0 ]; then
  bad "no '**\`github.com/ORG\`' concentration-group headers parsed from docs/dependency-concentration.md — heading format may have changed"
  exit 1
fi

printf '%s== phase 1: concentration-group sync (concentration.md -> exit-runbooks.md) ==%s\n' "$B" "$Z"
for org in "${ORGS[@]}"; do
  if grep -qF "\`github.com/$org\`" "$RUNBOOKS"; then
    ok "github.com/$org has a runbook section in dependency-exit-runbooks.md"
  else
    bad "github.com/$org is a named concentration group in dependency-concentration.md but has NO matching section in dependency-exit-runbooks.md — add one (or explain why not)"
  fi
done

# --- Phase 2: every register single-tool row has a matching runbook mention ---

# Extract the "Tool" column from register.md's own table (the row block starting
# right after the "| Tool | Criticality | ... |" header and its "|---|" separator).
# Each cell may carry a parenthetical annotation (e.g. a "(supersedes X, ADR-NNNN)"
# note) — strip everything from the first "(" onward to get the bare tool name a
# runbook section would actually be named after.
declare -a TOOLS=()
while IFS= read -r tool; do
  [ -n "$tool" ] || continue
  TOOLS+=("$tool")
done < <(awk '
    /^\| *Tool *\|/ { intable=1; next }
    intable && /^\|---/ { next }
    intable && /^\|/ { print; next }
    intable { intable=0 }
  ' "$REGISTER" | sed -E 's/^\| *//; s/ *\|.*$//; s/[[:space:]]*\(.*//; s/[[:space:]]+$//')

if [ "${#TOOLS[@]}" -eq 0 ]; then
  bad "no rows parsed from docs/dependency-register.md's Tool column — table format may have changed"
  exit 1
fi

echo
printf '%s== phase 2: register single-tool-row sync (register.md -> exit-runbooks.md) ==%s\n' "$B" "$Z"
for tool in "${TOOLS[@]}"; do
  if grep -qF -- "$tool" "$RUNBOOKS"; then
    ok "$tool is mentioned in dependency-exit-runbooks.md"
  else
    bad "$tool is a row in dependency-register.md's table but is NOT mentioned anywhere in dependency-exit-runbooks.md — add a runbook entry for it (or explain why not)"
  fi
done

echo
if [ "$drift" -eq 0 ]; then
  ok "every concentration group and every register row has a matching exit-runbook mention"
fi
exit "$drift"
