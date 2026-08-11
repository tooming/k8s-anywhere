include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/forgejo-config"
}

# forgejo provider auth: unlike the predecessor module's token-based provider, there
# is no forgejo-pat.sh-equivalent minting script yet (only a future migration item
# would add one), so this runs under basic-auth against the 'lab-admin' account
# scripts/forgejo-env-ensure.sh + forgejo-admin-ensure.sh already create. Credentials
# come from the FORGEJO_USERNAME / FORGEJO_PASSWORD env vars the provider itself
# reads (not passed through Terragrunt inputs).
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "forgejo" {
      host = "http://localhost:3300"
    }
  EOF
}
