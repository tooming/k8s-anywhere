# ADR-0013 — Longhorn distributed block storage on-demand

**Status.** Adopted. Decision taken in RFC #60. Manifests live in
`gitops/platform/longhorn.yaml` (non-auto-synced ArgoCD `Application`, chart pinned per
the Re-evaluation log below) and brought up with `make longhorn-up`.

---

## Context

The lab's primary persistent storage is handled today by:

| Layer | Technology | Scope |
|-------|-----------|-------|
| **Object storage (S3)** | Garage (ADR-0002) | Mimir blocks, Loki chunks, Tempo traces, Pyroscope profiles — all in Garage buckets |
| **Block / filesystem PVCs** | k3s built-in `local-path` provisioner | Everything that needs a PVC: Vault file backend, Garage data dir, Mimir WAL, Grafana DB, GitLab data |

The `local-path` provisioner works — it creates host-path PVCs on the single node — but it
is a thin shim, not a storage layer. It provides no snapshotting, no volume resizing, no
cross-node replication, and no storage-class selection beyond the default. As a learning
platform, the lab needs to demonstrate _how real block storage is managed in Kubernetes_,
including:

- Dynamic provisioning with a custom `StorageClass`
- Volume snapshots and clone operations
- A storage management UI
- The storage → workload dependency chain (volumes, attachment, health checks)

`docs/decisions/context.md` previously marked Longhorn "Deferred" because `local-path`
covers PVCs for the always-on stack. RFC #60 resolves this deferral: Longhorn is a
**learning objective**, not a replacement for `local-path`, and the on-demand / manual-sync
pattern (proven by TiDB, Artifactory, Istio) keeps it off the always-on budget.

---

## Decision

Deploy **Longhorn** as the lab's on-demand distributed block storage layer, using the
**official Helm chart** (`longhorn/longhorn` from `https://charts.longhorn.io`), pinned
at `1.11.3` (bumped from the original `1.7.3` pin 2026-07-18 after the `1.7.x` line
reached end-of-life — see [§Re-evaluation log](#re-evaluation-log)).

Longhorn is **on-demand, never auto-synced** (see *12 GB budget* below). The ArgoCD
`Application` lives in `gitops/platform/longhorn.yaml` with no `automated:` block; users
bring it up with `make longhorn-up` and tear it down with `make longhorn-down`.

`local-path` remains the provisioner for the always-on stack. Longhorn is an *additional*
storage class that co-exists with `local-path` — it does not replace it.

---

## Why Longhorn

| Criterion | Longhorn | Alternatives |
|-----------|---------|-------------|
| **Kubernetes-native** | Purpose-built for Kubernetes; manages volumes as CRDs | OpenEBS, Rook/Ceph are feature-comparable but heavier or more complex on k3d |
| **Official Helm chart** | `longhorn/longhorn` from `charts.longhorn.io` (CNCF project, SUSE-maintained) | No third-party chart supply-chain risk |
| **Learning surface** | Snapshot API, clone, StorageClass, PVC resize, CSI driver — the full Kubernetes storage story | `local-path` teaches none of this |
| **UI** | Built-in Longhorn UI (volume/node/snapshot dashboard) | Rook/Ceph UI is heavier and harder to wire |
| **k3d compatibility** | Works on k3d with `open-iscsi` or the embedded `longhorn` iSCSI; documented community path | Ceph requires raw-block devices; hard on k3d |
| **CNCF project** | Graduated CNCF project (2022) | Adds real-world relevance to the lab |

---

## Complementarity with ADR-0002 (Garage / S3)

Garage (ADR-0002) and Longhorn serve **different storage interfaces** and do not compete:

| | Garage | Longhorn |
|-|--------|---------|
| **Interface** | S3-compatible object store (HTTP PUT/GET) | CSI block/filesystem volumes (PVC/PV) |
| **Use cases** | Observability backends (Mimir, Loki, Tempo, Pyroscope) — large streaming writes | Workloads that need a mounted filesystem or raw block device |
| **State model** | Immutable chunks; no POSIX semantics | POSIX filesystem (ext4/xfs) or raw block |
| **Kubernetes API** | No PVC; accessed via HTTP endpoint | `PersistentVolumeClaim` → `PersistentVolume` via CSI |

The lab runs both: Garage for observability object storage (always-on), Longhorn for
block/filesystem PVCs on-demand. They are complementary storage tiers, not alternatives.

---

## 12 GB budget — on-demand, not auto-synced

The always-on stack already occupies ~7 GB of the 12 GB VM. Longhorn's footprint
estimate for the lab:

| Component | Approximate footprint |
|-----------|-----------------------|
| `longhorn-manager` DaemonSet (1 node effective) | ~200 MB |
| `longhorn-ui` Deployment | ~50 MB |
| `longhorn-driver-deployer` (CSI driver init) | ~30 MB |
| Overhead (engine processes, per-volume) | ~50–100 MB with a few test volumes |
| **Total** | **~350–400 MB** |

This is modest but non-trivial. Running Longhorn simultaneously with Artifactory (~1–2 GB)
and Istio (~480 MB) would be tight. Therefore:

- Longhorn is **on-demand** (non-auto-synced), same pattern as TiDB, Artifactory, and Istio.
- `make longhorn-up` / `make longhorn-down` give the user explicit control.
- A `bats` test asserts that the Longhorn ArgoCD `Application` has no `automated:` block
  (mirrors `tests/platform.bats` for Artifactory and Istio).

This is consistent with **ADR-0001** (workloads via ArgoCD, not `helm install`) and
**ADR-0005** (recreate-from-code on a single host — if PVCs are lost, `make longhorn-up`
re-provisions the storage class and the user re-creates volumes as needed).

---

## Why we are un-deferring now

`docs/decisions/context.md` originally deferred Longhorn with: _"not needed — `local-path`
covers PVCs; optional learning extra, fiddliest on k3d. Deferred."_ The reasons to
un-defer:

1. **Learning objective is concrete.** RFC #60 scoped the work: StorageClass + UI + one
   snapshot demo. The vague "fiddliest on k3d" concern is addressed by the on-demand
   pattern — Longhorn doesn't run unless the user explicitly asks for it.
2. **On-demand pattern proven.** TiDB (1.5 GB), Artifactory (~1–2 GB), and Istio (~480 MB)
   all land as manual-sync Applications with no always-on cost. Longhorn (~350–400 MB) fits
   the same pattern cleanly.
3. **Completes the storage learning path.** With Garage covering S3 and Longhorn covering
   block/PVC, the lab demonstrates both of the primary Kubernetes storage interfaces.
4. **CNCF graduation (2022) reduced the "fiddly" risk.** Longhorn v1.x has stable k3s/k3d
   support documented in the project's own guides.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Longhorn is deployed as an ArgoCD `Application` from the official Helm chart. `helm install` is never run directly. |
| [ADR-0002](adr-0002-garage-not-minio.md) | Garage (S3 object) and Longhorn (block/filesystem) are complementary storage tiers. Longhorn does not replace Garage. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Longhorn's DaemonSet architecture is node-distributed by design. The lab accepts a single-replica UI (ADR-0005). |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-node Longhorn on a single host — acceptable for learning. Production runs ≥ 3 nodes with replication factor ≥ 2. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | The Longhorn UI is exposed via an Envoy `HTTPRoute` (`longhorn.127.0.0.1.nip.io`), like every other lab UI. |

---

## Files (once the manifest item lands)

| Path | Role |
|------|------|
| `gitops/platform/longhorn.yaml` | ArgoCD Application — non-auto-synced; chart `longhorn/longhorn` from `https://charts.longhorn.io` |
| `gitops/longhorn/route.yaml` | Envoy `HTTPRoute` for the Longhorn UI (`longhorn.127.0.0.1.nip.io`) |
| `Makefile` | `longhorn-up` and `longhorn-down` targets |
| `tests/platform.bats` | bats assertion: Longhorn Application has no `automated:` block |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision changes but the underlying technology choice does not. A version bump
still leaves a dated trail so the reasoning behind the pin is never lost.

### 2026-07-18 — bumped `1.7.3` → `1.11.3` (RFC #528)

**Trigger.** Architect sweep found Longhorn's `1.7.x` line reached end-of-life
2025-09-04 (one year after its first stable release, under the pre-1.8
12-month support policy); the lab's `1.7.3` pin — roughly a year past that
line's support window — no longer receives security patches. A
version-currency gap, not a single named CVE.

**Decision: bump to `1.11.3`.** Deliberately one minor line behind the newest
`1.12.x` (which just went GA with the V2 Data Engine — a bigger behavioral
surface change than this routine currency bump warrants), same
smallest-safe-delta reasoning as this session's other version bumps.
Re-verified at pickup time (per RFC #528's acceptance criteria) that `1.11.3`
was still the latest stable patch on the `1.11.x` line and that `1.12.0`
remained the newest stable release overall (with only a `1.12.1-rc1`
pre-release beyond it) — confirmed directly against
`longhorn/longhorn`'s and `longhorn/charts`' GitHub release tags, not assumed
from the RFC. Diffed the chart's `values.yaml` between the old and new pins
for every key this repo's `valuesObject` sets
(`defaultSettings.defaultReplicaCount`, `persistence.defaultClassReplicaCount`,
`ingress.enabled`, `longhornUI.{replicas,resources}`,
`longhornManager.resources`): all five paths still exist unchanged at
`1.11.3` (the upstream default for `longhornUI.resources` is unset/`~`, but
that's the *default*, not a removed key — this repo's own override still
applies normally). The V2 (SPDK) Data Engine remains opt-in, not default, at
this pin — no behavior change from that GA.

**ADR-0004 caveat.** This remote clusterless session cannot verify Longhorn's
CSI driver, manager, or UI actually start cleanly against real (or absent)
volume data on a live cluster post-bump. **Rollback path:** revert
`gitops/platform/longhorn.yaml`'s `targetRevision`; since Longhorn is
on-demand and not auto-synced, this carries zero live-cluster risk unless the
maintainer already has it running via `make longhorn-up` with real
provisioned volumes, in which case a version-format mismatch on downgrade is
possible (same class of risk as any stateful storage engine) — verify
current state before reverting if Longhorn is actually up.

**Flip condition (next re-evaluation).** Re-check when the `1.11.x` line
itself approaches its own end-of-support window, or a specific CVE is filed
against the then-current pin.

### 2026-07-28 — flip condition re-checked, `1.11.3` kept (executor currency check)

**Trigger.** Periodic re-check of the 2026-07-18 flip condition above, as part of
this run's broader pinned-version currency sweep (PRs #815/#817/#818/#819).

**Re-checked directly against live sources (ADR-0004):** `longhorn/charts`' real
tags (`raw.githubusercontent.com/longhorn/charts/<tag>/charts/longhorn/Chart.yaml`,
since `api.github.com` and `charts.longhorn.io` are both proxy-blocked from this
sandbox but the raw CDN host is not) confirm `longhorn-1.12.0` is still the only
release past `1.11.3` — no `1.11.4`, `1.12.1`, or later tag exists yet. Neither
flip condition has fired: `1.11.x` is 10 days into its support window, nowhere
near end-of-life on the pre-1.8 12-month policy, and no CVE has been filed
against `1.11.3` in that window (checked; none found).

**Decision: kept at `1.11.3`.** The 2026-07-18 decision to deliberately stay one
minor line behind `1.12.x` (V2 Data Engine GA — a bigger behavioral surface
change than a routine currency bump warrants) still holds; overriding it without
either flip condition firing would silently contradict a binding, reasoned
architect decision rather than superseding it. No repo change this cycle.
Flip condition unchanged from the 2026-07-18 entry above.

### 2026-08-19 — GHSA sweep, no new advisory (executor security check, cycle 12)

**Trigger.** This run's direct-GHSA-advisory-page security sweep (the method
that found real gaps elsewhere this run, e.g. RabbitMQ/Cilium) reached Longhorn.

**Checked directly against `github.com/longhorn/longhorn/security/advisories`
(ADR-0004):** only two advisories exist for the entire project —
GHSA-27q8-g55w-83p9 and GHSA-g358-m2wp-mhhx, both High severity, both
published 2021-12-17. Neither has a version range that could plausibly reach
the current `1.11.3` pin (four-plus years and multiple major lines newer).

**Decision: kept at `1.11.3`, no CVE-driven action.** Confirms the
2026-07-28 currency check from a different angle (security advisories rather
than release-tag currency) rather than superseding it. Flip condition
unchanged from the 2026-07-18 entry above.

### 2026-09-03 — `1.12.1` now stable; flip condition still not triggered, kept

**Trigger.** This run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) re-checked every pinned chart's real upstream currency after the
"Now / next" lane was re-confirmed fully gated.

**Re-checked directly against live sources (ADR-0004):** `longhorn/longhorn`'s
own GitHub releases confirm `v1.12.1` (the `1.12.x` line the 2026-07-18 entry
named as the reason to stay one minor line behind) went stable **2026-08-14**
— cross-verified two ways, not assumed from a single fetch: (1) the release
tag's own page, and (2) `raw.githubusercontent.com/longhorn/longhorn/v1.12.1/
deploy/longhorn-images.txt`, which resolves and lists real
`longhornio/*:v1.12.1` image tags (a tag that doesn't exist would 404 there,
same verification method used for the ADR-0037/Vault tag check this run).
`v1.12.1`'s own release notes describe a materially larger surface than a
routine patch: V2 Data Engine fast volume cloning + experimental storage
sharding (erasure coding), extended instance-manager mTLS, new internal
`NetworkPolicy` ingress rules, and an explicit **breaking change** — "legacy
V2 linked-clone volumes created in v1.12.0 or earlier are deprecated... cannot
be operated on except for detachment and deletion."

**Decision: kept at `1.11.3` — the ADR's own flip condition has still not
fired.** Neither named trigger applies: `1.11.x` is roughly seven weeks into
its support window (nowhere near the pre-1.8 12-month EOL policy that
justified the original `1.7.3`→`1.11.3` bump), and the 2026-08-19 GHSA sweep
above found no CVE filed against `1.11.3`. `v1.12.1`'s own release notes
reinforce, rather than undercut, the original 2026-07-18 reasoning — this is
now confirmed as a bigger behavioral change (including a breaking one) than a
routine currency bump should absorb, not a smaller one. Bumping here without
either flip condition firing would silently contradict this ADR's own binding
decision (CLAUDE.md's "never silently violate an ADR" rule) — noted
explicitly rather than done quietly. Flip condition unchanged from the
2026-07-18 entry above.
