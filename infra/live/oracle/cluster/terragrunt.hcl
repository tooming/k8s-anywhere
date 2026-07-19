include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/oracle-k3s-cluster"
}

# oci provider auth: standard API-key auth (tenancy/user/fingerprint/private_key_path),
# matching the OCI CLI config the same operator already needs for
# scripts/tfstate-oracle-bootstrap.sh (both read from the same `oci setup config`
# profile in spirit, though Terraform's provider block takes them as explicit values
# rather than reading ~/.oci/config directly, so CI-with-no-credentials still gets a
# syntactically valid, if unusable, provider block for `terraform validate`).
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "oci" {
      tenancy_ocid     = "${get_env("OCI_TENANCY_ID", "")}"
      user_ocid        = "${get_env("OCI_USER_ID", "")}"
      fingerprint      = "${get_env("OCI_FINGERPRINT", "")}"
      private_key_path = "${get_env("OCI_PRIVATE_KEY_PATH", "")}"
      region           = "${get_env("OCI_REGION", "")}"
    }
  EOF
}

inputs = {
  tenancy_ocid   = get_env("OCI_TENANCY_ID")
  compartment_id = get_env("OCI_COMPARTMENT_ID")
  # ssh_public_key is the module's expected KEY CONTENT (metadata.ssh_authorized_keys),
  # not a path — reads the same file scripts/tfstate-oracle-bootstrap.sh's
  # OCI_SSH_PUBLIC_KEY_PATH points at, matching that script's key pair.
  ssh_public_key       = file(get_env("OCI_SSH_PUBLIC_KEY_PATH"))
  ssh_private_key_path = get_env("OCI_SSH_PRIVATE_KEY_PATH")
  # Optional hardening: restrict SSH + the k3s API to a known CIDR instead of the
  # module's open-by-default 0.0.0.0/0 (see variables.tf's admin_cidr description).
  # Unset OCI_ADMIN_CIDR to keep the current open-to-internet default.
  admin_cidr = get_env("OCI_ADMIN_CIDR", "0.0.0.0/0")
}
