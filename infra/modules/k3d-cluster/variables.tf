variable "cluster_name" {
  type        = string
  description = "k3d cluster name (the kube context becomes k3d-<name>)"
}

variable "servers" {
  type        = number
  default     = 1
  description = "Number of k3s server (control-plane) nodes"
}

variable "agents" {
  type        = number
  default     = 1
  description = "Number of k3s agent (worker) nodes"
}

variable "api_port" {
  type        = number
  default     = 6445
  description = "Host port for the Kubernetes API server"
}

variable "http_port" {
  type        = number
  default     = 8080
  description = "Host port mapped to the k3d loadbalancer :80 (ingress via Traefik)"
}

variable "https_port" {
  type        = number
  default     = 8446
  description = "Host port mapped to the k3d loadbalancer :443 (ingress via Traefik). NOT 8443 — the DR frontdoor's HTTPS TCP passthrough (scripts/bluegreen-frontdoor.sh) owns that port as the stable, blue/green-independent entry point."
}

variable "disable_traefik" {
  type        = bool
  default     = false
  description = "Disable the bundled Traefik ingress. Kept as an escape hatch (e.g. a future alternate ingress experiment) but Traefik is now the lab's sole north-south ingress controller (ADR-0040, supersedes ADR-0008) — leave false."
}

variable "disable_default_cni" {
  type        = bool
  default     = false
  description = "Disable k3s's bundled Flannel CNI + NetworkPolicy controller (--flannel-backend=none --disable-network-policy). Per ADR-0014, set to true ONLY when the Cilium ArgoCD Application is also being landed in the same change — otherwise the cluster comes up with no CNI and pods stay in ContainerCreating."
}
