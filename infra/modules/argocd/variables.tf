variable "chart_version" {
  type        = string
  default     = "9.5.15"
  description = "argo-cd Helm chart version (9.5.15 => ArgoCD v3.4.2)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
