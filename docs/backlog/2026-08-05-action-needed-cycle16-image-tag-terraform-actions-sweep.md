# [Action needed] Now/next still gated; image-tag/Terraform-chart/GitHub-Actions sweep clean after two real fixes landed this run

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
recent cycle has found gated, re-verified fresh this cycle:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (still open,
   no new comment since 2026-08-04).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (still open,
   no new comment since 2026-08-04).

[#980](https://github.com/tooming/k8s-anywhere/pull/980) (the maintainer's
own in-progress GitLab-runner work toward confirming both gates) is
unchanged. [#999](https://github.com/tooming/k8s-anywhere/issues/999) is
also unchanged.

## This run is NOT idle — two real fixes already landed this cycle-chain

Before reaching this record, this run's PLANNER-fallback passes found and
shipped two genuine upstream-currency deltas, each its own plan PR + build
PR (four merged PRs total):

- [#1008](https://github.com/tooming/k8s-anywhere/pull/1008) / [#1009](https://github.com/tooming/k8s-anywhere/pull/1009) —
  `ack-s3` (AWS Controllers for Kubernetes S3 chart) `1.8.2` → `1.9.0`.
- [#1010](https://github.com/tooming/k8s-anywhere/pull/1010) / [#1011](https://github.com/tooming/k8s-anywhere/pull/1011) —
  Vault's pinned image `hashicorp/vault:2.0.3` → `2.0.4` (server +
  unsealer), including distinguishing two real dependency-CVE fixes
  (GO-2026-5158/5841) from three false-positive-suppression commits that
  looked security-relevant at a glance but weren't.

This record covers the sweep that came up clean *after* those two real
fixes — i.e. this cycle's honest "nothing further found" record, not a
substitute for the work already shipped above.

## This cycle's fresh angles (none of cycles 1–15 or this run's own earlier
passes used these)

1. **Terraform-bootstrapped Helm chart versions beyond ArgoCD** — grepped
   `infra/modules/**/*.tf` for any other `chart_version`/`helm_release`
   pattern. Only `infra/modules/argocd` defines one (already current,
   `10.2.3`, bumped 2026-08-05 earlier today). No other Terraform-bootstrapped
   chart exists in this repo.
2. **Terraform provider version constraints** — `infra/modules/*/main.tf`'s
   `required_providers` blocks all use `~>` pessimistic constraints (ranges,
   not exact pins — e.g. `hashicorp/local ~> 2.5`, `hashicorp/random ~> 3.2`,
   `hcloud`-style `~> 8.0`). These resolve to the latest matching version at
   `terraform init` time automatically — not a stale-pin gap the way an
   exact `targetRevision`/`image:` tag is; nothing to bump.
3. **GitHub Actions workflow pins** — every `uses:` line across
   `.github/workflows/*.yml` re-verified directly against the real action
   repos: `actions/checkout@v7.0.1`, `actions/cache@v6.1.0`,
   `actions/github-script@v9.0.0`, `hashicorp/setup-terraform@v4.0.1` — all
   four are the exact newest stable tag on their respective repos right now
   (`git ls-remote --tags`, checked live). No gap.
4. **Garage (in-cluster S3 store, ADR-0002) image tag** — `dxflrs/garage:v2.3.0`
   pinned in `gitops/storage/garage/statefulset.yaml`. `git ls-remote --tags
   deuxfleurs-org/garage` shows `v2.3.0` as the newest stable tag. No gap.
5. **`scripts/lib/*.sh` direct bats coverage** — re-verified every lib file
   (including `frozen-monolith-check.sh`/`-sync-hook.sh`, fixed by this
   run's own earlier work) has a referencing `tests/*.bats` file. Clean.
6. **Orphaned `scripts/*.sh` check** — every script in `scripts/` is
   referenced by at least one of Makefile / another script / a test / a CI
   workflow / a git hook. No dead scripts found.

## Assessment

Two real, verified fixes shipped this run before this record (ack-s3 chart,
Vault image — both with a genuine security/currency rationale, not blind
bumps). This cycle's own fresh sweep, across six angles none of today's 15
prior cycles or this run's own earlier passes used, comes up clean. The
remaining gated items are genuinely blocked on live-cluster facts only the
maintainer can observe (a real GitLab CI run, a real Kargo promotion) — not
on an undiscovered gap in this repo.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) PR #980
merging; (c) a new GitHub issue (ungroomed intake — currently none exists);
(d) a new upstream CVE/release firing one of this repo's many tracked flip
conditions.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
