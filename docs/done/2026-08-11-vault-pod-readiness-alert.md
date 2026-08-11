# Vault pod-readiness alert rule — extend Grafana Unified Alerting (RFC #1084)

(CHARTER **Core Values** §"operational-resilience discipline"; planner-fallback gap
analysis 2026-08-11, reached via `executor.prompt.md` STEP 6b, PLANNER role — the
three standing Now/next migration items above remain gated on unconfirmed
maintainer-confirmation issues #631/#633, and this run's own sweep found no
un-RFC'd 🟡 item and no other lane holding an unpromoted item. **No prerequisites —
executor may pick up immediately.**) `docs/dora-audit-readiness.md` Q7's own gap
line names this exact hole: "Vault sealed has no metric to alert on at all, since
Vault isn't currently scraped by Alloy... A future item could add a Vault-health
scrape job + alert rule if that gap is worth closing." Verified directly (not
assumed, ADR-0004): `gitops/platform/observability-alloy.yaml` has no
`prometheus.scrape "vault"` block (grepped every `prometheus.scrape` name in the
file — 25 jobs, none named vault); RFC #1084's four rules
(`gitops/platform/observability-grafana.yaml` `valuesObject.alerting`) cover
ArgoCD health/sync, `kube_deployment_*` replica availability, and PVC phase — none
scoped to Vault, and Vault runs as a `StatefulSet` (`server.statefulSet` in
`gitops/platform/vault.yaml`), which `DeploymentReplicasUnavailable`'s
`kube_deployment_*` metric family structurally cannot match regardless of label
selectors. This is a real, previously-lived incident, not speculative: the
`vault-unsealer`'s own header comment (`gitops/vault/unsealer.yaml`) documents
Vault staying sealed for 4+ days after a 2026-07-29 outage, "silently breaking
every ExternalSecret refresh cluster-wide... but nothing surfaced that anywhere
visible" — exactly the detection gap this item closes, using a metric already
scraped today (no new scrape job needed): `kube_state_metrics` already emits
`kube_pod_status_ready` for every pod via the existing `ksm` scrape job.

## What was actually built

Added a fifth rule to `gitops/platform/observability-grafana.yaml`'s existing
`alerting.rules.yaml.groups[0].rules` list (same `lab-alerts` group, same
threshold-over-instant-Mimir-query shape as the other four — refId A queries
Mimir, refId B is a `threshold` expression `gt 0`, `noDataState: NoData`,
`execErrState: Error`, `datasourceUid: mimir`): `uid: vault-pod-not-ready`,
`title: VaultPodNotReady`, `for: 10m` (matches the other three non-OutOfSync
rules' cadence), `expr: kube_pod_status_ready{namespace="vault",
pod=~"vault-[0-9]+", condition="true"} == 0`. The `pod=~"vault-[0-9]+"` regex
scopes the rule to the Vault server StatefulSet pod (`vault-0`) specifically,
excluding the separate `vault-unsealer` Deployment pod in the same namespace
(label `app: vault-unsealer`, pod name prefix `vault-unsealer-`, which the regex
does not match) — alerting on the unsealer's own liveness would be a different,
narrower signal than "is Vault itself serving," and conflating the two would
misattribute which component actually failed. No `contactPoints`/notification
receiver added — stays visual-only per RFC #1084's own decision.

Extended `tests/observability-alerting.bats` (clusterless structural, the
per-scope alerting file — `tests/observability.bats` stays frozen): a new test
asserting `title: VaultPodNotReady` and its exact `expr:` string are present;
bumped the existing `'for: 10m'` count assertion from `3` to `4` and the existing
`'datasourceUid: mimir'` count assertion from `4` to `5` — both pre-existing
count-based tests, so leaving them unbumped would have failed `make ci` red on
the count mismatch (a real regression guard, not a new one added for its own
sake).

Updated `docs/dependency-tree.md`'s alerting data-flow row to name all five rules
and note `VaultPodNotReady` reads the already-scraped `ksm` job rather than
introducing a new Alloy scrape target. Updated `docs/dora-audit-readiness.md`
Q7's answer and gap text: the "Vault sealed → no metric" gap is now closed for
pod-readiness-level failures (sealed, crashed, unreachable); a narrower gap is
named in its place — Vault's own internal telemetry (seal state, token/lease
counts, storage backend health) still has no Alloy scrape job, only the coarser
pod-readiness signal this item adds.

## ADR-0004 caveat

This is a remote, clusterless session — it cannot verify this rule actually
fires against a live sealed Vault pod, or that Grafana correctly evaluates it
against a live Mimir. The PromQL expression uses a metric
(`kube_pod_status_ready`) already confirmed present via the existing `ksm`
scrape job (used by other dashboards/rules in this repo), and the YAML shape is
byte-for-byte structurally identical to the other four already-live rules, but
neither substitutes for watching the rule actually transition to `Firing` on a
live cluster with a sealed Vault pod.

## Rollback path

Delete the `vault-pod-not-ready` rule block from
`gitops/platform/observability-grafana.yaml`'s `alerting.rules.yaml` list;
ArgoCD syncs the removal within 30s, same as any other alerting.yaml edit, per
RFC #1084's own rollback precedent. No other component depends on this rule
existing — Grafana holds no other state tied to it.

## PR

https://github.com/tooming/k8s-anywhere/pull/1119
