#!/usr/bin/env bash
# Envoy backend-egress allowlist drift check: allow-envoy-proxy-backend-egress.yaml
# hand-maintains a list of namespaces the Envoy data-plane proxy may egress to. A
# namespace with a live HTTPRoute through the shared gateway (parentRefs: eg /
# lab-gateway) that is missing from this list has its HTTPRoute responses silently
# dropped by the envoy-gateway-system default-deny floor (ADR-0016) -- the exact bug
# that caused a real P1 incident for `harbor` (fixed 2026-08-03, PR #968) and
# recurred, undetected, for `tidb`/`longhorn-system`/`istio-system`/`kargo` (found +
# fixed 2026-08-07). This mechanically catches the class going forward -- not just
# re-asserting the currently-known-good list, which is what the old bats "includes
# all N backend namespaces" test alone could never do (it can't see a *new*
# HTTPRoute namespace added elsewhere). Runs in CI (the 'drift' job, a required
# check) and via `make ci`, mirroring scripts/lab-ui-check.sh's shape. Exit 0 = in
# sync; 1 = drift.
#
# One-directional by design: an allowlist entry with no *current* HTTPRoute (e.g.
# kyverno/velero/trivy-system/ack-system today) is not flagged -- over-inclusion in
# a same-cluster egress allowlist isn't the failure mode that bit us, and pruning
# those without evidence they're actually unused risks breaking something this
# check can't see (no port restriction is applied here, so a missing route doesn't
# necessarily mean unused egress). Only under-inclusion (a routed namespace missing
# from the list) is checked.
set -uo pipefail
ROOT="${ENVOYEGRESSCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ALLOWLIST="$ROOT/gitops/envoy-gateway-system/networkpolicy/allow-envoy-proxy-backend-egress.yaml"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

[ -f "$ALLOWLIST" ] || { echo "no allow-envoy-proxy-backend-egress.yaml -- nothing to check"; exit 0; }

# Namespaces already allowed egress (the values: list under matchExpressions).
allowed_ns="$(awk '
  /values:/ { invalues=1; next }
  invalues && /^[ \t]*- / {
    line=$0
    sub(/^[ \t]*-[ \t]*/, "", line)
    gsub(/[ \t]*$/, "", line)
    print line
    next
  }
  invalues { invalues=0 }
' "$ALLOWLIST" | sort -u)"

# Every HTTPRoute routed through the shared gateway (parentRefs: eg / lab-gateway),
# by its own metadata.namespace -- not the file path, since some HTTPRoutes are
# embedded (extraObjects) inside an unrelated Application's values.yaml (e.g.
# Grafana's HTTPRoute lives inside gitops/platform/observability-grafana.yaml but
# is namespaced "observability", not "platform").
route_files="$(grep -rl 'kind: HTTPRoute' "$ROOT"/gitops 2>/dev/null || true)"
route_namespaces=""
if [ -n "$route_files" ]; then
  route_namespaces="$(for f in $route_files; do
    awk '
      /kind: HTTPRoute/ { found=1; next }
      found && /namespace:/ {
        line=$0
        sub(/^[ \t]*namespace:[ \t]*/, "", line)
        gsub(/[ \t]*$/, "", line)
        print line
        found=0
      }
    ' "$f"
  done | sort -u)"
fi

for ns in $route_namespaces; do
  grep -qx "$ns" <<<"$allowed_ns" || bad "namespace '$ns' has an HTTPRoute through the shared gateway but is MISSING from allow-envoy-proxy-backend-egress.yaml (its HTTPRoute responses will be silently dropped by the default-deny floor -- same bug class as the harbor incident, PR #968)"
done

[ "$drift" -eq 0 ] && ok "every HTTPRoute namespace routed through the shared gateway is in allow-envoy-proxy-backend-egress.yaml's allowlist"
exit "$drift"
