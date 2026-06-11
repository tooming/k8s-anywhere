include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/argocd"
}

# Order + wiring: ArgoCD needs the cluster, and reads its kube context.
dependency "cluster" {
  config_path = "../cluster"
  mock_outputs = {
    kube_context = "k3d-k8s-lab"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# The helm provider points at the k3d cluster created by the cluster unit.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "helm" {
      kubernetes {
        config_path    = pathexpand("~/.kube/config")
        config_context = "${dependency.cluster.outputs.kube_context}"
      }
    }
  EOF
}

inputs = {
  chart_version = "9.5.20"
}
