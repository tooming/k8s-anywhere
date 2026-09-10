variable "chart_version" {
  type        = string
  default     = "10.8.4"
  description = "argo-cd Helm chart version (10.8.4 => ArgoCD v3.5.2)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
