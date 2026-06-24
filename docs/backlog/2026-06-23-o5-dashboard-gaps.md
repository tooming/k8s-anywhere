# Planner run — 2026-06-23 (O5 dashboard gaps)

## Context

The executor's "Now / next" lane had only two unchecked items, both blocked on
maintainer confirmation of in-cluster state:

- **ArgoCD PSS Phase 2** — requires the maintainer to verify Phase 1 is green in
  cluster before enabling the `enforce: restricted` label and `infra/` securityContext
  changes (RFC #205).
- **verifyImages Enforce flip** — requires the maintainer to confirm that at least
  one CI run has pushed a `.sig` tag to Artifactory after the `auto/cosign-ci-sign-step`
  PR merged (RFC #214).

Both are correctly in the ROADMAP; both remain blocked. No open GitHub issues existed
to groom. No pending architect items were found in `docs/roadmap/incoming/`.

## Gap analysis

**Objective O5** ("by 2026-09-30, every auto-synced Application has a
`grafana/dashboards/lab-<name>.json`") is the only objective with buildable
🟢 work remaining before its deadline.

Comparing `gitops/platform/` auto-synced Applications (those with an `automated:`
YAML key) against existing `grafana/dashboards/lab-*.json` files revealed two gaps:

| Application | ArgoCD app name | Namespace | Missing dashboard |
|---|---|---|---|
| `gitops/platform/demo.yaml` | `demo` | `lab-demo` | `lab-demo.json` |
| `gitops/platform/data-demo.yaml` | `data-demo` | `data` | `lab-data-demo.json` |

All other auto-synced Applications with workload pods are covered:
- observability-* → lab-alloy, lab-ksm, lab-loki (logs), lab-mimir, lab-node-exporter,
  lab-pyroscope (profiles), lab-tempo (traces), lab-grafana
- ack-s3 + kro + moto → lab-cloud-control-plane
- Single-app coverage: lab-capstone, lab-envoy, lab-external-secrets, lab-garage,
  lab-kyverno, lab-rabbitmq, lab-s3manager, lab-trivy, lab-valkey, lab-vault, lab-velero,
  lab-argo-rollouts; lab-argocd (from argocd-extras)
- NP-only / namespace-label-only Applications (no pods): excluded from O5 requirement

## Items added to ROADMAP.md

One new 🟢 item added to "Now / next" (after the `auto/pss-np-inkless` entry):

**`auto/demo-data-demo-dashboards`** — bundles `lab-demo.json` and `lab-data-demo.json`
in one PR. Both use only KSM + cAdvisor data already scraped by Alloy (no new scrape
jobs). Neither app has its own Prometheus metrics endpoint (HotROD is trace-only;
rabbitmq-load/valkey-load are shell loops). The dashboards show pod health + ArgoCD sync
state, which is the minimum O5 requires. Executor note allows splitting if the PR
crosses ~400 lines.

## No issues filed or closed this run

No open issues existed. No RFC issues were pending. No issues were opened because the
gap analysis produced a concrete ROADMAP item (not just a direction question).
