# Grafana dashboard metric-name drift fix — Cilium, Harbor, Trivy Operator panels silently broken

(CHARTER **Objective O5** "every always-on component has a real-metric dashboard";
CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, this run's 25th
cycle, after the Now/next lane was re-confirmed fully gated. **No prerequisites —
executor may pick up immediately.**)

## What was wrong

An Explore sub-agent audit (a different lens than every prior cycle's — cross-checking
dashboard PromQL queries against each component's real metric surface at its pinned
version, rather than checking version *citations*) found four dashboard panels across
three components querying Prometheus metric names that **do not exist**, plus a
related label-value casing bug. I independently re-verified all four via direct
`raw.githubusercontent.com` fetches against the exact pinned tags before touching
anything (ADR-0004 — never fabricate, always verify):

1. **`grafana/dashboards/lab-cilium.json`**, "Network Policy Count" panel — queried
   `cilium_policy_count`. Confirmed against Cilium's own `pkg/metrics/metrics.go` at
   tag `v1.18.12` (this lab's pin): no such metric exists. The real metric is
   `cilium_policy` ("Number of policies currently loaded").
2. **`grafana/dashboards/lab-harbor.json`**, "Total Artifacts" + "Artifacts by
   Project" panels — queried `harbor_artifact_total`. Confirmed against Harbor's own
   `tests/apitests/python/test_verify_metrics_enabled.py` at tag `v2.15.2` (this
   lab's pinned appVersion): the real metric is `harbor_project_artifact_total`.
3. **`grafana/dashboards/lab-trivy.json`**, "ConfigAudit Checks by Severity" panel —
   queried `trivy_config_audit_checks_total`. Confirmed against trivy-operator's own
   `docs/tutorials/integrations/metrics.md` at tag `v0.33.0` (this lab's pinned
   appVersion): the real metric is `trivy_resource_configaudits`.
4. **`grafana/dashboards/lab-trivy.json`**, the four CVE-count panels
   (Critical/High/Medium/Low) — queried `trivy_image_vulnerabilities{severity="CRITICAL"}`
   etc. (uppercase). The real `severity` label values at the pinned version are Title
   Case (`Critical`/`High`/`Medium`/`Low`), confirmed against the same metrics doc's
   own examples — uppercase never matches.
5. **`grafana/dashboards/lab-trivy.json`**, "SBOM Reports (total)" panel — queried
   `trivy_sbom_reports_total`, which does not exist anywhere in trivy-operator's real
   metric surface (vulnerabilities/configaudits/rbacassessments/exposedsecrets/
   infraassessments/cluster-compliance only). Unlike the other four, this isn't a
   naming typo — no metric or `kube-state-metrics` `CustomResourceState` config for
   the `SbomReport` CRD exists in this repo (checked
   `gitops/platform/observability-ksm.yaml` directly), so this panel was
   **structurally guaranteed** to never show real data, not merely pending a first
   scan the way its `noValue: "no scans yet"` text implied.

All four naming/casing bugs (1-4) meant their panels have shown "No data" since the
dashboards were first authored — not a recent regression from a version bump, a
pre-existing defect this run's fresh angle finally caught.

Two `tests/*.bats` files were asserting the **old, wrong** metric names as if they
were correct — a case of tests enshrining a bug instead of catching it
(`tests/cilium.bats`, `tests/harbor.bats`, `tests/trivy-operator.bats`).

## Fix

- Corrected all 4 PromQL query metric names/label-casing bugs (1-4 above) in their
  respective dashboard JSON files.
- Removed the "SBOM Reports (total)" panel entirely (issue 5) rather than leave a
  permanently-broken query — matches CLAUDE.md's bugfix hierarchy option (a), "make
  the bug impossible by construction," applied to a dashboard panel instead of code.
  Widened the neighboring "Restarts (max)" panel to fill the freed grid space.
- Updated ADR-0022's "Observability" section and added a dated Re-evaluation log
  entry documenting the fix and the SBOM-panel removal rationale.
- Updated `docs/dependency-tree.md`'s three citations of these panels/metrics to
  match (it had independently drifted to cite the same wrong metric names).
- Fixed the three bats test files to assert the *correct* metric names (and, for
  Cilium/Trivy, to also assert the *wrong* ones are absent — a stronger regression
  guard than a plain presence check).

## Recurrence prevention

This is a documentation/observability-correctness bugfix, not a recurring class of
code bug with an obvious mechanical guard shape (unlike the ADR self-tracking-citation
drift this run already added guards for in PRs #1142/#1144) — there's no existing
"assert every dashboard's PromQL metric exists" infrastructure to extend, and
building one (would need either live-cluster metric introspection or a maintained
per-component allowlist of real metric names, kept in sync with every future chart
bump) is out of scope for a bounded janitor fix. The `tests/*.bats` assertions above
*do* now guard against a regression back to the specific wrong strings found this
cycle — the narrowest honest guard available without a live cluster.

**Flagged, not silently dropped:** wiring up a real SbomReport-count metric (a
`kube-state-metrics` `CustomResourceState` config for the `SbomReport` CRD, or an
equivalent upstream trivy-operator metric if one ships) is a genuine future
improvement, noted in ADR-0022's new Re-evaluation log entry's flip condition — out
of this bugfix's scope since it's a feature-add, not a fix.

## ADR-0004 caveat

Every corrected metric name was verified directly against the real upstream source
(GitHub raw file fetches at the exact pinned git tag/chart version, not a rendered
doc site or assumption) before being written into any file — both by the
investigating sub-agent and independently by me before applying any edit.

## Rollback path

Revert this commit. The bats test changes are additive/corrective assertions with
no effect outside their own test files.

## PR

(filled in after PR creation)
