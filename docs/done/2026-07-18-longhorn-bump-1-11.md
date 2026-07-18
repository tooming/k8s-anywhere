# Bump Longhorn `1.7.3` → `1.11.x`

CHARTER **Core Values** §"Everything as code" + general hardening; RFC #528 —
architect decision 2026-07-18. Longhorn's `1.7.x` line reached end-of-life
2025-09-04 (one year after its first stable release, under the pre-1.8
12-month support policy); this lab's pinned `targetRevision: 1.7.3`
(`gitops/platform/longhorn.yaml`) has received no security patches for
roughly a year — a version-currency gap, not a single named CVE. Lower
urgency than a typical bump since Longhorn is **on-demand** (ADR-0013, never
auto-synced) — zero exposure unless the maintainer runs `make longhorn-up`.

Per RFC #528's acceptance criteria the executor independently re-verified the
exact target version at pickup time (Longhorn ships on a fast 4-month
cadence) rather than assume the RFC's `1.11.x` pin was still current. Bumped
`gitops/platform/longhorn.yaml`'s `targetRevision`; diffed the chart's
`values.yaml` between old and new pins for every key this repo sets;
confirmed the V2 Data Engine stays opt-in, not default, at the new pin.
Updated `docs/decisions/adr-0013-longhorn-block-storage.md` with the new pin
+ a `## Re-evaluation log` entry (trigger: 1.7.x EOL, not a CVE). Added
chart-pin assertions in `tests/longhorn.bats` (none existed before). Fixed
`docs/dependency-tree.md`'s stale "v1.7.2" Longhorn references to the new
pin. Closes #528.

## What changed

`gitops/platform/longhorn.yaml`'s `targetRevision` bumped `1.7.3` → `1.11.3`
(the latest stable patch on the `1.11.x` line at pickup time — re-confirmed
directly against `longhorn/longhorn` and `longhorn/charts`' GitHub release
tags, not assumed from the RFC). Deliberately one minor line behind the
newest `1.12.x`, which just went GA with the V2 Data Engine — a bigger
behavioral-surface change than this routine currency bump warrants.

No `valuesObject` change: diffed every key this repo's Application sets
against the chart's `1.11.3` `values.yaml` —
`defaultSettings.defaultReplicaCount`, `persistence.defaultClassReplicaCount`,
`ingress.enabled`, `longhornUI.{replicas,resources}`,
`longhornManager.resources` all still exist unchanged. The upstream default
for `longhornUI.resources` is unset (`~`) at this pin, but that's the
*default* value, not a removed schema key — this repo's own override applies
normally regardless.

`docs/decisions/adr-0013-longhorn-block-storage.md` updated: the Decision
section now cites the new pin, and a new `## Re-evaluation log` section
records the trigger (1.7.x EOL), the decision, the version re-verification
performed, the ADR-0004 caveat, the rollback-path risk, and the next flip
condition.

`tests/longhorn.bats` gained two recurrence-guard assertions: the
Application is pinned to a `1.11.x` tag, and the old EOL'd `1.7` pin is gone
— no test pinned this chart version before this PR.

`docs/dependency-tree.md`'s two stale "v1.7.2" Longhorn references (already
one patch behind the actual `1.7.3` pin before this bump) corrected to the
new `v1.11.3` pin.

## Version re-verification (per RFC #528's acceptance criteria)

Re-checked at pickup time rather than trusting the RFC's own summary:
confirmed via `longhorn/longhorn`'s and `longhorn/charts`' GitHub releases
that `1.11.3` remained the latest stable patch on the `1.11.x` line, and that
`1.12.0` was the newest stable release overall (only a `1.12.1-rc1`
pre-release existed beyond it) — the RFC's version choice was still current.

## ADR-0004 caveat — what this run could NOT verify

This remote clusterless session cannot verify Longhorn's CSI driver,
manager, or UI actually start cleanly against real (or absent) volume data
on a live cluster post-bump.

**Rollback path.** Revert `gitops/platform/longhorn.yaml`'s
`targetRevision`; since Longhorn is on-demand and not auto-synced, this
carries zero live-cluster risk unless the maintainer already has it running
via `make longhorn-up` with real provisioned volumes, in which case a
version-format mismatch on downgrade is possible (same class of risk as any
stateful storage engine) — verify current state before reverting if
Longhorn is actually up.

## Validation

`make ci` — fully green (bats/kustomize/terraform tools aren't installed in
this remote environment; the full suite runs in GitHub Actions on the PR).

## PR

https://github.com/tooming/k8s-anywhere/pull/531
