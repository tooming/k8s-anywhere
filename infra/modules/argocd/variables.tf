variable "chart_version" {
  type        = string
  default     = "10.2.1"
  description = "argo-cd Helm chart version (10.2.1 => ArgoCD v3.4.5)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
