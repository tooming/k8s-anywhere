#!/usr/bin/env bats
# Recurrence guard: gitops/apps/demo/deployment.yaml used to float on a ":latest" image
# tag while being an auto-synced (selfHeal: true) Application — the exact incident
# class that already bit ArgoCD (see gitops/kyverno/policies/disallow-latest-tag.yaml's
# header comments): the disallow-latest-tag Kyverno ClusterPolicy (Enforce mode) only
# excludes capstone/argocd, so any Pod recreation for this image was liable to
# be rejected on admission. Pinned 2026-07-28 (recreate-from-code hardening) — asserts
# the manifest never reverts to a floating tag.
#
# This file used to also cover gitops/storage/s3manager/deployment.yaml's own digest
# pin; those tests were removed 2026-09-07 alongside s3manager itself (ADR-0039,
# Garage/ADR-0002 removed entirely, no replacement — s3manager had nothing left to
# browse).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "demo hello Deployment does not use a floating :latest image tag" {
  run grep -q 'image: jaegertracing/example-hotrod:latest' "$REPO/gitops/apps/demo/deployment.yaml"
  [ "$status" -ne 0 ]
}

@test "demo hello Deployment pins jaegertracing/example-hotrod to 2.20.0" {
  run grep -q 'image: jaegertracing/example-hotrod:2.20.0' "$REPO/gitops/apps/demo/deployment.yaml"
  [ "$status" -eq 0 ]
}
