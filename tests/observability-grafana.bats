#!/usr/bin/env bats
# Clusterless structural tests for the Grafana image-tag pin (RFC #563 CVE bump).
# Recurrence guard: asserts the running Grafana binary and its ca-bundle init
# container stay on the same patched image tag, so a future bump that updates
# one occurrence and forgets the other doesn't silently reintroduce drift.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
  GRAFANA="$REPO/gitops/platform/observability-grafana.yaml"
}

@test "observability-grafana.yaml pins image.tag to 13.0.3" {
  [ "$(yqs '.spec.source.helm.valuesObject.image.tag' "$GRAFANA")" = "13.0.3" ]
}

@test "observability-grafana.yaml ca-bundle init container matches the same 13.0.3 pin" {
  run grep -q 'image: docker.io/grafana/grafana:13.0.3' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "observability-grafana.yaml has no stray 13.0.1 image-tag reference left" {
  run grep -q 'tag: "13.0.1"' "$GRAFANA"
  [ "$status" -ne 0 ]
  run grep -q 'image: docker.io/grafana/grafana:13.0.1' "$GRAFANA"
  [ "$status" -ne 0 ]
}

# --- Chart currency pin (planner-fallback upstream check, 2026-08-05) -------
@test "observability-grafana.yaml pins grafana chart to 12.10.3" {
  [ "$(yqs '.spec.source.targetRevision' "$GRAFANA")" = "12.10.3" ]
}
