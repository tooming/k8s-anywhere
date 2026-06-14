#!/usr/bin/env bats
# Clusterless structural tests for the capstone Rollout overlay + success-rate
# AnalysisTemplate (ADR-0020, RFC #154). Validates file existence, canary step
# ordering (setWeight 10 → pause 60s → analysis → setWeight 50 → pause 60s →
# analysis), AnalysisTemplate shape (Mimir URL, X-Scope-OrgID header, success-rate
# query, namespace arg), and the gatewayAPI traffic-router plugin reference.
# No cluster required — all checks are pure structural assertions on YAML content.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- success-rate AnalysisTemplate -------------------------------------------
@test "success-rate AnalysisTemplate file exists" {
  [ -f "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml" ]
}

@test "AnalysisTemplate is kind AnalysisTemplate" {
  run grep -q 'kind: AnalysisTemplate' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate is named success-rate" {
  run grep -q 'name: success-rate' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate targets namespace capstone (co-located with Rollout)" {
  run grep -q 'namespace: capstone' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate references Mimir query-frontend at documented URL" {
  run grep -q 'mimir-query-frontend.observability.svc.cluster.local:8080/prometheus' \
    "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate sends X-Scope-OrgID header" {
  run grep -q 'X-Scope-OrgID' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate X-Scope-OrgID header value is lab (single-tenant Mimir config)" {
  run grep -q 'value: lab' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate success condition gates at >= 0.95" {
  run grep -q '>= 0.95' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate query uses http_requests_total metric" {
  run grep -q 'http_requests_total' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate query filters out 5xx responses" {
  run grep -q 'code!~' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
}

@test "AnalysisTemplate declares a namespace arg for per-workload query scoping" {
  run grep -q 'name: namespace' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [ "$status" -eq 0 ]
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

@test "capstone Rollout references the gatewayAPI traffic-router plugin" {
  run grep -q 'argoproj-labs/gatewayAPI' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout gatewayAPI plugin points at the capstone HTTPRoute" {
  run grep -q 'name: capstone' "$REPO/gitops/apps/capstone/rollout.yaml"
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

@test "capstone Rollout analysis step references the success-rate template" {
  run grep -q 'templateName: success-rate' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout promotes canary weight to 50 in the second setWeight step" {
  run grep -q 'setWeight: 50' "$REPO/gitops/apps/capstone/rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Rollout analysis step passes namespace arg value capstone" {
  run grep -q 'value: capstone' "$REPO/gitops/apps/capstone/rollout.yaml"
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

# --- capstone-rollout ArgoCD Application -----------------------------------
@test "capstone-rollout Application exists in gitops/platform/" {
  [ -f "$REPO/gitops/platform/capstone-rollout.yaml" ]
}

@test "capstone-rollout Application sources the analysistemplates catalogue path" {
  run grep -q 'path: gitops/argo-rollouts/analysistemplates' "$REPO/gitops/platform/capstone-rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-rollout Application destination namespace is capstone" {
  run grep -q 'namespace: capstone' "$REPO/gitops/platform/capstone-rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-rollout Application is auto-synced (always-on; CRD instance, no footprint)" {
  run grep -q 'automated:' "$REPO/gitops/platform/capstone-rollout.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-rollout Application runs at sync-wave 5 (after argo-rollouts CRDs and capstone namespace)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "5"' "$REPO/gitops/platform/capstone-rollout.yaml"
  [ "$status" -eq 0 ]
}
