# [Action needed] Now/next still gated; docs/done record-completeness sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped fifteen real, merged deliverables (PRs
#789, #790, #792–#804), including two live-cluster bugfixes (#796, #797).

This cycle checked ROADMAP rule #7's own record-keeping requirement ("Check it off in the
same PR... create `docs/done/YYYY-MM-DD-<slug>.md`"): extracted all 118 branch-slug
references from ROADMAP.md (`auto/*`, `arch/*`, `plan/*`, `upgrade/*`, `chore/*`, `sync/*`)
and fuzzy-matched each against the 246 files under `docs/done/`. 9 had no obvious
substring match. Investigated each:

- 6 (`kyverno-policies`, `cosign-enforce-flip`, `o4-ci-rejection-gate`,
  `harbor-capstone-rewire`, `harbor-artifactory-decommission`,
  `capstone-deployment-removal`) are still-**unchecked** `[ ]` items (the same gated
  items this run has re-verified every cycle) — of course no `docs/done/` entry exists
  yet, that's correct and expected.
- 3 (`cilium-cve-bump-1-17-18`, `kargo-cve-bump-1-6-4`, `argocd-chart-10x-bump`) are
  checked `[x]` items that DO have real `docs/done/` records
  (`2026-07-18-cilium-cve-bump.md`, `2026-07-18-kargo-cve-bump-and-fixes.md`,
  `2026-07-28-argocd-chart-bump-9-7-1-to-10-2-1.md` respectively) — the fuzzy substring
  match just failed because those filenames don't repeat the exact version numbers from
  the branch slug. Confirmed by direct `ls`/`grep`, not assumed.

Every currently-checked ROADMAP item has a real `docs/done/` record. No actionable gap
surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
