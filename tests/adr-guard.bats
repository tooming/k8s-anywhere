#!/usr/bin/env bats
# Unit tests for scripts/adr-guard-hook.sh — the PostToolUse hook that
# rejects edits that reintroduce a technology an ADR named *-not-<rejected>*
# has ruled out (e.g. ADR-0002: Garage NOT MinIO).
# No cluster needed: the hook reads a JSON payload from stdin, checks the
# named file, and exits 0 (clean) or 2 (rejection found).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # .yaml in a neutral tmpdir — matches the *.yaml guard but has no rejected term
  CLEAN="$BATS_TEST_TMPDIR/clean.yaml"
  printf 'kind: Deployment\nspec:\n  template:\n    spec:\n      image: nginx:alpine\n' >"$CLEAN"
  # .yaml containing "minio" — rejected by ADR-0002
  DIRTY="$BATS_TEST_TMPDIR/dirty.yaml"
  printf 'kind: Deployment\nspec:\n  template:\n    spec:\n      image: minio/minio:latest\n' >"$DIRTY"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "adr-guard: empty JSON payload exits 0" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "adr-guard: docs/ path is excluded even when file mentions a rejected term" {
  # docs/platform-products.md discusses MinIO by name; the guard must stay silent.
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$REPO/docs/platform-products.md")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: path with no guarded extension or directory exits 0" {
  # A plain file that is neither *.yaml/yml/tf/hcl nor under infra/gitops/scripts.
  PLAIN="$BATS_TEST_TMPDIR/note"
  printf 'minio reference\n' >"$PLAIN"
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$PLAIN")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: clean yaml file exits 0" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$CLEAN")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: yaml containing rejected term exits 2" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$DIRTY")"
  [ "$status" -eq 2 ]
}

@test "adr-guard: rejection message names the rejected term" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$DIRTY")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"minio"* ]]
}

@test "adr-guard: rejection message names the ADR that enforces the ban" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$DIRTY")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"adr-0002"* ]]
}

# --- Supersession-aware behavior (ADR-0040 supersedes ADR-0008, reversing it) -------
#
# ADR-0008 is "envoy-gateway-not-traefik" (chosen=envoy-gateway, rejected=traefik) and
# its Status line says "Superseded by [ADR-0040]". ADR-0040 is
# "traefik-not-envoy-gateway" (chosen=traefik, rejected=envoy-gateway) — the exact
# same pair, flipped. So ADR-0008's "traefik" rejection must no longer fire, and
# ADR-0040's own "-not-" filename must now flag "envoy-gateway" instead (self-
# maintaining — no extra code needed for that half).

@test "adr-guard: reversed rejection (traefik, ADR-0008 superseded by ADR-0040) no longer fires" {
  TRAEFIK="$BATS_TEST_TMPDIR/traefik.yaml"
  printf 'kind: Deployment\nspec:\n  ingressClassName: traefik\n' >"$TRAEFIK"
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$TRAEFIK")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: the supersession's own rejection (envoy-gateway, ADR-0040) still fires" {
  ENVOY="$BATS_TEST_TMPDIR/envoy.yaml"
  printf 'kind: Deployment\nspec:\n  gatewayClassName: envoy-gateway\n' >"$ENVOY"
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$ENVOY")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"envoy-gateway"* ]]
  [[ "$output" == *"adr-0040"* ]]
}

@test "adr-guard: a chain supersession that does not flip the pair still rejects the original term" {
  # ADR-0011 (artifactory-not-nexus) is superseded by ADR-0024 (harbor-not-artifactory):
  # the comparison moved on to a different tech, it didn't reverse artifactory-vs-nexus.
  # "nexus" must still be rejected.
  NEXUS="$BATS_TEST_TMPDIR/nexus.yaml"
  printf 'kind: Deployment\nspec:\n  image: nexus:latest\n' >"$NEXUS"
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$NEXUS")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"nexus"* ]]
  [[ "$output" == *"adr-0011"* ]]
}
