#!/usr/bin/env bats
# Tests for scripts/envoy-egress-allowlist-check.sh — a new drift-check scope, per
# the drift-detectors-tests-check convention (tests/drift-detectors.bats itself is
# frozen; new scopes go in their own tests/drift-<scope>.bats file, mirroring
# tests/drift-gitops-manifest-checks.bats). Added as part of the janitor fix for the
# recurring "HTTPRoute namespace missing from the envoy backend-egress allowlist"
# bug class (harbor, PR #968; tidb/longhorn-system/istio-system/kargo, 2026-08-07).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/envoy-egress-allowlist-check"
}

@test "envoy-egress-allowlist-check: passes when every routed namespace is allowed" {
  run env ENVOYEGRESSCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/envoy-egress-allowlist-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every HTTPRoute namespace"* ]]
}

@test "envoy-egress-allowlist-check: fails when a routed namespace is missing from the allowlist" {
  run env ENVOYEGRESSCHECK_ROOT="$FIX/drift" bash "$REPO/scripts/envoy-egress-allowlist-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"testapp"* ]]
  [[ "$output" == *"MISSING"* ]]
}

@test "envoy-egress-allowlist-check: passes on the real repo's gitops HTTPRoutes + allowlist" {
  run bash "$REPO/scripts/envoy-egress-allowlist-check.sh"
  [ "$status" -eq 0 ]
}
