terraform {
  required_version = ">= 1.5"
  required_providers {
    forgejo = {
      source  = "svalabs/forgejo"
      version = "~> 1.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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
# explicit scope — is real. svalabs/terraform-provider-forgejo v1.5.2's schema
# (verified directly against its actual published resources, not just its docs site —
# a v1.5.0-pinned first attempt at this module cited a "personal_access_token"
# resource that turned out to exist only on the provider's unreleased main branch,
# caught by CI's live `terraform init` against the real registry, not by this
# clusterless session) exposes no explicit "allow force push" toggle the way
# ADR-0033's predecessor module needed — do not assume parity with that prior
# default-restrictive behavior here.
resource "forgejo_branch_protection" "main" {
  repository_id = forgejo_repository.gitops.id
  branch_name   = "main"
}

# Read-only deploy credential ArgoCD will use to clone this repo (a later ROADMAP
# item wires it into ArgoCD's actual repository-credential Secret — this module does
# not touch the cluster). svalabs/terraform-provider-forgejo v1.5.2 (the latest
# actually published version — verified against its real release tags, not assumed)
# has no HTTP-token-based deploy credential resource; `forgejo_deploy_key` (SSH,
# repository-scoped) is what it actually ships, so this uses that instead of the
# HTTP deploy token the module ADR-0035 supersedes had. Repository-scoped is the
# same shape that predecessor's deploy token had, even though the transport differs
# (SSH key vs. HTTP basic-auth token) — ArgoCD supports SSH repository credentials
# natively (`sshPrivateKey` on the repo Secret), so this is a usable substitute, not
# a downgrade.
resource "tls_private_key" "argocd_deploy" {
  algorithm = "ED25519"
}

resource "forgejo_deploy_key" "argocd" {
  repository_id = forgejo_repository.gitops.id
  title         = "argocd-read"
  key           = trimspace(tls_private_key.argocd_deploy.public_key_openssh)
  read_only     = true
}
