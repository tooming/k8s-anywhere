variable "chart_version" {
  type        = string
  default     = "10.2.2"
  description = "argo-cd Helm chart version (10.2.2 => ArgoCD v3.4.6)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace ArgoCD is installed into"
}
