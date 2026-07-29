# [Action needed] Now/next still gated; full-toolchain make ci + fallback-chain re-verify

## What's blocked

ROADMAP.md's *Now / next* lane still holds exactly 5 unchecked `[ ]` items, all
gated on the same standing maintainer-confirmation issues, re-checked this
cycle: [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — all three still
open, **zero comments**, unchanged since 2026-07-21. Every one of the 5 items
(`auto/cosign-enforce-flip`, `auto/o4-ci-rejection-gate`,
`auto/harbor-capstone-rewire`, `auto/harbor-artifactory-decommission`,
`auto/capstone-deployment-removal`) is already at minimal split-gate scope —
re-verified line-by-line this cycle: each remaining gate is a genuine
live-cluster-observation fact (a signed image actually pushed, a measured
Harbor footprint, an observed Kargo promotion) that no clusterless session can
substitute for, not a splittable batch of live+non-live work.

## What this cycle already did

Recovered a stranded PR from a prior run per executor STEP 1b:
[#830](https://github.com/tooming/k8s-anywhere/pull/830) (`arch/adr-0018-redis-license-recheck`)
had gone CI-green with no `[self-review]` comment posted — finished its
self-review and merged it (ADR-0018 audit #829: Redis's new AGPLv3 tri-license
option doesn't unseat Valkey; Keep, with a recorded flip condition).

## This cycle's fresh angle

Rather than repeat a prior sweep's text/pin-diffing technique, this cycle
walked the executor's own STEP 6b fallback chain fresh, with genuinely new
verification methods at each stop:

1. **Planner lens** — `gh issue list --state open` shows only the 3 standing
   `[Action required]` issues above; no ungroomed intake exists. Backlog is
   healthy at the ROADMAP-item level; nothing to promote or split further.
2. **Upgrade-drafter lens, but on CI tooling rather than gitops charts** (a
   distinct sub-scope no prior sweep note has covered explicitly): checked
   every pinned tool/action in `.github/workflows/ci.yml` directly against
   upstream via `git ls-remote --tags` (not assumed from training knowledge,
   ADR-0004) — `actions/checkout` (pinned `v7.0.1`, latest tag `v7.0.1`),
   `actions/cache` (pinned `v6.1.0`, latest `v6.1.0`), `hashicorp/setup-terraform`
   (pinned `v4.0.1`, latest `v4.0.1`), `kubeconform` (pinned `v0.8.0`, latest
   stable `v0.8.0`), `kustomize` (pinned `v5.8.1`, latest `v5.8.1`), Terraform
   binary (pinned `1.15.8`, latest stable `1.15.8`, next line is alpha-only).
   Every one is already current — no bump available.
3. **Full local toolchain install** — installed `bats`, `shellcheck`,
   `yamllint` (apt), `kubeconform v0.8.0`, `kustomize v5.8.1`, `terraform
   1.15.8`, and `mikefarah/yq` (binary releases) directly into this sandbox, so
   `make ci` ran for real instead of soft-skipping those checks locally (helm
   remains uninstallable here: `get.helm.sh` is unreachable from this sandbox,
   `github.com/helm/helm/releases` 404s through the proxy, no apt/snap package
   exists — a sandbox network-egress limitation, not a repo issue; the two
   helm-dependent checks, `helm-chart-pin-check` and the large-CRD SSA check,
   still soft-skip locally exactly as documented, matching prior sessions).
   Result: **full `make ci` run, exit 0, zero failures**, 2000+ real bats
   assertions executed (not skipped) for the first time this cycle instead of
   trusting a partial/skip-heavy run.
4. **Doc-drift lens** — the same full `make ci` run is doc-drift-author's own
   detection step (STEP 2); zero drift signals fired.
5. **CHARTER Objectives build-verification** (a angle not covered by any prior
   note listed in `docs/backlog/`) — directly checked that O3 and O6's stated
   *Measured by* mechanisms actually exist rather than trusting the ROADMAP's
   checked-off claim: `make dr-restore` (`Makefile:466`) + `tests/dr-restore.bats`
   exist for O3; `make capstone-demo` (`Makefile:494`) + `tests/capstone-demo.bats`
   exist for O6. Both objectives' measurement infrastructure is real, not just
   claimed.
6. **Janitor lens, script-coverage angle** — cross-referenced every file under
   `scripts/*.sh` (81 files) against `tests/`: every single script has at least
   one referencing bats file. No orphaned/untested script found.

No bounded, real, behavior-preserving cleanup or upgrade qualified this cycle.
Every fallback-chain stop (planner, upgrade-drafter, doc-drift, janitor) came
back clean via a distinct verification method from every prior dated note in
this directory — a materially stronger confidence level than a text-diff
sweep (this cycle actually *ran* the tools rather than skipping them), not a
repeat of the same technique for its own sake.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) `get.helm.sh` or an equivalent helm
binary source becoming reachable from this sandbox, so the two currently
soft-skipped helm-dependent local checks can also run for real (they still
run correctly in the GitHub Actions CI environment, which has open network
egress — this is a local-sandbox-only gap, not a `make ci` gate integrity
issue).

This note is this cycle's honest record — the run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
