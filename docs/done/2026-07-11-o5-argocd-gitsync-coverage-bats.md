# O5 bats gap — `lab-argocd.json` + `lab-gitsync.json` in `tests/dashboard-coverage.bats`

(CHARTER **Core Values** §"Docs & dashboards don't drift" + **Objective O5**, due
**2026-09-30**; O5 drift gap — both dashboards exist in `grafana/dashboards/` with real
Mimir datasource panels (`"uid": "mimir"`) but are absent from the O5 coverage sweep in
`tests/dashboard-coverage.bats`. `lab-argocd.json` (32 panels) covers ArgoCD operational
metrics already scraped by Alloy (four scrape targets in `observability-alloy.yaml`:
application-controller-metrics:8082, server-metrics:8083, repo-server-metrics:8084,
applicationset-controller-metrics:8080). `lab-gitsync.json` (4 panels, "Lab — Git Sync")
monitors Grafana native Git Sync health and proves ADR-0006 works in the lab. **No
prerequisites — executor may pick up immediately.** Add two section blocks to
`tests/dashboard-coverage.bats` following the existing 2-assertion-per-section pattern
(see `# argo-rollouts` section for the exact style): block headed `# argocd` with
`@test "lab-argocd.json exists (argocd coverage)"` asserting
`[ -f "$DASHBOARDS/lab-argocd.json" ]` and
`@test "lab-argocd.json has real Mimir datasource panel (ADR-0004)"`
asserting `run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-argocd.json"`;
block headed `# gitsync` with the same two assertions for `lab-gitsync.json`.
Verify both JSON files exist and contain `"uid": "mimir"` before committing.
`make ci` must pass. `docs/done/` entry required.
(auto/o5-argocd-gitsync-coverage-bats)

## PR

#361 — https://github.com/tooming/k8s-lab/pull/361
