#!/usr/bin/env bash
# Lab UIs drift check: the "Lab UIs" table in stack-health.yaml is hand-maintained,
# so it drifts when a UI route is added/removed. This flags that mechanically by
# comparing the panel against the host-based HTTPRoutes declared in gitops/ (the
# source of truth — works with the lab down, like readme-check). Runs in CI (the
# 'drift' job, a required check) and as a PostToolUse hook, so panel drift is caught
# mechanically — not by remembering to audit. Exit 0 = in sync; 1 = drift.
#
# Compares only host-based (`*.127.0.0.1.nip.io`) UIs — Grafana (localhost) and
# GitLab (off-cluster :8929) are stable special cases the skill handles by hand.
set -uo pipefail
# ROOT defaults to the repo; tests point LABUICHECK_ROOT at a fixture tree.
ROOT="${LABUICHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PANEL="$ROOT/gitops/observability/dashboards/stack-health.yaml"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -f "$PANEL" ] || { echo "no stack-health.yaml — nothing to check"; exit 0; }

# host-based UIs declared by HTTPRoutes in gitops (safe if no files match)
route_files="$(grep -rl 'kind: HTTPRoute' "$ROOT"/gitops 2>/dev/null || true)"
route_hosts=""
[ -n "$route_files" ] && route_hosts="$(printf '%s\n' "$route_files" | xargs grep -hoE '[a-z0-9-]+\.127\.0\.0\.1\.nip\.io' 2>/dev/null | sort -u)"

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
# (lab-ui-audit skill / ADR-0005.)
for u in $(grep -oE 'http://[a-z0-9-]+\.127\.0\.0\.1\.nip\.io(:[0-9]+)?' "$PANEL" 2>/dev/null | grep -vE ':8000$' | sort -u || true); do
  bad "Lab UIs panel URL '$u' is not on the stable front-door port :8000 (never hardcode per-cluster ports like :8080/:8082)"
done

[ "$drift" -eq 0 ] && printf '  \033[32m✓\033[0m Lab UIs panel matches the host-based HTTPRoutes in gitops (and uses the :8000 front door)\n'
exit "$drift"
