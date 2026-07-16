#!/usr/bin/env bats
# Clusterless structural tests for the Harbor day-0 credential seam (RFC #297 / ADR-0024).
# Validates that vault-bootstrap.sh seeds both Vault paths, that the ESO ExternalSecret
# exists and references the correct keys, and that harbor.yaml references the rendered
# Secret — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- vault-bootstrap.sh — Harbor credential seeding --------------------------

@test "vault-bootstrap.sh seeds secret/harbor/admin (admin-user + admin-password)" {
  run grep -q "secret/harbor/admin" "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "vault-bootstrap.sh writes admin-user to secret/harbor/admin" {
  run grep "harbor/admin" "$REPO/scripts/vault-bootstrap.sh"
  [[ "$output" == *"admin-user="* ]]
}

@test "vault-bootstrap.sh writes admin-password to secret/harbor/admin (random hex)" {
  run grep "harbor/admin" "$REPO/scripts/vault-bootstrap.sh"
  [[ "$output" == *"admin-password="* ]]
  [[ "$output" == *"openssl rand -hex"* ]]
}

@test "vault-bootstrap.sh seeds secret/harbor/registry (username + password)" {
  run grep -q "secret/harbor/registry" "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "vault-bootstrap.sh idempotent for harbor/admin (kv get guard)" {
  run grep "harbor/admin" "$REPO/scripts/vault-bootstrap.sh"
  [[ "$output" == *"kv get secret/harbor/admin"* ]]
}

@test "vault-bootstrap.sh idempotent for harbor/registry (kv get guard)" {
  run grep "harbor/registry" "$REPO/scripts/vault-bootstrap.sh"
  [[ "$output" == *"kv get secret/harbor/registry"* ]]
}

# --- harbor-admin-externalsecret.yaml ----------------------------------------

@test "harbor-admin ExternalSecret manifest exists" {
  [ -f "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml" ]
}

@test "harbor-admin ExternalSecret is in the harbor namespace" {
  run grep -q 'namespace: harbor' "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-admin ExternalSecret renders Secret named harbor-admin-creds" {
  run grep -q 'name: harbor-admin-creds' "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-admin ExternalSecret exposes HARBOR_ADMIN_PASSWORD key" {
  run grep -q 'HARBOR_ADMIN_PASSWORD' "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-admin ExternalSecret exposes HARBOR_ADMIN_USER key" {
  run grep -q 'HARBOR_ADMIN_USER' "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-admin ExternalSecret reads from Vault path harbor/admin" {
  run grep -q 'key: harbor/admin' "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-admin ExternalSecret uses the vault ClusterSecretStore" {
  run grep -q 'name: vault' "$REPO/gitops/secrets/harbor-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- harbor.yaml — existingSecretAdminPassword reference ---------------------

@test "harbor.yaml references existingSecretAdminPassword (no hard-coded default)" {
  run grep -q 'existingSecretAdminPassword: harbor-admin-creds' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor.yaml references existingSecretAdminPasswordKey for HARBOR_ADMIN_PASSWORD" {
  run grep -q 'existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor.yaml does NOT contain hard-coded default password Harbor12345" {
  run grep -q 'Harbor12345' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -ne 0 ]
}

# --- harbor-registry-externalsecret.yaml (capstone imagePullSecret prep) -----
# Split-the-gate slice of auto/harbor-capstone-rewire (ROADMAP.md rule #9):
# additive-only, not yet referenced by any Deployment/Rollout imagePullSecrets,
# so it changes no running workload's behavior — the still-gated cutover item
# is what actually points capstone at it.

@test "harbor-registry ExternalSecret manifest exists" {
  [ -f "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml" ]
}

@test "harbor-registry ExternalSecret is in the capstone namespace" {
  run grep -q 'namespace: capstone' "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-registry ExternalSecret renders a dockerconfigjson Secret named harbor-registry" {
  run grep -q 'name: harbor-registry' "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'type: kubernetes.io/dockerconfigjson' "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-registry ExternalSecret targets harbor.127.0.0.1.nip.io in the dockerconfigjson auths" {
  run grep -q 'harbor.127.0.0.1.nip.io' "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-registry ExternalSecret reads from Vault path harbor/registry" {
  run grep -q 'key: harbor/registry' "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-registry ExternalSecret uses the vault ClusterSecretStore" {
  run grep -q 'name: vault' "$REPO/gitops/secrets/harbor-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-registry ExternalSecret is not yet referenced as an imagePullSecret anywhere (prep-only, still-gated cutover owns that wiring)" {
  run grep -rl 'name: harbor-registry' "$REPO/gitops/apps/capstone/"
  [ "$status" -ne 0 ]
}
