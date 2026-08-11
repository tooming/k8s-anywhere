# Vault internal telemetry — `sys/metrics` scrape + dashboard depth

(CHARTER **Goals** §"operational-resilience discipline" + **Objective O5** "every
always-on component has a real-metric dashboard"; planner gap analysis 2026-08-11,
reached via `executor.prompt.md` STEP 6b PLANNER role after all six standing
Now/next items were re-confirmed gated (the three GitLab→Forgejo migration items
need live verification; the `verifyImages` Enforce flip / O4 CI gate / capstone
`Deployment` removal are all gated on unconfirmed maintainer-confirmation issues
#631/#633, re-checked this run — both still open, no new confirmation comment),
no open GitHub issue needed grooming, and `docs/roadmap/incoming/` held nothing
pending. **No prerequisites — executor may pick up immediately.**)
`docs/dora-audit-readiness.md` Q7's own gap line named this exact hole, left open
by the earlier `auto/vault-pod-readiness-alert` item (which added a pod-readiness
alert rule from the already-scraped KSM job, not a Vault-internals scrape): "Vault's
own internal metrics — seal state, token/lease counts, storage backend health —
still have no Alloy scrape job at all... A future item could add a full Vault
telemetry scrape job (`telemetry` stanza + `unauthenticated_metrics_access`) if
finer-grained Vault metrics are worth the added config surface." Verified directly
(not assumed, ADR-0004): `gitops/platform/vault.yaml`'s `server.standalone.config`
HCL block had no top-level `telemetry` stanza and its `listener "tcp"` block had no
nested `telemetry { unauthenticated_metrics_access = true }` (grepped both strings
directly — neither appeared anywhere in the file); `grafana/dashboards/lab-vault.json`'s
panels (`Vault Pod Running`, `Vault Memory (MiB)`, `Vault Restarts`, `Vault ArgoCD
Synced`, plus the shared ESO/secrets-layer panels) were all KSM/cAdvisor-derived
proxies — none read a metric Vault itself emits.

Added to `gitops/platform/vault.yaml`'s `server.standalone.config` HCL: a top-level
`telemetry { prometheus_retention_time = "24h", disable_hostname = true }` stanza
(enables Vault's built-in Prometheus-format metrics sink) and
`unauthenticated_metrics_access = true` nested inside the existing
`listener "tcp" { ... }` block (Vault's documented mechanism for exposing
`GET /v1/sys/metrics?format=prometheus` without a token). Added a
`prometheus.scrape "vault"` block to `gitops/platform/observability-alloy.yaml`
(mirrors the static-target `kyverno`/`velero`/`trivy_operator` blocks' shape):
target `vault.vault.svc.cluster.local:8200`, `metrics_path = "/v1/sys/metrics"`,
`params = {format = ["prometheus"]}`, `scrape_interval = "30s"`,
`forward_to = [prometheus.remote_write.mimir.receiver]`. Added
`gitops/vault/networkpolicy/allow-vault-metrics-from-observability.yaml` (mirrors
`allow-vault-from-eso.yaml`'s exact podSelector shape): ingress TCP 8200 from
`namespaceSelector: kubernetes.io/metadata.name: observability`,
`podSelector: app.kubernetes.io/name: alloy`; wired into
`gitops/vault/networkpolicy/kustomization.yaml`'s `resources:` list.

Extended `grafana/dashboards/lab-vault.json` with four new real-metric stat panels:
seal status (`vault_core_unsealed`), active-vs-standby (`vault_core_active`),
in-flight request count (`vault_core_in_flight_requests`), and lease count
(`vault_expire_num_leases`). **Metric names verified against Vault's own source**
(not docs prose or memory, ADR-0004) — shallow-cloned `hashicorp/vault` and grepped
`vault/core.go`, `vault/core_metrics.go`, `vault/ha.go`, and `vault/expiration.go`
for the exact `metrics.SetGauge`/`SetGaugeWithLabels` call sites: `{"core",
"unsealed"}`, `{"core", "active"}`, `{"core", "in_flight_requests"}`, `{"expire",
"num_leases"}` — all four confirmed present and exactly as named. The `Vault Active
Node` panel carries an explicit description caveat: this lab runs Vault standalone
(file storage, no HA/Raft), and the `active`/`standby` gauge is emitted from Vault's
HA leader-election path, which a non-HA deployment may never exercise — so that one
panel may legitimately read "no data" rather than a fabricated value (ADR-0004). All
four panels use `job="vault"` label selectors (not `namespace="vault"` — these are
Vault's own self-emitted metrics from a static-target scrape, not
KSM/cAdvisor-derived series, so they carry no Kubernetes `namespace` label; this was
caught and fixed during implementation by checking `lab-velero.json`'s equivalent
self-emitted-metric panels for the correct label precedent).

Added `tests/observability-vault.bats` (`tests/observability.bats` is frozen — new
scopes go in their own file): telemetry stanza + `unauthenticated_metrics_access`
present in `vault.yaml`; the Alloy scrape block exists with the correct address,
`metrics_path`, `params`, and `forward_to`; the dashboard is valid JSON, references
all four new metric names, has exactly 15 panels all using the `mimir` datasource,
and carries no fabricated/placeholder data. Extended the existing
`tests/networkpolicy-vault.bats` (per-namespace convention, not duplicated in the
new file) with assertions for the new NetworkPolicy file and its kustomization
wiring. Updated `docs/dependency-tree.md`'s Edge table with a new `Alloy → Vault`
row. Updated `docs/dora-audit-readiness.md` Q7's Answer/Gap to reflect the scrape
now existing (the escalation non-goal and CI-scoped-only MTTR caveat both remain,
unchanged).

## ADR-0004 caveat

This remote clusterless session cannot confirm live which of the four new metrics
actually emit a series without a real scrape target — any that don't will show "No
data" naturally in Grafana, never a fabricated value. `vault_core_active` in
particular may legitimately never populate on this lab's standalone (non-HA) Vault
deployment; the dashboard panel's own description field says so.

## Rollback path

Revert the `telemetry`/`unauthenticated_metrics_access` config in `vault.yaml`, the
`prometheus.scrape "vault"` block in `observability-alloy.yaml`, and the
NetworkPolicy allow-rule (delete the file + its `kustomization.yaml` reference).
ArgoCD syncs the revert within 30s same as any other edit to these auto-synced
Applications — note the Vault StatefulSet also needs a pod restart to drop the
removed listener stanza, the same operational cost the 2026-08-05 Vault image-tag
bump already carried.

## PR

https://github.com/tooming/k8s-anywhere/pull/1127
