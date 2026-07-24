# ADR-0018 — Valkey as the lab's cache / key-value store (supersedes ADR-0010)

**Status.** Adopted. Active in `gitops/platform/valkey.yaml` (ArgoCD Application,
auto-synced) and `gitops/data/valkey/` (StatefulSet with a redis_exporter sidecar +
Service + ExternalSecret). Demo traffic from `gitops/data/demo/valkey-load.yaml`.

---

## Context

ADR-0010 chose upstream `redis:7.4-alpine` under RSALv2 for the lab's cache/KV primitive,
with Valkey noted as "a legitimate choice" and "an easy future swap". Since ADR-0010 was
written, the landscape shifted enough to act:

- **Linux Foundation governance and permissive license.** Valkey was forked from the last
  OSI-licensed Redis (7.2.4) in March 2024 and is now governed by the Linux Foundation
  under the **BSD 3-Clause license** — strictly more permissive than Redis's RSALv2/SSPLv1
  dual license, and aligned with the rest of the lab stack (k3s, ArgoCD, Vault, Envoy
  Gateway, Grafana are all permissively licensed).

- **Cloud-provider default shift.** AWS ElastiCache for Valkey GA'd in October 2024; GCP
  Memorystore added Valkey support; Oracle, Snap, and Ericsson back the project. A learner
  querying the AWS console for a managed KV store now sees Valkey as the default offering.
  The "name learners recognize" rationale in ADR-0010 now favours Valkey.

- **Production-stable release.** Valkey 8.0 (September 2024) is production-stable and
  command-/protocol-compatible with Redis 7.2.x. The lab's `redis_exporter` sidecar, the
  `--requirepass` auth flag, the RDB-snapshot persistence model, and the Prometheus metrics
  endpoint are all identical against Valkey.

Options considered (unchanged from ADR-0010 shortlist):

| Option | Rationale against |
|--------|------------------|
| **Memcached** | Pure cache, no persistence or richer types; smaller teaching surface. |
| **KeyDB** | Multithreaded Redis fork, but a niche project with no clear lab benefit. |
| **Redis** | RSALv2 license; no longer the cloud-managed default; Valkey is a strict drop-in. |
| **Valkey** ✅ | BSD-3 license; Linux Foundation governance; protocol-identical to Redis 7.2; cloud-provider default. |

## Decision

Run **Valkey** as an **always-on** lab component, deployed by ArgoCD (ADR-0001) from
**plain Kubernetes manifests** (a `StatefulSet`, not a Helm chart). Auth is enforced via
`--requirepass`, with the password sourced from Vault via External Secrets
(`secret/valkey/default` → `valkey-creds`). A **redis_exporter** sidecar exposes Prometheus
metrics on `:9121`, scraped by Alloy. The teaching point is unchanged — a cache/KV store at
protocol level; the *name* learners walk away with shifts from "Redis" to "Valkey", matching
what they will encounter in cloud-managed services.

## Plain manifests over a Helm chart

Same reasoning as ADR-0009 and ADR-0010: a pinned `valkey/valkey:8.0-alpine` image in a
plain `StatefulSet` is fully reproducible, transparent, and validated by `kubeconform`.

## Single node — the ADR-0005 trade-off

The lab runs **one** Valkey replica with a persistent volume (an RDB snapshot every 60s;
AOF off — lab-grade durability). On restart it recovers in place. **Production** uses
**Valkey Cluster** (sharding + replicas) or a managed service; both are out of scope for a
12 GB single-host lab and are noted in `docs/dependency-tree.md`.

## Backward compatibility

`redis_exporter` (oliver006/redis_exporter) works unchanged against Valkey — the
`redis_*` metric names it emits are identical. The Grafana dashboard is renamed
`lab-valkey.json` with title and tags updated; panel queries are unchanged.

The Vault bootstrap seeds `secret/valkey/default` (and keeps `secret/redis/default` for
one release to avoid stalling any in-flight deployments during the transition).

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Deployed as an ArgoCD `Application` from a git path; no imperative `helm install`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | A shared cache decouples apps from recomputation/state; the single node is a deliberate lab SPOF (ADR-0005), with the production HA topology documented. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | The "Lab — Valkey" dashboard uses only real `redis_exporter` + cAdvisor metrics; the `valkey-load` demo generates real ops so panels aren't empty. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | One replica, recover-in-place on a persistent volume, instead of (impossible) single-host HA. |
| [ADR-0009](adr-0009-rabbitmq-message-broker.md) | RabbitMQ is the companion **message broker**; cache and broker are kept distinct on purpose to teach the boundary. |
| [ADR-0010](adr-0010-redis-cache.md) | Superseded. ADR-0010 chose Redis; this ADR records the explicit switch to Valkey and the reasoning. |

## Files

| Path | Role |
|------|------|
| `gitops/platform/valkey.yaml` | ArgoCD Application (auto-synced, sync-wave 3) |
| `gitops/data/valkey/statefulset.yaml` | Single-node Valkey + redis_exporter sidecar, persistent `/data` |
| `gitops/data/valkey/service.yaml` | Ports 6379 (valkey), 9121 (metrics) |
| `gitops/data/valkey/externalsecret.yaml` | `valkey-creds` ← Vault `secret/valkey/default` |
| `gitops/data/demo/valkey-load.yaml` | Demo client generating real SET/GET/INCR traffic |
| `grafana/dashboards/lab-valkey.json` | "Lab — Valkey" dashboard (real metrics) |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-20 — Valkey `8.1.0` release kept, pin stays `8.0-alpine` (audit #627)

**Trigger.** Routine architect sweep (executor fallback role) found
`valkey/valkey:8.1-alpine` is a real, currently-published tag on Docker Hub —
one minor version ahead of this ADR's pinned `8.0-alpine` (verified directly
against Docker Hub's tags API, not inferred).

**Decision: keep the pin at `8.0-alpine`.** Valkey's own real release notes for
`8.1.0` GA (fetched directly from
`raw.githubusercontent.com/valkey-io/valkey/8.1.0/00-RELEASENOTES`, not
inferred) state explicitly: "Upgrade urgency LOW: ... a minor version update
designed to further enhance performance, reliability, observability and
usability over Valkey 8.0 ... fully compatible with all previous Valkey
releases." No security fixes are listed for the `8.1.0` GA release itself.
Bumping a pin with no security or critical-bug rationale — only "a newer
minor exists" — would be pure churn, inconsistent with this repo's own
version-bump culture (every other pin change in this repo's history cites a
specific CVE or critical-bug fix as its rationale).

**Flip condition.** A CVE or critical-bug advisory is disclosed against the
`8.0.x` line that `8.1.x` (or later) fixes, OR a concrete lab-teaching need
emerges for an `8.1`+-only feature — bump
`gitops/data/valkey/statefulset.yaml` and `gitops/data/demo/valkey-load.yaml`'s
`valkey/valkey:8.0-alpine` pins to the fixed/needed version, update this ADR's
"Chart + version" reference (§"Plain manifests over a Helm chart"), and this
log entry's "kept" status.

### 2026-07-21 — Harbor's own cache scoped exception: bundled redis-photon, not Valkey (#632)

**Trigger.** Confirming ADR-0024's "12 GB gate" measurement (issue #632) required
actually running `make harbor-up` for the first time. The `harbor` namespace had
sat empty since the Harbor migration landed — not crashlooping, just never
synced. Root cause: `gitops/platform/harbor.yaml` pointed Harbor's cache
dependency at this ADR's platform Valkey via `redis.external.existingSecret`,
which drives the `goharbor/harbor` chart's `harbor.redis.pwdfromsecret` helper —
a Helm `lookup()` call that bakes the password into the core/jobservice
connection URL at *template* time. ArgoCD only ever renders manifests via `helm
template` (never `install`/`upgrade`), and `lookup()` is documented to always
return nil outside a live install/upgrade — so manifest generation hard-crashed
(nil pointer on `REDIS_PASSWORD`) before anything was ever applied. This is a
permanent chart/ArgoCD incompatibility, not a fixable misconfiguration.

**Decision: scoped exception, not a reconsideration of this ADR.**
`gitops/platform/harbor.yaml` now sets `redis.type: internal`, letting Harbor
deploy its own bundled `goharbor/redis-photon` pod instead of reusing platform
Valkey. This ADR's core decision — Valkey as *the lab's* cache/key-value store —
is unaffected; Harbor's bundled instance is a private dependency of one
on-demand component, exercising the discretion ADR-0024 §"Minimal profile"
already built in ("reuse platform Valkey... where practical... where the chart
allows it"). User-approved explicitly given the `adr-guard-hook` flag this
correctly raised.

**Flip condition.** If the `goharbor/harbor` chart ever supports injecting the
external-Redis password via a runtime env var (matching the pattern its
`registry` component already uses for `REGISTRY_REDIS_PASSWORD`, rather than
baking it into a template-time URL via `lookup()`), or ArgoCD gains a supported
way to make `lookup()` resolve during `helm template`, re-point
`gitops/platform/harbor.yaml` back at platform Valkey and remove this entry.

### 2026-07-22 — Valkey `8.0.10` security release; pin bumped from `8.0-alpine` (RFC #655, audit #654)

**Trigger.** Valkey shipped a coordinated security release across every
maintained branch on 2026-07-21 (`8.0.10`/`8.1.9`/`9.0.5`/`9.1.1`) fixing
**CVE-2026-56684** (TLS use-after-free in `CLIENT KILL` handling —
authenticated-client DoS) and **CVE-2026-63639** (corrupt stream RDB files
with a shared NACK across consumers) — verified directly from Valkey's real
GitHub release page (`github.com/valkey-io/valkey/releases/tag/8.0.10`,
marked "Upgrade Urgency: SECURITY"), not inferred. This is exactly the flip
condition the prior audit (#627, 2026-07-20) recorded in advance: a CVE
disclosed against the `8.0.x` line with a fix available on that same line.

**Decision: bump the pin to `8.0.10-alpine`.** `gitops/data/valkey/statefulset.yaml`
and `gitops/data/demo/valkey-load.yaml`'s `valkey/valkey:8.0-alpine` image
references are updated to `valkey/valkey:8.0.10-alpine` — the smallest safe
delta on the `8.0.x` line that carries both CVE fixes, deliberately not
jumping to `8.1.x`/`9.x` (no lab-teaching need for those minors; same
"smallest safe delta" reasoning as this repo's Cilium/Kargo/Grafana pin
bumps).

**Flip condition.** A CVE or critical-bug advisory is disclosed against the
`8.0.x` line (from `8.0.10` onward) that a later patch fixes, OR a concrete
lab-teaching need emerges for an `8.1`+-only feature — bump both files'
pins to the fixed/needed version and add a new dated log entry here.
