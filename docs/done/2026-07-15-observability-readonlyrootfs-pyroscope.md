# `observability` readOnlyRootFilesystem tighten — Pyroscope

**`observability` readOnlyRootFilesystem tighten — Pyroscope** (CHARTER **Objective
O2** hardening, ADR-0017 §"Per-workload field carve-outs"; split from the combined
Alloy/Grafana/Pyroscope item filed 2026-07-14; final slice, following
`auto/observability-readonlyrootfs-alloy` and
`auto/observability-readonlyrootfs-grafana`). Verified Pyroscope's actual write paths
against real chart and application source, fetched via `git clone
--filter=blob:none --sparse`:

- The `pyroscope` Helm chart is **not** in `grafana/helm-charts` (a `pyroscope-2.0.3`
  tag exists there but its tree contains no `pyroscope` chart at all — a stale/leftover
  tag) — the real source lives in the `grafana/pyroscope` application repo itself, tag
  `pyroscope-2.0.3`, `operations/pyroscope/helm/pyroscope/`.
- `templates/deployments-statefulsets.yaml`: with this config (`architecture.storage.v1:
  false` / `v2: true`, both chart defaults, and the single top-level `pyroscope:`
  component — i.e. `$component == "all"`), `$isMetastore` evaluates true (`(component ==
  "all" && v2) || component == "metastore"`), so the container mounts the same `data`
  volume twice: at `/data` (no subPath) and at `/data-metastore` (subPath `.metastore`,
  the chart default). Both mounts resolve to our existing `persistence.enabled: true,
  size: 4Gi` PVC (the `data` volume in the chart is PVC-backed whenever
  `persistence.enabled` is true).
- `-metastore.data-dir=./data-metastore/data` and related raft/snapshot args
  (`templates/deployments-statefulsets.yaml`) are relative paths; confirmed via
  `cmd/pyroscope/Dockerfile` that the image sets no `WORKDIR` (so the process's CWD is
  `/`), meaning `./data-metastore/...` resolves to `/data-metastore/...` — inside the
  mounted PVC subPath, not the root filesystem.
- Actual profile block data goes to the S3 backend (Garage, per
  `structuredConfig.storage.backend: s3` already in our config) — the local `/data` /
  `/data-metastore` paths only hold the metastore's raft consensus state and local
  metadata db.

No new volume or mount was required. Flipped
`pyroscope.containerSecurityContext.readOnlyRootFilesystem: false` → `true` in
`gitops/platform/observability-pyroscope.yaml`, replaced the stale "follow-up item"
comment with the verified rationale, and extended
`tests/securitycontext-observability.bats` with a `readOnlyRootFilesystem: true`
assertion for Pyroscope. This closes out the full Alloy/Grafana/Pyroscope
readOnlyRootFilesystem hardening item filed 2026-07-14.

(auto/observability-readonlyrootfs-pyroscope)

## PR

<!-- filled in after opening the PR -->
