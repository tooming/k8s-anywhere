#!/usr/bin/env bats
# Clusterless structural tests for the oracle cloud backend (ADR-0026/0027, RFC #377):
# infra/modules/oracle-k3s-cluster, infra/live/oracle/, infra/tfstate-oracle/. No
# running cluster or OCI account required — mechanical shape/contract checks only.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  MOD="$REPO/infra/modules/oracle-k3s-cluster"
  LIVE="$REPO/infra/live/oracle"
}

# --- module shape -------------------------------------------------------------

@test "oracle-k3s-cluster module has main.tf, variables.tf, outputs.tf" {
  [ -f "$MOD/main.tf" ]
  [ -f "$MOD/variables.tf" ]
  [ -f "$MOD/outputs.tf" ]
}

@test "oracle-k3s-cluster declares the oci and null required_providers" {
  run grep -q 'source  = "oracle/oci"' "$MOD/main.tf"
  [ "$status" -eq 0 ]
  run grep -q 'source  = "hashicorp/null"' "$MOD/main.tf"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster variables have no live-account defaults for account-specific values" {
  # cluster_name/tenancy_ocid/compartment_id/ssh_public_key/ssh_private_key_path must
  # stay required (no default =) so terraform validate never accidentally succeeds
  # against a real account by falling back to a baked-in value.
  for v in cluster_name tenancy_ocid compartment_id ssh_public_key ssh_private_key_path; do
    run sed -n "/^variable \"$v\" {/,/^}/p" "$MOD/variables.tf"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    ! grep -q 'default' <<< "$output"
  done
}

@test "oracle-k3s-cluster outputs match the k3d-cluster contract (cluster_name, kube_context, api_endpoint)" {
  for o in cluster_name kube_context api_endpoint; do
    run grep -q "output \"$o\"" "$MOD/outputs.tf"
    [ "$status" -eq 0 ]
  done
  # same output names as the localhost backend's module — infra/live/README.md's contract
  k3d_outputs="$(grep -oE '^output "[a-z_]+"' "$REPO/infra/modules/k3d-cluster/outputs.tf" | sort)"
  oracle_outputs="$(grep -oE '^output "[a-z_]+"' "$MOD/outputs.tf" | sort)"
  [ "$k3d_outputs" = "$oracle_outputs" ]
}

@test "oracle-k3s-cluster kube_context is namespaced oracle-<cluster_name> (never collides with k3d-k8s-lab)" {
  run grep -q 'value       = "oracle-\${var.cluster_name}"' "$MOD/outputs.tf"
  [ "$status" -eq 0 ]
}

# --- no hardcoded credentials/secrets ------------------------------------------

@test "oracle-k3s-cluster module has no hardcoded OCID, key, or secret literals" {
  # OCIDs/keys are always supplied via variables in this module; a literal
  # "ocid1.tenancy..." or a long hex/base64 blob would mean a real value leaked in.
  run grep -RE 'ocid1\.[a-z]+\.oc[0-9]' "$MOD"
  [ "$status" -ne 0 ]
}

@test "infra/tfstate-oracle templates use placeholders, not literal secrets" {
  run grep -q '__RPC_SECRET__' "$REPO/infra/tfstate-oracle/garage.toml.tpl"
  [ "$status" -eq 0 ]
  run grep -q '__ADMIN_TOKEN__' "$REPO/infra/tfstate-oracle/garage.toml.tpl"
  [ "$status" -eq 0 ]
  # unlike infra/tfstate/garage.toml (safe to hardcode — localhost-only), this
  # instance has a public IP and must never ship with a real secret value.
  run grep -qE 'rpc_secret *= *"[0-9a-f]{16,}"' "$REPO/infra/tfstate-oracle/garage.toml.tpl"
  [ "$status" -ne 0 ]
}

@test "tfstate-oracle-bootstrap.sh generates secrets at bootstrap time, never hardcodes them" {
  run grep -q 'openssl rand' "$REPO/scripts/tfstate-oracle-bootstrap.sh"
  [ "$status" -eq 0 ]
  # no long hex/base64 literal that would be a leaked real secret
  run grep -qE '[0-9a-f]{32,}' "$REPO/scripts/tfstate-oracle-bootstrap.sh"
  [ "$status" -ne 0 ]
}

# --- infra/live/oracle/ contract: argocd + gitlab units are byte-identical to local/'s ---

@test "infra/live/oracle/argocd/terragrunt.hcl is byte-identical to local/'s" {
  diff -q "$REPO/infra/live/local/argocd/terragrunt.hcl" "$LIVE/argocd/terragrunt.hcl"
}

@test "infra/live/oracle/gitlab/terragrunt.hcl is byte-identical to local/'s" {
  diff -q "$REPO/infra/live/local/gitlab/terragrunt.hcl" "$LIVE/gitlab/terragrunt.hcl"
}

@test "infra/live/oracle/cluster/terragrunt.hcl points source at oracle-k3s-cluster" {
  run grep -q 'source = "\${get_repo_root()}/infra/modules/oracle-k3s-cluster"' "$LIVE/cluster/terragrunt.hcl"
  [ "$status" -eq 0 ]
}

@test "infra/live/oracle/root.hcl has no default TFSTATE_ORACLE_ENDPOINT fallback" {
  # unlike local/root.hcl's localhost default, oracle's endpoint is a real
  # per-tenancy public IP with no sensible guess — must fail loudly if unset.
  run grep -q 'get_env("TFSTATE_ORACLE_ENDPOINT")' "$LIVE/root.hcl"
  [ "$status" -eq 0 ]
  run grep -qE 'get_env\("TFSTATE_ORACLE_ENDPOINT", ' "$LIVE/root.hcl"
  [ "$status" -ne 0 ]
}

# --- bounded retries: an unbounded `until` here hangs `terraform apply` forever --

@test "oracle-k3s-cluster main.tf's SSH-wait loop is bounded, not an infinite until" {
  # Regression: the SSH-reachability wait used to be a bare `until ...; do sleep 5;
  # done` with no upper bound -- if the instance never came up (OCI out-of-capacity,
  # a cloud-init failure, wrong SSH key), terraform apply would hang forever with no
  # diagnostic. Must count iterations and exit non-zero past a budget.
  run grep -q 'i=$((i + 1))' "$MOD/main.tf"
  [ "$status" -eq 0 ]
  run grep -q 'if \[ "$i" -ge 60 \]' "$MOD/main.tf"
  [ "$status" -eq 0 ]
  run grep -q 'exit 1' "$MOD/main.tf"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster main.tf's SSH-wait timeout message is diagnosable" {
  run grep -q 'did not become SSH-reachable' "$MOD/main.tf"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster cloud-init.yaml's k3s-install wait is bounded, not an infinite until" {
  # Same class of regression as the SSH-wait loop above, on the instance side:
  # `until [ -f .../k3s.yaml ]; do sleep 2; done` with no bound would hang cloud-init's
  # runcmd forever if the k3s install silently failed.
  run grep -q 'i=$((i + 1))' "$MOD/cloud-init.yaml"
  [ "$status" -eq 0 ]
  run grep -q '\[ "$i" -ge 150 \]' "$MOD/cloud-init.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'exit 1' "$MOD/cloud-init.yaml"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster destroy-time cleanup also unsets the kubeconfig users entry" {
  # Regression: the create-time sed renames cluster, context, AND user to the same
  # "oracle-<name>" string (k3s.yaml's default kubeconfig uses "default" for all
  # three) -- destroy only cleaned up the context + cluster, leaving a stale user
  # credential entry in ~/.kube/config on every destroy.
  run grep -q 'kubectl config unset users.oracle-' "$MOD/main.tf"
  [ "$status" -eq 0 ]
}
