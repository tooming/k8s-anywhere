variable "cluster_name" {
  type        = string
  description = "Cluster name (the kube context becomes oracle-<name>); also used for the instance display name and hostname label."
}

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the OCI tenancy (root compartment) — needed to look up the availability domain."
}

variable "compartment_id" {
  type        = string
  description = "OCID of the compartment to create the VCN/subnet/instance in."
}

variable "availability_domain_number" {
  type        = number
  default     = 1
  description = "Which availability domain (1-indexed) to place the instance in. Always Free Ampere A1 capacity varies by AD; retry with a different number if OCI reports out-of-capacity."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key installed on the instance (metadata.ssh_authorized_keys) — required to reach it for the kubeconfig retrieval step."
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key matching ssh_public_key, used locally to scp the k3s kubeconfig off the instance after cloud-init completes."
}

variable "ocpus" {
  type        = number
  default     = 2
  description = "OCPUs for the VM.Standard.A1.Flex shape. Always Free 2026 allocation is 2 OCPU total across all Ampere A1 instances in a tenancy (ADR-0027) — keep at 2 unless the tenancy's Always Free limits differ."
}

variable "memory_in_gbs" {
  type        = number
  default     = 12
  description = "Memory (GB) for the VM.Standard.A1.Flex shape. Always Free 2026 allocation is 12 GB total (ADR-0027)."
}

variable "api_port" {
  type        = number
  default     = 6443
  description = "Kubernetes API server port (k3s default) — opened in the security list and used to build the api_endpoint output."
}
