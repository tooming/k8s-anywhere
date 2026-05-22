include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/k3d-cluster"
}

inputs = {
  servers         = 1
  agents          = 1
  api_port        = 6445
  http_port       = 8080
  https_port      = 8443
  disable_traefik = true
}
