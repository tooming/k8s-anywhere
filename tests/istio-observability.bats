#!/usr/bin/env bats
# Clusterless structural tests for the Istio ambient mesh on-demand observability
# wiring (Alloy scrape + Grafana dashboard) added in
# auto/istio-observability-dashboard. Validates that the scrape block and dashboard
# are present and reference real metrics — no running cluster required (ADR-0004,
# ADR-0012).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ALLOY="$REPO/gitops/platform/observability-alloy.yaml"
  DASH="$REPO/grafana/dashboards/lab-istio.json"
}

# --- Alloy scrape block -------------------------------------------------------

@test "observability-alloy.yaml has istiod scrape block" {
  run grep -q 'prometheus.scrape "istiod"' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "istiod scrape target points to istiod service on port 15014" {
  run grep -q 'istiod.istio-system.svc.cluster.local:15014' "$ALLOY"
  [ "$status" -eq 0 ]
}

# --- Grafana dashboard --------------------------------------------------------

@test "lab-istio.json dashboard exists" {
  [ -f "$DASH" ]
}

@test "lab-istio.json has uid lab-istio" {
  run grep -q '"uid": "lab-istio"' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-istio.json references istio-system namespace in a KSM query" {
  run grep -q 'istio-system' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-istio.json uses Mimir datasource" {
  run grep -q '"uid": "mimir"' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-istio.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$DASH"
  [ "$status" -eq 1 ]
}
