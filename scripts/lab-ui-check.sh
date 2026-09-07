#!/usr/bin/env bash
# Lab UIs drift check: README.md's "## Endpoints" table is hand-maintained, so it
# drifts when a UI route is added/removed. This flags that mechanically by
# comparing it against the host-based IngressRoutes declared in gitops/ (the
# source of truth — works with the lab down, like readme-check). Runs in CI (the
# 'drift' job, a required check) and as a PostToolUse hook, so drift is caught
# mechanically — not by remembering to audit. Found live 2026-08-10: the table had
# silently missed two on-demand UIs (Harbor, TiDB demo) with no guard noticing.
# Exit 0 = in sync; 1 = drift.
#
# Used to also cross-check the Grafana "Lab UIs" dashboard panel
# (grafana/dashboards/stack-health.json) — removed 2026-09-06 (ADR-0041,
# observability stack removed with no replacement) along with the rest of
# grafana/. The README.md cross-check below is independent of that panel and
# stays fully functional.
#
# Compares only host-based (`*.127.0.0.1.nip.io`) UIs.
#
# Port :8080 (updated 2026-09-07): the DR front door + blue/green drill that used
# to make :8000 the only stable, cutover-independent entry point were removed
# entirely, no replacement. With only one cluster/mode left, k3d's own load
# balancer port (`http_port` in infra/modules/k3d-cluster/variables.tf, currently
# 8080) is simply THE port — there is no longer a blue/green ambiguity to hide
# behind a stable proxy port.
set -uo pipefail
# ROOT defaults to the repo; tests point LABUICHECK_ROOT at a fixture tree.
ROOT="${LABUICHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
README="$ROOT/README.md"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

# host-based UIs declared by IngressRoutes in gitops (safe if no files match)
route_files="$(grep -rl 'kind: IngressRoute' "$ROOT"/gitops 2>/dev/null || true)"
route_hosts=""
[ -n "$route_files" ] && route_hosts="$(printf '%s\n' "$route_files" | xargs grep -hoE '[a-z0-9-]+\.127\.0\.0\.1\.nip\.io' 2>/dev/null || true)"
[ -n "$route_hosts" ] && route_hosts="$(printf '%s\n' "$route_hosts" | sort -u)"

# Compares against README.md's "## Endpoints" table (scoped to that section
# only — a stray host-like string elsewhere in the doc, e.g. a wildcard cert note,
# should never trip this check).
if [ -f "$README" ]; then
  endpoints_section="$(awk '/^## Endpoints/{flag=1; next} /^## /{flag=0} flag' "$README")"
  readme_hosts="$(grep -oE '[a-z0-9-]+\.127\.0\.0\.1\.nip\.io' <<<"$endpoints_section" 2>/dev/null | sort -u)"

  for h in $route_hosts; do
    grep -qx "$h" <<<"$readme_hosts" || bad "UI '$h' has an IngressRoute but is MISSING from README.md's Endpoints table"
  done
  for h in $readme_hosts; do
    grep -qx "$h" <<<"$route_hosts" || bad "README.md's Endpoints table lists '$h' but no IngressRoute declares it (stale row?)"
  done

  # Port check: host-based UIs must use k3d's own load-balancer port :8080 — the
  # only entry point left now that the DR front door + blue/green drill are gone
  # (2026-09-07, no replacement). See the header comment above.
  for u in $(grep -oE 'http://[a-z0-9-]+\.127\.0\.0\.1\.nip\.io(:[0-9]+)?' <<<"$endpoints_section" 2>/dev/null | grep -vE ':8080$' | sort -u || true); do
    bad "README.md's Endpoints table URL '$u' is not on k3d's load-balancer port :8080 (never hardcode a different port)"
  done
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s README.md'"'"'s Endpoints table matches the host-based IngressRoutes in gitops (and uses the :8080 k3d load-balancer port)\n' "$G" "$Z"
exit "$drift"
