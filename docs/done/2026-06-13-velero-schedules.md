# 2026-06-13 — Velero Schedules — four stateful namespaces

**ROADMAP item:** Velero Schedules — four stateful namespaces (CHARTER Objective O1
+ gates Objective O3, RFC #155 / ADR-0021 §"Schedule set").
**Branch:** claude/zealous-curie-evu99r
**PR:** (see GitHub)

## Item description (verbatim from ROADMAP)

🟢 **Velero Schedules — four stateful namespaces** (CHARTER **Objective O1** + gates
**Objective O3**, RFC #155 — see ADR-0021 §"Schedule set" for binding cron + TTL).
Wait for the Velero controller PR above to merge first (CRDs need to exist for Schedule
manifests to validate in `make ci`). Add four `Schedule` CRs under
`gitops/velero/schedules/`: `data-daily.yaml` (`schedule: "0 2 * * *"`, `ttl: 168h`,
`includedNamespaces: [data]`, `defaultVolumesToFsBackup: true`); `tidb-daily.yaml`
(`schedule: "30 2 * * *"`, TTL 168h, namespace `tidb`); `capstone-daily.yaml`
(`schedule: "0 3 * * *"`, TTL 168h, namespace `capstone`); `vault-daily.yaml`
(`schedule: "30 3 * * *"`, TTL 168h, namespace `vault`). Add
`gitops/platform/velero-schedules.yaml` (auto-synced `Application`, sync-wave 5 — after
the velero controller establishes CRDs). Extend `tests/velero.bats` with four-schedule
assertions (each manifest exists, has the documented cron + TTL + namespace,
`defaultVolumesToFsBackup: true` present on each). (auto/velero-schedules)

## What landed

- `gitops/velero/schedules/data-daily.yaml` — `velero.io/v1` `Schedule`, cron
  `0 2 * * *`, `ttl: 168h`, `includedNamespaces: [data]`, `defaultVolumesToFsBackup: true`.
- `gitops/velero/schedules/tidb-daily.yaml` — cron `30 2 * * *`, TTL 168h, namespace
  `tidb`.
- `gitops/velero/schedules/capstone-daily.yaml` — cron `0 3 * * *`, TTL 168h, namespace
  `capstone`.
- `gitops/velero/schedules/vault-daily.yaml` — cron `30 3 * * *`, TTL 168h, namespace
  `vault`.
- `gitops/platform/velero-schedules.yaml` — auto-synced ArgoCD `Application`, sync-wave 5
  (after `velero-extras` wave 0 / `velero` wave 1 install the namespace + Schedule CRD),
  plain directory mode so it does not collide with `velero-extras` (wave 0) which targets
  `gitops/velero/` for the namespace alone. Auto-discovered by the `root` app-of-apps
  (`gitops/platform/`, recursive) — no `root-app.yaml` edit needed.
- `tests/velero.bats` — extended with the `velero-schedules` Application shape assertions
  (exists, sync-wave 5, path, auto-synced) and four per-Schedule assertions (kind, cron,
  TTL, namespace, `defaultVolumesToFsBackup`).

## Why

CHARTER Objective O3 requires every stateful namespace (`data`, `tidb`, `capstone`,
`vault`) to have a backup the `make dr-restore` path can recover from. The cron windows
are spread 30 min apart (02:00 / 02:30 / 03:00 / 03:30 UTC) so the single node never
snapshots two namespaces concurrently (ADR-0021 §"Schedule set"). The `make dr-restore`
runner that consumes these Schedules (`--from-schedule <ns>-daily`) lands in the next
ROADMAP item.

## Notes

- Clusterless: `make ci` validates manifest well-formedness (kubeconform skips the
  `Schedule` CRD schema via `-ignore-missing-schemas`, same as every other CRD-backed
  manifest in the repo). The Schedules only produce real backups on a live cluster with
  the Velero controller running.
- `tidb` is an on-demand namespace; its Schedule manifest is present now so backups begin
  on the next window once `make tidb-up` brings the cluster up — no further wiring.

## PR

https://github.com/tooming/k8s-anywhere/pull/198
