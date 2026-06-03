#!/usr/bin/env bats
# Clusterless checks for the capstone pipeline (steps 1–2):
# step 1: GitLab CI → Artifactory build+push
# step 2: ArgoCD Application deploying the pipeline-built image
# These assert structural wiring is internally consistent — CI file, no plaintext
# creds, Vault path seeded, ESO ExternalSecret in dockerconfigjson form, and the
# ArgoCD Application targeting gitops/apps/capstone.

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

@test "artifactory-registry ExternalSecret uses dockerconfigjson template" {
  run grep -q 'kubernetes.io/dockerconfigjson' "$REPO/gitops/secrets/artifactory-registry-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- Step 2: ArgoCD Application for the capstone app ---------------------------

@test "capstone ArgoCD Application exists in gitops/platform/" {
  [ -f "$REPO/gitops/platform/capstone.yaml" ]
}

@test "capstone Application has automated sync (auto-synced is fine; workload is light)" {
  run grep -q 'automated:' "$REPO/gitops/platform/capstone.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Application sources gitops/apps/capstone" {
  run grep -q 'path: gitops/apps/capstone' "$REPO/gitops/platform/capstone.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment exists in gitops/apps/capstone/" {
  [ -f "$REPO/gitops/apps/capstone/deployment.yaml" ]
}

@test "capstone Deployment pulls from the Artifactory docker-local registry" {
  run grep -q 'artifactory.127.0.0.1.nip.io/docker-local/hello' "$REPO/gitops/apps/capstone/deployment.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment references artifactory-registry imagePullSecret" {
  run grep -q 'artifactory-registry' "$REPO/gitops/apps/capstone/deployment.yaml"
  [ "$status" -eq 0 ]
}

# --- Step 3: Envoy HTTPRoute for the capstone app ---------------------------

@test "capstone HTTPRoute exists in gitops/apps/capstone/" {
  [ -f "$REPO/gitops/apps/capstone/route.yaml" ]
}

@test "capstone HTTPRoute is kind HTTPRoute" {
  run grep -q 'kind: HTTPRoute' "$REPO/gitops/apps/capstone/route.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone HTTPRoute declares capstone.127.0.0.1.nip.io hostname" {
  run grep -q 'capstone\.127\.0\.0\.1\.nip\.io' "$REPO/gitops/apps/capstone/route.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone HTTPRoute targets the capstone Service on port 8080" {
  run grep -q '8080' "$REPO/gitops/apps/capstone/route.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone HTTPRoute uses the eg gateway in lab-gateway namespace" {
  run grep -q 'namespace: lab-gateway' "$REPO/gitops/apps/capstone/route.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone.127.0.0.1.nip.io appears in the Grafana Lab UIs panel" {
  run grep -q 'capstone\.127\.0\.0\.1\.nip\.io' "$REPO/grafana/dashboards/stack-health.json"
  [ "$status" -eq 0 ]
}

# --- Step 4: Grafana dashboard for the capstone app ---------------------------

@test "lab-capstone.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-capstone.json" ]
}

@test "lab-capstone.json has uid lab-capstone" {
  run grep -q '"uid": "lab-capstone"' "$REPO/grafana/dashboards/lab-capstone.json"
  [ "$status" -eq 0 ]
}

@test "lab-capstone.json uses Mimir datasource for pod/container metrics" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-capstone.json"
  [ "$status" -eq 0 ]
}

@test "lab-capstone.json includes a Loki logs panel for namespace=capstone" {
  run grep -q '"uid": "loki"' "$REPO/grafana/dashboards/lab-capstone.json"
  [ "$status" -eq 0 ]
  run grep -q 'namespace.*capstone' "$REPO/grafana/dashboards/lab-capstone.json"
  [ "$status" -eq 0 ]
}

@test "lab-capstone.json includes a Tempo traces panel" {
  run grep -q '"uid": "tempo"' "$REPO/grafana/dashboards/lab-capstone.json"
  [ "$status" -eq 0 ]
}

@test "lab-capstone.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-capstone.json"
  [ "$status" -eq 1 ]
}

# --- Step 5: Vault secret + ExternalSecret for the capstone app ---------------

@test "capstone-app ExternalSecret exists in gitops/secrets/" {
  [ -f "$REPO/gitops/secrets/capstone-app-externalsecret.yaml" ]
}

@test "capstone-app ExternalSecret is kind ExternalSecret" {
  run grep -q 'kind: ExternalSecret' "$REPO/gitops/secrets/capstone-app-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-app ExternalSecret targets namespace capstone" {
  run grep -q 'namespace: capstone' "$REPO/gitops/secrets/capstone-app-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-app ExternalSecret pulls from vault key capstone/app" {
  run grep -q 'key: capstone/app' "$REPO/gitops/secrets/capstone-app-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-app ExternalSecret renders Secret named capstone-app-creds" {
  run grep -q 'name: capstone-app-creds' "$REPO/gitops/secrets/capstone-app-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-bootstrap.sh seeds secret/capstone/app" {
  run grep -q 'secret/capstone/app' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment injects APP_KEY from capstone-app-creds secret" {
  run grep -q 'capstone-app-creds' "$REPO/gitops/apps/capstone/deployment.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'APP_KEY' "$REPO/gitops/apps/capstone/deployment.yaml"
  [ "$status" -eq 0 ]
}
