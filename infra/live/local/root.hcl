# Root Terragrunt config for the local lab environment.
# Child units (cluster/, argocd/) include this for shared state + inputs. A
# gitlab/ unit (ADR-0033) and later a forgejo/ unit (ADR-0035) existed here in
# the past — both self-hosted git options were removed entirely 2026-09-07, no
# replacement (the repo now lives only on its public GitHub remote).

locals {
  cluster_name = "k8s-lab"
}

# State backend: local file, one per Terragrunt unit (ADR-0007, superseded 2026-09-07).
# The off-cluster Garage this used to point to (infra/tfstate/) was removed entirely
# that same day, no replacement — this lab is now single-host and single-operator with
# no S3-compatible store left anywhere, in-cluster or out, so a local backend is the
# honest simplification rather than standing up new bootstrap substrate to replace it.
# `path` uses get_terragrunt_dir() (the directory containing each unit's own
# terragrunt.hcl, e.g. infra/live/local/cluster/) rather than Terraform's own default
# (relative to its Terragrunt-managed working dir, inside the ephemeral
# .terragrunt-cache/ tree) — that default would silently lose state on every
# `.terragrunt-cache` wipe. *.tfstate is gitignored; per ADR-0005 ("recoverability over
# impossible HA"), if the file is ever lost the correct response on this disposable lab
# is recreate-from-code (`make down && make up`), not state recovery.
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      backend "local" {
        path = "${get_terragrunt_dir()}/terraform.tfstate"
      }
    }
  EOF
}

# Terragrunt auto-runs `terraform init` before every plan/apply. Pass -reconfigure so a
# backend change (e.g. this file's own migration from the removed S3/Garage backend to
# local) re-binds cleanly instead of failing with "Backend type changed from s3 to local".
terraform {
  extra_arguments "reconfigure" {
    commands  = ["init"]
    arguments = ["-reconfigure"]
  }
}

inputs = {
  cluster_name = local.cluster_name
}
