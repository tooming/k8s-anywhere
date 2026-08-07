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
| **Mimir** | Raw manifests (`gitops/observability/mimir`), single-binary `-target=all`, filesystem storage | ArgoCD `Application` `mimir`, `targetRevision: main` (kustomize path, not a Helm chart — Mimir has no official chart this lab tracks) | Image tag tracked via `context.md` (currently `3.1.4` per this run's earlier currency sweep) |
| **Loki** | Raw manifests (`gitops/observability/loki`), single-binary, Garage S3-backed | ArgoCD `Application` `loki`, `targetRevision: main` | Image tag tracked via ADR-0006 (currently `3.7.6`) |
| **Tempo** | Raw manifests (`gitops/observability/tempo`) | `deployment.yaml` pins `image: grafana/tempo:2.10.7` directly | `2.10.7` (tracked in ADR-0006's Re-evaluation log per this run's earlier correction) |
| **Pyroscope** | Helm chart | `gitops/platform/observability-pyroscope.yaml`, `targetRevision: 2.2.0` | `2.2.0` |
| **Alloy** | Helm chart | `gitops/platform/observability-alloy.yaml`, `targetRevision: 1.11.1` | `1.11.1` |
| **kube-state-metrics** | Helm chart, `prometheus-community/helm-charts` | `gitops/platform/observability-ksm.yaml`, `targetRevision: 8.1.3` | `8.1.3` |
| **node-exporter** | Helm chart, `prometheus-community/helm-charts` (`prometheus-node-exporter`) | `gitops/platform/observability-node-exporter.yaml`, `targetRevision: 4.56.1`; dedicated `node-exporter` namespace (not `observability`) because it needs `hostPID`/`hostNetwork`/`hostRootFsMount` semantics [ADR-0017](adr-0017-pod-security-standards-restricted.md)'s `restricted` profile forbids | `4.56.1` |

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

_(No entries yet — this is the ADR's first version. Future architect audits record
Keep/Supersede/Convert outcomes here.)_

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
