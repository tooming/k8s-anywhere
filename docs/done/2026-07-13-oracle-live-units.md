# `infra/live/oracle/{cluster,argocd,gitlab}/terragrunt.hcl`

RFC #377 item 2 (depended on item 1's module and item 3's tfstate backend, both
merged first). New `oracle/` backend directory mirroring `local/`'s three-unit
structure per `infra/live/README.md`'s contract:

- `cluster/terragrunt.hcl` — points `source` at `infra/modules/oracle-k3s-cluster`;
  generates the `oci` provider block (API-key auth via `OCI_TENANCY_ID`/`OCI_USER_ID`/
  `OCI_FINGERPRINT`/`OCI_PRIVATE_KEY_PATH`/`OCI_REGION` env vars); inputs read
  `OCI_TENANCY_ID`/`OCI_COMPARTMENT_ID`/`OCI_SSH_PUBLIC_KEY_PATH` (file content, not
  path — the module's `ssh_public_key` variable expects the key string)/
  `OCI_SSH_PRIVATE_KEY_PATH`.
- `argocd/terragrunt.hcl`, `gitlab/terragrunt.hcl` — **byte-identical** copies of
  `local/`'s units. No changes at all, proving the contract: only the `cluster` unit
  differs per backend.
- `root.hcl` — separate backend-block generation pointing at
  `TFSTATE_ORACLE_ENDPOINT` (no default, unlike `local/root.hcl`'s localhost
  fallback — this is a real per-tenancy public IP minted by
  `scripts/tfstate-oracle-bootstrap.sh`, so a silent empty default would just defer
  the error to a more confusing point).

**Validation note:** no automated CI check covers Terragrunt `.hcl` syntax at all
(`scripts/validate-terraform.sh` only validates `infra/modules/*/`, never
`infra/live/*/` — true for `local/`'s existing units too, not a new gap this PR
introduces). Hand-verified against `local/`'s proven structure; not run against a
real OCI account.

## PR

https://github.com/tooming/k8s-anywhere/pull/382
