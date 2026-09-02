#!/usr/bin/env bash
# Dependency exit-runbooks concentration-group sync check — closes the second
# "no mechanical drift guard yet" gap docs/dependency-exit-runbooks.md's own
# "Keeping this in sync" section names (the first, register -> concentration.md,
# is scripts/dependency-concentration-sync-check.sh): docs/dependency-concentration.md
# (Q16) names concentration groups worst-first; docs/dependency-exit-runbooks.md (Q17)
# is in turn a downstream consumer of those groups — a new group appearing in
# concentration.md (an org crossing from 1 to 2+ rows) should get a matching runbook
# section, and nothing today catches a miss.
#
# Mechanical, deterministic, network-free: every `github.com/ORG` heading in
# dependency-concentration.md (its own established "**`github.com/ORG`**" group-header
# shape) must appear as a matching "## `github.com/ORG`" section heading in
# dependency-exit-runbooks.md. Does NOT require exit-runbooks.md to cover every
# `always-on-core` single-tool row (that partial slice — 4 of 11 as of 2026-09-02 — is
# a deliberate, documented scope choice, not drift) — only that every real
# concentration GROUP (this file's own worst-first "Findings" list) has a runbook.
#
# Run by `make dependency-exit-runbooks-sync-check`, wired into `make ci`.
# Exit 0 = every concentration group has a matching runbook section; 1 = drift.
set -uo pipefail

ROOT="${DEPRUNBOOKCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONCENTRATION="$ROOT/docs/dependency-concentration.md"
RUNBOOKS="$ROOT/docs/dependency-exit-runbooks.md"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

[ -f "$CONCENTRATION" ] || { bad "docs/dependency-concentration.md not found"; exit 1; }
[ -f "$RUNBOOKS" ] || { bad "docs/dependency-exit-runbooks.md not found"; exit 1; }

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

printf '%s== dependency exit-runbooks concentration-group sync (concentration.md -> exit-runbooks.md) ==%s\n' "$B" "$Z"
drift=0
for org in "${ORGS[@]}"; do
  if grep -qF "\`github.com/$org\`" "$RUNBOOKS"; then
    ok "github.com/$org has a runbook section in dependency-exit-runbooks.md"
  else
    bad "github.com/$org is a named concentration group in dependency-concentration.md but has NO matching section in dependency-exit-runbooks.md — add one (or explain why not)"
  fi
done

echo
if [ "$drift" -eq 0 ]; then
  ok "every concentration group has a matching exit-runbook section"
fi
exit "$drift"
