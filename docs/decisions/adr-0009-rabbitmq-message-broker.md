# ADR-0009 — RabbitMQ as the lab's message broker (plain manifests, always-on)

**Status.** Adopted. Active in `gitops/platform/rabbitmq.yaml` (ArgoCD Application,
auto-synced) and `gitops/data/rabbitmq/` (StatefulSet + Service + ConfigMap +
ExternalSecret + HTTPRoute). Demo traffic from `gitops/data/demo/rabbitmq-load.yaml`.

---

## Context

The lab teaches the cloud-native stack as one coherent system. It had no **messaging /
async** primitive — there was no way to demonstrate event-driven decoupling, work
queues, or a producer/consumer split feeding the observability pillars. A broker is also
a natural backbone for the capstone's inner loop (a service publishes, another consumes).

Options considered for the broker:

| Option | Rationale against / for |
|--------|-------------------------|
| **Apache Kafka** | Log-structured streaming, partitions, consumer groups — powerful, but a heavy JVM footprint (broker + controller/ZooKeeper or KRaft) that fights the 12 GB budget, and overkill for teaching basic async messaging. |
| **NATS** | Very light and fast, but a different (subject-based) model with a smaller "classic broker" teaching surface; no management UI as rich as RabbitMQ's. |
| **Redis Streams** | Already adding Redis (ADR-0010), but conflating cache and broker hides the architectural boundary the lab wants to teach; no first-class AMQP semantics. |
| **RabbitMQ** ✅ | The canonical AMQP broker: queues, exchanges, bindings, acks — the concepts most transferable when *learning* messaging. Ships a first-class management UI and a Prometheus plugin, so it integrates cleanly with the lab's Envoy ingress and LGTMP observability. Modest single-node footprint. |

## Decision

Run **RabbitMQ** as an **always-on** lab component, deployed by ArgoCD (ADR-0001) from
**plain Kubernetes manifests** (a `StatefulSet`, not a Helm chart or an operator). The
broker enables `rabbitmq_management` (UI, routed by Envoy) and `rabbitmq_prometheus`
(metrics, scraped by Alloy). Its default user/password come from Vault via External
Secrets (`secret/rabbitmq/default` → `rabbitmq-creds`), so it never boots on the
well-known `guest/guest` default.

## Plain manifests over a Helm chart / operator

- The two common charts (Bitnami) have been subject to image-distribution and licensing
  churn that breaks reproducibility — antithetical to the lab's "rebuild with one
  command" charter bar. A pinned official `rabbitmq:3.13-management` image in a plain
  `StatefulSet` is fully reproducible and transparent (no chart indirection).
- The **RabbitMQ Cluster Operator** is the production-correct choice for HA, but adds CRDs
  and an operator pod for no teaching gain at single-node lab scale.
- Plain manifests keep the whole definition reviewable in-repo and validated by
  `kubeconform` (core kinds), consistent with the demo/TiDB-demo pattern.

## Single node — the ADR-0005 trade-off

The lab runs **one** RabbitMQ node with a persistent volume (mnesia + the Erlang cookie
survive restarts, so the node recovers in place). This is the same single-host
recoverability-over-HA stance as ADR-0005. **Production** runs a 3-node cluster with
**quorum queues** for failover; that topology is out of scope for a 12 GB single-host lab
and is noted in `docs/dependency-tree.md`.

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Deployed as an ArgoCD `Application` from a git path; no imperative `helm install`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | A broker is itself a decoupling primitive; the single node is a deliberate lab SPOF (see ADR-0005), with the production cluster topology documented. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | The "Lab — RabbitMQ" dashboard is built only on real `rabbitmq_prometheus` + cAdvisor metrics; the `rabbitmq-load` demo generates real traffic so panels aren't empty. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | One node, recover-in-place on a persistent volume, instead of (impossible) single-host HA. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | The management UI is exposed via an Envoy `HTTPRoute` (`rabbitmq.127.0.0.1.nip.io`), like every other lab UI. |
| [ADR-0010](adr-0010-redis-cache.md) | Redis is the companion **cache/KV** primitive; kept distinct from the broker on purpose. |

## Files

| Path | Role |
|------|------|
| `gitops/platform/rabbitmq.yaml` | ArgoCD Application (auto-synced, sync-wave 3) |
| `gitops/data/rabbitmq/statefulset.yaml` | Single-node broker, persistent `/var/lib/rabbitmq` |
| `gitops/data/rabbitmq/configmap.yaml` | `enabled_plugins` (management + prometheus) + `rabbitmq.conf` |
| `gitops/data/rabbitmq/service.yaml` | Ports 5672 (amqp), 15672 (management), 15692 (prometheus) |
| `gitops/data/rabbitmq/route.yaml` | Envoy `HTTPRoute` for the management UI |
| `gitops/data/rabbitmq/externalsecret.yaml` | `rabbitmq-creds` ← Vault `secret/rabbitmq/default` |
| `gitops/data/demo/rabbitmq-load.yaml` | Demo publisher/consumer generating real traffic |
| `grafana/dashboards/lab-rabbitmq.json` | "Lab — RabbitMQ" dashboard (real metrics) |
