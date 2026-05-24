# Root Terragrunt config for the local lab environment.
# Child units (cluster/, argocd/, gitlab/) include this for shared state + inputs.

locals {
  cluster_name = "k8s-lab"
}

# State lives in the off-cluster Garage (infra/tfstate), one key per unit. That Garage
# is brought up + bootstrapped by `make tfstate-up` BEFORE any apply, so the state
# backend never depends on the cluster this Terraform builds (no bootstrap loop). Creds
# come from the AWS_* env vars the Makefile exports; endpoint overridable via
# TFSTATE_ENDPOINT. `region` must match the Garage s3_region (infra/tfstate/garage.toml).
# We write backend.tf directly (generate, not remote_state) so Terragrunt does not
# try to manage the bucket via the real AWS APIs against Garage.
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      backend "s3" {
        bucket                      = "tfstate"
        key                         = "${path_relative_to_include()}/terraform.tfstate"
        region                      = "garage"
        use_path_style              = true
        use_lockfile                = true
        skip_credentials_validation = true
        skip_region_validation      = true
        skip_metadata_api_check     = true
        skip_requesting_account_id  = true
        endpoints {
          s3 = "${get_env("TFSTATE_ENDPOINT", "http://localhost:3900")}"
        }
      }
    }
  EOF
}

inputs = {
  cluster_name = local.cluster_name
}
