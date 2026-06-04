# ADR-0010 — Redis as the lab's cache / key-value store (plain manifests, always-on)

**Status.** Superseded by [ADR-0018](adr-0018-valkey-not-redis.md). Valkey (BSD-3,
Linux Foundation) replaced Redis once Valkey 8.0 reached production stability and became
the default managed-KV offering on AWS and GCP. See ADR-0018 for the full rationale.

---

## Context

The lab had no **cache / key-value** primitive — the data structure most apps reach for
first (caching, sessions, counters, rate limits, ephemeral state). Adding one alongside
the message broker (ADR-0009) completes a minimal "data layer" the demo and capstone can
build on, and gives the observability stack a second real workload to chart.

Options considered:

| Option | Rationale against / for |
|--------|-------------------------|
| **Memcached** | Pure cache, no persistence or richer types; smaller teaching surface than Redis. |
| **KeyDB** | Multithreaded Redis fork, but a niche project; no clear lab benefit over upstream. |
| **Valkey** | The Linux Foundation BSD-licensed fork created after Redis relicensed (2024). A legitimate choice; for a *localhost teaching lab* the upstream `redis` image under RSALv2 is unencumbered (the license only restricts offering Redis as a competing managed service), and "Redis" remains the name learners recognize. Valkey stays an easy future swap (drop-in protocol compatibility). |
| **Redis** ✅ | The de-facto KV store; ubiquitous client/exporter ecosystem; `redis_exporter` gives clean Prometheus metrics. Tiny single-node footprint. |

## Decision

Run **Redis** as an **always-on** lab component, deployed by ArgoCD (ADR-0001) from
**plain Kubernetes manifests** (a `StatefulSet`, not a Helm chart). Auth is enforced via
`--requirepass`, with the password sourced from Vault via External Secrets
(`secret/redis/default` → `redis-creds`). A **redis_exporter** sidecar exposes Prometheus
metrics on `:9121`, scraped by Alloy.

## Plain manifests over a Helm chart

Same reasoning as ADR-0009: the popular Bitnami Redis chart has had image-distribution /
licensing churn that undermines the "rebuild with one command" charter bar. A pinned
official `redis:7.4-alpine` image in a plain `StatefulSet` is fully reproducible,
transparent, and validated by `kubeconform`.

## Single node — the ADR-0005 trade-off

The lab runs **one** Redis replica with a persistent volume (an RDB snapshot every 60s;
AOF off — lab-grade durability). On restart it recovers in place. **Production** uses
**Redis Sentinel** (automatic failover) or **Redis Cluster** (sharding + replicas); both
are out of scope for a 12 GB single-host lab and are noted in
`docs/dependency-tree.md`.

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Deployed as an ArgoCD `Application` from a git path; no imperative `helm install`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | A shared cache decouples apps from recomputation/state; the single node is a deliberate lab SPOF (ADR-0005), with the production HA topology documented. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | The "Lab — Redis" dashboard uses only real `redis_exporter` + cAdvisor metrics; the `redis-load` demo generates real ops so panels aren't empty. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | One replica, recover-in-place on a persistent volume, instead of (impossible) single-host HA. |
| [ADR-0009](adr-0009-rabbitmq-message-broker.md) | RabbitMQ is the companion **message broker**; cache and broker are kept distinct on purpose to teach the boundary. |

## Files

| Path | Role |
|------|------|
| `gitops/platform/redis.yaml` | ArgoCD Application (auto-synced, sync-wave 3) |
| `gitops/data/redis/statefulset.yaml` | Single-node Redis + redis_exporter sidecar, persistent `/data` |
| `gitops/data/redis/service.yaml` | Ports 6379 (redis), 9121 (metrics) |
| `gitops/data/redis/externalsecret.yaml` | `redis-creds` ← Vault `secret/redis/default` |
| `gitops/data/demo/redis-load.yaml` | Demo client generating real SET/GET/INCR traffic |
| `grafana/dashboards/lab-redis.json` | "Lab — Redis" dashboard (real metrics) |
