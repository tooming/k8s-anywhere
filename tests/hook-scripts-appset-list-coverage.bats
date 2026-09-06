#!/usr/bin/env bats
# Structural coverage for scripts/appset-list-coverage-sync-hook.sh — a new
# PostToolUse hook, per the hook-scripts-coverage-tests-check convention
# (tests/hook-scripts-coverage.bats itself is frozen; new hook-script coverage
# goes in its own tests/hook-scripts-<scope>.bats file). Mirrors the existing
# readme-sync-hook.sh coverage exactly (same payload shape, same
# filtered/unfiltered/in-sync assertions).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "appset-list-coverage-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/appset-list-coverage-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "appset-list-coverage-sync-hook: unrelated gitops yaml exits 0 (filtered out)" {
  run bash "$REPO/scripts/appset-list-coverage-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "appset-list-coverage-sync-hook: the networkpolicy-appset.yaml itself (currently in sync) exits 0" {
  run bash "$REPO/scripts/appset-list-coverage-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/networkpolicy-appset.yaml")"
  [ "$status" -eq 0 ]
}

@test "appset-list-coverage-sync-hook: the governance-appset.yaml itself (currently in sync) exits 0" {
  run bash "$REPO/scripts/appset-list-coverage-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/governance-appset.yaml")"
  [ "$status" -eq 0 ]
}
