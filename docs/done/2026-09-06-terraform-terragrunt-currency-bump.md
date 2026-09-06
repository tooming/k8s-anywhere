# Terraform `1.15.9`→`1.16.1` + Terragrunt `v1.1.3`→`v1.1.4` — routine currency, first-ever review of a previously-undated register row

JANITOR-fallback coverage/hardening sweep 2026-09-06. `docs/dependency-register.md`'s
Terraform/Terragrunt row was the one remaining active row still reading "not dated in
ADR (no Re-evaluation log)" — every other row had a real reviewed date by this point in
the run (Garage, Kyverno, Trivy Operator, ESO, Vault, Kargo, Harbor, Forgejo, moto, ACK,
KRO, s3manager all already carry a recent, dated entry). This closes that gap with the
lab's first-ever currency/security check of its own bootstrap tooling.

## What was checked

**Terraform** (exact-pinned in CI via `hashicorp/setup-terraform`, `.github/workflows/
ci.yml` + `oracle-cluster-apply.yml` + `oracle-cluster-apply-retry.yml`, and locally via
`scripts/ensure-manifest-tools-hook.sh`):

- Confirmed the latest stable release directly: `v1.16.1` (2026-09-02), vs. the pinned
  `1.15.9`.
- Checked `hashicorp/terraform`'s full published GitHub security advisory list: exactly
  one advisory exists, ever — GHSA-4rvg-555h-r626 (High, 2019), cleartext transmission
  of Terraform state snapshots over the Azure backend with certain SAS tokens. This
  repo has never used an Azure state backend (state lives in Garage S3, ADR-0007) —
  not applicable regardless of version.
- Checked the `v1.16.0` release notes (first release in the 1.16.x line) for breaking
  changes: one upgrade note exists — `bastion_host_key` provisioner behavior changed.
  Checked every `infra/modules/*/main.tf` directly: none use `bastion_host`/SSH
  connection blocks, only `local-exec` provisioners. Not applicable.

**Terragrunt** (exact-pinned only in `oracle-cluster-apply.yml`/`oracle-cluster-apply-
retry.yml`'s "Install terragrunt" steps — no local/CI clusterless dev-flow pin, since
`make ci` never runs a real `terragrunt apply`):

- Confirmed the latest stable release directly: `v1.1.4` (2026-08-27), vs. the pinned
  `v1.1.3`.
- Checked the real `v1.1.4` release notes: genuine security hardening (generated files/
  directories now get restricted permissions — `0600`/`0700`, previously readable by
  other users on a shared machine; registry credentials no longer duplicated into
  generated CLI config files; toolchain moved to Go v1.27), no documented breaking
  change.

## What was done

Bumped both pins, in every file that carries them, keeping the three workflows'
established "keep in sync" convention intact:

- `.github/workflows/ci.yml`: `terraform_version: "1.15.9"` → `"1.16.1"`
- `.github/workflows/oracle-cluster-apply.yml`: same bump + the terragrunt download
  URL `v1.1.3` → `v1.1.4`
- `.github/workflows/oracle-cluster-apply-retry.yml`: same two bumps
- `scripts/ensure-manifest-tools-hook.sh`: `TERRAFORM_VERSION="1.15.9"` → `"1.16.1"`
- `tests/ci-tool-pins.bats`: updated the exact-pin assertions for both tools, added a
  "no workflow references the pre-bump terraform 1.15.9 pin" negative test (mirroring
  the existing 1.9.8/1.15.8 negative tests) and a matching "no workflow references the
  pre-bump terragrunt v1.1.3 pin" negative test — the exact drift-guard shape this
  file's own header comment describes closing for the 2026-07-28 terraform/terragrunt
  sync gap.

## Verification

Installed Terraform `1.16.1` directly in this sandbox (matching CI's own install
command, minus `sudo`) and re-ran `make ci`'s `terraform` step against it: `terraform
fmt`/`validate`/`tflint` all pass clean across `infra/` with zero pre-existing
failures — the pin bump surfaced no compatibility issue. Terragrunt itself is not
installed or exercised in this clusterless sandbox (no OCI credentials reachable
here, same standing caveat every prior terragrunt bump in these workflows'
own comments has recorded) — this workflow's own next real run against Oracle
Cloud is the actual verification, as it has been for every prior terragrunt bump.

`make ci` passes green (`tests/ci-tool-pins.bats`'s updated + new assertions included).

## Result

`docs/dependency-register.md`'s Terraform/Terragrunt row now carries a real,
dated, detailed review for the first time. No `gitops/` change — bootstrap
tooling only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1469
