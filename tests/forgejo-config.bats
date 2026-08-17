#!/usr/bin/env bats
# ROADMAP "GitLab → Forgejo migration" item 2: infra/modules/forgejo-config must
# provide org/repo/branch-protection/deploy-token resource coverage via
# svalabs/terraform-provider-forgejo, with a Terragrunt live unit for both backends
# (parallels the predecessor module's own coverage, ADR-0035). Clusterless,
# structural — mirrors tests/argocd-chart-pin.bats's file-content-assertion pattern;
# no live Forgejo instance is needed to confirm the module declares the right
# resources and both live units point at it.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  MAIN="$REPO/infra/modules/forgejo-config/main.tf"
  VARS="$REPO/infra/modules/forgejo-config/variables.tf"
  OUTPUTS="$REPO/infra/modules/forgejo-config/outputs.tf"
  LOCAL_TG="$REPO/infra/live/local/forgejo/terragrunt.hcl"
  ORACLE_TG="$REPO/infra/live/oracle/forgejo/terragrunt.hcl"
}

@test "forgejo-config module files exist" {
  [ -f "$MAIN" ]
  [ -f "$VARS" ]
  [ -f "$OUTPUTS" ]
}

@test "forgejo-config declares the svalabs/forgejo provider" {
  grep -q 'source  = "svalabs/forgejo"' "$MAIN"
}

@test "forgejo-config declares org/repo/branch-protection/deploy-token resource coverage" {
  grep -q 'resource "forgejo_organization" "lab"' "$MAIN"
  grep -q 'resource "forgejo_repository" "gitops"' "$MAIN"
  grep -q 'resource "forgejo_branch_protection" "main"' "$MAIN"
  grep -q 'resource "forgejo_deploy_key" "argocd"' "$MAIN"
}

@test "forgejo-config deploy key is read-only and repository-scoped" {
  run sed -n '/^resource "forgejo_deploy_key" "argocd" {/,/^}/p' "$MAIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"repository_id = forgejo_repository.gitops.id"* ]]
  [[ "$output" == *"read_only     = true"* ]]
}

@test "forgejo-config repository is private" {
  run sed -n '/^resource "forgejo_repository" "gitops" {/,/^}/p' "$MAIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"private     = true"* ]]
}

@test "forgejo-config declares the kubernetes provider and the ArgoCD repo-credential Secret" {
  grep -q 'source  = "hashicorp/kubernetes"' "$MAIN"
  grep -q 'resource "kubernetes_secret" "argocd_repo"' "$MAIN"
}

@test "forgejo-config repo-credential Secret is SSH-keyed, additive, and does not touch any live Application" {
  run sed -n '/^resource "kubernetes_secret" "argocd_repo" {/,/^}/p' "$MAIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *'name      = "repo-forgejo-gitops"'* ]]
  [[ "$output" == *'"argocd.argoproj.io/secret-type" = "repository"'* ]]
  [[ "$output" == *"sshPrivateKey"* ]]
  # Not the predecessor's Secret name — this is additive, never a replacement.
  [[ "$output" != *"repo-gitlab-gitops"* ]]
}

@test "forgejo-config: every gitops/**/*.yaml Application repoURL points at Forgejo" {
  # The repoURL flip landed 2026-08-17 (ROADMAP "GitLab -> Forgejo migration" item 4,
  # PR #1205) — this now asserts the opposite of what it did pre-flip: no gitops
  # manifest should still reference the old GitLab HTTP repoURL.
  ! grep -rq "host.k3d.internal:8929" "$REPO/gitops/"
  grep -rq "host.k3d.internal:2223" "$REPO/gitops/"
}

@test "forgejo-config variables declare argocd_namespace and repo_url_in_cluster" {
  grep -q 'variable "argocd_namespace"' "$VARS"
  grep -q 'variable "repo_url_in_cluster"' "$VARS"
  grep -q 'default     = "ssh://git@host.k3d.internal:2223/lab/k8s-lab.git"' "$VARS"
}

@test "forgejo-config main.tf does not name the rejected git host (ADR-0035 guard parity)" {
  ! grep -qi 'gitlab' "$MAIN"
}

@test "local and oracle forgejo terragrunt units both source infra/modules/forgejo-config" {
  grep -q 'source = "\${get_repo_root()}/infra/modules/forgejo-config"' "$LOCAL_TG"
  grep -q 'source = "\${get_repo_root()}/infra/modules/forgejo-config"' "$ORACLE_TG"
}

@test "local and oracle forgejo terragrunt units point at the compose stack's host port 3300" {
  grep -q 'host = "http://localhost:3300"' "$LOCAL_TG"
  grep -q 'host = "http://localhost:3300"' "$ORACLE_TG"
}

@test "forgejo terragrunt units include the shared root config" {
  grep -q 'find_in_parent_folders("root.hcl")' "$LOCAL_TG"
  grep -q 'find_in_parent_folders("root.hcl")' "$ORACLE_TG"
}

@test "forgejo terragrunt units declare a cluster dependency and the kubernetes provider" {
  grep -q 'dependency "cluster"' "$LOCAL_TG"
  grep -q 'dependency "cluster"' "$ORACLE_TG"
  grep -q 'provider "kubernetes"' "$LOCAL_TG"
  grep -q 'provider "kubernetes"' "$ORACLE_TG"
}
