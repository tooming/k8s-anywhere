#!/usr/bin/env bats
# Structural coverage for scripts/workflow-timeout-sync-hook.sh — a new
# PostToolUse hook, per the hook-scripts-coverage-tests-check convention
# (tests/hook-scripts-coverage.bats itself is frozen; new hook-script coverage
# goes in its own tests/hook-scripts-<scope>.bats file). Mirrors the existing
# envoy-egress-allowlist-sync-hook.sh coverage exactly (same payload shape, same
# filtered/unfiltered/in-sync assertions).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "workflow-timeout-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/workflow-timeout-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "workflow-timeout-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/workflow-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "workflow-timeout-sync-hook: a real workflow file (currently in sync) exits 0" {
  run bash "$REPO/scripts/workflow-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/.github/workflows/ci.yml")"
  [ "$status" -eq 0 ]
}

@test "workflow-timeout-sync-hook: a real .forgejo/workflows file (currently in sync) exits 0" {
  run bash "$REPO/scripts/workflow-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/.forgejo/workflows/build-sign-push.yml")"
  [ "$status" -eq 0 ]
}
