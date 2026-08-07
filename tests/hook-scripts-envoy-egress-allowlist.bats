#!/usr/bin/env bats
# Structural coverage for scripts/envoy-egress-allowlist-sync-hook.sh — a new
# PostToolUse hook, per the hook-scripts-coverage-tests-check convention
# (tests/hook-scripts-coverage.bats itself is frozen; new hook-script coverage
# goes in its own tests/hook-scripts-<scope>.bats file). Mirrors the existing
# lab-ui-sync-hook.sh coverage in tests/hook-scripts-coverage.bats exactly (same
# payload shape, same filtered/unfiltered/in-sync assertions).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "envoy-egress-allowlist-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/envoy-egress-allowlist-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "envoy-egress-allowlist-sync-hook: unrelated gitops yaml with no HTTPRoute exits 0 (filtered out)" {
  run bash "$REPO/scripts/envoy-egress-allowlist-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "envoy-egress-allowlist-sync-hook: a real HTTPRoute manifest (currently in sync) exits 0" {
  run bash "$REPO/scripts/envoy-egress-allowlist-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/tidb-demo/route.yaml")"
  [ "$status" -eq 0 ]
}

@test "envoy-egress-allowlist-sync-hook: the allowlist file itself (currently in sync) exits 0" {
  run bash "$REPO/scripts/envoy-egress-allowlist-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/envoy-gateway-system/networkpolicy/allow-envoy-proxy-backend-egress.yaml")"
  [ "$status" -eq 0 ]
}
