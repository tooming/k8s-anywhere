#!/usr/bin/env bats
# Tests for scripts/kustomize-orphan-check.sh — the drift guard that catches a
# file sitting next to a kustomization.yaml but not referenced by it (dropped
# from resources: but never deleted, or never wired in). See that script's
# header for the real bug this guards against recurring (gitops/harbor/
# networkpolicy/allow-harbor-clusterip-egress.yaml, orphaned for a month and
# still edited as if live in PR #716).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/kustomize-orphan-check"
}

@test "kustomize-orphan-check: passes when every file is referenced by its kustomization.yaml" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-check: fails on a file dropped from resources: but left on disk" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/drift" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"allow-foo-clusterip-egress.yaml"* ]]
  [[ "$output" == *"not referenced anywhere in"* ]]
}

@test "kustomize-orphan-check: a missing gitops/ directory is a clean no-op" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/no-gitops-dir" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]]
}

@test "kustomize-orphan-check: passes on the real repo's gitops/ tree" {
  run bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 0 ]
}
