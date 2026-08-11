include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/forgejo-config"
}

dependency "cluster" {
  config_path = "../cluster"
  mock_outputs = {
    kube_context = "k3d-k8s-lab"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# forgejo provider auth: unlike the predecessor module's token-based provider, there
# is no forgejo-pat.sh-equivalent minting script yet (only a future migration item
# would add one), so this runs under basic-auth against the 'lab-admin' account
# scripts/forgejo-env-ensure.sh + forgejo-admin-ensure.sh already create. Credentials
# come from the FORGEJO_USERNAME / FORGEJO_PASSWORD env vars the provider itself
# reads (not passed through Terragrunt inputs). The kubernetes provider (needed for
# this module's ArgoCD repository-credential Secret) mirrors the predecessor module's
# own generate block exactly.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "forgejo" {
      host = "http://localhost:3300"
    }
    provider "kubernetes" {
      config_path    = pathexpand("~/.kube/config")
      config_context = "${dependency.cluster.outputs.kube_context}"
    }
  EOF
}
