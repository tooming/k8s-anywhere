output "namespace" {
  value       = helm_release.argocd.namespace
  description = "Namespace ArgoCD is installed into"
}

output "release_name" {
  value       = helm_release.argocd.name
  description = "Helm release name"
}
