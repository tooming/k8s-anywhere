#!/usr/bin/env bats
# Recurrence guard for ADR-0033's "currently unpinned" finding: gitlab/docker-compose.yml
# used to pin both the omnibus service and its runner to the floating `:latest`
# tag, unlike every other always-on dependency in this lab. An unpinned tag can
# silently jump major versions on a routine `docker compose pull`, with no PR, no
# changelog review, and no rollback record — the exact failure mode ADR-0030 (k3s)
# already guards against. This file asserts neither service ever regresses back to
# `:latest`, mirroring tests/argocd-chart-pin.bats's exact-pin assertion pattern.
# The `gitlab-tls` nginx sidecar this file used to also cover (added 2026-08-13
# for the same floating-tag gap on its own `1.27-alpine` minor-version pin) was
# removed 2026-09-06 (ADR-0041, observability stack removed with no replacement).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  COMPOSE="$REPO/gitlab/docker-compose.yml"
}

@test "gitlab service is pinned to an explicit version, not :latest" {
  run grep -F 'image: gitlab/gitlab-ce:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" != *':latest'* ]]
}

@test "gitlab-runner service is pinned to an explicit version, not :latest" {
  run grep -F 'image: gitlab/gitlab-runner:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" != *':latest'* ]]
}

@test "gitlab service is pinned to 19.2.2-ce.0 (15 real security fixes over 19.2.1)" {
  run grep -F 'image: gitlab/gitlab-ce:19.2.2-ce.0' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "gitlab service is not pinned to the superseded 19.2.1-ce.0 tag" {
  run grep -F 'image: gitlab/gitlab-ce:19.2.1-ce.0' "$COMPOSE"
  [ "$status" -eq 1 ]
}

@test "gitlab-runner service is pinned to v19.2.2 (version parity with the gitlab-ce pin)" {
  run grep -F 'image: gitlab/gitlab-runner:v19.2.2' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "gitlab-runner service is not pinned to the superseded v19.2.1 tag" {
  run grep -F 'image: gitlab/gitlab-runner:v19.2.1' "$COMPOSE"
  [ "$status" -eq 1 ]
}

@test "gitlab-tls service no longer exists (ADR-0041)" {
  run grep -q 'gitlab-tls:' "$COMPOSE"
  [ "$status" -ne 0 ]
}
