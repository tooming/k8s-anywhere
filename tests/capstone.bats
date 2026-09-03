#!/usr/bin/env bats
# Clusterless checks for the capstone pipeline (steps 1–2):
# step 1: GitLab CI → Harbor build+push
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

@test "gitlab-ci.yml references HARBOR_USER and HARBOR_PASSWORD variables (no plaintext)" {
  run grep -q 'HARBOR_USER' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
  run grep -q 'HARBOR_PASSWORD' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
}

@test "gitlab-ci.yml contains no hardcoded credential values (no bare password: value)" {
  # Looks for password key followed immediately by a literal value (not a $VAR or flag).
  run grep -E '^\s*password:\s*[^$]' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 1 ]
}

# The sign-image job only cosign-signs the $CI_COMMIT_SHORT_SHA tag, not :latest
# (which is what the deployed Deployment/Rollout actually reference) -- this
# relies on `docker tag` making :latest an alias for the exact same digest, so
# cosign's digest-based signature (and Kyverno's digest-based verifyImages
# check) covers both tags from one signing call. If build-and-push ever
# rebuilds :latest separately instead of tagging the already-built/pushed SHA
# image, that assumption breaks silently and :latest would deploy unsigned.
@test "build-and-push creates :latest via docker tag (same digest as the signed SHA tag), not a separate build" {
  run grep -q 'docker tag ' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
  # Only one docker build invocation should exist in the whole pipeline.
  run bash -c "grep -c 'docker build ' '$REPO/.gitlab-ci.yml'"
  [ "$output" = "1" ]
}

@test "sign-image signs the CI_COMMIT_SHORT_SHA tag (the digest both tags share)" {
  run grep -q 'cosign sign' "$REPO/.gitlab-ci.yml"
  [ "$status" -eq 0 ]
  run bash -c "awk '/^sign-image:/{flag=1} flag' '$REPO/.gitlab-ci.yml' | grep -q 'CI_COMMIT_SHORT_SHA'"
  [ "$status" -eq 0 ]
}

# --- retry_cmd wrapper (found live 2026-08-13, #631) --------------------------
# ~15 distinct pipeline failures this session were all transient network/Harbor
# errors (Docker Hub base-image i/o timeouts, occasional 502/504 from Harbor,
# `docker login` hitting the same "context deadline exceeded" class reaching
# Harbor's token endpoint) that cleared on a subsequent attempt. `retry_cmd`
# wraps each network-facing step in-job before GitLab's own `retry: 2` whole-job
# fallback kicks in. These fixes landed as direct live-verified commits (no PR,
# no bats coverage) — recurrence guard so a future edit can't silently drop the
# wrapper (or move its definition back to `script:`, which broke login coverage
# the first time this fix was written) with nothing catching it.
@test "build-and-push defines retry_cmd in before_script (not script, so login is covered too)" {
  run bash -c "awk '/^build-and-push:/{flag=1} flag && /^[a-z_-]+:$/ && !/^build-and-push:/{exit} flag' '$REPO/.gitlab-ci.yml' | grep -q 'before_script:'"
  [ "$status" -eq 0 ]
  run bash -c "awk '/^build-and-push:/{flag=1} /^  before_script:/{bs=1} /^  script:/{bs=0} bs' '$REPO/.gitlab-ci.yml' | grep -q 'retry_cmd()'"
  [ "$status" -eq 0 ]
}

@test "build-and-push wraps docker login, build, and both push commands in retry_cmd" {
  run bash -c "awk '/^build-and-push:/{flag=1} flag' '$REPO/.gitlab-ci.yml' | grep -c 'retry_cmd '"
  [ "$status" -eq 0 ]
  [ "$output" -ge 4 ]
  run bash -c "awk '/^build-and-push:/{flag=1} flag' '$REPO/.gitlab-ci.yml' | grep -q 'retry_cmd sh -c .*docker login'"
  [ "$status" -eq 0 ]
}

@test "build-and-push and sign-image both set retry: 2 as a whole-job fallback" {
  run bash -c "grep -c '^  retry: 2$' '$REPO/.gitlab-ci.yml'"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

# --- Dockerfile for the pipeline build --------------------------------------
@test "demo app Dockerfile exists for the capstone CI build" {
  [ -f "$REPO/gitops/apps/demo/Dockerfile" ]
}

# 2026-08-18: FROM now points at Harbor's own mirror of this image
# (${REGISTRY}/library/example-hotrod), not docker.io directly — see the
# Dockerfile's own comment and tests/forgejo-ci.bats' dedicated assertion for
# the full story (docker.io's auth-token endpoint was the one consistently-
# unreachable hop in the whole CI pipeline). These two tests just check the
# image identity survived the rehost, not the exact FROM line shape — that
# belongs to forgejo-ci.bats, which owns the CI-pipeline-specific assertion.
@test "demo Dockerfile is based on the hotrod image" {
  run grep -q 'example-hotrod' "$REPO/gitops/apps/demo/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "demo Dockerfile pins hotrod to 2.20.0, not a floating :latest tag (2026-07-28)" {
  run grep -q 'example-hotrod:2.20.0' "$REPO/gitops/apps/demo/Dockerfile"
  [ "$status" -eq 0 ]
  ! grep -q 'example-hotrod:latest' "$REPO/gitops/apps/demo/Dockerfile"
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

@test "capstone Deployment pulls from the Harbor library registry" {
  run grep -q 'harbor.127.0.0.1.nip.io/library/hello' "$REPO/gitops/apps/capstone/deployment.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment references harbor-registry imagePullSecret" {
  run grep -q 'harbor-registry' "$REPO/gitops/apps/capstone/deployment.yaml"
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

# --- O4 CI verify-rejection RBAC (issue #1229) ------------------------------
# The .forgejo/workflows/build-sign-push.yml verify-rejection job needs a
# KUBECONFIG scoped to create/delete Pod in capstone. Issue #1229 asked for a
# dedicated least-privilege ServiceAccount rather than a broad credential; this
# manifest is that. These assertions are the mechanical guard that a future edit
# can't silently drop it or broaden its scope (same silent-drop failure class
# that removed the verify-rejection job itself — PR #1402).

RBAC="gitops/apps/capstone/ci-verify-rejection-rbac.yaml"

@test "ci-verify-rejection RBAC manifest exists and is wired into the kustomization" {
  [ -f "$REPO/$RBAC" ]
  run grep -q 'ci-verify-rejection-rbac.yaml' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "ci-verify-rejection RBAC defines exactly a ServiceAccount, Role, and RoleBinding" {
  run grep -c '^kind: ' "$REPO/$RBAC"
  [ "$output" = "3" ]
  run grep -q '^kind: ServiceAccount' "$REPO/$RBAC"
  [ "$status" -eq 0 ]
  run grep -q '^kind: Role' "$REPO/$RBAC"
  [ "$status" -eq 0 ]
  run grep -q '^kind: RoleBinding' "$REPO/$RBAC"
  [ "$status" -eq 0 ]
}

@test "ci-verify-rejection RBAC is namespace-scoped to capstone (no ClusterRole/ClusterRoleBinding)" {
  run grep -qE '^kind: (ClusterRole|ClusterRoleBinding)' "$REPO/$RBAC"
  [ "$status" -ne 0 ]
  run grep -c 'namespace: capstone' "$REPO/$RBAC"
  [ "$output" = "4" ]
}

@test "ci-verify-rejection Role grants only pods verbs, nothing broader" {
  # The only resources: line is pods; no secrets/deployments/etc.
  run grep -E '^\s+resources:' "$REPO/$RBAC"
  [ "$output" = '    resources: ["pods"]' ]
  run grep -E '^\s+verbs:' "$REPO/$RBAC"
  [ "$output" = '    verbs: ["create", "delete", "get", "list"]' ]
}

@test "ci-verify-rejection ServiceAccount does not auto-mount its token" {
  run grep -q 'automountServiceAccountToken: false' "$REPO/$RBAC"
  [ "$status" -eq 0 ]
}

@test "verify-rejection kubeconfig runbook exists and is linked from the workflow header" {
  [ -f "$REPO/docs/runbooks/2026-09-04-ci-verify-rejection-kubeconfig.md" ]
  run grep -q 'docs/runbooks/2026-09-04-ci-verify-rejection-kubeconfig.md' "$REPO/.forgejo/workflows/build-sign-push.yml"
  [ "$status" -eq 0 ]
}
