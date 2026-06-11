variable "chart_version" {
  type        = string
  default     = "9.5.20"
  description = "argo-cd Helm chart version (9.5.20 => ArgoCD v3.4.3)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
