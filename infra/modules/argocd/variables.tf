variable "chart_version" {
  type        = string
  default     = "9.7.1"
  description = "argo-cd Helm chart version (9.7.1 => ArgoCD v3.4.4)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
