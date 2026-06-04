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
