# Planner run 2026-07-01 — Harbor + Kargo observability gaps

**Run summary**: Gap analysis found two CHARTER Core Value "Real observability only"
gaps for on-demand components (Harbor and Kargo) that lack Grafana dashboards and Alloy
scrape jobs. No open issues to groom. No incoming architect items in `docs/roadmap/incoming/`.

## What was found

### Now/next lane state

The Now/next lane was starved of buildable 🟢 items:

| Item | Status |
|------|--------|
| `cosign-enforce-flip` | Blocked — needs maintainer confirmation that ≥1 CI run pushed `.sig` tags to Artifactory |
| `o4-ci-rejection-gate` | Blocked — depends on cosign-enforce-flip |
| `harbor-make-targets` | In flight — PR #308 |
| `harbor-pss-adr0017-row` | In flight — PR #310 |
| `harbor-capstone-rewire` | Blocked — needs maintainer confirmation on #297 (Harbor footprint gate) |
| `harbor-artifactory-decommission` | Blocked — depends on harbor-capstone-rewire |

### Gap analysis findings

Two components have no Grafana dashboard or Alloy scrape job, violating the CHARTER Core
Value "Real observability only" — every major platform component should have a real-metric
dashboard (not a placeholder). This is the same gap that drove the `lab-inkless.json`,
`lab-alloy.json`, `lab-s3manager.json`, and other on-demand dashboard additions.

1. **Harbor** (ADR-0024): Harbor is deployed as an on-demand OCI registry. The
   `harbor-application` and `harbor-networkpolicy` PRs merged into main. Harbor exposes
   Prometheus metrics via its built-in exporter when `metrics.enabled: true` is set in
   the chart values. No scrape job or dashboard exists yet.

2. **Kargo** (ADR-0023): Kargo is the GitOps promotion engine. It is deployed as an
   on-demand component (`gitops/platform/kargo.yaml`). Kargo api, controller, and
   webhooks-server expose controller-runtime metrics on port 8080. The kargo NetworkPolicy
   has no ingress allow from `observability`, and there is no scrape job or dashboard.

## Items added to ROADMAP.md Now/next

Both items added after `harbor-pss-adr0017-row` and before `harbor-capstone-rewire`
(which is maintainer-blocked) so they are the topmost buildable items:

1. **`auto/harbor-observability-dashboard`** — Harbor dashboard + NP metrics allow +
   Alloy scrape. Prerequisite: harbor-application merged ✓. No maintainer confirmation
   needed.

2. **`auto/kargo-observability-dashboard`** — Kargo dashboard + NP metrics allow +
   Alloy scrape. No prerequisites beyond kargo.yaml existing ✓.

## Blocking signals surfaced

Two separate maintainer confirmations are needed to unblock the remaining lane:

1. **O4 path**: Maintainer should confirm on the relevant ROADMAP context that ≥1 GitLab
   CI run on main has pushed a `.sig` OCI tag to Artifactory (verifying the cosign CI step
   from `auto/cosign-ci-sign-step` is working). Once confirmed, the executor can pick up
   `cosign-enforce-flip`.

2. **Harbor migration path**: Maintainer should confirm on issue #297 that the minimal
   Harbor profile has been brought up on the live cluster and its footprint (~500 MB) is
   within the 12 GB budget. Once confirmed, the executor can pick up `harbor-capstone-rewire`.
