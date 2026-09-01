# ADR-0034 — Grafana LGTM(P) stack internals + kube-state-metrics/node-exporter for observability

**Status.** Adopted (retroactive). Architect decision, RFC #1073 — ratifies components
that have been running as this lab's observability pipeline since early bootstrap;
this ADR gives the internals the dedicated record every other real, always-on
dependency already has. Not a supersession — no prior ADR named these tools as its
subject (only [ADR-0006](adr-0006-grafana-native-git-sync.md) covers Grafana, the
pane-of-glass presentation layer on top of everything decided here).

---

## Context

`docs/dependency-register.md`'s own construction rule (every row cites the ADR that
decided it) surfaced a real, self-identified gap: the observability pipeline's
internals — **Mimir** (metrics store), **Loki** (log store), **Tempo** (trace store),
**Pyroscope** (continuous profiling), **Alloy** (the unified collector that scrapes/
receives and forwards to all four), and the two standard Kubernetes metrics exporters
Alloy scrapes — **kube-state-metrics** and **node-exporter** — have no dedicated ADR.
Only Grafana, the dashboard/UI layer querying all of them, has one. This ADR closes
that gap for all seven in one decision, mirroring [ADR-0012](adr-0012-istio-ambient-not-sidecar.md)'s
precedent of one ADR deciding multiple tightly-coupled tools (there, Istio + Kiali;
here, five members of one vendor's co-designed product family plus two industry-standard
exporters that family is built to consume).

### Why one ADR, not seven

Unlike Istio/Kiali (two separate CNCF projects that happen to integrate), five of these
seven — Mimir, Loki, Tempo, Pyroscope, Alloy — are **all authored and maintained by
Grafana Labs as one deliberately co-designed family** (the "LGTM(P)" stack: Loki, Grafana,
Tempo, Mimir, Pyroscope), sharing a common query surface (`X-Scope-OrgID` multi-tenancy,
consistent label/PromQL-adjacent query languages across signal types) and a single
collector (Alloy, itself the unified successor to Grafana Agent, replacing what used to
be separate Prometheus/Promtail/OTel-Collector agents). Deciding Mimir in isolation from
Loki, or Alloy in isolation from what it feeds, would misrepresent the actual choice this
lab made: **adopt one integrated observability vendor's stack**, not five independent
point solutions that happen to coexist. kube-state-metrics and node-exporter are the two
non-Grafana-authored pieces in this ADR, included because they exist purely as **Alloy's
scrape targets** — they have no independent role in this lab outside feeding this
pipeline, so deciding them separately would orphan them from the context that explains
why they're here at all.

### Real alternatives considered

| Signal | Chosen | Alternative(s) considered | Why not chosen |
|---|---|---|---|
| **Metrics store** | Mimir (single-binary, filesystem storage) | Prometheus + Thanos (or + Cortex, Mimir's own predecessor) | Prometheus alone has no long-term/multi-tenant storage story; Thanos/Cortex solve that but add a second, differently-shaped set of components (sidecar, store-gateway, compactor as separate binaries) versus Mimir's single-binary `-target=all` mode, which is the deliberately simpler operational shape this 12 GB lab needs (see `gitops/observability/mimir`'s own header comment: "Decoupled from collection (Alloy), per the no-monolithic-Prometheus call"). |
| **Log store** | Loki (single-binary, Garage S3-backed) | ELK/OpenSearch | Loki indexes only labels, not full log text, which is dramatically cheaper on CPU/memory/storage than Elasticsearch's full-text indexing — the right trade-off for a lab whose log volume is small and whose queries are Kubernetes-label-driven, not full-text search. Also reuses the lab's existing Garage S3 store ([ADR-0002](adr-0002-garage-not-minio.md)) rather than introducing a second storage technology. |
| **Trace store** | Tempo | Jaeger | Tempo shares Grafana's query surface and, like Loki, indexes only trace IDs (not full spans) for a much smaller storage footprint than Jaeger's default Elasticsearch/Cassandra backends — same reasoning as the log-store choice, and keeps the whole pipeline on one vendor's consistent operational model. |
| **Continuous profiling** | Pyroscope | py-spy / manual `pprof` collection, or no profiling at all | Pyroscope is the only one of these that's a real always-on *pipeline* component (continuous, low-overhead, queryable in Grafana) rather than a point-in-time manual tool — it's what makes "profiles" a first-class pillar of the CHARTER Goals' observability list (metrics, logs, traces, **profiles**) alongside the other three signal types, not an afterthought. |
| **Collector / agent** | Alloy | Prometheus + Promtail + a separate OTel Collector (the pre-Alloy status quo) | Alloy is Grafana Labs' unified successor that replaced Grafana Agent, itself built to receive OpenTelemetry natively and forward to all four LGTM(P) backends from one process/config — one collector instead of three cuts the lab's footprint and config surface for the same coverage. |
| **Cluster object metrics** | kube-state-metrics (official `prometheus-community` chart) | Hand-rolled `kubectl`-polling exporter | kube-state-metrics is the de-facto standard Kubernetes SIG-instrumentation-adjacent exporter for object state (pod phases, deployment replica readiness, etc.) that every mainstream Kubernetes observability stack uses — no real alternative considered because none is warranted. |
| **Node/host metrics** | node-exporter (official `prometheus-community` chart) | cAdvisor-only, or a custom exporter | node-exporter is the same de-facto-standard choice as kube-state-metrics, for the adjacent host-level (CPU/mem/disk/net) signal — paired with the "Node Exporter Full" community Grafana dashboard this lab already benefits from for free. |

---

## Decision

Continue running the **Grafana LGTM(P) stack** (Loki, Tempo, Mimir, Pyroscope, unified
by Alloy) plus **kube-state-metrics** and **node-exporter** as the lab's always-on
observability pipeline, all in the `observability` namespace (node-exporter in its own
dedicated `node-exporter` namespace — see below) — as decided when the lab was first
bootstrapped, formally recorded here for the first time.

### What's actually running (verified directly against `gitops/`)

| Component | Deployment shape | Source | Version pin |
|---|---|---|---|
| **Mimir** | Raw manifests (`gitops/observability/mimir`), single-binary `-target=all`, filesystem storage | ArgoCD `Application` `mimir`, `targetRevision: main` (kustomize path, not a Helm chart — Mimir has no official chart this lab tracks) | `image: grafana/mimir:3.1.5` (tracked in this ADR's own Re-evaluation log, 2026-08-20 CVE bump) |
| **Loki** | Raw manifests (`gitops/observability/loki`), single-binary, Garage S3-backed | ArgoCD `Application` `loki`, `targetRevision: main` | Image tag tracked via ADR-0006 (currently `3.7.6`) |
| **Tempo** | Raw manifests (`gitops/observability/tempo`) | `deployment.yaml` pins `image: grafana/tempo:2.10.8` directly | `2.10.8` (tracked in ADR-0006's Re-evaluation log, 2026-08-13 security bump) |
| **Pyroscope** | Helm chart | `gitops/platform/observability-pyroscope.yaml`, `targetRevision: 2.2.1` | `2.2.1` |
| **Alloy** | Helm chart | `gitops/platform/observability-alloy.yaml`, `targetRevision: 1.11.1` | `1.11.1` |
| **kube-state-metrics** | Helm chart, `prometheus-community/helm-charts` | `gitops/platform/observability-ksm.yaml`, `targetRevision: 8.4.1` | `8.4.1` (tracked in this ADR's own Re-evaluation log, 2026-09-01 currency bump) |
| **node-exporter** | Helm chart, `prometheus-community/helm-charts` (`prometheus-node-exporter`) | `gitops/platform/observability-node-exporter.yaml`, `targetRevision: 4.56.3`; dedicated `node-exporter` namespace (not `observability`) because it needs `hostPID`/`hostNetwork`/`hostRootFsMount` semantics [ADR-0017](adr-0017-pod-security-standards-restricted.md)'s `restricted` profile forbids | `4.56.3` (tracked in this ADR's own Re-evaluation log, 2026-09-01 currency bump) |

Mimir and Loki are deliberately **not** Helm charts (Mimir has no chart this lab
tracks; both run from hand-maintained raw manifests) — this is an existing, working
operational choice, not a gap; it is noted here rather than silently assumed, per
ADR-0004.

### Why kept as one integrated vendor stack rather than swapped piecewise

All five Grafana-authored components already satisfy [ADR-0004](adr-0004-no-fabricated-content.md)
(every dashboard panel across this lab's `grafana/dashboards/*.json` files sources real,
auto-discovered data from this exact pipeline — verified per-component in each
component's own ADR/dashboard work), [ADR-0002](adr-0002-garage-not-minio.md) (Loki
reuses Garage rather than introducing a second object store), and the 12 GB budget
constraint (single-binary/lightweight deployment shapes throughout, no HA multi-process
topologies). Nothing found while researching this ADR suggests a real reason to
reconsider any individual piece — this is a **Keep**, not a **Supersede**, decision.

---

## Scope & exceptions

**In scope:** the choice of Mimir/Loki/Tempo/Pyroscope/Alloy/kube-state-metrics/
node-exporter as the lab's observability-pipeline internals, and their integration
shape (Alloy as sole collector feeding all four Grafana-authored stores).

**Out of scope (explicit, tracked separately):**

- Grafana itself — already [ADR-0006](adr-0006-grafana-native-git-sync.md).
- `docs/dependency-register.md` gaining rows for these seven tools citing this ADR
  (follow-up executor item — doc-only, kept out of this architecture PR to keep it
  reviewable).
- Any component swap, version bump, or configuration change — this ADR ratifies the
  existing choice; routine version currency is the executor/upgrade-drafter's ongoing
  work, tracked in each component's citation in `docs/dependency-register.md` and (for
  Grafana/Tempo/Loki specifically) in ADR-0006's own Re-evaluation log.

---

## Re-evaluation log

**2026-09-01** — node-exporter chart bumped `4.56.1` → `4.56.3` (upgrade-drafter
fallback, routine currency sweep, `executor.prompt.md` STEP 6b — the twelfth cycle
of this run). Verified directly (ADR-0004) via a sparse clone of
`prometheus-community/helm-charts`: the tagged `Chart.yaml` at
`prometheus-node-exporter-4.56.3` shows `version: "4.56.3"`, `appVersion: "1.12.1"`
(unchanged app version — chart-only bump). `git diff
prometheus-node-exporter-4.56.1 prometheus-node-exporter-4.56.3 --
charts/prometheus-node-exporter/values.yaml` shows two changes: (1) an additive
`kubeRBACProxy.listenHost` default (`":"`, no behavior change — this lab doesn't
enable `kubeRBACProxy` anyway); (2) a **real default behavior change** —
`extraArgs` moves from empty (`[]`) to two new filesystem-collector exclusion
flags (`--collector.filesystem.mount-points-exclude=...`,
`--collector.filesystem.fs-types-exclude=...`) that filter out pseudo/container
filesystems (overlay, proc, tmpfs-family, container-runtime mount paths) from
node-exporter's `node_filesystem_*` metrics. This lab's `valuesObject` in
`gitops/platform/observability-node-exporter.yaml` sets no `extraArgs` override,
so it inherits the new default. Checked `grafana/dashboards/lab-node-exporter.json`
directly: only two `node_filesystem_*` metrics are queried
(`node_filesystem_avail_bytes`, `node_filesystem_size_bytes`), both for real host
disk usage — excluding pseudo-filesystem noise from these series is a genuine
improvement (fewer, more relevant time series), not a regression; no panel breaks.
**Flip condition:** revisit if a future dashboard panel needs a filesystem type
this exclusion list now hides.

**2026-09-01** — kube-state-metrics chart bumped `8.4.0` → `8.4.1` (upgrade-drafter
fallback, same routine currency sweep as the node-exporter entry above). Verified
directly (ADR-0004): the tagged `Chart.yaml` at `kube-state-metrics-8.4.1` shows
`version: "8.4.1"`, `appVersion: "2.20.0"` (unchanged app version — chart-only
bump). `git diff kube-state-metrics-8.4.0 kube-state-metrics-8.4.1 --
charts/kube-state-metrics/values.yaml` is purely additive: new commented-out
opt-in collector entries (`validatingadmissionpolicies`,
`validatingadmissionpolicybindings`, `mutatingadmissionpolicies`,
`mutatingadmissionpolicybindings`, all disabled by default, matching this lab's
"comment out to disable" convention for every other collector) plus a doc-comment
rewording. No `valuesObject` key this lab sets (`fullnameOverride`,
`selfMonitor.enabled`, `securityContext.*`, `containerSecurityContext.*`,
`resources.*`) changed shape.

**2026-08-20** — kube-state-metrics chart bumped `8.3.1` → `8.4.0` (executor-fallback
upstream-currency sweep, `executor.prompt.md` STEP 6b — the "Now / next" lane was
still fully gated on issues #633/#1229, re-checked with no new confirmation; a
Kyverno/Trivy Operator/cert-manager/External Secrets/KEDA/Velero/Cilium currency
sweep this same cycle found each already at the newest stable release, and Envoy
Gateway's `v1.9.0` bump remains correctly deferred per this ADR's sibling ADR-0008's
own 2026-08-18 Re-evaluation-log entry — not repeated here). Verified directly
(ADR-0004): the tagged `Chart.yaml` at `kube-state-metrics-8.4.0` shows
`version: "8.4.0"`, `appVersion: "2.20.0"` (up from `8.3.1`'s `2.19.1`) — a real
appVersion bump, not packaging-only this time. The upstream `kube-state-metrics`
`v2.20.0` release notes name, among additive metrics (pod-disruption tracking,
admission-policy object metrics, HPA scale-behavior-tolerance metrics, a new
`kube_node_spec_pod_cidrs` metric, DRA `kube_pod_resourceclaim_info`, init-container
state/exit-code tracking, ephemeral-volume label generation, PV access-mode
metrics, allowlist wildcard support, and a watch-sharding performance change) one
security fix explicitly: a Go toolchain bump (Go 1.26.6) remediating `GO-2026-5038`,
plus a `client-go` bump to `v0.36.3`. The only breaking change named — "Custom
Resource State (CRS) metrics are now feature-frozen" — does not apply here: this
repo's `valuesObject` in `gitops/platform/observability-ksm.yaml` sets no
`customResourceState:` key at all. A byte-level diff of the chart's `values.yaml`
between the two tags confirms every key this repo's `valuesObject` actually sets
(`fullnameOverride`, `selfMonitor.enabled`, `securityContext.{enabled,runAsNonRoot,
runAsUser,runAsGroup,seccompProfile.type}`, `containerSecurityContext.
{allowPrivilegeEscalation,privileged,readOnlyRootFilesystem,capabilities.drop}`,
`resources.{requests,limits}`) keeps the identical shape and chart defaults — no
schema change affects this Application's rendered manifest beyond the new
kube-state-metrics binary itself emitting the additive metrics above. **Convert** —
a real, additive, security-relevant bump, not a no-op like the 8.3.0→8.3.1 packaging
fix below.

**2026-08-20** — Mimir image tag bumped `3.1.4` → `3.1.5` (upgrade-drafter fallback,
`executor.prompt.md` STEP 6b — the "Now / next" lane was still fully gated on issue
#633 and the two GitLab→Forgejo migration items, and this run's earlier PLANNER/
ARCHITECT passes found no ungroomed issues and no un-RFC'd 🟡 items). Verified
directly (not assumed, ADR-0004): `git ls-remote --tags github.com/grafana/mimir`
shows `mimir-3.2.0` and an intermediate `mimir-3.1.5` both ahead of the pinned
`3.1.4`. A real clone's `CHANGELOG.md` at the `mimir-3.1.5` tag shows exactly one
entry: `[BUGFIX] Upgrade Go to 1.26.6 to address CVE-2026-33818, CVE-2026-39821,
CVE-2026-46600, CVE-2026-56853, CVE-2026-56858, CVE-2026-56859, CVE-2026-56860, and
CVE-2026-56862 (#16408)` — a clean, same-line Go-stdlib CVE bump with zero
config/flag surface change. `docker hub`'s tag API confirms `grafana/mimir:3.1.5`
exists (pushed 2026-08-20).

**Deliberately did not jump to `3.2.0`** even though it's the highest stable tag:
its `CHANGELOG.md` entry carries a long list of `[CHANGE]` lines with real
behavioral/config impact — query-frontend default-behavior flips (query sharding
on by default, reduced default querier concurrency), the embedded Alertmanager UI
being removed entirely (upstream dropped the embeddable package), and a
**required-coordinated-upgrade** note ("This change requires upgrading from Mimir
3.1" for the querier/store-gateway opaque-gRPC-type change) — exactly the kind of
live-cluster-verified rollout this clusterless session cannot safely assert
succeeded (ADR-0004). The `3.1.x` line's own latest patch delivers the real
security fix with none of that risk; `3.2.0` is left for a future live-cluster
session with the headroom to verify a coordinated upgrade actually completes
cleanly.

Also corrected this ADR's own "What's actually running" table row (above), which
previously read "Image tag tracked via `context.md` (currently `3.1.4`...)" —
`context.md` (`docs/decisions/context.md`) has no Mimir version reference at all
(checked directly; it only lists Garage S3 bucket names), so that citation was
already stale/wrong independent of this bump. Reshaped the cell to the same
`` `gitops/<dir>` `` + `` `image: <name>:<tag>` `` phrasing Tempo's row already uses,
which brings Mimir under `scripts/adr-image-pin-sync-check.sh`'s existing
mechanical drift guard (Shape 2) for the first time — it previously couldn't parse
the old `context.md`-citing phrasing, so Mimir's row could have gone stale
silently, the exact failure mode Tempo's 2026-08-18 entry below already fixed for
that row specifically. No script change needed; the existing guard now covers this
row automatically now that its phrasing matches.

**ADR-0004 caveat.** This remote, clusterless session verified the changelog and
published-image facts directly, but cannot verify Mimir starts cleanly and keeps
ingesting metrics post-bump on a live cluster. Rollback is a one-line `image:` tag
revert; Mimir is a plain manifest (not ArgoCD-templated Helm), so a revert takes
effect on the next GitOps sync, and its storage (Garage S3 buckets `mimir`/
`mimir-ruler`) is untouched by an image-tag change either way.

**Flip condition (next re-evaluation).** Revisit the `3.2.0` minor once a
live-cluster session can verify the coordinated querier/store-gateway upgrade path,
or sooner if a new advisory names a version at or above `3.1.5` as affected.

**2026-08-18** — table-row correction (Tempo): this ADR's own "What's actually
running" table (above) still cited Tempo's image tag as `2.10.7`, but the live pin
in `gitops/observability/tempo/deployment.yaml` has been `2.10.8` since 2026-08-13
(a real security fix — Go 1.26.5 stdlib CVEs plus grpc/otel/x-net/x-text/compress
`[security]` dependency bumps — already correctly recorded in
[ADR-0006](adr-0006-grafana-native-git-sync.md)'s own Re-evaluation log the same
day). This table's cell simply wasn't updated when that bump landed — the same
self-tracking-note-can-silently-drift failure mode this ADR's other rows already
guard against via `scripts/adr-chart-version-sync-check.sh`'s table-row shape, just
in this row's `image:`-pin phrasing, which that check didn't parse. Corrected the
table cell to `2.10.8` (janitor-fallback cleanup, `executor.prompt.md` STEP 6b,
found live while investigating a fresh doc-consistency lens after the "Now / next"
lane came up fully gated and PLANNER/ARCHITECT/UPGRADE-DRAFTER found nothing
further this run). **Mechanical guard added** (CLAUDE.md's "every bugfix must
prevent recurrence"): extended `scripts/adr-image-pin-sync-check.sh` with a second
self-tracking shape — a table row citing a `gitops/<dir>` raw-manifest directory
alongside the `image: <name>:<tag>` it pins directly (mirrors
`adr-chart-version-sync-check.sh`'s existing table-row shape for `targetRevision`,
just for a raw image pin instead of a chart version) — so this specific row, and
any future row using the same convention, can never silently drift again; `make
adr-image-pin-sync-check` now fails loudly if it does. No component reconsidered —
this is a doc-only correction, not a new finding about Tempo itself.

**2026-08-17** — kube-state-metrics chart bumped `8.3.0` → `8.3.1` (executor-fallback
upstream-currency gap analysis, `executor.prompt.md` STEP 6b, this run's second pass —
the "Now / next" lane was still fully gated after the first pass's ACK bump). Verified
directly (ADR-0004): the tagged `Chart.yaml` at `kube-state-metrics-8.3.1` shows
`version: "8.3.1"`, `appVersion: "2.19.1"` (unchanged from `8.3.0`) — a packaging-only
patch release, not a major bump. The upstream release note names exactly one change:
"Fix autosharding configuration service" (PR prometheus-community/helm-charts#7176,
merged/tagged 2026-08-17, same day). A byte-level diff of `templates/service.yaml`
between the two tags confirms the fix's full scope: `spec.type`, the NodePort
conditionals, and the `loadBalancerIP`/`loadBalancerSourceRanges` blocks each gain a
`(not .Values.autosharding.enabled)` / `{{- if .Values.autosharding.enabled }}...{{-
else }}` guard so a sharded (`StatefulSet`, headless-Service) deployment renders a
correct Service instead of the prior chart line's Service shape (plus one unrelated
whitespace-control fix, `{{ if .Values.selfMonitor.enabled }}` → `{{- if
.Values.selfMonitor.enabled }}`). This repo's `valuesObject` sets no `autosharding:`
key at all — the chart default (`autosharding.enabled: false`) applies, so every
changed conditional evaluates identically before and after the bump; the rendered
Service for this Application is unaffected by the fix itself. `templates/
deployment.yaml`/`clusterrole.yaml`/`values.yaml` are unchanged for the
`kube-state-metrics` subchart specifically (the wider `prometheus-community/
helm-charts` monorepo's compare view lists 7 commits across the tag range, but the
other 6 touch unrelated sibling charts — `nginx-prometheus-exporter`,
`memcached_exporter`, `alertmanager`, CI workflows — not this one). **Keep** — no
reason to reconsider the component itself, this is a routine packaging-only bump with
zero effective change to this lab's rendered manifest.

**2026-08-12** — kube-state-metrics chart bumped `8.2.0` → `8.3.0` (executor-fallback
currency sweep, UPGRADE-DRAFTER role). Verified directly (ADR-0004): `git ls-remote
--tags prometheus-community/helm-charts` shows `kube-state-metrics-8.3.0` as the
newest tag on the `8.x` line (no major bump); `Chart.yaml`'s `appVersion` is unchanged
(`2.19.1` → `2.19.1`). A full diff of `values.yaml` (fetched both tags' raw content —
this session had no reachable Helm-repo/git-clone path for `prometheus-community/
helm-charts`, only `raw.githubusercontent.com` per-file fetches) shows exactly one
addition: a new `rbac.customResourceState.createClusterRoleRules` key, defaulting to
`true` (the chart's existing implicit behavior) — this repo's `valuesObject` sets no
`rbac:` override at all, so the default applies and behavior is unchanged.
`templates/service.yaml`, `templates/deployment.yaml`, `templates/clusterrole.yaml`,
and `README.md` are byte-identical between the two tags — the existing
`securityContext`/`containerSecurityContext` hardening and the `selfMonitor`
:8081-port wiring this ADR's table and `tests/observability-ksm.bats` document carry
forward unchanged. **Keep** — no reason to reconsider the component itself, this is a
routine packaging-only bump.

**2026-08-10** — kube-state-metrics chart bumped `8.1.3` → `8.2.0` (upgrade-drafter
fallback, PR #1098; this entry added by a separate janitor cleanup since chart-pin
bumps stay out of that routine's own scope). Chart's `appVersion` unchanged (`2.19.1`
→ `2.19.1`) — a packaging-only release adding an optional `aggregationRule` values
key, no change to any key this repo's `valuesObject` sets, so the existing
`securityContext`/`containerSecurityContext` hardening in this ADR's own table above
carries forward unchanged. **Keep** — no reason to reconsider the component itself.

**2026-08-10** — Pyroscope chart bumped `2.2.0` → `2.2.1` (executor-fallback currency
sweep). Verified directly (ADR-0004): `git ls-remote --tags grafana/pyroscope` shows
`pyroscope-2.2.1` as the newest tag; the chart's own `Chart.yaml` `version`/`appVersion`
both move together, and a full source diff (`git diff pyroscope-2.2.0 pyroscope-2.2.1 --
operations/pyroscope/helm/pyroscope/`) shows only version-label churn in the rendered
manifests — `values.yaml` and every template are byte-identical, so this repo's existing
`readOnlyRootFilesystem: true` verification (this ADR's own table, checked against the
pinned chart source) carries forward unchanged. The upstream release (PR grafana/
pyroscope#5474) is explicitly a **security release**: `github.com/getkin/kin-openapi`
(GHSA-r277-6w6q-xmqw, critical), `google.golang.org/grpc` (GHSA-hrxh-6v49-42gf),
`golang.org/x/text` (CVE-2026-56852), `golang.org/x/net` (CVE-2026-46600), plus a
`klauspost/compress` bump and UI-dependency (tar/js-yaml/brace-expansion/ip-address)
fixes. **Keep** — no reason to reconsider Pyroscope itself, this is a routine security
patch. Flip condition unchanged from below.

_(This is the ADR's first version besides the entry above. Future architect audits
record Keep/Supersede/Convert outcomes here.)_

**Flip condition:** revisit any individual component if (a) it stops satisfying
ADR-0004 (a dashboard panel is found sourcing fabricated/placeholder data), (b) Grafana
Labs deprecates or EOLs a component in favor of a successor (as already happened once —
Alloy superseding Grafana Agent), or (c) the 12 GB budget can no longer absorb the
pipeline's combined footprint on the localhost backend.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0002](adr-0002-garage-not-minio.md) | Loki's chunk/index storage backend is Garage, not a second object-store technology. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Every dashboard panel across this lab sources real data from this exact pipeline — the invariant this ADR's components exist to make true. |
| [ADR-0006](adr-0006-grafana-native-git-sync.md) | Grafana is the query/dashboard layer on top of every component this ADR decides; Grafana's own ADR already tracks Tempo/Loki image-tag currency in its Re-evaluation log — unchanged by this ADR. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) / [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Every component here runs under `observability`'s (or node-exporter's dedicated namespace's) default-deny NetworkPolicy and PSS profile — node-exporter's `hostPID`/`hostNetwork` need is exactly why it lives in its own non-`restricted` namespace rather than `observability`. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | All seven components are Apache 2.0 / AGPLv3-free-tier OSS, no paid tier required. |
