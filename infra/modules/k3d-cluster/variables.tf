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
  description = "Host port mapped to the k3d loadbalancer :80 (ingress via Envoy)"
}

variable "https_port" {
  type        = number
  default     = 8443
  description = "Host port mapped to the k3d loadbalancer :443 (ingress via Envoy)"
}

variable "disable_traefik" {
  type        = bool
  default     = true
  description = "Disable the bundled Traefik ingress — we use Envoy Gateway instead"
}
