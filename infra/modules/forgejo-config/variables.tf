variable "org_name" {
  type        = string
  default     = "lab"
  description = "Forgejo organization that holds the lab project (parallels the predecessor module's group_path)"
}

variable "project_name" {
  type        = string
  default     = "k8s-lab"
  description = "Forgejo repository name (the GitOps monorepo)"
}

variable "argocd_namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace where the ArgoCD repository Secret is created (parallels the predecessor gitlab-config module's variable of the same name)"
}

variable "repo_url_in_cluster" {
  type        = string
  default     = "ssh://git@host.k3d.internal:2223/lab/k8s-lab.git"
  description = <<-EOT
    Repo URL as reachable from inside the cluster (used by ArgoCD). SSH, not HTTP,
    because forgejo_deploy_key (below) is an SSH key, not an HTTP token — the
    predecessor gitlab-config module's repo_url_in_cluster was http://host.k3d.internal:8929/...
    because gitlab_project_deploy_token is HTTP basic-auth; svalabs/terraform-provider-forgejo
    v1.5.2 has no HTTP-token-based deploy credential resource (see main.tf's
    forgejo_deploy_key comment), so this repo's ArgoCD credential is SSH instead. Port 2223
    matches forgejo/docker-compose.yml's GITEA__server__SSH_PORT / host port mapping.
    NOT yet consumed by any gitops/ Application repoURL — this variable only feeds the
    ArgoCD repository-credential Secret below; the ROADMAP "GitLab -> Forgejo migration"
    list's Application-repoURL flip is a separate, later, live-verified item (this one
    is deliberately additive/prep-only, no live-synced Application is repointed here).
  EOT
}
