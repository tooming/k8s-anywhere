# ADR index gap + stale planned/count claims across 5 docs — record correction

Executor-fallback JANITOR pass (`executor.prompt.md` STEP 6b, fifteenth cycle,
2026-08-10), via a sixth delegated deep gap-analysis sweep. Six independently-verified
drift bugs found and fixed, all record-correction (the real state already exists and
is already tested elsewhere — only the prose describing it had gone stale).

## What changed

- `docs/decisions/README.md` — added missing ADR-0033/ADR-0034 index entries.
- `docs/decisions/adr-0013-longhorn-block-storage.md` — fixed stale "manifests
  pending" status line; Longhorn has been live for months.
- `docs/dora-audit-readiness.md` — fixed Q14's stale dependency-register tool/ADR
  count (22/20 → 32/24, direct count).
- `docs/dependency-register.md` — fixed its own scope note's stale ADR count (32 →
  34), which contradicted the same file's body 40 lines below.
- `docs/platform-products.md` — fixed TiDB/Istio+Kiali/Longhorn/artifact-registry rows
  (and the Tier-5 diagram, priority table, intro, and team-ownership table) from
  "planned" to "on-demand, built"; replaced stale "Artifactory/Nexus" with Harbor
  (ADR-0024 superseded Artifactory in July).
- `docs/decisions/adr-0029-keda-event-driven-autoscaling.md` — relabeled the "Out of
  scope" section header; both listed follow-ups (cert-manager TLS wiring, ScaledObject
  demo) are already shipped per the same ADR's own Files table.

## Verification

Every claim read directly at both ends of the contradiction before editing (ADR-0004).
Confirmed `tests/keda.bats`/`tests/keda-scaledobject.bats` exist and
`gitops/platform/keda.yaml`/`gitops/data/demo/keda-scaling/` manifests are real before
touching the KEDA ADR. `make ci` green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1096
