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
# `kubernetes` is an ATTRIBUTE here, not a block — hashicorp/helm v3 changed the
# provider's own connection config schema (separate from the helm_release resource
# schema audited in infra/modules/argocd/main.tf's issue #791 comment, which never
# ran a real `terraform apply` to catch this: `kubernetes { ... }` (v2 block syntax)
# fails immediately in v3 with "Blocks of type kubernetes are not expected here" —
# found live 2026-08-06 running the first real apply since the v3 constraint bump.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "helm" {
      kubernetes = {
        config_path    = pathexpand("~/.kube/config")
        config_context = "${dependency.cluster.outputs.kube_context}"
      }
    }
  EOF
}

inputs = {
  chart_version = "10.3.2"
}
