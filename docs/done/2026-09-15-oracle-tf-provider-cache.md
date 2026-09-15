# Cache Terraform providers in `oracle-cluster-apply-retry.yml` / `oracle-cluster-apply.yml` (issue #1619)

groomed 2026-09-15 (STEP 6b PLANNER-fallback grooming: the "Now / next" lane was
completely empty — every backlog item `[x]`, zero open PRs — and issue #1619 was the
one open, ungroomed intake item). Same missing-provider-cache gap `ci.yml`'s
`terraform` job had before PR #1618 fixed it there: no `TF_PLUGIN_CACHE_DIR` +
`actions/cache` step, so every run of the hourly-cron `oracle-cluster-apply-retry.yml`
(fires every 17 minutes past the hour) and the manual `oracle-cluster-apply.yml`
re-downloads the `oracle/oci` provider (large) from scratch — most retry runs end in an
expected "Out of host capacity" no-op, so that download is frequently paid just to
reach the no-op. **Scope:** apply PR #1618's exact pattern (`Set TF_PLUGIN_CACHE_DIR`
env step + `mkdir -p` + `actions/cache@<same pinned sha>` keyed on
`hashFiles('infra/modules/**/.terraform.lock.hcl')`, restore-keys scoped to
`runner.os`) to whichever job(s) in each of these two workflows run `terraform
init`/`plan`/`apply`. This is purely a caching addition to the CI runner's
provider-plugin directory — it does not change what `terraform apply` does or
touches, so it carries no live-infra-mutation risk and needs no architect RFC;
`make ci`'s `shellcheck`/`yamllint` lint job (the only local gate that touches
`.github/workflows/*.yml`) is sufficient to validate the YAML. Issue #1619 was already
closed as part of this grooming (per the planner's STEP 6) — reference it in the
implementation PR body, no further issue action needed.

## Implementation

Applied the caching pattern to both workflows' `terragrunt`/`retry` jobs, right after
their existing `Install terragrunt` step and before credential rendering:

- `Set TF_PLUGIN_CACHE_DIR` env step + `mkdir -p "$TF_PLUGIN_CACHE_DIR"` (identical to
  `ci.yml`'s `terraform` job).
- `actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9` (v6.1.0, same pinned SHA as
  `ci.yml`), path `${{ env.TF_PLUGIN_CACHE_DIR }}`.

One deviation from `ci.yml`'s exact cache-key pattern was necessary: `ci.yml` keys on
`hashFiles('infra/modules/**/.terraform.lock.hcl')` because `infra/live/local/`'s lock
files are committed. `infra/live/oracle/`'s lock files are **not** committed (no
`.terraform.lock.hcl` exists under `infra/live/oracle/` or
`infra/modules/oracle-k3s-cluster/`/`infra/modules/argocd/` — verified via `find`), so
that exact hash pattern would always evaluate to the same (empty-hash) key. Instead,
each workflow's cache key hashes the relevant module(s)' `main.tf` — the file whose
`required_providers` block actually determines which provider versions get pulled:

- `oracle-cluster-apply-retry.yml` (hardcoded to the `cluster` unit only): keys on
  `infra/modules/oracle-k3s-cluster/main.tf`.
- `oracle-cluster-apply.yml` (dispatches against either the `cluster` or `argocd`
  unit): keys on both `infra/modules/oracle-k3s-cluster/main.tf` and
  `infra/modules/argocd/main.tf`, since a single job serves whichever unit
  `inputs.unit` selects.

Both use the same `restore-keys: ${{ runner.os }}-tfplugins-oracle-` fallback prefix
and share a cache-key namespace (`tfplugins-oracle-`, distinct from `ci.yml`'s
`tfplugins-` namespace for the `infra/modules/**` local-backend units).

## Verification

- `make lint` (shellcheck + yamllint) — clean.
- `make ci` — full run green (bats/kustomize/terraform/drift/manifests, all gates).
- This remote session has no reachable Oracle Cloud credentials or network egress to
  `*.oraclecloud.com`/`registry.terraform.io` (ADR-0027's own caveat, restated in
  `oracle-cluster-apply.yml`'s header comment), so the cache actually restoring/saving
  correctly can only be verified by these two workflows' own next real runs — same
  caveat every other currency bump in these two files' history already carries.

## PR

#1621
