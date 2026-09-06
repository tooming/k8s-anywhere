#!/usr/bin/env bash
# docs/decisions/context.md is a hand-maintained "live decisions" summary that cites
# specific component versions in prose (KRO's chart version, ACK s3-controller's chart
# version — the Grafana/Pyroscope citations this check used to also track were removed
# 2026-09-06 alongside the components themselves, ADR-0041). Unlike the
# self-tracking ADR "Chart + version" pattern (adr-chart-version-sync-check.sh),
# context.md has no structured marker to parse — it went stale for real, twice: a
# session found "Grafana 13.0.1" and "Pyroscope (chart 2.0.2" and "KRO (0.4.1" all
# quietly out of date after later bumps (to 13.0.3, 2.2.0, 0.9.2 respectively)
# landed elsewhere without this file being updated (2026-07-28); a 2026-08-12
# executor sweep then found the same thing had already happened to the ACK
# citation ("chart 1.8.1", two real chart bumps — #859, #1009 — behind the live
# 1.9.0 pin), added here as this check's fourth tracked citation. This guard makes
# that recurrence impossible for every citation it tracks: it asserts each prose
# version citation equals the real live gitops pin. NOTE: unlike the ADR guards,
# this list is NOT self-maintaining — a new context.md version citation needs its
# own `check_one` call added here manually.
#
# Run by `make context-doc-version-sync-check`, the CI 'drift' gate, and the
# context-doc-version-sync-hook.sh PostToolUse hook. Exit 0 = every tracked
# citation matches its live pin; 1 = drift found.
set -uo pipefail
ROOT="${CONTEXTDOCCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq.sh"

CONTEXT_MD="$ROOT/docs/decisions/context.md"
if [ ! -f "$CONTEXT_MD" ]; then
  echo "no docs/decisions/context.md — nothing to check"
  exit 0
fi

if ! command -v yq >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    echo "yq not installed (required in CI to verify context.md version sync)"
    exit 1
  fi
  echo "yq not installed — skipping context.md version sync check (install to check locally)"
  exit 0
fi

drift=0
printf '%s== context.md version sync ==%s\n' "$B" "$Z"

check_one() {
  local label="$1" doc_pattern="$2" gitops_file="$3" yq_path="$4"
  local doc_version live_version gitops_path

  doc_version="$(grep -oE "$doc_pattern" "$CONTEXT_MD" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  if [ -z "$doc_version" ]; then
    bad "$label: could not find the expected version citation in context.md — has the phrasing changed? Update this check's pattern."
    return
  fi

  gitops_path="$ROOT/$gitops_file"
  if [ ! -f "$gitops_path" ]; then
    bad "$label: references missing gitops file $gitops_file"
    return
  fi

  live_version="$(yqs "$yq_path" "$gitops_path")"
  if [ "$live_version" = "$doc_version" ]; then
    ok "$label: context.md's \"$doc_version\" matches $gitops_file"
  else
    bad "$label: context.md says \"$doc_version\" but $gitops_file has \"$live_version\" — update context.md's prose to match the live pin"
  fi
}

# Grafana image tag / Pyroscope chart version checks REMOVED 2026-09-06
# (ADR-0041): both components (and their context.md citations) are gone —
# the entire observability stack was removed with no replacement.

check_one "KRO chart version" 'KRO\*\* \([0-9]+\.[0-9]+\.[0-9]+' \
  "gitops/platform/kro.yaml" '.spec.source.targetRevision'

check_one "ACK s3-controller chart version" 'ACK\*\* s3-controller \(chart [0-9]+\.[0-9]+\.[0-9]+' \
  "gitops/platform/ack-s3.yaml" '.spec.source.targetRevision'

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s every tracked context.md version citation matches its live gitops pin\n' "$G" "$Z"
exit "$drift"
