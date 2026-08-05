# [Action needed] Now/next still gated; coverage/monolith/CHARTER-objective sweep clean

## What's blocked

Re-verified fresh (nothing has changed since the prior cycle's record,
`docs/backlog/2026-08-05-action-needed-cycle13-split-gate-analysis.md`).
ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (last comment
   2026-08-04, still open).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first (`grep -q "validationFailureAction: Enforce"
   gitops/kyverno/policies/verify-image-signatures.yaml` still fails).
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (last comment
   2026-08-04, still open).

[#980](https://github.com/tooming/k8s-anywhere/pull/980) (human-authored, the
maintainer's own GitLab-runner + registry-port fix toward confirming both
gates) is still open, `mergeable_state: clean`, no new activity since
2026-08-04. [#999](https://github.com/tooming/k8s-anywhere/issues/999) (the
third standing `[Action required]` issue, ArgoCD `argocd` Kyverno
`latest`-tag carve-out) is also unchanged.

## This cycle's fresh angle: coverage completeness + monolith-file + CHARTER-objective sweep

Rather than repeat a chart/image-currency or doc-drift lens (already
exhaustively swept across cycles 1–13), this cycle checked three angles none
of those cycles used:

1. **Every `scripts/*.sh` has bats coverage** — walked all scripts in
   `scripts/` and grepped `tests/*.bats` for each script's basename. Zero
   scripts found without a referencing test.
2. **No shared-monolith file needs splitting** — ranked every tracked
   `.sh`/`.md`/`.yaml`/`.yml`/`.tf`/`.bats` file by line count. Nothing in
   `scripts/` or `lib/` exceeds ~190 lines (`dora-metrics.sh` is the
   largest); the largest files overall are `ROADMAP.md` (append-only backlog
   history, expected to grow) and test/doc files, none of which are
   "shared" code carrying duplication risk in the way the janitor role's
   mandate targets.
3. **CHARTER Objectives O1–O7 cross-checked against real repo state** (not
   assumed): O1 (Tier 1 next-wave) — all four components' Applications,
   ADRs, dashboards confirmed present. O2 (default-deny + PSS-restricted) —
   unchanged since prior sweeps. O3 (stateful DR) — `scripts/dr-restore.sh`
   confirmed to already cover all six namespaces the Objective names (`data
   tidb capstone vault observability inkless`), including the two added
   2026-07-29. O4 — the one genuinely open Objective, tracked by items 1–2
   above. O5 (dashboards) — no new auto-synced Application without a
   dashboard found. O6/O7 — `make capstone-demo` / `make dora-metrics`
   targets confirmed present and wired. No gap found.

Also re-grepped the repo for `TODO`/`FIXME`/`XXX` outside `docs/backlog/` and
`docs/done/`: the two remaining hits (`disallow-latest-tag.yaml`) are both
already tracked by standing issue #999, with an inline dated comment
explaining exactly why the carve-out can't be removed yet (Terraform-only
bootstrap seam, ADR-0001) — no new action available there.

## Assessment

This run (today, 2026-08-05) has already landed a real k3s security bump
(#995/ADR-0030) and an argo-cd chart bump (#1002-adjacent) plus 12 further
merged PRs across five earlier sweep angles per the prior cycle's own
record. This cycle adds a sixth angle (coverage/monolith/objective
completeness) and finds nothing further to build cleanly this run. The three
gated items remain atomic live-cluster-state mutations or CI-runner facts
only the maintainer can observe.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) PR #980
merging; (c) a new GitHub issue of any size; (d) a new upstream CVE/release
against a component this repo tracks.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
