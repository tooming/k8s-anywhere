# ADR-0009 — RabbitMQ as the lab's message broker (plain manifests, always-on)

**Status.** Removed 2026-09-06 (maintainer decision — component dropped from the lab
entirely, no replacement). All `gitops/data/rabbitmq/`, `gitops/platform/rabbitmq.yaml`
manifests, the KEDA rabbitmq-load-scaler ScaledObject/TriggerAuthentication that used
RabbitMQ as its trigger source (see ADR-0029, also removed the same day), the
`lab-rabbitmq.json` dashboard, and every rabbitmq test and cross-reference were deleted
in the same change. The decision record below is kept for history (why RabbitMQ was
adopted, what it demonstrated) but no longer describes anything live in the repo — do
not treat any manifest path or Makefile target named below as still existing.

~~**Status.** Adopted. Active in `gitops/platform/rabbitmq.yaml` (ArgoCD Application,
auto-synced) and `gitops/data/rabbitmq/` (StatefulSet + Service + ConfigMap +
ExternalSecret + HTTPRoute). Demo traffic from `gitops/data/demo/rabbitmq-load.yaml`.~~

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
  command" charter bar. The official `rabbitmq:4.3.5-management` image it ran (bumped
  from the original `3.13-management` pin 2026-07-18, patched to `4.3.3` 2026-07-21,
  then `4.3.4` 2026-07-24, then `4.3.5` 2026-08-19 — see [§Re-evaluation
  log](#re-evaluation-log)) in a plain `StatefulSet` was fully reproducible and
  transparent (no chart indirection) — no longer live, per the Status line above.
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

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision changes but the underlying technology choice does not. A version bump
still leaves a dated trail so the reasoning behind the pin is never lost.

### 2026-07-18 — bumped `3.13-management` → `4.3.2-management` (RFC #522)

**Trigger.** Architect sweep found RabbitMQ's 2024 community-support policy now
covers only the current + previous minor series (`4.3.x`/`4.2.x` as of this
audit); the lab's `3.13-management` pin — four minor series back — no longer
receives free security patches. A version-currency gap, not a single named CVE.

**Decision: bump to `4.3.2-management`.** Groundable and low-risk for this lab:
`gitops/data/rabbitmq/configmap.yaml` sets no `khepri_db` feature flag, so the
node runs on RabbitMQ's default Mnesia metadata store. Per RFC #522's
acceptance criteria, this executor independently re-checked the upgrade-path
guidance at pickup time (RabbitMQ's own docs plus multiple
`rabbitmq/rabbitmq-server` GitHub discussion threads on the Mnesia→Khepri
migration, read as search-result summaries rather than full thread text — a
live-cluster dry run is the only way to fully confirm this, which this
clusterless session cannot do): a direct 3.13 → 4.x upgrade is the supported
path for a Mnesia-based node; only nodes that had explicitly *enabled* Khepri
on 3.13 are blocked from a direct jump and need blue-green instead — not this
lab's case, since Khepri was never enabled here. The metadata store migrates
automatically on first boot of the 4.x binary; no `rabbitmq.conf` change was
needed for the bump itself.

**ADR-0004 caveat.** This remote clusterless session cannot verify the
Mnesia→Khepri migration actually completes cleanly against this lab's live
persisted queue data on a real cluster — that's only exercisable on the
maintainer's hardware. **Rollback path:** revert
`gitops/data/rabbitmq/statefulset.yaml`'s image tag; ArgoCD self-heals the
StatefulSet back onto the old binary. Note this is a genuine *downgrade* of an
on-disk metadata format once Khepri has migrated in — the reverted 3.13 binary
reads Mnesia's on-disk format, not Khepri's, so a clean revert is **not**
guaranteed once the new node has booted and migrated. Per ADR-0005's
already-accepted single-node recreate-over-HA posture, the realistic recovery
path if a revert is ever needed is `make dr-restore` / reseeding the queue
state from Velero, not an in-place downgrade.

**Flip condition (next re-evaluation).** Re-check when RabbitMQ's `4.3.x` line
itself ages out of the community-support window (per the project's own
release-information page) or a specific CVE is filed against the then-current
pin.

### 2026-07-21 — patch bump `4.3.2-management` → `4.3.3-management` (upgrade-drafter)

**Trigger.** `rabbitmq/rabbitmq-server` cut `v4.3.3` on 2026-07-20 (verified
directly against the real release notes at
`raw.githubusercontent.com/rabbitmq/rabbitmq-server/v4.3.3/release-notes/4.3.3.md`
and the `rabbitmq:4.3.3-management` tag on Docker Hub, pushed 2026-07-21). Same
`4.3.x` minor series as the current pin — a maintenance release (a Ra
leader-election partition-scenario bug fix plus a `ra` dependency bump to
`3.1.9`), not a metadata-store or config-format change.

**Decision: bump to `4.3.3-management`.** Same-series patch bump, no Khepri/Mnesia
migration risk beyond what the 2026-07-18 entry above already accepted (both
`4.3.2` and `4.3.3` are past that one-time migration). No `rabbitmq.conf` change
needed. Rollback path unchanged from the entry above.

**Flip condition (next re-evaluation).** Unchanged from above.

### 2026-07-24 — patch bump `4.3.3-management` → `4.3.4-management` (upgrade-drafter)

**Trigger.** `rabbitmq/rabbitmq-server` cut `v4.3.4` on 2026-07-23 (verified directly
against the real release notes at
`raw.githubusercontent.com/rabbitmq/rabbitmq-server/main/release-notes/4.3.4.md` — the
tag-pinned `v4.3.4/release-notes/4.3.4.md` path 404s, the release notes only exist on
`main`, same shape as prior verifications — and the `rabbitmq:4.3.4-management` Docker
Hub tag, `tag_status: active`, `last_updated: 2026-07-23T23:54:39Z`, digest
`sha256:a113bcac1f900561a90bce860bdbf6ac3edf23720e4a4ad3453709844be82153`). Same `4.3.x`
minor series as the current pin — a maintenance release (quorum-queue metrics/snapshot
fix after a `3.13.x`→`4.2.x`→`4.3.x` upgrade path, an AMQP 1.0 parser strictness fix, a
stream single-active-consumer coordinator fix, and a management-UI CSP hardening change
removing `unsafe-eval`/`unsafe-inline`), not a metadata-store or config-format change.

**Decision: bump to `4.3.4-management`.** Same-series patch bump, no Khepri/Mnesia
migration risk beyond what the 2026-07-18 entry above already accepted (`4.3.2`,
`4.3.3`, and `4.3.4` are all past that one-time migration). No `rabbitmq.conf` change
needed. Rollback path unchanged from the entries above.

**Flip condition (next re-evaluation).** Unchanged from above.

### 2026-07-27 — CVE-2026-44839 / CVE-2026-57219 audited, already fixed (audit #761)

**Trigger.** This ADR's own flip condition (above): "a specific CVE is filed
against the then-current pin." Two have been filed since the last entry:
**CVE-2026-44839** (stored XSS via unsanitized vhost names in the management
UI — affects `3.7.0` up to, not including, `4.1.2`/`4.0.13`) and
**CVE-2026-57219** (unauthenticated management endpoint exposes the OAuth
client secret, CVSS 8.7 — introduced in `3.13.0`, fixed in
`4.3.0`/`4.2.6`/`4.1.11`/`4.0.20`/`3.13.15`).

**Decision: keep `4.3.4-management` — already satisfied.** Both CVEs' fixed
floors (`4.1.2`/`4.0.13` for 44839; `4.3.0` for 57219 on the `4.3.x` line) sit
at or below the current pin `4.3.4`. No bump needed; recorded so this flip
condition has an on-record answer instead of silently going unaddressed.

**Flip condition (next re-evaluation).** Unchanged from above.

### 2026-08-19 — patch bump `4.3.4-management` → `4.3.5-management` (upgrade-drafter)

**Trigger.** `rabbitmq/rabbitmq-server` cut `v4.3.5` (verified directly against
the real release notes at both `raw.githubusercontent.com/rabbitmq/rabbitmq-
server/v4.3.5/release-notes/4.3.5.md` and the `main`-branch path — unlike the
`4.3.4` entry above, the tag-pinned path resolves fine this time, both return
identical content — and the `rabbitmq:4.3.5-management` Docker Hub tag,
`tag_status: active`, `last_updated: 2026-08-18T23:53:42.912558Z`, digest
`sha256:b6a1a446c10038cbe65cfe0a1015141411da3a2731282a21cf1583d235da2ca8`). Same
`4.3.x` minor series as the current pin — a maintenance release (a direct
reply-to duplicate-delivery fix, a quorum-queue recovery-checkpoint
partial-initialization fix, a mixed-`4.2.x`/`4.3.x`-cluster quorum-queue query
fallback fix, AMQP 1.0 framing/parser hardening for malformed frames, a topic
exchange fix capping multi-segment `#` wildcards to one per binding key, and an
OAuth 2 token-refresh user-tag fix), not a metadata-store or config-format
change. No CVE/GHSA found against `4.3.4` specifically (checked the same way
as every prior entry on this ADR).

**Decision: bump to `4.3.5-management`.** Same-series patch bump, no
Khepri/Mnesia migration risk beyond what the 2026-07-18 entry above already
accepted. No `rabbitmq.conf` change needed. Rollback path unchanged from the
entries above.

**ADR-0004 caveat:** this remote, clusterless session cannot verify RabbitMQ
still starts cleanly and the demo load generator still connects post-bump on a
real cluster — rollback is a one-line `image:` revert; ArgoCD re-syncs the
prior tag on next reconciliation (always-on, auto-synced, so this reaches the
live cluster on next sync, not just on manual trigger).

**Flip condition (next re-evaluation).** Unchanged from above.

### 2026-08-19 — correction: `4.3.5` actually fixes 10 CVEs disclosed the same day, not zero

**Trigger.** The entry above states "No CVE/GHSA found against `4.3.4`
specifically" — that was checked against `rabbitmq-server`'s release notes
and Docker Hub tag metadata only, not its GitHub Security Advisories page.
A follow-up sweep of `github.com/rabbitmq/rabbitmq-server/security/advisories`
(same run, later cycle) found **ten GHSAs published 2026-08-18** — the exact
day `v4.3.5` was cut — all fixed at `4.3.5`/`4.2.10`/`4.1.15`/`4.0.24`/
`3.13.19` (a coordinated multi-line disclosure, not specific to this lab's
line): one **High** (GHSA-cfqc-c682-93mm, CVSS v4 8.2 — Web STOMP:
unauthenticated clients can exhaust broker memory via compressed
pre-authentication messages, ~64 MiB retained per ~90 KB of wire data,
"a handful of concurrent connections can exceed broker memory limits"),
four **Moderate** (GHSA-6gmw-wxch-cvvc — shovel URI credentials disclosed to
read-only monitoring users; GHSA-6xpg-rfmh-grhq — unauthenticated STOMP
pre-auth frame-size limit unenforced, 4 MiB instead of the intended 64 KiB;
GHSA-3526-xvv4-q9mr — administrator RCE via reflected Erlang distribution
authentication; GHSA-6chv-gv3h-cvcj — direct reply-to forged-suffix fanout
causes quadratic mailbox memory (DoS)), and five **Low**
(GHSA-27gv-h5q6-cpwg — policymaker-role RCE via the same
Erlang-distribution-reflection chain as the administrator RCE above;
GHSA-pj8f-mw2q-3xjj — consistent-hash exchange empty-array crash;
GHSA-4826-gphh-vw3x — MQTT 5 `Receive Maximum: 0` bypasses delivery-credit
limits; GHSA-jv99-v328-mvmm — MQTT 5 malformed `PUBLISH` property disconnects
subscribers; GHSA-86fm-44m9-rqjx — OAuth credential refresh retains a revoked
`impersonator` tag on existing connections). (1 High + 4 Moderate + 5 Low = 10.)

**This lab's `4.3.5` pin (landed earlier this same run, PR #1250) already
carries the fix for all ten** — verified directly against each advisory's
own "Patched versions" list, every one of which names `4.3.5` on the `4.3.x`
line. No further bump is needed; this is a correction to the record, not a
new action item.

**Why this matters going forward:** this ADR's own CVE-check convention
(checking release notes + registry tag metadata) missed a same-day-disclosed
advisory batch that a routine version bump happened to already fix. Future
audits on this ADR should check
`github.com/rabbitmq/rabbitmq-server/security/advisories` directly, not only
release notes — the two sources don't always publish on the same schedule,
and a "no CVE found" claim from release notes alone can understate real risk
even when, as here, the outcome (already patched) turns out the same.

**Flip condition (next re-evaluation).** Unchanged from above.

### 2026-09-04 — currency re-check, no newer patch, kept

**Trigger.** Ranked `dependency-register.md` rows by "Last reviewed" date and
picked up the oldest still-untouched entries this run — RabbitMQ's own last
check was 2026-08-19.

**Re-checked directly (ADR-0004):** Docker Hub's tags API confirms neither
`4.3.6-management` nor `4.4.0-management` exist (both 404) — `4.3.5-management`
is still the newest tag on the `4.3.x` line. **Decision: kept.** No currency
or security gap. Flip condition unchanged from above.
