terraform {
  required_version = ">= 1.5"
  required_providers {
    forgejo = {
      source  = "svalabs/forgejo"
      version = "~> 1.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "forgejo_organization" "lab" {
  name       = var.org_name
  visibility = "private"
}

resource "forgejo_repository" "gitops" {
  owner       = forgejo_organization.lab.name
  name        = var.project_name
  description = "k8s-lab GitOps monorepo — synced into the cluster by ArgoCD"
  private     = true
  auto_init   = false
}

# Mirrors the branch-protection intent of the module ADR-0035 supersedes (see that
# ADR's own predecessor: it force-allowed pushes on `main` because its git host
# protects `main` out of the box by default). Forgejo starts from the opposite
# default — repositories are NOT protected until a protection resource is created for
# them — so this resource ADDS a policy rather than relaxing one. It exists here, with
# every optional argument left at its provider default (no whitelist restrictions, no
# required approvals), purely so branch-protection resource coverage — this item's own
# explicit scope — is real. svalabs/terraform-provider-forgejo v1.5.0's schema
# (verified directly against its published docs) exposes no explicit "allow force
# push" toggle the way ADR-0033's predecessor module needed — do not assume parity
# with that prior default-restrictive behavior here.
resource "forgejo_branch_protection" "main" {
  repository_id = forgejo_repository.gitops.id
  branch_name   = "main"
}

# Password for the argocd-ro bot account below. Never reused after user creation —
# the credential ArgoCD actually clones with is the personal access token further
# down, not this password. Generated rather than threaded in from a variable so this
# module stays self-contained, the same way the module ADR-0035 supersedes generated
# its own project-scoped deploy-token secret server-side without the caller supplying
# one.
resource "random_password" "argocd_bot" {
  length  = 32
  special = false
}

# Dedicated bot user to hold the read-only deploy credential. svalabs/terraform-
# provider-forgejo has no project-scoped "deploy token" resource the way ADR-0033's
# predecessor module's provider did; its `forgejo_deploy_key` resource is an SSH
# public key (used for SSH read/write), not the HTTP-basic-usable secret ArgoCD's
# git-over-HTTP repository credential needs (the same shape that predecessor's deploy
# token provided). `forgejo_personal_access_token` is the closest equivalent, but a
# PAT belongs to a user account — so a minimal, restricted bot user stands in for that
# prior project-scoped deploy token.
resource "forgejo_user" "argocd" {
  login                      = "argocd-ro"
  email                      = "argocd-ro@localhost.localdomain"
  password                   = random_password.argocd_bot.result
  full_name                  = "ArgoCD (read-only repo clone)"
  must_change_password       = false
  restricted                 = true
  allow_create_organization  = false
  send_notify                = false
}

resource "forgejo_collaborator" "argocd_ro" {
  repository_id = forgejo_repository.gitops.id
  user          = forgejo_user.argocd.login
  permission    = "read"
}

# Per svalabs/terraform-provider-forgejo's own documented upstream limitation ("Due to
# an upstream limitation, one cannot create access tokens when authorized with access
# tokens. Use basic-auth instead."), the `forgejo` provider block each
# infra/live/*/forgejo/terragrunt.hcl generates for this module MUST authenticate via
# host+username+password (the FORGEJO_USERNAME/FORGEJO_PASSWORD env vars the provider
# itself reads), not api_token, or this resource fails to apply.
resource "forgejo_personal_access_token" "argocd" {
  user   = forgejo_user.argocd.login
  name   = "argocd-read"
  scopes = ["read:repository"]
}
