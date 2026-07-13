# Root Terragrunt config for the oracle backend (ADR-0026/0027). Child units
# (cluster/, argocd/, gitlab/) include this for shared state + inputs — argocd/ and
# gitlab/ are byte-identical to infra/live/local/'s units; only this file and cluster/
# differ per backend, per infra/live/README.md's contract.

locals {
  cluster_name = "k8s-anywhere-oracle"
}

# State lives in the SEPARATE off-cluster Garage instance from RFC #377 item 3
# (infra/tfstate-oracle/, scripts/tfstate-oracle-bootstrap.sh — a distinct Always Free
# AMD Micro instance, never the Ampere A1 VM this backend's own cluster/ unit creates;
# see ADR-0027's "Terraform state" section for why). Brought up by
# `make tfstate-oracle-up` BEFORE any terragrunt apply here, exactly mirroring how
# infra/live/local/root.hcl depends on `make tfstate-up`.
#
# Same generate-not-remote_state approach as local/root.hcl, for the same reason:
# Garage partially supports the S3 API and Terragrunt's remote_state block calls
# CreateBucket, which Garage handles unreliably — Terraform's native s3 backend only
# needs bucket-exists/object-get/object-put, which works.
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
        skip_credentials_validation = true
        skip_region_validation      = true
        skip_metadata_api_check     = true
        skip_requesting_account_id  = true
        endpoints = {
          s3 = "${get_env("TFSTATE_ORACLE_ENDPOINT")}"
        }
      }
    }
  EOF
}

# No default for TFSTATE_ORACLE_ENDPOINT (unlike local/root.hcl's localhost fallback):
# it's a real, per-tenancy public IP minted by tfstate-oracle-bootstrap.sh, never a
# fixed value — get_env(name) with one argument fails loudly if unset, which is
# correct here (silently falling back to nothing would just produce a confusing
# downstream S3-connection error instead).

terraform {
  extra_arguments "reconfigure" {
    commands  = ["init"]
    arguments = ["-reconfigure"]
  }
}

inputs = {
  cluster_name = local.cluster_name
}
