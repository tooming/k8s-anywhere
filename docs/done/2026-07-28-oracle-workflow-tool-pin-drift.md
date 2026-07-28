# Fix oracle-cluster-apply*.yml's drifted terraform/terragrunt pins

CHARTER **Core Values** §"Everything as code" + general CI hygiene. Architect-role
fallback (`executor.prompt.md` STEP 6b) continuing this cycle's `.gitlab-ci.yml`
image-pin audit (PR #817) into the adjacent GitHub Actions tool-version-pin class.
"Now / next" remains fully gated on standing maintainer-confirmation issues
#631/#632/#633 (re-checked this cycle — still no confirmation comments on any of
the three).

## What was found

`.github/workflows/oracle-cluster-apply.yml` and its scheduled companion
`oracle-cluster-apply-retry.yml` (the only automatable bridge to a real Oracle
Cloud tenancy, per ADR-0027/issue #406) both still pinned:

- `terraform_version: "1.9.8"` — but `.github/workflows/ci.yml` bumped its own
  `terraform_version` to `"1.15.8"` on 2026-07-21 (`tests/ci-tool-pins.bats`'s
  existing "upgrade-drafter, 2026-07-21" test names this). The retry workflow's
  own trailing comment reads `# keep in sync with oracle-cluster-apply.yml /
  ci.yml` — a stated intent this drift had already silently violated for a week.
- `terragrunt` install pinned to `v0.67.0` (a pre-1.0 release) in both files,
  while the real latest is `v1.1.1`.

Root cause: `tests/ci-tool-pins.bats`'s existing "no workflow references the
pre-bump terraform 1.9.8 pin" regression test only grepped `ci.yml` — the exact
mechanical guard that should have caught this only covered one of the three
files that needed to move together.

## Why this is a same-run Convert, not another standing gate

Both files are `workflow_dispatch`/`schedule`-triggered GitHub Actions workflows
(CI/build-time tooling, not gitops-deployed cluster state); this remote session
has no reachable Oracle Cloud credentials or live GitLab regardless, so `make
ci`'s clusterless coverage is the verification ceiling either way.

- **terraform 1.15.8**: not a fresh unknown — `ci.yml`'s own `terraform` job has
  already run this exact version against these same `infra/modules/*` repeatedly
  since 2026-07-21 with no reported issue.
- **terragrunt v1.1.1**: verified directly against Terragrunt's real v1.0.0
  release notes (`github.com/gruntwork-io/terragrunt/releases/tag/v1.0.0`,
  fetched live, per ADR-0004) before bumping. None of its documented breaking
  changes (`tflint` dependency removed, `.terragrunt-cache` now always
  generated, `find`/`list` discovering hidden dirs by default, `render
  --format=json` dependent-discovery removed, Windows path normalization
  removed, `terragrunt.stack.hcl` ambiguity warnings) touch anything this repo's
  `infra/live/oracle/*` units actually use: no `tflint` `before_hook`, no
  `find`/`list`/`render` calls anywhere in this repo, no `*.stack.hcl` files
  (confirmed via `find infra/live -iname "terragrunt.stack.hcl"`, zero results),
  Linux runners only. Terragrunt's own v1 policy is no breaking changes across
  minor releases, so 1.1.1 carries the same guarantee as 1.0.0. Both the
  terraform and terragrunt download URLs were verified to actually resolve
  (`curl -o /dev/null -w '%{http_code}'` → `200`) before committing.

## What changed

- `.github/workflows/oracle-cluster-apply.yml`: `terraform_version` `1.9.8` →
  `1.15.8`; terragrunt install URL `v0.67.0` → `v1.1.1`. Comments record the
  audit trail.
- `.github/workflows/oracle-cluster-apply-retry.yml`: same two bumps, same
  comment pattern (cross-referencing the sibling file to avoid duplicating the
  full trail twice).
- `tests/ci-tool-pins.bats`:
  - **Fixed the actual gap**: broadened "no workflow references the pre-bump
    terraform 1.9.8 pin" from grepping only `ci.yml` to every `.github/workflows/
    *.yml` file — this is the mechanical change that makes the next version of
    this exact bug class impossible, not just this one instance.
  - Added assertions pinning both oracle workflows' `terraform_version` (1.15.8)
    and terragrunt (v1.1.1) as recurrence guards.
  - Added a repo-wide guard against any workflow referencing the retired
    terragrunt v0.67.0 URL.

`make ci` passes locally (both workflow files re-validated as parseable YAML;
all real checks green). No topology change; README/`docs/dependency-tree.md`
don't reference either pin.

PR: (this run's `arch/oracle-workflow-tool-pin-drift` branch)
