# tfstate-oracle bootstrap — restrict SSH/Garage-S3 ingress to a configurable CIDR

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b; same-run follow-up to
`docs/done/2026-07-19-oracle-admin-cidr-hardening.md` — this is the identical bug
class recurring in a sibling component the earlier fix didn't cover.)

`infra/modules/oracle-k3s-cluster`'s security list hardcoded SSH + the k3s API
ingress source to `0.0.0.0/0` (fixed earlier this run). While checking for the same
pattern elsewhere in `infra/`, found the *identical* issue in
`scripts/tfstate-oracle-bootstrap.sh` — the imperative OCI CLI bootstrap for the
**second**, always-internet-facing Oracle instance (the off-cluster Garage
Terraform-state backend, per ADR-0007's causal-ordering precedent, ADR-0027's
"Terraform state" section). Its `oci network security-list create` call hardcoded
both ingress rules — SSH (22) and the Garage S3 API (3900) — to
`"source":"0.0.0.0/0"`. Exposing an S3-compatible storage backend holding
Terraform state to the entire internet is arguably a higher-stakes instance of the
same exposure class than the k3s API case (a compromised Garage endpoint could leak
or corrupt this repo's own infra state).

Fixed the same way, reusing the exact `OCI_ADMIN_CIDR` env var name the
`infra/modules/oracle-k3s-cluster` fix introduced (one setting hardens both
Oracle-backend instances consistently): added
`OCI_ADMIN_CIDR="${OCI_ADMIN_CIDR:-0.0.0.0/0}"` near the script's other env-var
reads, and substituted it into both `"source"` fields of the
`--ingress-security-rules` JSON (the `--egress-security-rules` rule legitimately
keeps its literal `0.0.0.0/0` destination — outbound-only, not an exposure).
**Non-breaking**: default value unchanged, so the script still works with no extra
input.

New `tests/oracle-cluster.bats` assertion (clusterless): the env-var default line
exists; the security-list-creation block references `$OCI_ADMIN_CIDR` in both
ingress `"source"` fields; no hardcoded `"source":"0.0.0.0/0"` remains in that
block. `bash -n` confirms the script's syntax is still valid after the edit.

**ADR-0004 caveat:** this script is explicitly marked "UNVERIFIED against a real
OCI account/tenancy as of authoring" in its own header comment — unlike the
Terraform module fix, this imperative script has never been live-exercised in this
repo's history at all (per that same header), so this change carries the same
pre-existing verification gap the script always had, not a new one introduced here.

`make ci` passes (local tool-stub mode).

## PR

(filled in after PR creation)
