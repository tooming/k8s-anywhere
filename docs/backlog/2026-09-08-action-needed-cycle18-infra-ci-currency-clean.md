# [Action needed] Cycle 18 — infra/CI tooling currency sweep also came up clean

Follow-up to
[2026-09-08-action-needed-cycle17-doc-drift-sweep-exhausted.md](2026-09-08-action-needed-cycle17-doc-drift-sweep-exhausted.md)
(PR #1530). A genuinely different lens this cycle — infrastructure and CI
tooling currency, not application/dependency currency or doc drift — also
came up clean.

## What this cycle checked (all already current)

- **Terraform provider constraints** (`hashicorp/helm ~> 3.0`,
  `hashicorp/null ~> 3.2`, `hashicorp/local ~> 2.5`, `oracle/oci ~> 8.0`):
  all use pessimistic (`~>`) constraints that already float to the latest
  matching release at `terraform init` time — no manual bump needed by
  design (this is what `tests/*.bats`' own "provider constraint allows the
  X.x line" assertions guard).
- **Terraform CLI / Terragrunt CLI**: `git ls-remote --tags` against both
  upstream repos confirms `v1.16.1` (Terraform) and `v1.1.4` (Terragrunt)
  are already each project's latest stable tag — matches the current pins
  exactly (bumped to these same versions earlier this run's history,
  `docs/done/2026-09-06-terraform-terragrunt-currency-bump.md`).
- **`.github/workflows/ci.yml`'s pinned Actions** (commit-SHA pinned, per
  this repo's supply-chain-hardening convention): `actions/checkout`
  (`v7.0.1`), `actions/cache` (`v6.1.0`), `hashicorp/setup-terraform`
  (`v4.0.1`) — `git ls-remote --tags` against all three upstream repos
  confirms every one is already pinned to its latest stable release.
- **Orphaned Forgejo/GitLab CI file remnants**: `find . -iname
  "*.gitlab-ci.yml" -o -iname "*forgejo*"` (excluding docs/history/tests
  that legitimately reference the removed components by name) returns only
  `docs/decisions/adr-0035-forgejo-not-gitlab.md` itself — the historical
  ADR record, correctly retained.

Combined with cycle 17's sweep (doc-drift, incident-log follow-ups, ADR
flip conditions, application/chart dependency currency, `scripts/lib/`
duplication), this run has now checked every currency/drift dimension this
repo's own drift-detector suite doesn't already mechanically cover in
`make ci`.

## What would open new work

Same as cycle 17's note: a new upstream release (now including CI Actions
and Terraform/Terragrunt themselves, all confirmed current as of this
cycle), a new GitHub issue/RFC/CHARTER edit, or issue #1517 resolving.

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's
last resort. The run continues (STEP 8) — going back to STEP 1
immediately.
