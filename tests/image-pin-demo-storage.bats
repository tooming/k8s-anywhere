#!/usr/bin/env bats
# Recurrence guard: gitops/apps/demo/deployment.yaml used to float on a ":latest" image
# tag while being an auto-synced (selfHeal: true) Application — the exact incident
# class that already bit ArgoCD (see gitops/kyverno/policies/disallow-latest-tag.yaml's
# header comments, from when Kyverno still existed — removed entirely 2026-09-07,
# ADR-0019). Originally pinned 2026-07-28 (recreate-from-code hardening) against
# jaegertracing/example-hotrod; that image was swapped for nginx-unprivileged
# 2026-09-08 (ADR-0017's lab-demo PSS flip, ROADMAP auto/lab-demo-hello-world-swap) —
# same hardening rule, new image: asserts the manifest never reverts to a floating tag.
#
# This file used to also cover gitops/storage/s3manager/deployment.yaml's own digest
# pin; those tests were removed 2026-09-07 alongside s3manager itself (ADR-0039,
# Garage/ADR-0002 removed entirely, no replacement — s3manager had nothing left to
# browse).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "demo hello Deployment does not use a floating :latest image tag" {
  run grep -qE '^\s*image: nginxinc/nginx-unprivileged:latest' "$REPO/gitops/apps/demo/deployment.yaml"
  [ "$status" -ne 0 ]
}

@test "demo hello Deployment pins nginx-unprivileged to an exact version (no-floating-tag hardening)" {
  run grep -qE '^\s*image: nginxinc/nginx-unprivileged:[0-9]+\.[0-9]+\.[0-9]+-alpine$' "$REPO/gitops/apps/demo/deployment.yaml"
  [ "$status" -eq 0 ]
}
