#!/usr/bin/env bats
# Clusterless checks for the capstone build pipeline (step 1: GitLab CI → Artifactory).
# These assert the structural wiring is internally consistent — the CI file exists,
# contains no plaintext credentials, the Vault path is seeded, and the ESO
# ExternalSecret is declared — so a mis-wired capstone step is caught before any
# live pipeline runs. No cluster needed.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- .gitlab-ci.yml exists and has the right shape ---------------------------
@test "gitlab-ci.yml exists at the repo root" {
  [ -f "$REPO/.gitlab-ci.yml" ]
}

@test "gitlab-ci.yml declares a build stage" {
  run grep -q '^stages:' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
  run grep -q 'build' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
}

@test "gitlab-ci.yml references ARTIFACTORY_USER and ARTIFACTORY_PASSWORD variables (no plaintext)" {
  run grep -q 'ARTIFACTORY_USER' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
  run grep -q 'ARTIFACTORY_PASSWORD' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
}

@test "gitlab-ci.yml contains no hardcoded credential values (no bare password: value)" {
  # Looks for password key followed immediately by a literal value (not a $VAR or flag).
  run grep -E '^\s*password:\s*[^$]' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 1 ]
}

# --- Dockerfile for the pipeline build --------------------------------------
@test "demo app Dockerfile exists for the capstone CI build" {
  [ -f "$REPO/gitops/apps/demo/Dockerfile" ]
}

@test "demo Dockerfile is based on the hotrod image" {
  run grep -q 'FROM jaegertracing/example-hotrod' "$REPO/gitops/apps/demo/Dockerfile"
  [ "$status" -eq 0 ]
}

# --- Vault seeding ----------------------------------------------------------
@test "vault-bootstrap.sh seeds secret/artifactory/registry" {
  run grep -q 'secret/artifactory/registry' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- ESO ExternalSecret for in-cluster imagePullSecret material -------------
@test "artifactory-registry ExternalSecret exists in gitops/secrets/" {
  [ -f "$REPO/gitops/secrets/artifactory-registry-externalsecret.yaml" ]
}

@test "artifactory-registry ExternalSecret pulls from vault key artifactory/registry" {
  run grep -q 'key: artifactory/registry' "$REPO/gitops/secrets/artifactory-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}
