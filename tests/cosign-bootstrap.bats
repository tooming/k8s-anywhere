#!/usr/bin/env bats
# Clusterless structural tests for scripts/cosign-bootstrap.sh.
# ADR-0019 §"Cosign keypair management" — verifies script existence, executability,
# the cosign generate-key-pair invocation, keypair output path, ConfigMap wiring,
# and the --dry-run=client idempotency pattern. No cluster or cosign binary needed.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/cosign-bootstrap.sh"
  MK="$REPO/Makefile"
}

# --- script presence and executability ---------------------------------------
@test "cosign-bootstrap.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "cosign-bootstrap.sh is executable" {
  [ -x "$SCRIPT" ]
}

# --- cosign generate-key-pair invocation -------------------------------------
@test "cosign-bootstrap.sh invokes cosign generate-key-pair" {
  run grep -q 'cosign generate-key-pair' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- keypair output path -----------------------------------------------------
@test "cosign-bootstrap.sh generates keypair under infra/secrets/cosign/" {
  run grep -q 'infra/secrets/cosign' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- ConfigMap name and namespace --------------------------------------------
@test "cosign-bootstrap.sh creates ConfigMap named cosign-public-key" {
  run grep -q 'cosign-public-key' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "cosign-bootstrap.sh targets the kyverno namespace (NS=kyverno)" {
  run grep -q 'NS=kyverno' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- idempotency pattern (mirrors vault-bootstrap.sh + garage-bootstrap.sh) --
@test "cosign-bootstrap.sh uses --dry-run=client" {
  run grep -q '\-\-dry-run=client' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "cosign-bootstrap.sh pipes dry-run output to kubectl apply -f -" {
  run grep -q 'kubectl apply -f -' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- ConfigMap name matches verifyImages policy keyRef ----------------------
@test "verifyImages policy references cosign-public-key ConfigMap" {
  POLICY="$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  [ -f "$POLICY" ]
  run grep -q 'cosign-public-key' "$POLICY"
  [ "$status" -eq 0 ]
}

@test "verifyImages policy scopes to Harbor registry" {
  POLICY="$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  [ -f "$POLICY" ]
  run grep -q 'harbor.127.0.0.1.nip.io' "$POLICY"
  [ "$status" -eq 0 ]
}

# --- Makefile wiring (RFC #214 Item 1) ----------------------------------------

@test "Makefile has a cosign-bootstrap target" {
  run grep -q '^cosign-bootstrap:' "$MK"
  [ "$status" -eq 0 ]
}

@test "make up calls cosign-bootstrap after garage-bootstrap" {
  garage_line=$(grep -n 'MAKE) garage-bootstrap' "$MK" | head -1 | cut -d: -f1)
  cosign_line=$(grep -n 'MAKE) cosign-bootstrap' "$MK" | head -1 | cut -d: -f1)
  [ -n "$garage_line" ] && [ -n "$cosign_line" ]
  [ "$cosign_line" -gt "$garage_line" ]
}

# --- .gitlab-ci.yml sign stage (RFC #214 Item 2) ------------------------------

setup_ci() {
  CI_FILE="$REPO/.gitlab-ci.yml"
}

@test ".gitlab-ci.yml exists" {
  setup_ci
  [ -f "$CI_FILE" ]
}

@test ".gitlab-ci.yml declares a 'sign' stage" {
  setup_ci
  run grep -q '^\s*- sign$' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test ".gitlab-ci.yml has a sign-image job" {
  setup_ci
  run grep -q '^sign-image:' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "sign-image job uses a digest-pinned bitnami/cosign image (2026-07-28: bitnami/cosign:2 no longer exists)" {
  setup_ci
  run grep -q 'bitnami/cosign@sha256:' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "build-and-push job and its dind service use the actively-maintained docker:29 line (2026-07-28: docker:24 confirmed 2yr stale)" {
  setup_ci
  run grep -q '^\s*image: docker:29$' "$CI_FILE"
  [ "$status" -eq 0 ]
  run grep -q 'name: docker:29-dind' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "sign-image job disables Rekor (COSIGN_EXPERIMENTAL: \"0\")" {
  setup_ci
  run grep -q 'COSIGN_EXPERIMENTAL.*"0"' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "sign-image job uses --allow-insecure-registry (HTTP Artifactory route)" {
  setup_ci
  run grep -q '\-\-allow-insecure-registry' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "sign-image job signs the short-SHA tagged image" {
  setup_ci
  run grep -q 'CI_COMMIT_SHORT_SHA' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "sign-image job needs build-and-push" {
  setup_ci
  run grep -q 'build-and-push' "$CI_FILE"
  [ "$status" -eq 0 ]
}

@test "sign-image job cleans up /tmp/cosign in after_script" {
  setup_ci
  run grep -q 'rm -rf /tmp/cosign' "$CI_FILE"
  [ "$status" -eq 0 ]
}
