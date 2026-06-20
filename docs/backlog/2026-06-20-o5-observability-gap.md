# Planner run 2026-06-20 — O5 gap-fill: observability infrastructure dashboards

## Context

Planner invoked as executor fallback (lane analysis: External Secrets dashboard
in-flight as PR #234; ArgoCD PSS Phase 2 + verifyImages Enforce flip both blocked
on maintainer cluster confirmation; PSS items from RFCs #229 + #230 being groomed
by PR #235). No open GitHub issues to groom (intake queue empty). No files in
`docs/roadmap/incoming/`.

## Gap analysis

CHARTER O5: "every Application in `gitops/bootstrap/root-app.yaml`'s auto-synced
set has a matching `grafana/dashboards/lab-<name>.json` with at least one panel
backed by a real data source — by 2026-09-30."

Cross-referencing all Applications with `automated:` syncPolicy in `gitops/platform/`
against the existing `grafana/dashboards/lab-*.json` files (accounting for catch-all
dashboards: `lab-cloud-control-plane.json` covers ack-s3/kro/moto; `lab-capstone.json`
covers demo/data-demo; overlays and NetworkPolicy Applications don't need own dashboards):

| Application | Expected dashboard | Status |
|---|---|---|
| observability-alloy | lab-alloy.json | **MISSING** — no self-scrape, no dashboard |
| observability-ksm | lab-ksm.json | **MISSING** — metrics already scraped |
| observability-node-exporter | lab-node-exporter.json | **MISSING** — metrics already scraped |
| external-secrets | lab-external-secrets.json | In-flight as PR #234 |
| All other auto-synced apps | lab-*.json | Covered ✓ |

Notes:
- `cilium` has `# DO NOT add an automated: syncPolicy block` comment — it is NOT
  auto-synced; brought up manually via `make cilium-up`. Not an O5 gap.
- `s3manager` is a utility web UI; it has an HTTPRoute entry in stack-health.json
  and doesn't expose meaningful Prometheus metrics. Excluded from O5 scope as it
  has no scrape-able service.
- `tidb-*` apps carry `# ON-DEMAND: no automated: block` guards — not auto-synced.

## Items groomed

Three new 🟢 executor items added to ROADMAP.md `Now / next` after the blocked items:

1. **`auto/alloy-self-monitoring`** — Grafana Alloy self-monitoring dashboard + new
   self-scrape job targeting `alloy.observability.svc.cluster.local:12345`. Requires
   modifying `observability-alloy.yaml` to add the scrape block (same Green-tier
   pattern as external_secrets, kyverno, argo_rollouts scrape jobs added in previous
   executor PRs).

2. **`auto/ksm-cluster-health-dashboard`** — KSM cluster-health dashboard. KSM metrics
   already scraped via existing `prometheus.scrape "ksm"` block. Dashboard-only PR:
   new `lab-ksm.json` + bats tests + dependency-tree.md update.

3. **`auto/node-exporter-vitals-dashboard`** — Node Exporter vitals dashboard. Metrics
   already scraped via existing `prometheus.scrape "node_exporter"` block. Dashboard-
   only PR: new `lab-node-exporter.json` + bats tests + dependency-tree.md update.

## No issues closed

No open issues were present in the intake queue (0 open GitHub issues).
