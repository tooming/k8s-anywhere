output "cluster_name" {
  value       = var.cluster_name
  description = "Name of the Oracle Cloud k3s cluster"
}

output "kube_context" {
  value       = "oracle-${var.cluster_name}"
  description = "kubectl context for this cluster, merged into ~/.kube/config by the kubeconfig null_resource"
}

output "api_endpoint" {
  value       = "https://${oci_core_instance.cluster.public_ip}:${var.api_port}"
  description = "Kubernetes API server endpoint"
}
