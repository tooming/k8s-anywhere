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
| Inkless broker | `ghcr.io/aiven/inkless:4.2.1-0.47` (bumped 2026-09-03 from `:4.2.1-0.46`, pinned 2026-08-18; was `:latest` — see Re-evaluation log) | Single-node KRaft (broker+controller combined); diskless mode |
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

## Observability — kafka-exporter sidecar

The Inkless broker's own StatefulSet (`gitops/inkless/inkless-statefulset.yaml`)
runs a `danielqsj/kafka-exporter:v1.9.0` sidecar — a Prometheus exporter that
translates the broker's Kafka-protocol metrics (topic/partition offsets,
consumer-group lag) into scrapeable Prometheus metrics, the same role
`redis_exporter` plays for Valkey ([ADR-0018](adr-0018-valkey-not-redis.md)).
Verified directly (ADR-0004, 2026-09-03 coverage sweep — this section had no
prior mention despite the sidecar being live since Inkless first landed):
Docker Hub's tags API confirms `v1.9.0` (2025-02-17) is still the newest real
version tag (`latest` was re-pushed 2026-04-13 but carries no newer content);
zero published GHSA advisories exist for `danielqsj/kafka_exporter`.

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

### 2026-09-03 — kafka-exporter sidecar documented + currency-checked (coverage sweep gap)

**Trigger.** This run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) found the `danielqsj/kafka-exporter:v1.9.0` sidecar in
`gitops/inkless/inkless-statefulset.yaml` had zero mention anywhere in this
ADR, despite being live since Inkless first landed — the same class of gap
already closed elsewhere this run via full new ADRs (ADR-0038, ADR-0039), but
here small enough to close as a section addition to the existing governing
ADR instead (kafka-exporter is Inkless's own observability sidecar, not an
independent architectural choice).

**Checked directly (ADR-0004):** Docker Hub's tags API confirms `v1.9.0`
(2025-02-17) is still the newest real version tag; zero published GHSA
advisories exist for `danielqsj/kafka_exporter`. **Decision: kept at
`v1.9.0`** — no currency or security gap, this cycle's work is documentation
only (see the new §Observability — kafka-exporter sidecar section above).

**Flip condition (next re-evaluation).** Re-check kafka-exporter currency and
GHSA status on the next full-sweep pass.

### 2026-09-03 — bumped Inkless broker `4.2.1-0.46` → `4.2.1-0.47` (currency sweep; DB migration caveat)

**Trigger.** Planner-fallback currency sweep (`executor.prompt.md` STEP 6b,
Now/next's three standing items still gated on unconfirmed
maintainer-confirmation issues #633/#1229) re-checked `ghcr.io/aiven/inkless`
per its own numbered-release-line convention established in the 2026-08-18
entry below.

**Verified directly (not assumed, ADR-0004).** GitHub's release list for
`aiven/inkless` shows `inkless-release-0.47` (published 2026-08-19) as the
newest release, one build past the currently-pinned `0.46`. Confirmed the
exact image tag `ghcr.io/aiven/inkless:4.2.1-0.47` is real and pullable via
the same anonymous-token GHCR manifest query the 2026-08-18 entry used
(`GET /v2/aiven/inkless/manifests/4.2.1-0.47` with an `Accept` header
covering `application/vnd.oci.image.index.v1+json` — a first attempt using
only `application/vnd.docker.distribution.manifest.v2+json` returned a
misleading 404, since this is a multi-arch manifest list, not a single-arch
manifest; re-tried with the broader `Accept` header and confirmed 200,
cross-checked against the known-good `4.2.1-0.46` tag returning the same
200 to validate the query methodology itself wasn't broken).

**Release contents.** No named CVE or security advisory this release —
`inkless-release-0.47`'s own notes list real bug fixes (retention-enforcement
throughput pacing, control-plane row repair, ISR/ take clearing after a
classic-to-diskless switch, bounded error-message/logging sizes) and new
metrics/observability additions. **Caveat flagged, not silently absorbed:**
the release notes state "Three PostgreSQL migrations included; migrations
V24 and V25 require table-level locks" against the `postgres:17`
batch-coordinator this ADR's Stack table already names. This session could
not confirm from GitHub's README/release notes alone whether Inkless runs
these migrations automatically on broker startup (the common pattern for
this class of embedded-migration tooling) or needs a human-triggered step —
neither this repo's own docs nor Inkless's public README document its
migration-execution mechanism. Since Inkless is on-demand
(`gitops/platform/inkless.yaml` carries no `syncPolicy.automated`) and is not
currently running in any live cluster this session can affect, this bump
itself carries zero live-cluster blast radius today — but the next `make
inkless-up` needs to watch the broker's startup logs for migration
completion before assuming the bump is safe. Filed as a `[Manual step]`
issue per ROADMAP rule/`executor.prompt.md` STEP 6.5 rather than left only in
this ADR entry.

**Action.** Bumped `gitops/inkless/inkless-statefulset.yaml`'s broker image
to `ghcr.io/aiven/inkless:4.2.1-0.47`. Updated `tests/inkless.bats` (assert
`4.2.1-0.47` present, add a new "no stray `4.2.1-0.46`" guard, mirroring this
repo's other per-component pin-bump pattern). `docs/dependency-register.md`'s
Aiven Inkless row updated to match.

**ADR-0004 caveat.** This remote, clusterless session verified the release
existence and published-image facts directly, but cannot verify the broker
starts cleanly and the PostgreSQL migrations complete successfully on a live
cluster — flagged above and tracked via a standing `[Manual step]` issue
rather than assumed benign. Rollback is a one-line image-tag revert; no data
loss risk from the revert itself since Inkless's real state lives in
Garage S3 + the `postgres:17` PVC, both untouched by reverting the broker's
image tag alone (though a completed forward migration is not automatically
reversed by an image downgrade — a real consideration if a live `make
inkless-up` hits trouble post-bump, noted in the manual-step issue).

**Flip condition (next re-evaluation).** Revisit Inkless's pin again when a
new numbered release is published, or when the `[Manual step]` issue's
observation reveals the migration behavior for future bumps' reference.

### 2026-08-18 — pinned Inkless broker `ghcr.io/aiven/inkless:latest` → `:4.2.1-0.46`, removed the Kyverno `disallow-latest-tag` carve-out

**Trigger.** Executor run, STEP 6b JANITOR-fallback pass over
`gitops/kyverno/policies/disallow-latest-tag.yaml`'s own header comment, which
named its exact flip condition for the `inkless` namespace carve-out (added
2026-07-28): "remove the exclusion once ghcr.io/aiven/inkless ships a stable,
pinnable named release tag."

**Verified directly (not assumed, ADR-0004).** Fetched
`https://ghcr.io/v2/aiven/inkless/tags/list?n=1000` (anonymous pull token,
reachable this session even though most Helm-chart-repo hosts are not) — 673
tags, no pagination `Link` header (the full list). Alongside the rotating
`edge`/`edge-<commit>` builds this ADR's Context section already described,
the project now publishes a clear `<kafka-version>-<inkless-build>` numbered
line (e.g. `4.0.0-0.33` through `4.2.1-0.46`, the newest). This satisfies the
carve-out's flip condition — a real, stable, pinnable named release now
exists.

**Not a pin-what's-running no-op.** Checked `latest`'s manifest digest
(`sha256:8796d83f...`) against every candidate numbered tag's digest,
including the newest (`4.2.1-0.46`, `sha256:b44697ca...`) and `edge`
(`sha256:d82e90e6...`) — none matched. Rather than guess why (repositories
can rebuild `latest` for reasons that change its digest without a
corresponding numbered release, e.g. metadata/attestation regeneration) or
assert an unverifiable equivalence, this is recorded honestly as a real
version change, not a same-content re-pin. Inkless is on-demand
(`gitops/platform/inkless.yaml` carries no `syncPolicy.automated`), so this
carries zero live-cluster blast radius until a user next runs `make
inkless-up`; rollback is a one-line image-tag revert.

**Action.** Bumped `gitops/inkless/inkless-statefulset.yaml`'s broker image to
`ghcr.io/aiven/inkless:4.2.1-0.46`. Removed `inkless` from
`disallow-latest-tag.yaml`'s `exclude.any[].resources.namespaces` list
(`[capstone, inkless]` → `[capstone]`), closing this component's `disallow-
latest-tag` (Objective O4 pre-requisite, ADR-0019) admission-policy gap.
Updated `tests/kyverno.bats` (replaced the "excludes the inkless namespace"
assertion with a "no longer excludes" regression guard, mirroring the
existing argocd-carve-out-removal pattern; updated the exclude-list-length
assertion `2` → `1`) and `tests/inkless.bats` (added a pinned-tag assertion +
a no-floating-tag guard, mirroring this repo's other per-component pin
pairs).

**Flip condition (if this needs revisiting).** None expected — this closes
the carve-out permanently unless Aiven Inkless stops publishing numbered
releases and reverts to `edge`-only, which would be a genuine downstream
regression worth its own fresh audit.

### 2026-08-05 — held `postgres` batch-coordinator image at the `17.x` line (issue #1013)

**Trigger.** Executor run, STEP 6b PLANNER-fallback image-tag sweep found
`postgres/postgres`'s real tags include the `REL_18_*` series (up to
`REL_18_4`) — PostgreSQL 18 is a released major version, one line past this
ADR's pinned `postgres:17` (the batch-metadata coordinator database in
`gitops/inkless/postgres-statefulset.yaml`). Docker Hub confirms matching
`18.x` image tags exist.

**Decision: hold at the `17.x` line.** PostgreSQL major-version upgrades are
not binary-compatible across majors — they require `pg_upgrade` or a
dump/restore against the existing on-disk data directory, not just a fresh
container start. `inkless-postgres` is a single-replica StatefulSet
(ADR-0005) backed by a real PersistentVolume holding live batch-metadata
state whenever Inkless is brought up (`make inkless-up`). A remote
clusterless session cannot verify a `17`→`18` data-directory upgrade path
succeeds without data loss, nor confirm the Inkless broker's own SQL/driver
usage is 18-compatible — mirrors this same log's own `apache/kafka` hold
(2026-07-24, RFC #708) and [ADR-0013](adr-0013-longhorn-block-storage.md)'s
Longhorn `1.12.0` hold: decline a major bump whose upgrade-path safety can't
be confirmed against this lab's actual live topology from this sandbox,
rather than chase the newest release blind.

**Flip condition (next re-evaluation).** Re-check when either: (a) a
live-cluster session verifies a `17`→`18` upgrade path (`pg_upgrade` or
dump/restore) against a real `inkless-postgres` PVC succeeds without data
loss, (b) Inkless's own documentation states PostgreSQL 18 compatibility
explicitly, or (c) a CVE is filed against `postgres:17.x` that `18.x` fixes
and `17.x` does not receive a backport for.

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
