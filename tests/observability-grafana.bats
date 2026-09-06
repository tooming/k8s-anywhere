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

@test "observability-grafana.yaml pins image.tag to 13.0.8" {
  [ "$(yqs '.spec.source.helm.valuesObject.image.tag' "$GRAFANA")" = "13.0.8" ]
}

@test "observability-grafana.yaml ca-bundle init container matches the same 13.0.8 pin" {
  run grep -q 'image: docker.io/grafana/grafana:13.0.8' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "observability-grafana.yaml has no stray 13.0.1 image-tag reference left" {
  run grep -q 'tag: "13.0.1"' "$GRAFANA"
  [ "$status" -ne 0 ]
  run grep -q 'image: docker.io/grafana/grafana:13.0.1' "$GRAFANA"
  [ "$status" -ne 0 ]
}

@test "observability-grafana.yaml has no stray 13.0.3 image-tag reference left" {
  run grep -q 'tag: "13.0.3"' "$GRAFANA"
  [ "$status" -ne 0 ]
  run grep -q 'image: docker.io/grafana/grafana:13.0.3' "$GRAFANA"
  [ "$status" -ne 0 ]
}

@test "observability-grafana.yaml has no stray 13.0.5 image-tag reference left" {
  run grep -q 'tag: "13.0.5"' "$GRAFANA"
  [ "$status" -ne 0 ]
  run grep -q 'image: docker.io/grafana/grafana:13.0.5' "$GRAFANA"
  [ "$status" -ne 0 ]
}

@test "observability-grafana.yaml has no stray 13.0.6 image-tag reference left" {
  run grep -q 'tag: "13.0.6"' "$GRAFANA"
  [ "$status" -ne 0 ]
  run grep -q 'image: docker.io/grafana/grafana:13.0.6' "$GRAFANA"
  [ "$status" -ne 0 ]
}

@test "observability-grafana.yaml has no stray 13.0.7 image-tag reference left" {
  run grep -q 'tag: "13.0.7"' "$GRAFANA"
  [ "$status" -ne 0 ]
  run grep -q 'image: docker.io/grafana/grafana:13.0.7' "$GRAFANA"
  [ "$status" -ne 0 ]
}

# --- Chart currency pin (upgrade-drafter fallback, 2026-08-10; bumped 2026-09-06) ---
@test "observability-grafana.yaml pins grafana chart to 12.11.2" {
  [ "$(yqs '.spec.source.targetRevision' "$GRAFANA")" = "12.11.2" ]
}

@test "observability-grafana.yaml does not pin the stale 12.10.4 chart" {
  [ "$(yqs '.spec.source.targetRevision' "$GRAFANA")" != "12.10.4" ]
}

# --- lab-grafana.json dashboard metric-drift fix (2026-08-12, 5th audit batch) ---
# "Active users" queried grafana_authenticated_user_requests, a metric that does not
# exist anywhere in grafana/grafana (verified against the real v13.0.5 source, exhaustive
# grep found zero hits) -- the panel could never show data. The real gauge for this is
# grafana_stat_active_users (pkg/infra/metrics/metrics.go, Namespace=grafana,
# Name=stat_active_users). Separately, "Login rate" grouped `by (handler)` on
# grafana_api_login_post_total, a real metric but a bare unlabeled Counter (no `handler`
# label exists) -- misleading, not "no data", but still an inaccurate per-handler claim.

@test "lab-grafana.json references the real grafana_stat_active_users metric" {
  run grep -q 'grafana_stat_active_users' "$REPO/grafana/dashboards/lab-grafana.json"
  [ "$status" -eq 0 ]
}

@test "lab-grafana.json does not reference the fabricated grafana_authenticated_user_requests metric" {
  run grep -q 'grafana_authenticated_user_requests' "$REPO/grafana/dashboards/lab-grafana.json"
  [ "$status" -eq 1 ]
}

@test "lab-grafana.json login-rate panel does not group by the nonexistent handler label" {
  run grep -q 'by (handler) (rate(grafana_api_login_post_total' "$REPO/grafana/dashboards/lab-grafana.json"
  [ "$status" -eq 1 ]
}
