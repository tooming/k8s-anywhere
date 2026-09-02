#!/usr/bin/env bash
# Dependency concentration-risk sync check — closes the "no mechanical drift guard
# yet" limitation docs/dependency-register.md, docs/dependency-concentration.md, and
# docs/dependency-exit-runbooks.md each honestly flag in their own "Keeping this in
# sync" sections (DORA audit readiness Q14/Q16/Q17 — see docs/dora-audit-readiness.md).
#
# Mechanical, deterministic, network-free (unlike dependency-maintenance-check.sh,
# which needs real network access and is deliberately kept out of `make ci`): counts
# how many docs/dependency-register.md rows share each github.com upstream org, and
# fails if any org backing 2+ rows (a real concentration point per
# docs/dependency-concentration.md's own "Method" section) isn't actually named there
# — catching the exact drift class those files' own "no mechanical drift guard yet"
# notes describe (a register edit that changes an org's row count without a matching
# update to the concentration rollup).
#
# Does NOT check the reverse (a concentration-file entry with no matching register
# rows) or docs/dependency-exit-runbooks.md's own downstream sync to concentration.md
# — both are real, separately-scoped gaps, same shape as this repo's other partial-
# coverage drift guards (e.g. adr-chart-version-sync-check.sh only checks ADRs that
# self-declare a chart-version note).
#
# Run by `make dependency-concentration-sync-check`, wired into `make ci`.
# Exit 0 = every concentration org (2+ rows) is named in concentration.md; 1 = drift.
set -uo pipefail

ROOT="${DEPCONCCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REGISTER="$ROOT/docs/dependency-register.md"
CONCENTRATION="$ROOT/docs/dependency-concentration.md"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dependency-register.sh"

[ -f "$REGISTER" ] || { bad "docs/dependency-register.md not found"; exit 1; }
[ -f "$CONCENTRATION" ] || { bad "docs/dependency-concentration.md not found"; exit 1; }

declare -A ORG_COUNT=()
while IFS=$'\t' read -r tool source; do
  [ -n "$tool" ] || continue
  match="$(depreg_github_match "$source")"
  [ -n "$match" ] || continue
  org="$(cut -d/ -f1 <<<"$match")"
  ORG_COUNT["$org"]=$(( ${ORG_COUNT["$org"]:-0} + 1 ))
done < <(depreg_rows "$REGISTER")

if [ "${#ORG_COUNT[@]}" -eq 0 ]; then
  bad "no github.com upstream sources parsed from docs/dependency-register.md — table format may have changed"
  exit 1
fi

printf '%s== dependency concentration-risk sync (register -> concentration.md) ==%s\n' "$B" "$Z"
drift=0
for org in "${!ORG_COUNT[@]}"; do
  count="${ORG_COUNT[$org]}"
  [ "$count" -ge 2 ] || continue
  if grep -qF "github.com/$org" "$CONCENTRATION"; then
    ok "github.com/$org ($count rows) is named in dependency-concentration.md"
  else
    bad "github.com/$org backs $count rows in dependency-register.md but is NOT named in dependency-concentration.md — add a concentration entry (or explain why not)"
  fi
done

echo
if [ "$drift" -eq 0 ]; then
  ok "every register org backing 2+ rows is named in dependency-concentration.md"
fi
exit "$drift"
