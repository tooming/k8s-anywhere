include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/k3d-cluster"
}

inputs = {
  servers              = 1
  agents               = 1
  api_port             = 6445
  http_port            = 8080
  https_port           = 8443
  disable_traefik      = true
  # ADR-0014: Flannel + bundled NetworkPolicy controller disabled; Cilium is the CNI.
  # Run `make cilium-up` immediately after `make cluster-up` — before `make argocd`
  # or any workload — to install Cilium and enable pod networking.
  disable_default_cni  = true
}
