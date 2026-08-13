variable "chart_version" {
  type        = string
  default     = "10.3.3"
  description = "argo-cd Helm chart version (10.3.3 => ArgoCD v3.5.1)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
