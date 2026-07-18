- [ ] 🟡 **Migrate Grafana chart source off the deprecated `grafana.github.io/helm-charts`
  repo** (RFC #544 — architect decision 2026-07-18). `gitops/platform/observability-grafana.yaml`'s
  chart source (`repoURL: https://grafana.github.io/helm-charts`, `targetRevision: 10.5.15`)
  is deprecated and frozen: the chart's own `Chart.yaml` at that tag carries `deprecated: true`,
  and its README states migration to `grafana-community/helm-charts` completed
  2026-01-30. Migrate to `repoURL: https://grafana-community.github.io/helm-charts`,
  `targetRevision: 12.7.2` (verified current at the new source, `appVersion: 13.1.0`).
  Do **not** bump the running Grafana image version in the same change — `valuesObject.image.tag`
  stays pinned at `"13.0.1"` (documented unified-storage migration bug history for
  Git Sync users, ADR-0006); the chart-source migration only picks up newer Helm
  templates/schema, not a newer running binary. `observability-alloy.yaml` and
  `observability-pyroscope.yaml` also use the old repoURL but show no deprecation
  signal at their own dedicated source repos — out of scope for this item.
  See RFC #544's acceptance criteria for the full schema-diff and doc-update checklist.
  `make ci` must pass. `docs/done/` entry required. Closes #544.
