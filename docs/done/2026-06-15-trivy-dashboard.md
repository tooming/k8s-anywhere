# Trivy Operator dashboard — done

**Branch:** `auto/trivy-dashboard`
**ROADMAP item:** `🟢 Trivy Operator dashboard (CHARTER Objective O1 + O5; auto/trivy-dashboard)`
**Date:** 2026-06-15

## What was delivered

New `grafana/dashboards/lab-trivy.json` — "Lab — Trivy Operator (Supply Chain)" dashboard
modelled on `lab-kyverno.json` stat-row pattern. Panels:

- **Operator Running** — `kube_deployment_status_replicas_available{namespace="trivy-system"}` (KSM)
- **Memory (MiB)** — `container_memory_working_set_bytes{namespace="trivy-system"}` (cAdvisor)
- **ArgoCD Synced** — `argocd_app_info{name=~"trivy-operator.*", sync_status="Synced"}`
- **CVE Critical / High / Medium / Low** — `sum(trivy_image_vulnerabilities{severity="…"})` for each severity
- **SBOM Reports (total)** — `sum(trivy_sbom_reports_total)` (direct CHARTER supply-chain goal)
- **Restarts (max)** — `kube_pod_container_status_restarts_total{namespace="trivy-system"}`
- **Top-10 Vulnerable Workloads** — `topk(10, sum by (resource)(trivy_image_vulnerabilities))` (bargauge)
- **ConfigAudit Checks by Severity** — `sum by (severity)(trivy_config_audit_checks_total)` (piechart donut)

All panels use real Mimir data with `noValue` fallbacks that show "no scans yet" / "not deployed" naturally until scan data arrives — no fabricated content (ADR-0004). Trivy has no web UI, so no HTTPRoute or stack-health.json row was added.

The Alloy scrape job (`prometheus.scrape "trivy_operator"` targeting
`trivy-operator.trivy-system.svc.cluster.local:8080`) was already wired in
`gitops/platform/observability-alloy.yaml` by the prior `auto/trivy-operator` PR.

## Other changes

- `tests/trivy-operator.bats` — 7 new dashboard assertions: file exists, references
  `trivy_image_vulnerabilities`, references `trivy_sbom_reports_total`, references
  `trivy_config_audit_checks_total`, no fabricated data (ADR-0004), uses Mimir datasource,
  and `docs/dependency-tree.md` Trivy note updated.
- `docs/dependency-tree.md` — Trivy Operator note updated to confirm dashboard present;
  new integration-edges table row added for the Grafana dashboard.
- `ROADMAP.md` — item checked `[x]`.
