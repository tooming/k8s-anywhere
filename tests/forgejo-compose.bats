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
  run grep -F 'image: code.forgejo.org/forgejo/forgejo:' "$COMPOSE"
  [ "$status" -eq 0 ]
  [[ "$output" != *':latest'* ]]
}

@test "forgejo service is pinned to 16.0.2" {
  run grep -F 'image: code.forgejo.org/forgejo/forgejo:16.0.2' "$COMPOSE"
  [ "$status" -eq 0 ]
}

@test "forgejo service uses code.forgejo.org, not codeberg.org (2026-09-06: codeberg.org registry unreachable from the Colima VM)" {
  run grep -F 'image: codeberg.org/forgejo/forgejo:' "$COMPOSE"
  [ "$status" -eq 1 ]
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
  # A fixed -A<N> line count here was bumped three times (60 -> 70 -> 80) as
  # explanatory comments accumulated above `healthcheck:` (most recently the
  # 2026-09-06 codeberg.org-registry-swap comment pushed it past 80) — switched
  # to an awk range bounded by the *next* top-level service key instead, so this
  # can never go stale again regardless of how many comment lines land above it.
  run awk '/^  forgejo:/,/^  forgejo-runner:/' "$COMPOSE"
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

@test "forgejo-runner-ensure.sh exists and is executable" {
  [ -x "$REPO/scripts/forgejo-runner-ensure.sh" ]
}

@test "forgejo-runner-ensure.sh reads FORGEJO_ADMIN_PASSWORD from forgejo/.env, not a hardcoded credential" {
  run grep -q "forgejo/.env" "$REPO/scripts/forgejo-runner-ensure.sh"
  [ "$status" -eq 0 ]
  run grep -q "FORGEJO_ADMIN_PASSWORD" "$REPO/scripts/forgejo-runner-ensure.sh"
  [ "$status" -eq 0 ]
}

@test "forgejo-runner-ensure.sh fetches the registration token with GET, not POST (405 Method Not Allowed regression guard, found live 2026-08-13)" {
  run grep -q -- '-X GET' "$REPO/scripts/forgejo-runner-ensure.sh"
  [ "$status" -eq 0 ]
  run grep -q -- '-X POST.*registration-token' "$REPO/scripts/forgejo-runner-ensure.sh"
  [ "$status" -eq 1 ]
}

@test "Makefile has forgejo-up and forgejo-down targets" {
  run grep -q '^forgejo-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  run grep -q '^forgejo-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "forgejo-harbor-secret-sync.sh exists and is executable" {
  [ -x "$REPO/scripts/forgejo-harbor-secret-sync.sh" ]
}

@test "forgejo-harbor-secret-sync.sh reads Harbor's live admin credential, not a hardcoded one" {
  run grep -q "harbor-admin-creds" "$REPO/scripts/forgejo-harbor-secret-sync.sh"
  [ "$status" -eq 0 ]
  run grep -q "HARBOR_ADMIN_USER" "$REPO/scripts/forgejo-harbor-secret-sync.sh"
  [ "$status" -eq 0 ]
  run grep -q "HARBOR_ADMIN_PASSWORD" "$REPO/scripts/forgejo-harbor-secret-sync.sh"
  [ "$status" -eq 0 ]
}

@test "forgejo-harbor-secret-sync.sh is best-effort (never hard-fails harbor-up on a sync miss)" {
  run grep -q '^set -uo pipefail' "$REPO/scripts/forgejo-harbor-secret-sync.sh"
  [ "$status" -eq 0 ]
  run grep -qE 'set -euo pipefail' "$REPO/scripts/forgejo-harbor-secret-sync.sh"
  [ "$status" -eq 1 ]
}

@test "Makefile's harbor-up runs forgejo-harbor-secret-sync (recurrence guard for #631/#633 credential drift)" {
  run grep -A5 '^harbor-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"forgejo-harbor-secret-sync"* ]]
}
