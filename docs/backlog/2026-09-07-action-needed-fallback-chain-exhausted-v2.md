# [Action needed] Fallback chain exhausted again — 7 real JANITOR fixes landed this streak, vein now substantially mined

Follow-up to
[2026-09-07-action-needed-fallback-chain-exhausted.md](2026-09-07-action-needed-fallback-chain-exhausted.md)
(PR #1488). Since that note, this run's JANITOR-fallback found and fixed
**seven more** distinct, real issues in a single "post-2026-09-06-removal-
wave / stale-claim" sweep across the repo's docs:

- [#1486](https://github.com/tooming/k8s-anywhere/pull/1486) — two stale
  gap notes in ROADMAP.md's Cross-cutting hardening section.
- [#1487](https://github.com/tooming/k8s-anywhere/pull/1487) — GitLab-rename
  item's inline Update prose moved into its investigation file.
- [#1489](https://github.com/tooming/k8s-anywhere/pull/1489) — post-removal-
  wave stale content in `platform-products.md` + `dependency-concentration.md`.
- [#1490](https://github.com/tooming/k8s-anywhere/pull/1490) — stale Q17
  exit-runbook gap claim in `dora-audit-readiness.md`.
- [#1491](https://github.com/tooming/k8s-anywhere/pull/1491) — stale
  tool/ADR count in `dora-audit-readiness.md`'s Q14.
- [#1492](https://github.com/tooming/k8s-anywhere/pull/1492) — a broken
  `ROADMAP.md:2615` line-number citation in `dora-audit-readiness.md`'s Q5.
- [#1493](https://github.com/tooming/k8s-anywhere/pull/1493) — stale
  removed-component examples in `incident-log.md`'s Severity scheme.

This note records that the vein is now **substantially mined**, not
necessarily exhausted forever — a comprehensive re-sweep this cycle found
nothing further:

## What's blocked in "Now / next" (unchanged)

Same three items as the prior note — all still genuinely gated:
1. Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh` (needs live-cluster
   SSH-push design work).
2. Decommission `gitlab/docker-compose.yml` (sequentially blocked on #1 —
   `make up` still calls the GitLab targets for its Terraform-state import).
3. Remove legacy capstone `Deployment` (gated on issue #633, re-checked this
   cycle: still open, unchanged since 2026-09-06, still reporting a genuine
   host-capacity blocker for running Harbor+Kargo long enough to observe one
   full promotion cycle).

## What was re-checked this cycle (all came up empty again)

- **PLANNER-shaped gap analysis**: re-read CHARTER.md's Objectives (O1–O7)
  and Goals sections end-to-end — every Objective is met or on track for its
  date, every qualitative Goal has a corresponding built component with its
  own ADR + bats coverage. No open `rfc`-labeled or otherwise-ungroomed issue
  exists (only #633/#1229, both standing maintainer-gate issues).
- **UPGRADE-DRAFTER, more thoroughly this time**: enumerated every
  `targetRevision:` across `gitops/**/*.yaml` (12 distinct pinned versions,
  excluding the ~35 legitimate self-referencing `main` pins upgrade-drafter's
  own rule exempts) and every `image:` line — all match
  `docs/dependency-register.md`'s already-confirmed-current pins exactly.
  Also checked the Terraform-bootstrapped ArgoCD chart
  (`infra/modules/argocd/variables.tf` + both `terragrunt.hcl` files,
  the enumeration pass upgrade-drafter's own STEP 2 calls out as distinct
  from the `gitops/` walk) — `10.5.0` everywhere, consistent, current.
- **The "post-removal-wave stale content" JANITOR lens itself**: re-ran the
  cross-file grep for TiDB/Istio/Longhorn/RabbitMQ/Valkey/KEDA mentions
  across every `docs/*.md` + README.md + CHARTER.md file that matches —
  every remaining hit (`docs/00-architecture.md`, `docs/DR.md`,
  `docs/dependency-concentration.md`, `docs/dependency-exit-runbooks.md`,
  `docs/dependency-register.md`, `docs/dependency-tree.md`,
  `docs/dora-audit-readiness.md`, `docs/incident-log.md`,
  `docs/platform-products.md`, `README.md`, `CHARTER.md`) is now correctly
  historically framed ("was built, then removed 2026-09-06, no
  replacement"). No further instance of this bug class found.
- Issue #633: re-checked, unchanged (16 comments, last updated 2026-09-06).

## What would open new work

- A live-cluster/interactive session picking up the GitLab-migration items
  or confirming issue #633.
- A future upstream release (checked most recently in this run's own
  `docs/industry/2026-W37-digest.md`) that bumps a pinned chart/image.
- A new GitHub issue, RFC, or CHARTER edit landing between now and the next
  cycle.

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
