#!/usr/bin/env bats
# Coverage for scripts/analysistemplate-step-count-sync-hook.sh, the PostToolUse
# companion to scripts/analysistemplate-step-count-check.sh (ADR-0020 re-evaluation
# log, 2026-08-06 entry). Split into its own tests/hook-scripts-<scope>.bats file
# per the hook-scripts-coverage-tests-check convention
# (tests/hook-scripts-coverage.bats is frozen). Mirrors
# tests/hook-scripts-coverage.bats's mimir-readonly-root-sync-hook section.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "analysistemplate-step-count-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/analysistemplate-step-count-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-sync-hook: a non-Rollout/AnalysisTemplate file exits 0 (filtered out)" {
  run bash "$REPO/scripts/analysistemplate-step-count-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/observability/loki/deployment.yaml")"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-sync-hook: a fixtures/ file exits 0 (filtered out)" {
  run bash "$REPO/scripts/analysistemplate-step-count-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/tests/fixtures/analysistemplate-step-count-check/drift/gitops/rollouts/manifest.yaml")"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-sync-hook: real capstone rollout.yaml (count already set) exits 0" {
  run bash "$REPO/scripts/analysistemplate-step-count-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/apps/capstone/rollout.yaml")"
  [ "$status" -eq 0 ]
}

@test "analysistemplate-step-count-sync-hook: real success-rate AnalysisTemplate (count already set) exits 0" {
  run bash "$REPO/scripts/analysistemplate-step-count-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/argo-rollouts/analysistemplates/success-rate.yaml")"
  [ "$status" -eq 0 ]
}
