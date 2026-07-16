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
  # NOT 8443: the DR frontdoor's HTTPS TCP passthrough (scripts/bluegreen-frontdoor.sh)
  # is the stable, blue/green-independent entry point and owns host :8443 (mirrors how
  # :8000 there is distinct from this cluster's own :8080 http_port above). Binding this
  # cluster's own direct k3d loadbalancer port to the same :8443 makes `docker run` for
  # the frontdoor container fail ("port is already allocated") on every fresh `make up`.
  https_port           = 8446
  disable_traefik      = true
  # ADR-0014: Flannel + bundled NetworkPolicy controller disabled; Cilium is the CNI.
  # Run `make cilium-up` immediately after `make cluster-up` — before `make argocd`
  # or any workload — to install Cilium and enable pod networking.
  disable_default_cni  = true
}
