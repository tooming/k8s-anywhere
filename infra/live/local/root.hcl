# Root Terragrunt config for the local lab environment.
# Child units (cluster/, argocd/, gitlab/) include this for shared state + inputs.

locals {
  cluster_name = "k8s-lab"
}

# Local state — one tfstate per unit, stored in the unit's dir.
# No remote backend: this is a throwaway localhost lab.
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

inputs = {
  cluster_name = local.cluster_name
}
