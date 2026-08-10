#!/usr/bin/env bash
# Lab UIs drift check: the "Lab UIs" table in stack-health.json AND README.md's
# "## Endpoints" table are both hand-maintained, so either drifts when a UI route
# is added/removed. This flags that mechanically by comparing both against the
# host-based HTTPRoutes declared in gitops/ (the source of truth — works with the
# lab down, like readme-check). Runs in CI (the 'drift' job, a required check) and
# as a PostToolUse hook, so drift in either list is caught mechanically — not by
# remembering to audit. README.md's Endpoints table was found live 2026-08-10 to
# have silently missed two on-demand UIs (Harbor, TiDB demo) with no guard
# noticing — this check now covers that table too, not just the Grafana panel.
# Exit 0 = in sync; 1 = drift.
#
# Compares only host-based (`*.127.0.0.1.nip.io`) UIs — Grafana (localhost) and
# GitLab (off-cluster :8929) are stable special cases the skill handles by hand.
set -uo pipefail
# ROOT defaults to the repo; tests point LABUICHECK_ROOT at a fixture tree.
ROOT="${LABUICHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PANEL="$ROOT/grafana/dashboards/stack-health.json"
README="$ROOT/README.md"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

[ -f "$PANEL" ] || { echo "no stack-health.json — nothing to check"; exit 0; }

# host-based UIs declared by HTTPRoutes in gitops (safe if no files match)
route_files="$(grep -rl 'kind: HTTPRoute' "$ROOT"/gitops 2>/dev/null || true)"
route_hosts=""
[ -n "$route_files" ] && route_hosts="$(printf '%s\n' "$route_files" | xargs grep -hoE '[a-z0-9-]+\.127\.0\.0\.1\.nip\.io' 2>/dev/null || true)"
[ -n "$route_hosts" ] && route_hosts="$(printf '%s\n' "$route_hosts" | sort -u)"

# host-based UIs the panel advertises
panel_hosts="$(grep -oE '[a-z0-9-]+\.127\.0\.0\.1\.nip\.io' "$PANEL" 2>/dev/null | sort -u)"

# routed but not advertised -> a UI is missing from the panel
for h in $route_hosts; do
  grep -qx "$h" <<<"$panel_hosts" || bad "UI '$h' has an HTTPRoute but is MISSING from the Lab UIs panel"
done
# advertised but not routed -> a stale row (GitLab/Grafana are excluded above)
for h in $panel_hosts; do
  grep -qx "$h" <<<"$route_hosts" || bad "Lab UIs panel lists '$h' but no HTTPRoute declares it (stale row?)"
done

# Port check: host-based UIs must use the stable front-door port :8000. The front door
# routes to whichever cluster is active across a blue/green cutover; the per-cluster Envoy
# ports (:8080 blue, :8082 green) are NOT stable and must never be hardcoded in the panel.
# (See ADR-0005.)
for u in $(grep -oE 'http://[a-z0-9-]+\.127\.0\.0\.1\.nip\.io(:[0-9]+)?' "$PANEL" 2>/dev/null | grep -vE ':8000$' | sort -u || true); do
  bad "Lab UIs panel URL '$u' is not on the stable front-door port :8000 (never hardcode per-cluster ports like :8080/:8082)"
done

# Same comparison against README.md's "## Endpoints" table (scoped to that section
# only — a stray host-like string elsewhere in the doc, e.g. a wildcard cert note,
# should never trip this check).
if [ -f "$README" ]; then
  endpoints_section="$(awk '/^## Endpoints/{flag=1; next} /^## /{flag=0} flag' "$README")"
  readme_hosts="$(grep -oE '[a-z0-9-]+\.127\.0\.0\.1\.nip\.io' <<<"$endpoints_section" 2>/dev/null | sort -u)"

  for h in $route_hosts; do
    grep -qx "$h" <<<"$readme_hosts" || bad "UI '$h' has an HTTPRoute but is MISSING from README.md's Endpoints table"
  done
  for h in $readme_hosts; do
    grep -qx "$h" <<<"$route_hosts" || bad "README.md's Endpoints table lists '$h' but no HTTPRoute declares it (stale row?)"
  done
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s Lab UIs panel and README.md Endpoints table both match the host-based HTTPRoutes in gitops (and use the :8000 front door)\n' "$G" "$Z"
exit "$drift"
