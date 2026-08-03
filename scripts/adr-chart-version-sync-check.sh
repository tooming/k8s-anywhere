#!/usr/bin/env bash
# ADR chart-version sync check: some ADRs' "Chart + version" section explicitly
# marks itself as a LIVE MIRROR of the gitops pin ("pin lives in `<file>`'s
# `targetRevision`"), as opposed to the "vX.Y.x (latest stable at executor
# pickup time)" phrasing most ADRs use for a point-in-time decision record that
# never needs updating. ADR-0020 and ADR-0021 both use the self-tracking
# phrasing, and both have already gone stale once after a chart bump landed
# without the ADR prose being updated to match — caught only by a manual
# planner gap-analysis pass (PR #616 fixed ADR-0020's stale "2.41.0" note after
# PR #615 bumped the live pin to 2.41.1), not a gate. This guard makes that
# recurrence impossible: it discovers every ADR using the self-tracking
# phrasing (no hardcoded list — self-maintaining as new ADRs adopt the same
# convention) and asserts its stated chart version equals the real
# targetRevision pin.
#
# Deliberately does NOT flag ADRs using the "vX.Y.x (latest stable at executor
# pickup time)" phrasing (e.g. ADR-0019, 0022, 0023, 0028, 0029) — that's an
# intentional point-in-time record, not a live mirror, so a later patch bump
# leaving it unchanged is not drift.
#
# Run by `make adr-chart-version-sync-check`, the CI 'drift' gates, and the
# PostToolUse hook. Exit 0 = every self-tracking ADR matches its live pin;
# 1 = drift found.
set -uo pipefail
# ROOT defaults to the repo; tests point ADRCHARTVERSIONCHECK_ROOT at a fixture tree.
ROOT="${ADRCHARTVERSIONCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq.sh"
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

ADR_DIR="$ROOT/docs/decisions"
if [ ! -d "$ADR_DIR" ]; then
  echo "no docs/decisions/ — nothing to check"
  exit 0
fi

if ! command -v yq >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    echo "yq not installed (required in CI to verify ADR chart-version sync)"
    exit 1
  fi
  echo "yq not installed — skipping ADR chart-version sync check (install to check locally)"
  exit 0
fi

drift=0
found=0
printf '%s== ADR chart-version sync ==%s\n' "$B" "$Z"
for adr in "$ADR_DIR"/adr-*.md; do
  [ -f "$adr" ] || continue

  # Match the self-tracking "Chart + version" phrasing, joined across its two
  # lines: "- **Chart:** `repo/chart` `VERSION` (`appVersion: X`; pin lives in"
  # followed by "  `gitops/path.yaml`'s `targetRevision` ...".
  combined="$(awk '/\*\*Chart:\*\*.*pin lives in/ { line=$0; if ((getline nl) > 0) { print line " " nl } }' "$adr")"
  [ -n "$combined" ] || continue
  found=1

  mapfile -t tokens < <(printf '%s' "$combined" | grep -oE '`[^`]+`' | tr -d '`')
  adr_version="${tokens[1]:-}"
  gitops_file="${tokens[3]:-}"
  name="$(basename "$adr")"

  if [ -z "$adr_version" ] || [ -z "$gitops_file" ]; then
    bad "$name: 'pin lives in ... targetRevision' phrasing found but couldn't parse chart version / gitops path — check the Chart + version section's format"
    continue
  fi

  gitops_path="$ROOT/$gitops_file"
  if [ ! -f "$gitops_path" ]; then
    bad "$name: references missing gitops file $gitops_file"
    continue
  fi

  live_version="$(yqs '.spec.source.targetRevision' "$gitops_path")"
  if [ "$live_version" = "$adr_version" ]; then
    ok "$name: Chart + version ($adr_version) matches $gitops_file's targetRevision"
  else
    bad "$name: Chart + version says \"$adr_version\" but $gitops_file's targetRevision is \"$live_version\" — update the ADR's Chart + version note (and Re-evaluation log) to match the live pin"
  fi
done

if [ "$found" -eq 0 ]; then
  ok "no ADR uses the self-tracking 'pin lives in ... targetRevision' phrasing"
fi

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s every self-tracking ADR chart-version note matches its live gitops pin\n' "$G" "$Z"
exit "$drift"
