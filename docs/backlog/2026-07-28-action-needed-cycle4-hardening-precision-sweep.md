# [Action needed] Now/next still gated; hardening/doc-precision sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). Earlier cycles this run already shipped `upgrade/*` PRs #789 (Alloy
chart) and #790 (Grafana chart), plus filed issue #791 (Terraform provider major-version
gaps) via PR #792 — all merged.

This cycle tried four distinct, previously-untried lenses per ROADMAP rule #9's
"try a lens the last pass didn't" guidance:

1. **ADR re-evaluation staleness.** Computed each ADR's most recent dated
   `## Re-evaluation log` entry. `adr-0021-velero-backup-restore.md` (last touched
   2026-07-20, the longest gap among version-pinning ADRs) was re-checked: the pinned
   chart (`velero`, `12.1.0`) is confirmed still the real upstream latest
   (`vmware-tanzu/helm-charts` `Chart.yaml`, live fetch), and no new 2026 security
   advisory exists beyond the one already-known 2020 GHSA. `adr-0007` (off-cluster Garage
   tfstate backend, no re-evaluation log at all) pins the identical image
   (`dxflrs/garage:v2.3.0`) as the in-cluster Garage instance already checked clean two
   days ago (`docs/backlog/2026-07-26-action-needed-cycle3-harbor-kafka-gitlab-recheck.md`)
   — no separate finding.
2. **CHARTER Objective measurement-mechanism presence check.** Verified O3 ("`make
   dr-restore` ... measured by a bats target that times the restore") and O6 ("`make
   capstone-demo` ... wall-clocks the path") both already have real `Makefile` targets
   (`dr-restore`, `capstone-demo`) and dedicated bats coverage (`tests/dr-restore.bats`,
   `tests/capstone-demo.bats`) — both objectives' `make ci` presence-check bar is already
   met.
3. **TODO/FIXME sweep** across `gitops/`, `infra/`, `scripts/`, `Makefile`: only two
   markers exist, both already known and tracked (the `argo-cd` `global.image.tag: latest`
   TODO re-verified as still correctly un-actionable in issue #781 earlier today; the
   `disallow-latest-tag.yaml` policy's documented exception for that same override).
4. **Doc-precision check.** Every `ADR-NNNN` citation in CHARTER.md (15 distinct numbers)
   resolves to a real `docs/decisions/adr-NNNN-*.md` file whose topic matches its citation
   context — no stale/wrong ADR-number reference found.

No actionable gap surfaced from any of the four lenses this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
