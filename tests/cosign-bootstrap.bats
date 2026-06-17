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

# --- ConfigMap name matches verifyImages policy keyRef (conditional) ---------
@test "verifyImages policy references cosign-public-key ConfigMap (if policy exists)" {
  POLICY="$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  if [ ! -f "$POLICY" ]; then
    skip "verify-image-signatures.yaml not yet on branch — pending kyverno-policies PR merge"
  fi
  run grep -q 'cosign-public-key' "$POLICY"
  [ "$status" -eq 0 ]
}

@test "verifyImages policy scopes to artifactory registry (if policy exists)" {
  POLICY="$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  if [ ! -f "$POLICY" ]; then
    skip "verify-image-signatures.yaml not yet on branch — pending kyverno-policies PR merge"
  fi
  run grep -q 'artifactory.127.0.0.1.nip.io' "$POLICY"
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
