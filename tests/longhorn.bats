#!/usr/bin/env bats
# Clusterless structural tests for the Longhorn on-demand observability wiring
# (Alloy scrape job + Grafana dashboard) added in auto/longhorn-dashboard.
# Validates that the scrape block and dashboard are present and reference real
# metrics — no running cluster required (ADR-0004, ADR-0013).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ALLOY="$REPO/gitops/platform/observability-alloy.yaml"
  DASH="$REPO/grafana/dashboards/lab-longhorn.json"
  APP="$REPO/gitops/platform/longhorn.yaml"
}

# --- chart pin (ADR-0013 §Re-evaluation log, RFC #528) -----------------------
@test "longhorn Application is pinned to a community-supported 1.11.x series (not 1.7.x)" {
  run grep -q 'targetRevision: 1\.11\.' "$APP"
  [ "$status" -eq 0 ]
}

@test "longhorn Application is not pinned to the EOL'd 1.7 series" {
  run grep -q 'targetRevision: 1\.7\.' "$APP"
  [ "$status" -eq 1 ]
}

# --- Alloy scrape block -------------------------------------------------------

@test "observability-alloy.yaml has longhorn scrape block" {
  run grep -q 'prometheus.scrape "longhorn"' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "longhorn scrape target points to longhorn-manager on port 9500" {
  run grep -q 'longhorn-manager.longhorn-system.svc.cluster.local:9500' "$ALLOY"
  [ "$status" -eq 0 ]
}

# --- Grafana dashboard --------------------------------------------------------

@test "lab-longhorn.json dashboard exists" {
  [ -f "$DASH" ]
}

@test "lab-longhorn.json references longhorn-system namespace in a KSM query" {
  run grep -q 'longhorn-system' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-longhorn.json uses Mimir datasource" {
  run grep -q '"uid": "mimir"' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-longhorn.json has uid lab-longhorn" {
  run grep -q '"uid": "lab-longhorn"' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-longhorn.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$DASH"
  [ "$status" -eq 1 ]
}
