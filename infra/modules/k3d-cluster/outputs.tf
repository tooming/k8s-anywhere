output "cluster_name" {
  value       = var.cluster_name
  description = "Name of the created k3d cluster"
}

output "kube_context" {
  value       = "k3d-${var.cluster_name}"
  description = "kubectl context for this cluster"
}

output "api_endpoint" {
  value       = "https://127.0.0.1:${var.api_port}"
  description = "Kubernetes API server endpoint"
}
