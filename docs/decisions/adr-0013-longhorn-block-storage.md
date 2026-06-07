# ADR-0013 — Longhorn distributed block storage on-demand

**Status.** Adopted. Decision taken in RFC #60. Manifests pending (next ROADMAP item);
will live in `gitops/platform/longhorn.yaml` (non-auto-synced ArgoCD `Application`) and
brought up with `make longhorn-up`.

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
**official Helm chart** (`longhorn/longhorn` from `https://charts.longhorn.io`).

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
