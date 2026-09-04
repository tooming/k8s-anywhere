# `observability` readOnlyRootFilesystem tighten — Grafana

**`observability` readOnlyRootFilesystem tighten — Grafana** (CHARTER **Objective O2**
hardening, ADR-0017 §"Per-workload field carve-outs"; split from the combined
Alloy/Grafana/Pyroscope item filed 2026-07-14; follow-up to
`auto/observability-readonlyrootfs-alloy`). Verified Grafana's actual write paths
against real chart and application source, fetched via `git clone
--filter=blob:none --sparse` (the network-access method recorded in the prior
Alloy PR):

- `grafana-community/helm-charts` repo (the `grafana` chart migrated off
  `grafana/helm-charts` — a stale README there now just points at the new repo), tag
  `grafana-10.5.15`, `charts/grafana/templates/_pod.tpl`: the main container mounts
  `storage` (our PVC) at `GF_PATHS_DATA` (`/var/lib/grafana`, which also covers
  `GF_PATHS_PLUGINS` at `/var/lib/grafana/plugins`), and mounts an **unconditional**
  chart-managed `emptyDir` named `search` at `/var/lib/grafana-search`
  (`GF_UNIFIED_STORAGE_INDEX_PATH`) regardless of any value — no action needed there.
- `grafana/grafana` repo, tag `v13.0.1`, `pkg/infra/log/log.go`
  (`ReadLoggingConfig`): the log directory (`GF_PATHS_LOGS`, `/var/log/grafana` by
  default) is only `os.MkdirAll`'d inside the `case "file":` branch of the per-mode
  logger loop. Our `grafana.ini` sets `log.mode: console` (the chart default, and the
  Docker entrypoint `packaging/docker/run.sh` also hardcodes
  `cfg:default.log.mode="console"`), so that branch never runs — `/var/log/grafana`
  is never created or written under this configuration.

No new volume or mount was required. Flipped
`containerSecurityContext.readOnlyRootFilesystem: false` → `true` in
`gitops/platform/observability-grafana.yaml`, replaced the stale "follow-up item"
comment with the verified rationale, and extended
`tests/securitycontext-observability.bats` with a `readOnlyRootFilesystem: true`
assertion for Grafana.

(auto/observability-readonlyrootfs-grafana)

## PR

https://github.com/tooming/k8s-anywhere/pull/414
