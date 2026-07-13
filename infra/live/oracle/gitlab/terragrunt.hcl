include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/gitlab-config"
}

dependency "cluster" {
  config_path = "../cluster"
  mock_outputs = {
    kube_context = "k3d-k8s-lab"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# gitlab provider auth comes from the GITLAB_TOKEN env var (minted by scripts/gitlab-pat.sh).
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "gitlab" {
      base_url = "http://localhost:8929/api/v4/"
    }
    provider "kubernetes" {
      config_path    = pathexpand("~/.kube/config")
      config_context = "${dependency.cluster.outputs.kube_context}"
    }
  EOF
}
