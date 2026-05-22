output "project_http_url" {
  value       = gitlab_project.gitops.http_url_to_repo
  description = "HTTP clone URL (host side, via localhost:8929)"
}

output "project_path_with_namespace" {
  value       = gitlab_project.gitops.path_with_namespace
  description = "e.g. lab/k8s-lab"
}

output "argocd_repo_secret" {
  value       = kubernetes_secret.argocd_repo.metadata[0].name
  description = "Name of the ArgoCD repository Secret"
}
