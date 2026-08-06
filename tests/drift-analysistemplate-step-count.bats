#!/usr/bin/env bats
# Tests for scripts/analysistemplate-step-count-check.sh (ADR-0020 re-evaluation
# log, 2026-08-06 entry) — the mechanical guard against a step-gating
# AnalysisTemplate (referenced from a Rollout's steps[].analysis.templates[])
# setting `interval` without `count`. Argo Rollouts rejects that combination as
# "runs indefinitely" on every reconcile, which is what crashlooped the
# argo-rollouts controller pod (145 restarts / 45h) before the fix. Split into
# its own tests/drift-<scope>.bats file per the drift-detectors-tests-check
# convention (tests/drift-detectors.bats is frozen).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/analysistemplate-step-count-check"
}

@test "analysistemplate-step-count-check: FAILS when a step-referenced metric has interval but no count" {
  run env ANALYSISTEMPLATE_STEP_COUNT_CHECK_ROOT="$FIX/drift" \
          bash "$REPO/scripts/analysistemplate-step-count-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"has interval but no count"* ]]
  [[ "$output" == *"runs indefinitely"* ]]
}

@test "analysistemplate-step-count-check: passes when the step-referenced metric sets count" {
  run env ANALYSISTEMPLATE_STEP_COUNT_CHECK_ROOT="$FIX/in-sync" \
          bash "$REPO/scripts/analysistemplate-step-count-check.sh"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-check: passes when the interval-only metric is a background analysis, not step-gating" {
  # spec.strategy.canary.analysis (background) is legitimately allowed to run
  # indefinitely -- only steps[].analysis (step-gating) requires count.
  run env ANALYSISTEMPLATE_STEP_COUNT_CHECK_ROOT="$FIX/background-ok" \
          bash "$REPO/scripts/analysistemplate-step-count-check.sh"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-check: skips (does not fail) when the referenced template isn't found locally" {
  # e.g. a ClusterAnalysisTemplate, or one synced from elsewhere -- can't verify,
  # so this must not be a false-positive failure.
  run env ANALYSISTEMPLATE_STEP_COUNT_CHECK_ROOT="$FIX/template-not-found" \
          bash "$REPO/scripts/analysistemplate-step-count-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "analysistemplate-step-count-check: passes on the real repo manifests" {
  run bash "$REPO/scripts/analysistemplate-step-count-check.sh"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-check: real repo's capstone success-rate template sets count: 5" {
  run grep -A1 'interval: 30s' "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml"
  [[ "$output" == *"count: 5"* ]]
}
