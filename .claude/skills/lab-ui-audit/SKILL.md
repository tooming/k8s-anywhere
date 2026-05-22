---
name: lab-ui-audit
description: >-
  Audit and sync the "Lab UIs" panel in the Grafana stack-health dashboard
  against the cluster's actual Envoy routes, so a newly added (or removed)
  in-cluster UI is never missing from the dashboard. Use this in the k8s-lab
  project whenever you add, remove, or re-route a user-facing UI (anything with
  a Gateway-API HTTPRoute hostname, plus the off-cluster GitLab), or whenever
  the user says a UI link is missing / stale on the dashboard.
---

# Lab UI audit

**Why this exists:** the "Lab UIs" table is hand-maintained in
`gitops/observability/dashboards/stack-health.yaml` (panel id 10). It is easy to
add a UI and forget the link. This skill makes the check mechanical.

## Definition of done for any UI change
A UI change is **not complete** until the "Lab UIs" table reflects it in the
*same* commit. A "UI" = anything a human opens in a browser:
- in-cluster apps exposed via an Envoy **HTTPRoute** with a `hostname`
  (`*.127.0.0.1.nip.io`) or a path on `localhost:8080`, **plus**
- off-cluster UIs (GitLab on `:8929`).

Backends viewed *through* Grafana (Mimir, Loki, Tempo, Pyroscope) are **not**
separate UIs — do not list them.

## Audit procedure
1. List live routes and their hostnames:
   ```sh
   kubectl get httproute -A \
     -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,HOSTNAMES:.spec.hostnames'
   ```
2. List what the dashboard currently advertises:
   ```sh
   grep -oE '\| \*\*[^*]+\*\* \| http[^ ]+' gitops/observability/dashboards/stack-health.yaml
   ```
3. Diff them. Every routed UI (host-based or `localhost` path) must appear once
   in the table; every table row must map to a real route (or GitLab). Add
   missing rows, remove dead ones.
4. Each row: `| **Name** | URL | one-line role |`. Host-based UIs use
   `http://<name>.127.0.0.1.nip.io:8080` (Envoy listener is `:8080`).
5. If the table grew, bump the panel-10 `gridPos.h` so rows still fit, and shift
   the `y` of every panel below it by the same delta.
6. Commit + push to the `gitlab` remote (ArgoCD syncs from there), then refresh:
   `kubectl -n argocd annotate application observability-dashboards argocd.argoproj.io/refresh=hard --overwrite`
   (or the `grafana`/`root` app if the panel ships via the Grafana chart).

## Current expected set (keep in sync)
ArgoCD · Grafana · Vault · GitLab · S3 browser (s3manager) · moto.
