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
  grep -q 'resource "forgejo_personal_access_token" "argocd"' "$MAIN"
}

@test "forgejo-config repository is private" {
  run sed -n '/^resource "forgejo_repository" "gitops" {/,/^}/p' "$MAIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"private     = true"* ]]
}

@test "forgejo-config does not manage a kubernetes_secret (out of scope for this item)" {
  ! grep -q 'kubernetes_secret' "$MAIN"
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
