terraform {
  required_version = ">= 1.5"
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

resource "gitlab_group" "lab" {
  name = var.group_path
  path = var.group_path
}

resource "gitlab_project" "gitops" {
  name                   = var.project_name
  namespace_id           = gitlab_group.lab.id
  visibility_level       = "private"
  description            = "k8s-lab GitOps monorepo — synced into the cluster by ArgoCD"
  initialize_with_readme = false
}

# Read-only token ArgoCD uses to clone the private repo.
resource "gitlab_project_deploy_token" "argocd" {
  project  = gitlab_project.gitops.id
  name     = "argocd-read"
  username = "argocd"
  scopes   = ["read_repository"]
}

# Register the repo + creds with ArgoCD. This is a bootstrap secret (it's how the
# GitOps engine authenticates to its source), so Terraform owning it is correct.
resource "kubernetes_secret" "argocd_repo" {
  metadata {
    name      = "repo-gitlab-gitops"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    type     = "git"
    url      = var.repo_url_in_cluster
    username = gitlab_project_deploy_token.argocd.username
    password = gitlab_project_deploy_token.argocd.token
  }
}
