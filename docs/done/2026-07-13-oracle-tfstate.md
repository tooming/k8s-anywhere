# Second off-cluster Garage state store for the `oracle` backend

RFC #377 item 3 — corrected in ADR-0027 2026-07-13: the state backend cannot live on
the same VM the `oracle-k3s-cluster` module creates, since that Terraform apply needs
the state backend to already exist — same causal-ordering constraint
[ADR-0007](../decisions/adr-0007-off-cluster-garage-tfstate-backend.md) already solved
for `local/`. Uses the *separate* Always Free AMD Micro allocation (1/8 OCPU / 1 GB —
distinct quota from the Ampere A1 shape the k3s cluster uses).

`infra/tfstate-oracle/{garage.toml.tpl,cloud-init.yaml.tpl}` — templates, no hardcoded
secrets (unlike `infra/tfstate/garage.toml`'s throwaway localhost-only secrets, this
instance has a public IP). `scripts/tfstate-oracle-bootstrap.sh` — idempotent bootstrap
via the OCI CLI (never Terraform, matching ADR-0007's precedent that the state backend
is imperative): creates its own VCN/subnet/internet-gateway/security-list (separate
10.21.0.0/16 CIDR from the k3s cluster's 10.20.0.0/16), generates the Garage RPC secret
+ admin token + S3 access key at bootstrap time (persisted only in a git-ignored local
`.env`, never committed), launches the `VM.Standard.E2.1.Micro` instance via cloud-init,
then bootstraps the Garage layout/key/bucket over SSH — mirroring
`scripts/tfstate-bootstrap.sh`'s idempotency pattern. New `make tfstate-oracle-up` /
`make tfstate-oracle-down` targets.

**Validation note:** no OCI CLI, credentials, or account exist in this environment —
this script is unverified against a real OCI tenancy. `bash -n` syntax-checked clean;
the OCI CLI flag names and shapes (`VM.Standard.E2.1.Micro`, `oci compute instance
launch`, `oci network *`) were verified against current Oracle/community documentation,
not executed.

## PR

https://github.com/tooming/k8s-anywhere/pull/381
