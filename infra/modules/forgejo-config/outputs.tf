output "repo_clone_url" {
  value       = forgejo_repository.gitops.clone_url
  description = "HTTP clone URL (host side, via localhost:3300)"
}

output "repo_ssh_url" {
  value       = forgejo_repository.gitops.ssh_url
  description = "SSH clone URL — what the deploy key below is scoped to"
}

output "repo_full_name" {
  value       = forgejo_repository.gitops.full_name
  description = "e.g. lab/k8s-lab"
}

output "argocd_deploy_private_key" {
  value       = tls_private_key.argocd_deploy.private_key_openssh
  sensitive   = true
  description = "SSH private key paired with the read-only deploy key registered on the repository. A future ROADMAP item consumes this to build ArgoCD's repository-credential Secret — this module does not touch the cluster itself."
}
