#!/usr/bin/env bats
# Recurrence guard: gitops/apps/demo/deployment.yaml and
# gitops/storage/s3manager/deployment.yaml both used to float on a ":latest" image
# tag while being auto-synced (selfHeal: true) Applications — the exact incident
# class that already bit ArgoCD (see gitops/kyverno/policies/disallow-latest-tag.yaml's
# header comments): the disallow-latest-tag Kyverno ClusterPolicy (Enforce mode) only
# excludes capstone/argocd, so any Pod recreation for these two images was liable to
# be rejected on admission. Pinned 2026-07-28 (recreate-from-code hardening) — asserts
# neither manifest reverts to a floating tag.

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

@test "s3manager Deployment does not use a floating :latest image tag" {
  run grep -q 'image: cloudlena/s3manager:latest' "$REPO/gitops/storage/s3manager/deployment.yaml"
  [ "$status" -ne 0 ]
}

@test "s3manager Deployment pins cloudlena/s3manager by digest" {
  run grep -q 'image: cloudlena/s3manager@sha256:' "$REPO/gitops/storage/s3manager/deployment.yaml"
  [ "$status" -eq 0 ]
}

@test "s3manager Deployment pins the current digest (v0.9.0-equivalent, bumped 2026-09-03, ADR-0039)" {
  run grep -q 'image: cloudlena/s3manager@sha256:cc4b81ea29fb59610e29df6707ab6646e36e32744bbb700cffd5d2d6bf60c03f' "$REPO/gitops/storage/s3manager/deployment.yaml"
  [ "$status" -eq 0 ]
}

@test "s3manager Deployment does not pin the stale pre-2026-08-18 digest" {
  run grep -q 'image: cloudlena/s3manager@sha256:f666e6fca127ec07b90c3c207eeb6730817b6ad0807356db6eb63fbda6bdacb2' "$REPO/gitops/storage/s3manager/deployment.yaml"
  [ "$status" -ne 0 ]
}

@test "s3manager Deployment does not pin the stale pre-2026-09-03 v0.8.0 digest" {
  run grep -q 'image: cloudlena/s3manager@sha256:9ed3a8ecf10381031b19afa4e5ff863efddb81aeac2f84b142a2190d7973e68b' "$REPO/gitops/storage/s3manager/deployment.yaml"
  [ "$status" -ne 0 ]
}
