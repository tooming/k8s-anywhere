variable "group_path" {
  type        = string
  default     = "lab"
  description = "GitLab group that holds the lab project"
}

variable "project_name" {
  type        = string
  default     = "k8s-lab"
  description = "GitLab project name (the GitOps monorepo)"
}

variable "repo_url_in_cluster" {
  type        = string
  default     = "http://host.k3d.internal:8929/lab/k8s-lab.git"
  description = "Repo URL as reachable from inside the cluster (used by ArgoCD)"
}

variable "argocd_namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace where the ArgoCD repository Secret is created"
}
