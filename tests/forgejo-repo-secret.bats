#!/usr/bin/env bats
# Clusterless structural tests for scripts/forgejo-repo-secret.sh — the script that
# closes the fresh-cluster gap found live 2026-09-06: `root-app.yaml`'s repoURL
# (ssh://git@host.k3d.internal:2223/lab/k8s-lab.git, ADR-0035) needs a
# `repo-forgejo-gitops` Secret in the argocd namespace, but a freshly recreated k3d
# cluster (`make down && make up`) starts with no such Secret even though Forgejo
# itself (a separate, longer-lived docker-compose stack) already has org/repo/
# deploy-key state from a prior run. Without it, `root-app`'s first sync fails:
# "error creating SSH agent: SSH_AUTH_SOCK not-specified".
#
# No live cluster or Forgejo instance is needed to confirm the script exists, is
# idempotent by construction, and is wired into `make up` before `root-app` — mirrors
# tests/cosign-bootstrap.bats's structural-assertion pattern.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/forgejo-repo-secret.sh"
  MK="$REPO/Makefile"
}

# --- script presence and executability ---------------------------------------
@test "forgejo-repo-secret.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "forgejo-repo-secret.sh is executable" {
  [ -x "$SCRIPT" ]
}

@test "forgejo-repo-secret.sh passes shellcheck" {
  run shellcheck --severity=warning "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- targets the right repo, namespace, and Secret ---------------------------
@test "forgejo-repo-secret.sh targets the lab/k8s-lab repo" {
  grep -q 'ORG="lab"' "$SCRIPT"
  grep -q 'REPO_NAME="k8s-lab"' "$SCRIPT"
}

@test "forgejo-repo-secret.sh manages the repo-forgejo-gitops Secret in the argocd namespace" {
  grep -q 'NS=argocd' "$SCRIPT"
  grep -q 'SECRET_NAME=repo-forgejo-gitops' "$SCRIPT"
}

@test "forgejo-repo-secret.sh points the Secret at the Forgejo SSH repoURL" {
  grep -q 'ssh://git@host.k3d.internal:2223/\${ORG}/\${REPO_NAME}.git' "$SCRIPT"
}

@test "forgejo-repo-secret.sh Secret carries the ArgoCD repository-type label" {
  grep -q 'argocd.argoproj.io/secret-type: repository' "$SCRIPT"
}

@test "forgejo-repo-secret.sh Secret is git-typed with an sshPrivateKey field" {
  grep -q '^  type: git$' "$SCRIPT"
  grep -q 'sshPrivateKey: |' "$SCRIPT"
}

# --- idempotency: only regenerates when the current key isn't actually live -----
@test "forgejo-repo-secret.sh checks whether the existing Secret's key is still registered before regenerating" {
  grep -q 'still_valid' "$SCRIPT"
  grep -q 'ssh-keygen -y' "$SCRIPT"
}

@test "forgejo-repo-secret.sh exits early (no-op) when the existing key is still valid" {
  run sed -n '/if \[ -n "\$still_valid" \]; then/,/^fi$/p' "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"exit 0"* ]]
}

@test "forgejo-repo-secret.sh registers the new key and applies the Secret before deleting any prior key (safe ordering)" {
  register_line=$(grep -n "registering new deploy key" "$SCRIPT" | head -1 | cut -d: -f1)
  apply_line=$(grep -n 'kubectl apply -f -' "$SCRIPT" | tail -1 | cut -d: -f1)
  delete_line=$(grep -n 'api -X DELETE' "$SCRIPT" | tail -1 | cut -d: -f1)
  [ -n "$register_line" ] && [ -n "$apply_line" ] && [ -n "$delete_line" ]
  [ "$apply_line" -gt "$register_line" ]
  [ "$delete_line" -gt "$apply_line" ]
}

@test "forgejo-repo-secret.sh retries the kubectl apply against a transient apiserver failure" {
  grep -q 'retrying in' "$SCRIPT"
}

# --- org/repo creation is idempotent (only when actually missing) ------------
@test "forgejo-repo-secret.sh only creates the org/repo when a GET first reports them missing" {
  run sed -n '/org + repo exist/,/^fi$/p' "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"! api"* ]]
}

# --- credential source --------------------------------------------------------
@test "forgejo-repo-secret.sh reads FORGEJO_ADMIN_PASSWORD from forgejo/.env" {
  grep -q "FORGEJO_ADMIN_PASSWORD" "$SCRIPT"
  grep -q 'forgejo/.env\|ROOT/forgejo/.env\|ENV_FILE="\$ROOT/forgejo/.env"' "$SCRIPT"
}

# --- Makefile wiring -----------------------------------------------------------
@test "Makefile has a forgejo-repo-secret target" {
  run grep -q '^forgejo-repo-secret:' "$MK"
  [ "$status" -eq 0 ]
}

@test "make up calls forgejo-up before forgejo-repo-secret, and forgejo-repo-secret before root-app" {
  forgejo_up_line=$(grep -n 'MAKE) forgejo-up' "$MK" | head -1 | cut -d: -f1)
  secret_line=$(grep -n 'MAKE) forgejo-repo-secret' "$MK" | head -1 | cut -d: -f1)
  root_app_line=$(grep -n 'MAKE) root-app' "$MK" | head -1 | cut -d: -f1)
  [ -n "$forgejo_up_line" ] && [ -n "$secret_line" ] && [ -n "$root_app_line" ]
  [ "$secret_line" -gt "$forgejo_up_line" ]
  [ "$root_app_line" -gt "$secret_line" ]
}
