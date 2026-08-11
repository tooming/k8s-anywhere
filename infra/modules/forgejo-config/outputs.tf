output "repo_clone_url" {
  value       = forgejo_repository.gitops.clone_url
  description = "HTTP clone URL (host side, via localhost:3300)"
}

output "repo_full_name" {
  value       = forgejo_repository.gitops.full_name
  description = "e.g. lab/k8s-lab"
}

output "argocd_username" {
  value       = forgejo_user.argocd.login
  description = "Username the read-only personal access token below belongs to (paired as HTTP basic-auth credentials)"
}

output "argocd_read_token" {
  value       = forgejo_personal_access_token.argocd.token
  sensitive   = true
  description = "Read-only personal access token for the argocd-ro user. A future ROADMAP item consumes this to build ArgoCD's repository-credential Secret and re-point Applications at this remote — this module does not touch the cluster itself."
}
