# Oracle backend — restrict SSH/API ingress to a configurable CIDR, not hardcoded 0.0.0.0/0

(CLAUDE.md §"Every bugfix must prevent recurrence" (applied proactively — a real
security gap in `infra/` code, not yet exploited only because the Oracle backend
hasn't had a live k3s instance launch complete yet); janitor fallback role, invoked
via `executor.prompt.md` STEP 6b, found via a "dependency/security hardening" lens
distinct from this run's earlier CVE/version sweeps.)

`infra/modules/oracle-k3s-cluster/main.tf`'s `oci_core_security_list` resource
hardcoded both ingress rules (SSH port 22, and the k3s API port `var.api_port`,
default 6443) to `source = "0.0.0.0/0"` — open to the entire internet, with no way
to restrict it. Verified directly (ADR-0004): no ADR (including ADR-0027, this
backend's binding ADR) discusses or accepts this posture; it's an unaddressed gap,
not a documented trade-off. For a "production-shaped cloud-native platform"
(CHARTER's Vision), leaving both SSH and the cluster control plane wide open on a
real internet-facing cloud instance is a real anti-pattern worth fixing before the
first live instance launch actually succeeds (currently still blocked on an
unrelated Oracle Always Free capacity constraint, per `infra/live/README.md`).

Added a new `admin_cidr` variable (`infra/modules/oracle-k3s-cluster/variables.tf`,
default `"0.0.0.0/0"` — **non-breaking**: the module still works out of the box with
no extra input, same default behavior as before) and used it for both ingress
rules' `source` field, replacing the hardcoded literal (the egress-all rule
legitimately keeps its own literal `0.0.0.0/0` — that's outbound-only and not a
security exposure). Wired `infra/live/oracle/cluster/terragrunt.hcl` to read it from
a new optional `OCI_ADMIN_CIDR` env var (defaulting to the same open CIDR if unset),
matching this file's existing env-var-driven input pattern.

New `tests/oracle-cluster.bats` assertions (clusterless): `admin_cidr` variable
exists with the documented open default and an explicit warning in its description;
the security list's two ingress rules reference `var.admin_cidr`, not a hardcoded
`0.0.0.0/0` (distinguishing them from the legitimate egress-all literal); the
terragrunt unit wires `OCI_ADMIN_CIDR` correctly.

**ADR-0004 caveat:** `infra/live/README.md`'s Status table records that this
module's VCN/subnet/security-list/internet-gateway layer was live-verified against
a real OCI tenancy on 2026-07-15 — this change parameterizes the security list's
source field without changing its default value or resource shape, so that
verification should still hold, but this remote clusterless session cannot
re-exercise a live `terraform apply` to confirm it. `terraform` is not installed in
this sandbox, so `validate-terraform.sh` skips locally the same as every other
Terraform-touching change this run; the change is syntactically a straightforward
literal→variable-reference swap in the same shape as every other variable already
used in this resource block. Full verification is pending the next live
`terraform apply` (this repo's normal Oracle-backend verification path, already
gated on the unrelated capacity constraint).

`make ci` passes (local tool-stub mode).

## PR

[#574](https://github.com/tooming/k8s-anywhere/pull/574)
