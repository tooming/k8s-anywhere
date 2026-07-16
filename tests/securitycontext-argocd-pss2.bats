#!/usr/bin/env bats
# Clusterless structural tests for ArgoCD PSS Phase 2 (RFC #205, ADR-0017).
# Asserts infra/modules/argocd/values.yaml carries the required securityContext
# hardening and emptyDir scratch volumes added in auto/argocd-pss-enforce.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VALUES="$REPO/infra/modules/argocd/values.yaml"
}

@test "argocd values.yaml sets global runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$VALUES"
  [ "$status" -eq 0 ]
}

@test "argocd values.yaml sets global readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$VALUES"
  [ "$status" -eq 0 ]
}

@test "argocd values.yaml drops ALL capabilities" {
  run grep -q '\- ALL' "$VALUES"
  [ "$status" -eq 0 ]
}

@test "argocd values.yaml has emptyDir tmp volume (readOnlyRootFilesystem carve-out)" {
  run grep -q 'emptyDir: {}' "$VALUES"
  [ "$status" -eq 0 ]
}

@test "argocd values.yaml repoServer mounts tmp at /tmp" {
  run grep -q 'mountPath: /tmp' "$VALUES"
  [ "$status" -eq 0 ]
}

@test "argocd values.yaml sets seccompProfile type RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$VALUES"
  [ "$status" -eq 0 ]
}
