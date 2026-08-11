include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/forgejo-config"
}

# forgejo provider auth: svalabs/terraform-provider-forgejo's own documented upstream
# limitation is that it cannot mint access tokens (forgejo_personal_access_token) when
# itself authenticated via api_token — so, unlike the predecessor module's token-based
# provider, this one must run under basic-auth. Credentials come from the
# FORGEJO_USERNAME / FORGEJO_PASSWORD env vars the provider itself reads (not passed
# through Terragrunt inputs) — point them at the 'lab-admin' account
# scripts/forgejo-env-ensure.sh + forgejo-admin-ensure.sh create.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "forgejo" {
      host = "http://localhost:3300"
    }
  EOF
}
