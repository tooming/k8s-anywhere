# Planner note — 2026-07-04: TiDB + Longhorn on-demand observability

## What was blocked

The "Now / next" lane has four unchecked items, all with live-cluster or
maintainer-confirmation prerequisites the executor cannot verify clusterlessly:

1. `auto/cosign-enforce-flip` — requires maintainer to confirm a `.sig` tag was
   pushed to Artifactory by the GitLab CI signing flow.
2. `auto/o4-ci-rejection-gate` — depends on #1 merging first.
3. `auto/harbor-capstone-rewire` — requires maintainer to confirm Harbor fits the
   12 GB budget on-demand (GitHub issue #297 go/no-go gate).
4. `auto/harbor-artifactory-decommission` — depends on #3 merging first.

None of these can be built by the executor this run. The lane is functionally
stalled on two human-gated confirmations.

## Gap analysis (what was found)

Comparing the CHARTER Core Values ("Real observability only — dashboards and
outputs reflect auto-discovered state") against the actual repo state:

- **TiDB on-demand observability**: `gitops/tidb/networkpolicy/allow-tidb-from-observability.yaml`
  already allows ingress TCP 10080 from `observability` — but the NP comment
  references an "existing Alloy scrape job" that **does not exist** in
  `gitops/platform/observability-alloy.yaml`. No `prometheus.scrape "tidb"` block
  is present. No `grafana/dashboards/lab-tidb.json` exists. This is a NP/scrape
  mismatch that leaves TiDB metrics unscraped and the on-demand component
  unobservable.

- **Longhorn on-demand observability**: `gitops/longhorn/networkpolicy/allow-longhorn-metrics-ingress.yaml`
  allows ingress TCP 9500 from `observability` — but no `prometheus.scrape "longhorn"`
  block exists in `observability-alloy.yaml`. No `grafana/dashboards/lab-longhorn.json`
  exists. Longhorn exposes real Prometheus metrics at `:9500/metrics` but they are
  not collected.

Both gaps follow the established on-demand observability precedent:
`lab-kargo.json` + scrape job (added in `auto/kargo-observability-dashboard`),
`lab-harbor.json` + scrape job (added in `auto/harbor-observability-dashboard`),
`lab-inkless.json` + scrape job (existing). The TiDB and Longhorn gaps are the
last two on-demand components with NP metrics-ingress allows but no corresponding
scrape + dashboard.

## Items added to ROADMAP.md "Now / next"

Two new 🟢 items added at the end of "Now / next" (after `auto/networkpolicy-tier1-bats`):

- `auto/tidb-dashboard` — TiDB on-demand Alloy scrape + dashboard
- `auto/longhorn-dashboard` — Longhorn on-demand Alloy scrape + dashboard

Both are pure dashboard + scrape-config changes (🟢 Green tier). No Makefile
changes, no new chart sources, no new NP changes (the ingress allows are
pre-wired). The executor can build either item without prerequisites.

## Blocking condition surface (O4)

The lane's O4-chain blockage (verifyImages enforce flip + CI rejection gate)
requires the maintainer to confirm the cosign CI signing flow is working — at
least one GitLab CI run must have pushed a `.sig` tag to the Artifactory
registry. Once the maintainer verifies this on PR #297 (or a dedicated comment),
the executor can pick up `auto/cosign-enforce-flip` directly.
