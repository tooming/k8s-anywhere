# Grafana Unified Alerting — four rules for known failure conditions

(RFC #1084 — architect decision 2026-08-10; closes `docs/dora-audit-readiness.md` Q7's
"no alerting" gap; planner-groomed 2026-08-10 — the RFC's own Acceptance criteria
is the spec below, no further sizing needed. **No prerequisites — executor may
pick up immediately.**) Add an alerting-provisioning ConfigMap to
`gitops/platform/observability-grafana.yaml`'s `valuesObject` (Grafana's chart
supports mounting extra provisioning files the same way dashboards/datasources
are already provisioned — check the chart's own `extraConfigmapMounts` or
equivalent `valuesObject` key, mirroring whatever mechanism the existing
datasource provisioning in this same file already uses) defining exactly these
four rules, each `for:` the duration below, in Grafana's file-based alerting
provisioning YAML format (`apiVersion: 1`, a `groups:` list under the
provisioning `alerting` kind):
1. **ArgoCDAppUnhealthy** — `argocd_app_info{health_status!="Healthy"} == 1`,
   `for: 10m`.
2. **ArgoCDAppOutOfSync** — `argocd_app_info{sync_status="OutOfSync"} == 1`,
   `for: 30m`.
3. **DeploymentReplicasUnavailable** —
   `kube_deployment_status_replicas_available < kube_deployment_spec_replicas`,
   `for: 10m`.
4. **PVCStuckPendingOrLost** —
   `kube_persistentvolumeclaim_status_phase{phase=~"Pending|Lost"} == 1`,
   `for: 10m`.

All four query the existing Mimir datasource (already configured with
`X-Scope-OrgID: lab`) — no new datasource, no new scrape target. No
`receivers:`/contact-point/notification config was added — per the RFC, this is
visual-only (Grafana's Alerting UI shows firing state; no external channel
exists in this lab to wire one to).

## What was actually built

`gitops/platform/observability-grafana.yaml`'s `valuesObject` gained a new
`alerting.rules.yaml` provisioning block (the Grafana Helm chart's standard
file-based alerting-provisioning key, the same shape as the existing
`datasources`/`dashboardProviders` blocks in this same file). Each rule uses
Grafana Unified Alerting's modern "threshold expression" shape — an instant
Mimir query (`refId: A`) feeding a `type: threshold` expression (`refId: B`,
`datasourceUid: __expr__`, `evaluator: {type: gt, params: [0]}`) as the alert
condition — rather than the older `classic_conditions` style, since this is a
first-time alerting build with no legacy format to match.

New `tests/observability-alerting.bats` (clusterless structural): asserts the
`alerting:` block exists; asserts each of the four rule titles + their exact
PromQL `expr` strings are present; asserts the `for:` duration counts match the
RFC (three rules at `10m`, one at `30m`); asserts all four rules query
`datasourceUid: mimir` (no new datasource introduced); asserts no
`contactPoints:`/`notificationPolicies:`/`receivers:`/SMTP/webhook/Slack/
PagerDuty config exists anywhere in the file — a recurrence guard against
silently smuggling in a notification receiver later without a fresh RFC
decision, per CLAUDE.md's bugfix-prevents-recurrence framing applied
preventatively here (guarding an intentional design boundary, not a bug, but
the same "make the violation mechanically detectable" principle).

Updated `docs/dependency-tree.md` with a new data-flow row: `Grafana Unified
Alerting → Mimir (RFC #1084)`, naming all four rules, the 1m evaluation
interval, and the visual-only note. Updated `docs/dora-audit-readiness.md`'s Q7
answer to record that the "no alerting" half of the gap is now closed for these
four conditions, while explicitly naming the gaps that remain (Vault isn't
scraped by Alloy at all, so there's no metric to alert on for a sealed Vault;
escalation stays a permanent non-goal for this solo-operator lab).

## ADR-0004 caveat

This is a remote, clusterless session — it cannot verify these rules actually
evaluate correctly or fire on a live Grafana instance querying a live Mimir.
The PromQL expressions were verified against real, already-scraped metrics
(confirmed present in `grafana/dashboards/*.json` and the Alloy scrape config
before this item was even RFC'd), and the YAML was validated with `python3
-m yaml` to parse correctly, but neither substitutes for watching a rule
actually transition to `Firing` on a live cluster.

## Rollback path

Revert the `alerting:` block in `gitops/platform/observability-grafana.yaml`;
Grafana re-syncs via ArgoCD on its next reconciliation and the provisioned
rules disappear. No other component depends on these rules existing — Grafana
holds no other state tied to them.

## PR

(filled in after PR creation)
