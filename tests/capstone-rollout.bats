#!/usr/bin/env bats
# Clusterless structural tests for the capstone Rollout overlay (ADR-0020, RFC #154).
# Validates file existence, canary step ordering (setWeight 10 → pause 60s →
# setWeight 50 → pause 60s), and Traefik's built-in traffic-routing (ADR-0040).
#
# The success-rate AnalysisTemplate (Mimir-backed SLO gate) and the standalone
# capstone-rollout Application that deployed it were both removed 2026-09-06
# (ADR-0041, observability stack removed with no replacement) — canary
# progression is now weight/pause-only, with no automated SLO-regression halt.
# No cluster required — all checks are pure structural assertions on YAML content.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "success-rate AnalysisTemplate no longer exists (ADR-0041)" {
  [ ! -f "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml" ]
}

@test "capstone-rollout Application no longer exists (ADR-0041)" {
  [ ! -f "$REPO/gitops/platform/capstone-rollout.yaml" ]
}

# --- Capstone Rollout --------------------------------------------------------
@test "capstone Rollout file exists" {
  [ -f "$REPO/gitops/apps/capstone/rollout.yaml" ]
}

@test "capstone Rollout is kind Rollout" {
  run grep -q 'kind: Rollout' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout uses canary strategy" {
  run grep -q 'canary:' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout declares canaryService capstone-canary" {
  run grep -q 'canaryService: capstone-canary' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout declares stableService capstone-stable" {
  run grep -q 'stableService: capstone-stable' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout uses Traefik's built-in traffic-routing, not a plugin (ADR-0040)" {
  run grep -q 'traefik:' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'argoproj-labs/gatewayAPI' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -ne 0 ]
}

@test "capstone Rollout points at the capstone TraefikService" {
  run grep -q 'weightedTraefikServiceName: capstone' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout first step sets canary weight to 10" {
  run grep -q 'setWeight: 10' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout pause step duration is 60s" {
  run grep -q 'duration: 60s' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout no longer has an analysis step (ADR-0041)" {
  run grep -q 'analysis:' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -ne 0 ]
}

@test "capstone Rollout promotes canary weight to 50 in the second setWeight step" {
  run grep -q 'setWeight: 50' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

# --- Canary and stable Services ---------------------------------------------
@test "capstone-stable Service is defined in rollout.yaml" {
  run grep -q 'name: capstone-stable' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-canary Service is defined in rollout.yaml" {
  run grep -q 'name: capstone-canary' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}
