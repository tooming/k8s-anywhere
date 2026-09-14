#!/usr/bin/env bash
# docs/decisions/context.md and docs/dependency-tree.md are hand-maintained prose
# docs that, when either tracks a component's version, needs that citation kept in
# sync by hand. Unlike the self-tracking ADR "Chart + version" pattern
# (adr-chart-version-sync-check.sh), these docs have no structured marker to parse
# — context.md went stale for real, twice: a session found "Grafana 13.0.1" and
# "Pyroscope (chart 2.0.2" and "KRO (0.4.1" all quietly out of date after later
# bumps (to 13.0.3, 2.2.0, 0.9.2 respectively) landed elsewhere without this file
# being updated (2026-07-28); a 2026-08-12 executor sweep then found the same thing
# had already happened to the ACK citation ("chart 1.8.1", two real chart bumps —
# #859, #1009 — behind the live 1.9.0 pin). A 2026-09-14 content-accuracy read
# found the identical bug class in docs/dependency-tree.md's own cert-manager
# citation ("v1.21.1", one real chart bump — 2026-09-11 — behind the live 1.21.2
# pin) — the first tracked citation in that file, extending this guard beyond
# context.md rather than inventing a second mechanism. This guard makes that
# recurrence impossible for every citation it tracks: it asserts each prose
# version citation equals the real live gitops pin. NOTE: unlike the ADR guards,
# this list is NOT self-maintaining — a new prose version citation (in either
# doc) needs its own `check_one` call added here manually.
#
# The Grafana/Pyroscope check_one calls were REMOVED 2026-09-06 (ADR-0041, both
# components dropped with no replacement); the KRO and ACK s3-controller check_one
# calls were REMOVED 2026-09-07 (ADR-0038, ACK/moto/KRO all dropped with no
# replacement). context.md currently tracks zero citations again; the
# dependency-tree.md cert-manager check_one call below is this checker's only
# live citation as of 2026-09-14.
#
# Run by `make context-doc-version-sync-check`, the CI 'drift' gate, and the
# context-doc-version-sync-hook.sh PostToolUse hook. Exit 0 = every tracked
# citation matches its live pin; 1 = drift found.
set -uo pipefail
ROOT="${CONTEXTDOCCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq.sh"

CONTEXT_MD="$ROOT/docs/decisions/context.md"
DEPENDENCY_TREE_MD="$ROOT/docs/dependency-tree.md"
if [ ! -f "$CONTEXT_MD" ] && [ ! -f "$DEPENDENCY_TREE_MD" ]; then
  echo "no docs/decisions/context.md or docs/dependency-tree.md — nothing to check"
  exit 0
fi

if ! command -v yq >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    echo "yq not installed (required in CI to verify context/dependency-tree doc version sync)"
    exit 1
  fi
  echo "yq not installed — skipping context/dependency-tree doc version sync check (install to check locally)"
  exit 0
fi

drift=0
printf '%s== context/dependency-tree doc version sync ==%s\n' "$B" "$Z"

check_one() {
  local label="$1" doc_file="$2" doc_pattern="$3" gitops_file="$4" yq_path="$5"
  local doc_version live_version gitops_path doc_name

  doc_name="${doc_file#"$ROOT"/}"
  if [ ! -f "$doc_file" ]; then
    # A doc this checker tracks simply not existing in the current ROOT is not
    # itself drift — an isolated fixture/hook invocation scoped to only one of
    # the two tracked docs (e.g. a context.md-only test fixture) legitimately
    # has no docs/dependency-tree.md at all. The top-level "neither doc
    # exists" guard above already covers the real "nothing to check" case.
    return
  fi

  doc_version="$(grep -oE "$doc_pattern" "$doc_file" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  if [ -z "$doc_version" ]; then
    bad "$label: could not find the expected version citation in $doc_name — has the phrasing changed? Update this check's pattern."
    return
  fi

  gitops_path="$ROOT/$gitops_file"
  if [ ! -f "$gitops_path" ]; then
    bad "$label: references missing gitops file $gitops_file"
    return
  fi

  live_version="$(yqs "$yq_path" "$gitops_path")"
  if [ "$live_version" = "$doc_version" ]; then
    ok "$label: $doc_name's \"$doc_version\" matches $gitops_file"
  else
    bad "$label: $doc_name says \"$doc_version\" but $gitops_file has \"$live_version\" — update $doc_name's prose to match the live pin"
  fi
}

# Grafana image tag / Pyroscope chart version checks REMOVED 2026-09-06
# (ADR-0041): both components (and their context.md citations) are gone —
# the entire observability stack was removed with no replacement.

# KRO chart version / ACK s3-controller chart version checks REMOVED 2026-09-07
# (ADR-0038): moto, ACK, and KRO were all dropped from the lab with no replacement
# (ACK/moto: maintainer decision; KRO: orphaned dependent of ACK) — their
# context.md citations are gone too.

# dependency-tree.md's cert-manager chart-version citation (added 2026-09-14,
# found stale at "v1.21.1" while the live pin had already moved to 1.21.2 via
# ADR-0028's own 2026-09-11 Re-evaluation log entry).
check_one "cert-manager (dependency-tree.md)" "$DEPENDENCY_TREE_MD" \
  'cert-manager` v[0-9]+\.[0-9]+\.[0-9]+' \
  "gitops/platform/cert-manager.yaml" '.spec.source.targetRevision'

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s every tracked context/dependency-tree doc version citation matches its live gitops pin\n' "$G" "$Z"
exit "$drift"
