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
# SECOND, independent check (2026-09-03, JANITOR-fallback): the reverse direction
# — a concentration.md group whose own stated "N tools" count no longer matches
# the register's real row count for that org (register rows removed/re-orged since
# the concentration entry was written), or whose org has dropped below the 2-row
# concentration threshold entirely (a stale entry naming a group that no longer
# exists). This was named as an open gap in this script's very first version
# (#1379) — "Does NOT check the reverse" — and left that way until this sweep
# closed it. Parses concentration.md's own established heading shape
# (`` **`github.com/ORG` — N tools** ``, see its "Findings, worst-first" section)
# and compares N against the same $ORG_COUNT map the forward check already builds.
#
# docs/dependency-exit-runbooks.md's own downstream sync to concentration.md was
# also named here as an open gap when this script first landed (#1379) — that one
# was actually closed the same day by a sibling script,
# scripts/dependency-exit-runbooks-sync-check.sh (#1380), but this comment went
# un-updated until this same 2026-09-03 sweep caught the drift (a stale comment
# claiming an already-closed gap is its own small instance of the exact "nothing
# catches it" failure mode this script exists to close for the register itself).
#
# Run by `make dependency-concentration-sync-check`, wired into `make ci`.
# Exit 0 = every concentration org (2+ rows) is named in concentration.md AND every
# named group's stated tool count matches the register; 1 = drift.
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

echo
printf '%s== dependency concentration-risk sync (concentration.md -> register, reverse) ==%s\n' "$B" "$Z"

# Every "**`github.com/ORG` — N tools" group header in concentration.md's own
# established shape. Captures the org and its stated count as tab-separated pairs.
mapfile -t GROUP_LINES < <(grep -oE '\*\*`github\.com/[A-Za-z0-9_.-]+`[^0-9]*[0-9]+ tools?' "$CONCENTRATION" \
  | sed -E 's/^\*\*`github\.com\/([A-Za-z0-9_.-]+)`[^0-9]*([0-9]+) tools?.*/\1\t\2/')

if [ "${#GROUP_LINES[@]}" -eq 0 ]; then
  bad "no '**\`github.com/ORG\` — N tools' concentration-group headers parsed from docs/dependency-concentration.md — heading format may have changed"
  exit 1
fi

for line in "${GROUP_LINES[@]}"; do
  org="${line%%$'\t'*}"
  stated="${line##*$'\t'}"
  actual="${ORG_COUNT[$org]:-0}"
  if [ "$actual" -lt 2 ]; then
    bad "github.com/$org is named as a concentration group in dependency-concentration.md but backs only $actual row(s) in dependency-register.md now (below the 2-row threshold) — remove the stale entry or explain why it's kept"
  elif [ "$actual" -ne "$stated" ]; then
    bad "github.com/$org's stated count in dependency-concentration.md ($stated tools) no longer matches dependency-register.md's real row count ($actual) — update the entry"
  else
    ok "github.com/$org's stated count ($stated tools) matches dependency-register.md's real row count"
  fi
done

echo
if [ "$drift" -eq 0 ]; then
  ok "every concentration.md group's stated count matches the register, and no group is stale"
fi
exit "$drift"
