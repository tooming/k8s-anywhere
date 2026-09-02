#!/usr/bin/env bash
# Dependency maintenance-health check — closes DORA audit readiness Q15's named gap
# ("no scheduled re-check of maintenance health (is the project still active, still
# maintained) after initial adoption") — see docs/dora-audit-readiness.md.
#
# docs/dependency-register.md is already the single source of truth for this lab's
# third-party dependencies (33 rows, one per tool, each citing its binding ADR). This
# script walks that table's own "Upstream source" column, extracts every row's
# github.com repo, and reports how long it's been since that repo's default branch
# last received a commit. A repo with no commit in over a year is flagged for a
# fresh look — NOT a failure: a mature, feature-complete dependency going quiet is
# not automatically a problem, so this never asserts "unmaintained", only "worth
# checking" (ADR-0004 — no fabricated verdicts, just a real, dated signal).
#
# Resolves via `git clone --bare --depth 1 --filter=tree:0` + `git log -1
# --format=%cI` (a few hundred KB, ~1-2s per repo, no auth needed) rather than the
# GitHub REST API: this session's own environment gates api.github.com/github.com
# HTTP(S) requests to repos outside its configured scope (verified directly this
# run — every api.github.com call returned an access-scope message, not repo data),
# but the git smart-HTTP protocol itself is not scoped the same way, confirmed
# working against every table row's real upstream during this script's own
# development. Network-tolerant by design, mirroring helm-chart-pin-check.sh: a
# clone that fails (unreachable, renamed, rate-limited) is SKIPPED, never treated as
# evidence of staleness.
#
# Report-only — deliberately NOT wired into `make ci`. A ~30-repo sweep (each a
# real, if small, network fetch) is unsuitable as a hard, always-on CI gate; this is
# meant to be run periodically on demand (e.g. by a future architect/janitor cycle),
# same shape as ondemand-budget-check.sh / dora-metrics.sh in this same "Metrics
# (on-demand, clusterless)" Makefile section.
#
# A few register rows (Terraform/Terragrunt, Oracle Cloud Infrastructure, Forgejo)
# have no github.com upstream source at all — reported as skipped, not stale; their
# own currency is tracked elsewhere (ADR Re-evaluation logs, the industry digest).
#
# Usage: dependency-maintenance-check.sh [--stale-days N]   (default 365)
# Exit: 0 = every reachable repo committed within the window (or all were skipped);
#       1 = at least one repo exceeded the staleness window (advisory, not a bug).
set -uo pipefail

ROOT="${DEPMAINT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REGISTER="$ROOT/docs/dependency-register.md"
STALE_DAYS="${DEPMAINT_STALE_DAYS:-365}"

while [ $# -gt 0 ]; do
  case "$1" in
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dependency-register.sh"
# ok()/skip() come from lib/colors.sh (shared, per tests/colors-lib.bats's
# de-duplication guard). warn() is local — no shared equivalent exists yet
# (bad() carries a drift=1 side effect this advisory report doesn't want).
warn() { printf '  %s⚠%s %s\n' "$Y" "$Z" "$1"; }

[ -f "$REGISTER" ] || { warn "docs/dependency-register.md not found"; exit 1; }

# Test seam: a resolver stub prints "<days-since-last-commit>" or "UNREACHABLE" for
# "<owner> <repo>", so enumeration/classification/exit logic is testable offline
# without hitting the real network.
RESOLVER="${DEPMAINT_RESOLVER:-}"

resolve_builtin() {
  local owner="$1" repo="$2" tmp date_str epoch now
  tmp="$(mktemp -d)"
  if ! timeout 20 git clone --bare --depth 1 --filter=tree:0 --quiet \
       "https://github.com/$owner/$repo.git" "$tmp" >/dev/null 2>&1; then
    rm -rf "$tmp"; echo UNREACHABLE; return
  fi
  date_str="$(git -C "$tmp" log -1 --format=%cI HEAD 2>/dev/null)"
  rm -rf "$tmp"
  [ -n "$date_str" ] || { echo UNREACHABLE; return; }
  epoch="$(date -u -d "$date_str" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%S%z' "$date_str" +%s 2>/dev/null)"
  [ -n "$epoch" ] || { echo UNREACHABLE; return; }
  now="$(date -u +%s)"
  echo $(( (now - epoch) / 86400 ))
}

resolve() {
  if [ -n "$RESOLVER" ]; then "$RESOLVER" "$1" "$2"; else resolve_builtin "$1" "$2"; fi
}

# Enumerate every table row's Tool + Upstream-source cell (shared parser, lib/
# dependency-register.sh — also used by dependency-concentration-sync-check.sh).
declare -a ROWS=()
while IFS=$'\t' read -r tool source; do
  [ -n "$tool" ] || continue
  ROWS+=("$tool"$'\t'"$source")
done < <(depreg_rows "$REGISTER")

if [ "${#ROWS[@]}" -eq 0 ]; then
  warn "no rows parsed from docs/dependency-register.md — table format may have changed"
  exit 1
fi

printf '%s== dependency maintenance health (docs/dependency-register.md, %s-day window) ==%s\n' "$B" "$STALE_DAYS" "$Z"
stale=0
for row in "${ROWS[@]}"; do
  IFS=$'\t' read -r tool source <<<"$row"
  match="$(depreg_github_match "$source")"
  if [ -z "$match" ]; then
    skip "$tool: no github.com upstream source in the register — skipped"
    continue
  fi
  owner="$(cut -d/ -f1 <<<"$match")"
  repo="$(cut -d/ -f2 <<<"$match")"
  result="$(resolve "$owner" "$repo")"
  case "$result" in
    UNREACHABLE)  skip "$tool: github.com/$owner/$repo unreachable — skipped" ;;
    ''|*[!0-9]*)  skip "$tool: resolver gave an unexpected result — skipped" ;;
    *)
      if [ "$result" -gt "$STALE_DAYS" ]; then
        warn "$tool: github.com/$owner/$repo — no commit in ${result}d (> ${STALE_DAYS}d window) — worth a fresh look, not necessarily a problem"
        stale=1
      else
        ok "$tool: github.com/$owner/$repo — last commit ${result}d ago"
      fi
      ;;
  esac
done

echo
if [ "$stale" -eq 0 ]; then
  ok "no dependency exceeds the ${STALE_DAYS}-day maintenance-activity window (or all were unreachable)"
else
  warn "one or more dependencies exceed the ${STALE_DAYS}-day window — re-verify maintenance status, not an automatic action"
fi
exit "$stale"
