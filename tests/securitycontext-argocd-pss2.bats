#!/usr/bin/env bats
# Clusterless structural tests for ArgoCD PSS Phase 2 (RFC #205, ADR-0017).
# Asserts infra/modules/argocd/values.yaml carries the required securityContext
# hardening and emptyDir scratch volumes added in auto/argocd-pss-enforce.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # yqs(): yq-variant-robust scalar read (strips quoting differences).
  load lib/yq
  VALUES="$REPO/infra/modules/argocd/values.yaml"
}

# Pod-level fields live under `global.securityContext` (the chart's real key,
# templates/argocd-application-controller/deployment.yaml reads
# `.Values.global.securityContext`), NOT `global.podSecurityContext` (silent
# no-op in this chart's schema -- found auditing PR #493's bug class against
# this file). Path-aware via yqs() so a regression back to the wrong key
# fails these tests instead of silently passing a bare grep.

@test "argocd values.yaml sets global.securityContext.runAsNonRoot: true" {
  [ "$(yqs '.global.securityContext.runAsNonRoot' "$VALUES")" = "true" ]
}

@test "argocd values.yaml sets global.securityContext.seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.global.securityContext.seccompProfile.type' "$VALUES")" = "RuntimeDefault" ]
}

@test "argocd values.yaml does NOT use the dead global.podSecurityContext key" {
  [ "$(yqs '.global.podSecurityContext // "absent"' "$VALUES")" = "absent" ]
}

# Container-level PSS restricted fields (readOnlyRootFilesystem,
# allowPrivilegeEscalation: false, capabilities.drop: [ALL]) are NOT set by
# this file at all -- the chart's own `<component>.containerSecurityContext`
# already defaults to exactly these values for every component (controller,
# repoServer, applicationSet, server, and the bundled session-cache
# sub-chart), verified against the pinned chart version (argo-cd-9.5.20).
# `global.containerSecurityContext` is not a valid key in this chart's schema
# (it's per-component, not global) -- guard against reintroducing it.
@test "argocd values.yaml does NOT use the dead global.containerSecurityContext key" {
  [ "$(yqs '.global.containerSecurityContext // "absent"' "$VALUES")" = "absent" ]
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
