# ADR-0015 — Aiven Inkless (diskless Kafka) on-demand

**Status.** Adopted. Manifests live in `gitops/inkless/` and `gitops/platform/inkless.yaml`
(non-auto-synced ArgoCD `Application`). Bring up with `make inkless-up`, tear down with
`make inkless-down`.

---

## Context

The lab's existing data layer (ADR-0009 RabbitMQ, ADR-0010 Redis) covers message-broker and
cache patterns. It does not cover **high-throughput, distributed event streaming** — the
architectural pattern Kafka pioneered. A complementary learning objective is:

> Store event-stream data durably in object storage (the "diskless/tiered-storage" model),
> understanding how separating compute and storage changes the operational profile of a
> streaming broker.

[Aiven Inkless](https://github.com/aiven/inkless) is an open-source fork of Apache Kafka
that implements [KIP-1150: Diskless Topics](https://cwiki.apache.org/confluence/display/KAFKA/KIP-1150%3A+Diskless+Topics).
Instead of writing Kafka records to broker-local disks, Inkless writes them directly to
object storage (S3-compatible). A SQL database (PostgreSQL) acts as the batch coordinator:
it stores batch metadata (topic, partition, object ID, extent) and establishes a global
linear order for consumer reads. The broker maintains only an in-memory read cache; there
is no cross-broker replication of user data.

Inkless is **not a long-term fork** — Aiven is contributing these changes upstream to Apache
Kafka. It is open for informational and experimentation purposes. The lab uses it to
demonstrate the diskless architecture before it lands in mainline Kafka.

---

## Decision

Deploy **Aiven Inkless** as an on-demand lab component, backed by the lab's existing
**Garage** S3-compatible object store (ADR-0002) and a single-node **PostgreSQL** instance
(new dependency, scoped to the `inkless` namespace).

The deployment is **on-demand, never auto-synced** — the 12 GB VM budget cannot absorb a
JVM Kafka broker (~1 GB) on top of the always-on stack without explicit user intent.

### Stack

| Component | Image / Source | Notes |
|-----------|---------------|-------|
| Inkless broker | `ghcr.io/aiven/inkless:latest` | Single-node KRaft (broker+controller combined); diskless mode |
| PostgreSQL | `postgres:17` | Batch coordinator (control plane); single-node per ADR-0005 |
| S3 storage | Garage (ADR-0002) | `inkless` bucket; new `inkless-key` S3 credential pair |

---

## Why Inkless

| Criterion | Inkless | Alternatives |
|-----------|---------|-------------|
| **Diskless architecture** | Implements KIP-1150; data written to S3, no broker disk | Standard Kafka requires broker-local disks (tiered storage defers, not eliminates) |
| **S3-compatible storage** | Works with any S3 endpoint — Garage (ADR-0002) is already in the lab | No new storage dependency |
| **Official Docker image** | `ghcr.io/aiven/inkless` published by Aiven on GHCR | No build step needed |
| **Kafka API-compatible** | Standard Kafka producer/consumer clients work unchanged | Learning focus stays on architecture, not client migration |
| **PostgreSQL control plane** | Standard `postgres:17`; a common dependency in cloud-native stacks | Adds the "Postgres as a coordination service" learning pattern |
| **Learning surface** | Compute/storage separation, diskless offset assignment, batch coordinator design | Unique architecture not covered by RabbitMQ/Redis |

---

## Complementarity with existing data layer

| | RabbitMQ (ADR-0009) | Redis (ADR-0010) | Inkless |
|-|---------------------|-----------------|---------|
| **Pattern** | Push message-broker (AMQP) | Key-value cache / pub-sub | Pull event log (Kafka protocol) |
| **Durability model** | Quorum queues (replicated disk) | AOF/RDB (disk) | Object storage (S3) + in-memory cache |
| **Consumption model** | Queue consumer (message deleted on ack) | Get / subscribe | Log consumer (offset-based replay) |
| **Storage coupling** | Broker owns storage | Instance owns storage | Decoupled: broker is stateless compute |

They are complementary patterns, not alternatives.

---

## Garage integration (ADR-0002)

Inkless is configured to use the lab's existing Garage instance as its S3 backend:

- **Endpoint:** `http://garage.storage.svc.cluster.local:3900`
- **Bucket:** `inkless` (created by `scripts/garage-bootstrap.sh`)
- **Credentials:** `inkless-key` S3 key pair; stored at `secret/inkless/s3` in Vault by
  `garage-bootstrap.sh`, synced to the `inkless-broker-creds` Kubernetes Secret via ESO.

Garage's S3-compatible API, path-style access, and `us-east-1` region shim are already
proven by the observability stack (Mimir, Loki, Tempo, Pyroscope). Inkless uses the same
`path_style_access = true` approach — no extra Garage configuration is needed.

---

## PostgreSQL control plane

Inkless requires a SQL database to linearise batch metadata. `postgres:17` is a
well-known, officially-supported image with no additional dependencies. A single replica is
used (ADR-0005: single-host lab; production deployments use HA Postgres). The database is
scoped to the `inkless` namespace; credentials flow `Vault → ESO → Secret`.

---

## 12 GB budget — on-demand, not auto-synced

| Component | Estimated footprint |
|-----------|-------------------|
| Inkless broker (JVM, -Xmx768M) | ~900 MB |
| PostgreSQL | ~150 MB |
| **Total** | **~1.1 GB** |

The ArgoCD `Application` in `gitops/platform/inkless.yaml` has **no `automated:` block**
— ArgoCD discovers it but does not sync it. Users bring it up with:

```sh
make inkless-up   # triggers ArgoCD sync for the inkless Application
make inkless-down # cascade-deletes all inkless resources
```

---

## Relationships to other ADRs

| ADR | Relationship |
|-----|-------------|
| ADR-0001 (GitOps) | Workload deployed as an ArgoCD `Application`; no imperative `helm install` |
| ADR-0002 (Garage) | Garage is Inkless's S3 backend — the existing `garage-bootstrap.sh` adds the inkless bucket |
| ADR-0003 (no needless SPOF) | Single-node per ADR-0005 trade-off; production would add replicas |
| ADR-0004 (real metrics) | Grafana dashboard uses real KSM/cAdvisor metrics; no fabricated data |
| ADR-0005 (recreate-over-HA) | 1 broker + 1 postgres; `make inkless-up` recreates from manifests |
| ADR-0009/0010 (RabbitMQ/Redis) | Complementary data-layer patterns; different interfaces and durability models |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision changes but the underlying technology choice does not. A version bump
(or a deliberate decision to hold one) still leaves a dated trail so the
reasoning is never lost.

### 2026-07-24 — held `apache/kafka` client image at `3.9.2` (RFC #708)

**Trigger.** Upgrade-drafter sweep (issue #705) found `apache/kafka:4.3.1` is now
the newest Docker Hub tag for the image `gitops/inkless/kafka-load.yaml` pins at
`3.9.2` (the newest patch on the `3.9.x` line) for its producer/consumer
load-generator CLI containers. `4.3.1` is a major version.

**Decision: hold at `3.9.2`.** Kafka `4.0` dropped ZooKeeper mode entirely
(KRaft-only) and changed several client/CLI defaults and protocol-version
negotiation behavior. This image is used purely as a Kafka-protocol client
against the Inkless broker, not as a broker itself — the risk is whether
Inkless's own Kafka-protocol implementation correctly negotiates with a 4.x
client, which is undocumented (neither this ADR nor Inkless's own docs state a
supported client-version range) and unverifiable from a remote clusterless
session (no live cluster access, per ADR-0004). Mirrors
[ADR-0013](adr-0013-longhorn-block-storage.md)'s Longhorn `1.12.0` hold: decline
a bump whose behavioral change can't be confirmed safe against this lab's
actual live topology, rather than chase the newest release blind.

**Flip condition (next re-evaluation).** Re-check when either: (a) Inkless's own
documentation or release notes explicitly state Kafka 4.x client-protocol
compatibility, (b) a live-cluster verification confirms a Kafka 4.x
producer/consumer CLI round-trips successfully against the running Inkless
broker, or (c) a CVE is filed against `apache/kafka:3.9.x` that `4.x` fixes and
`3.9.x` does not receive a backport for.
