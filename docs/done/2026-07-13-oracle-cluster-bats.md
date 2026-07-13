# `tests/oracle-cluster.bats`

RFC #377 item 4. Clusterless structural tests for the oracle cloud backend — no
running cluster or OCI account required:

- Module shape: `main.tf`/`variables.tf`/`outputs.tf` exist, `oci`/`null`
  `required_providers` declared.
- Required variables (`cluster_name`, `tenancy_ocid`, `compartment_id`,
  `ssh_public_key`, `ssh_private_key_path`) have no `default` — verified with the
  same `sed`-block-extraction the test itself uses, run manually against the real
  files before committing (no `bats` binary available in this environment to
  execute the suite directly).
- Output names (`cluster_name`, `kube_context`, `api_endpoint`) match
  `k3d-cluster`'s exactly — the `infra/live/README.md` contract.
- `kube_context` is namespaced `oracle-<cluster_name>`, never colliding with
  `k3d-k8s-lab`.
- No hardcoded OCIDs in the module; `infra/tfstate-oracle/` templates use
  placeholders, never literal secrets; `tfstate-oracle-bootstrap.sh` generates
  secrets via `openssl rand`, contains no long hex/base64 literal.
- `infra/live/oracle/{argocd,gitlab}/terragrunt.hcl` are byte-identical to
  `local/`'s (`diff -q`) — mechanical proof of the "only `cluster` differs per
  backend" contract, mirroring the repo's existing drift-detector pattern.
- `infra/live/oracle/root.hcl` has no default `TFSTATE_ORACLE_ENDPOINT` fallback.

**Validation note:** every grep/diff/sed assertion in this file was run manually
against the real repo files before committing (all passed) since no `bats` binary
is available in this sandbox to execute the suite directly — CI's `unit` job (which
does have `bats` installed) is the first actual run of the test file itself.

## PR

https://github.com/tooming/k8s-anywhere/pull/383
