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

# The argo-cd chart (9.5.20) already renders its own "tmp" emptyDir volume +
# /tmp mount unconditionally for both repoServer and server (readOnlyRootFilesystem
# carve-out baked into the chart's templates, not gated on our values). A manual
# repoServer.volumes/server.volumes override duplicating "tmp" therefore breaks
# `helm upgrade` outright: "Deployment.apps ... Duplicate value: \"tmp\"" — hit on
# a from-scratch `make up`, since Terraform's helm_release then fails validation
# and the whole bootstrap aborts at the argocd step. Guard against reintroducing it.
@test "argocd values.yaml does not define its own repoServer tmp volume (chart already provides one; duplicate breaks helm upgrade)" {
  run bash -c "awk '/^repoServer:/{flag=1; print; next} flag && /^[a-zA-Z]/{flag=0} flag' '$VALUES' | grep -q 'name: tmp'"
  [ "$status" -ne 0 ]
}

@test "argocd values.yaml does not define its own server tmp volume (chart already provides one; duplicate breaks helm upgrade)" {
  run bash -c "awk '/^server:/{flag=1; print; next} flag && /^[a-zA-Z]/{flag=0} flag' '$VALUES' | grep -q 'name: tmp'"
  [ "$status" -ne 0 ]
}

@test "argocd values.yaml sets seccompProfile type RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$VALUES"
  [ "$status" -eq 0 ]
}
