variable "chart_version" {
  type        = string
  default     = "10.9.1"
  description = "argo-cd Helm chart version (10.9.1 => ArgoCD v3.5.3)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
