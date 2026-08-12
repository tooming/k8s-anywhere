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

# --- metric-value drift guard (2026-08-12) ------------------------------------
# "Healthy Volumes" queried robustness="Healthy" (Title-Case) -- the real
# longhorn_volume_robustness label value is lowercase "healthy" (verified
# against longhorn-manager v1.11.3 source, k8s/pkg/apis/longhorn/v1beta2/
# volume.go's VolumeRobustnessHealthy = VolumeRobustness("healthy"), emitted
# verbatim via string(r) with no case transform). Same case-mismatch class of
# bug as PR #1155's Trivy severity-label fix -- the panel could never match a
# real series. Real, negative-but-honest result on every other panel: the
# "attached" volume-state label value is already correctly lowercase.
@test "lab-longhorn.json queries the real lowercase robustness=\"healthy\" label value" {
  run grep -q 'robustness=\\"healthy\\"' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-longhorn.json does not query the nonexistent Title-Case robustness=\"Healthy\" label value" {
  run grep -q 'robustness=\\"Healthy\\"' "$DASH"
  [ "$status" -eq 1 ]
}
