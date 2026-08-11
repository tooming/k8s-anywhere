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
