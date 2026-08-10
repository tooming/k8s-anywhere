#!/usr/bin/env bats
# ADR-0035 migration stage 1: forgejo/docker-compose.yml stands up Forgejo + its
# runner alongside the still-live GitLab stack. Mirrors tests/gitlab-compose.bats'
# exact-pin assertion pattern (ADR-0030's precedent: never regress to a floating tag,
# which for GitLab meant `:latest` — Forgejo doesn't even publish that tag, so here
# the guard is just "pinned to a real version", i.e. not empty / not a git ref).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  COMPOSE="$REPO/forgejo/docker-compose.yml"
}

@test "forgejo/docker-compose.yml exists" {
  [ -f "$COMPOSE" ]
}

@test "forgejo service is pinned to an explicit version" {
  run grep -F 'image: codeberg.org/forgejo/forgejo:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" != *':latest'* ]]
}

@test "forgejo service is pinned to 16.0.2" {
  run grep -F 'image: codeberg.org/forgejo/forgejo:16.0.2' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "forgejo-runner service is pinned to an explicit version" {
  run grep -F 'image: code.forgejo.org/forgejo/runner:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" != *':latest'* ]]
}

@test "forgejo-runner service is pinned to 13.0.0" {
  run grep -F 'image: code.forgejo.org/forgejo/runner:13.0.0' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "forgejo service uses a distinct host port from GitLab's 8929" {
  run grep -F '"3300:3000"' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "forgejo service defines a healthcheck (image ships none of its own)" {
  run grep -A40 '^  forgejo:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"healthcheck:"* ]]
}

@test "forgejo-runner depends on forgejo being healthy, not just started" {
  run grep -A7 '^  forgejo-runner:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"condition: service_healthy"* ]]
}

@test "forgejo data volume is a named volume, not a bind mount (Colima virtiofs setgid bug precedent)" {
  run grep -F 'forgejo_data:/data' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "forgejo-env-ensure.sh exists and is executable" {
  [ -x "$REPO/scripts/forgejo-env-ensure.sh" ]
}

@test "forgejo-admin-ensure.sh exists and is executable" {
  [ -x "$REPO/scripts/forgejo-admin-ensure.sh" ]
}

@test "Makefile has forgejo-up and forgejo-down targets" {
  run grep -q '^forgejo-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  run grep -q '^forgejo-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}
