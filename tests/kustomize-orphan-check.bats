#!/usr/bin/env bats
# Tests for scripts/kustomize-orphan-check.sh — the drift guard that catches a
# file sitting next to a kustomization.yaml but not referenced by it (dropped
# from resources: but never deleted, or never wired in), plus (pass 2) a whole
# gitops/ directory with no kustomization.yaml at all that nothing references
# any more. See that script's header for the real bugs each pass guards
# against recurring: pass 1 is gitops/harbor/networkpolicy/
# allow-harbor-clusterip-egress.yaml (orphaned for a month and still edited as
# if live, PR #716); pass 2 is gitops/argo-rollouts/ (left on disk,
# unreferenced from anywhere, after PR #1497 removed Argo Rollouts).

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

@test "kustomize-orphan-check: fails on a kustomization-less directory referenced from nowhere" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/orphaned-dir" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gitops/foo/ has no kustomization.yaml"* ]]
  [[ "$output" == *"dead directory"* ]]
}

@test "kustomize-orphan-check: passes when a kustomization-less directory is named by an Application path:" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/dir-referenced" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-check: passes when a kustomization-less directory's file is pulled in by a sibling's relative resource path" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/basename-referenced" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-check: passes when a kustomization-less directory's file is applied directly by the Makefile" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/makefile-referenced" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-check: a mention in docs/ does not count as a live reference" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/docs-only-reference" bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gitops/foo/ has no kustomization.yaml"* ]]
}

@test "kustomize-orphan-check: KUSTOMIZE_ORPHAN_CHECK_DIRS scopes the directory pass" {
  run env KUSTOMIZE_ORPHAN_CHECK_ROOT="$FIX/orphaned-dir" \
    KUSTOMIZE_ORPHAN_CHECK_DIRS="$FIX/orphaned-dir/gitops/foo" \
    bash "$REPO/scripts/kustomize-orphan-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gitops/foo/ has no kustomization.yaml"* ]]
}
