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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
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

# Read-only deploy credential ArgoCD will use to clone this repo (wired into ArgoCD's
# actual repository-credential Secret below). svalabs/terraform-provider-forgejo v1.5.2 (the latest
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

# Register the repo + creds with ArgoCD, parallel to the module ADR-0035 supersedes'
# own kubernetes_secret.argocd_repo resource — but under a DIFFERENT Secret name
# ("repo-forgejo-gitops", not that predecessor's "repo-<host>-gitops") so this is
# purely additive: no existing repository Secret is replaced, and no
# gitops/**/*.yaml Application's repoURL is touched by this module (grep confirms
# none currently reference this host/port). That predecessor's kubernetes_secret used
# a username/password (HTTP basic-auth) data pair; this one uses sshPrivateKey (SSH),
# matching the SSH-only deploy credential this module actually has (see
# forgejo_deploy_key's comment above).
# `insecure = "true"` is intended to skip ArgoCD's SSH known-hosts check for this repo,
# matching this lab's existing risk tolerance for other in-cluster-only endpoints (e.g.
# Harbor's TLS-disabled minimal profile, ADR-0024) — host.k3d.internal never leaves
# the Colima VM. VERIFIED 2026-08-27 (ADR-0004, no live cluster needed for this one —
# checked against ArgoCD's own published docs instead): argoproj/argo-cd's own
# `docs/operator-manual/argocd-repositories.yaml` reference example states the
# `insecure` field "does not validate the server's host key or TLS certificate" and
# uses it in BOTH its SSH and HTTPS repository examples — it is the current, unified
# field for this on ArgoCD's Repository type. The alternative this comment used to
# flag, `insecureIgnoreHostKey`, is real but deprecated in favor of `insecure` — using
# it here would have been a regression to the older field name, not a fix. This field
# name is confirmed correct as-is; no change needed.
#
# Deliberately NOT wired up yet: no live Application repoURL points at
# var.repo_url_in_cluster, so ArgoCD keeps syncing from the still-live predecessor git
# host exactly as before this resource exists. Flipping Applications' repoURL (and
# root-app.yaml's) to actually use this credential is a separate, later ROADMAP item —
# that flip needs a live cluster to verify a real sync (ADR-0004), which this remote
# clusterless session cannot do, so it stays split out (mirrors RFC #214's cosign
# make-up-wiring/ci-sign-step/enforce-flip split — this resource is the "wiring"
# slice, the repoURL flip is the later "enforce" slice).
resource "kubernetes_secret" "argocd_repo" {
  metadata {
    name      = "repo-forgejo-gitops"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    type          = "git"
    url           = var.repo_url_in_cluster
    sshPrivateKey = tls_private_key.argocd_deploy.private_key_openssh
    insecure      = "true"
  }
}
