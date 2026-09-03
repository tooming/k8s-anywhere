# ADR-0021 — Velero for cluster + PVC backup/restore to Garage S3

**Status.** Adopted. Decision taken by the architect routine in this RFC. Always-on
component. CHARTER **Objective O1** (one of four Tier 1 next-wave components,
due 2026-12-31) and **gates Objective O3** (`make dr-restore` recovers every
stateful namespace from latest Velero backup in under 10 min).

---

## Context

CHARTER Core Value *Stateful DR is exercised* requires every stateful
namespace (`data`, `tidb`, `capstone`, `vault`) to have a Velero schedule and
a `make dr-restore` path that recovers from the **latest backup**, not just
re-creates the workload from manifest. Today there is no backup layer at all:
`make dr-test` rebuilds workloads via `make up` (manifest re-apply), which is
correct for stateless workloads but silently loses every PVC's contents and
every secret/CR not encoded in git.

Velero is the de-facto CNCF backup standard for Kubernetes (incubating tier).
The two viable alternatives are **Stash** (deprecated upstream in 2023, off
the table) and **Kasten K10** (commercial / closed-source — fails ADR-0011's
prevailing OSS preference).

---

## Decision

Adopt **Velero** as the lab's always-on backup/restore controller, with
**Garage** (ADR-0002) as the S3 backend and **Kopia** as the
filesystem-snapshot uploader (the in-tree default since Velero 1.11).

### Chart + version

- **Chart:** `vmware-tanzu/velero` `12.1.0` (`appVersion: 1.18.1`; pin lives in
  `gitops/platform/velero.yaml`'s `targetRevision` — this note read "v8.4.x
  (latest 8.x stable at executor pickup time)" until the 2026-07-20 RFC #617
  bump; see [§Re-evaluation log](#re-evaluation-log) for the full history).
- **Source:** `https://vmware-tanzu.github.io/helm-charts`
- **Namespace:** `velero` (new namespace; PSA label `restricted`).

### Footprint controls

```yaml
configuration:
  defaultVolumesToFsBackup: true   # Kopia FS-snapshot for all PVCs
  features: EnableCSI              # CSI snapshot if a backend supports it (Longhorn does)
deployNodeAgent: true              # required for FS-backup, runs as DaemonSet
resources:
  requests: { memory: 128Mi }
  limits:   { memory: 256Mi }
nodeAgent:
  resources:
    requests: { memory: 64Mi }
    limits:   { memory: 192Mi }
```

Total: ~250-450 MiB (controller + node-agent DaemonSet on the single node).

### Garage backend (ADR-0002 binding)

Velero needs an S3 bucket. Reuse the existing in-cluster Garage instance, new
bucket:

```yaml
configuration:
  backupStorageLocation:
  - name: garage
    provider: aws
    bucket: velero
    config:
      region: garage
      s3ForcePathStyle: "true"
      s3Url: http://garage.storage.svc.cluster.local:3900
```

Garage bootstrap (`scripts/garage-bootstrap.sh`) gains: create `velero-key`
S3 access key + grant on `velero` bucket; store creds at Vault path
`secret/velero/s3`; create `velero` bucket. An ExternalSecret
(`gitops/secrets/velero-s3-externalsecret.yaml`) renders the
`cloud-credentials` Secret the Velero Helm chart consumes.

### `Schedule` set (one per stateful namespace)

Land in `gitops/velero/schedules/` (separate ArgoCD Application, sync-wave 5
so the controller is up first). Cron windows are deliberately spread so the
node isn't snapshotting two namespaces concurrently:

| Schedule | Namespace | Cron | TTL | Includes |
|----------|-----------|------|-----|----------|
| `observability-daily` | `observability` | `0 1 * * *` | 168h | All resources + PVCs (Loki + Mimir + Tempo, 5Gi each) |
| `data-daily` | `data` | `0 2 * * *` | 168h (7d) | All resources + PVCs (RabbitMQ + Valkey) |
| `tidb-daily` | `tidb` | `30 2 * * *` | 168h | All resources + PVCs (PD/TiKV/TiDB) |
| `capstone-daily` | `capstone` | `0 3 * * *` | 168h | All resources (no PVCs in pilot) |
| `vault-daily` | `vault` | `30 3 * * *` | 168h | All resources + Vault PVC (file backend) |
| `inkless-daily` | `inkless` | `0 4 * * *` | 168h | All resources + PVCs (Inkless broker + Postgres catalog, 2Gi each; on-demand ns, pre-wired like `tidb-daily`) |

`observability-daily` added 2026-07-29 (architect gap audit — see
§Re-evaluation log) to close the mismatch between CHARTER O3's "every
stateful namespace" claim and the original four-namespace set, which
predated the `observability` namespace holding its own PVCs.

Each `Schedule` uses `defaultVolumesToFsBackup: true` so PVCs are captured
via Kopia regardless of CSI driver. Restic is **not** used (deprecated in
Velero 1.14; Kopia is the replacement).

### `make dr-restore` target (Objective O3 enabler)

```makefile
dr-restore: ## Restore every stateful namespace from latest Velero backup (Objective O3)
	@./scripts/dr-restore.sh data tidb capstone vault observability inkless
```

`scripts/dr-restore.sh` (new) iterates `velero restore create --from-schedule
<ns>-daily --wait`. Wall-clock budgeted at 10 min total per CHARTER O3;
script fails if wall time exceeds 600s. The script lives outside `tests/` so
`make ci` doesn't run it (it needs a cluster). The default namespace list
was extended to `observability` and `inkless` on 2026-07-29 once their own
Schedules (`observability-daily`, `inkless-daily`, see above) landed — see
§"Scope & exceptions" for the full six-namespace set this ADR covers.

### Observability

Velero exposes Prometheus metrics on `:8085/metrics`. Add Alloy
`prometheus.scrape "velero"`. Dashboard `grafana/dashboards/lab-velero.json`:
last-backup-age per Schedule (real `velero_backup_last_successful_timestamp`),
backup duration p95, backup/restore phase counters, node-agent pod status.

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/velero/networkpolicy/` (ADR-0016). Allows:
  ingress TCP 8085 from `observability` (metrics scrape); egress TCP 3900
  to `storage` (Garage backups); egress to every backed-up namespace's pods
  (Kopia reads PV contents — practically a wildcard pod-selector inside
  cluster, scoped by `namespaceSelector`).
- PSA label `restricted` (no carve-out needed for controller; node-agent
  needs `hostPath` mounts to read PV contents — same DaemonSet carve-out
  pattern as ADR-0017's node-exporter row).

---

## Why Velero (not alternatives)

- **De-facto Kubernetes-backup standard.** CNCF incubating; quoted as the
  reference DR tool in Kubernetes-DR best-practice writeups across vendors.
- **Garage works as the backend** because Garage is S3-API-compatible
  (ADR-0002) — Velero's `aws` provider with `s3ForcePathStyle=true` is the
  documented Garage configuration.
- **Kopia FS-snapshot covers `local-path` PVCs** — the lab's default
  StorageClass today (ADR-0013's Longhorn is on-demand). Most other backup
  tools require a CSI snapshot driver.
- **Stash is dead** (upstream archived 2023). **Kasten K10** is commercial.
  No third OSS option is realistic.

---

## Scope & exceptions

**In scope** — backup of every stateful namespace listed in CHARTER O3
(`data`, `tidb`, `capstone`, `vault`, `observability`, `inkless`); restore via
`make dr-restore`; real-metric dashboard.

**Out of scope (this RFC):**

- **The in-cluster `storage` (Garage) namespace's own PVC.** Garage is both
  the workload being backed up *and* the S3 target every Velero backup is
  written to — a Garage PVC loss would destroy the live data and every
  stored backup for every other namespace in the same event, which a
  same-target fs-snapshot does not meaningfully protect against (unlike
  `observability`/`data`/`tidb`/`vault`, which back up to a target
  independent of themselves). Deferred rather than silently added, per
  ADR-0004 (adding a Schedule here would assert protection this design does
  not actually provide). **Flip condition:** a backup target independent of
  the in-cluster Garage instance exists (e.g. the off-host tfstate Garage
  below, once repurposed, or a genuine second copy per the next bullet).
- Off-host backup (e.g. push to a cloud S3 bucket as second copy). The single
  off-host Garage instance for tfstate (ADR-0007) is for state, not backups —
  separate concern, can be a follow-up RFC.
- Cross-cluster restore (e.g. restore to a fresh k3d). Possible once Velero is
  in place but not a CHARTER objective.
- Backup encryption-at-rest beyond what Garage provides by default.
- Velero scheduled-backup retention beyond 7 days (single-host disk pressure).
- TiDB application-consistent backup via TiDB-Operator's `BackupSchedule` CR
  (Velero is volume-level; TiDB also has its own logical backup CR — wire that
  in a follow-up so the lab demonstrates both layers).

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0021-velero-backup-restore.md` | This ADR |
| `gitops/platform/velero.yaml` | Auto-synced ArgoCD `Application` for the controller + node-agent |
| `gitops/platform/velero-schedules.yaml` | Auto-synced ArgoCD `Application` for the Schedule set (sync-wave 5) |
| `gitops/velero/schedules/*.yaml` | Six `Schedule` CRs (grew from the original four — see §Schedule set and the 2026-07-29 Re-evaluation log entry) |
| `gitops/velero/networkpolicy/kustomization.yaml` | Default-deny overlay |
| `gitops/secrets/velero-s3-externalsecret.yaml` | Renders `cloud-credentials` Secret from Vault |
| `scripts/garage-bootstrap.sh` | Day-0 seam — create `velero-key` + bucket, seed Vault path |
| `scripts/dr-restore.sh` | `make dr-restore` runner — Objective O3 |
| `Makefile` | New `dr-restore` target |
| `gitops/platform/observability-alloy.yaml` | New `velero` scrape job |
| `grafana/dashboards/lab-velero.json` | Real-metric dashboard (Objective O5) |
| `tests/velero.bats` | Clusterless tests: Application shape, six schedules, ExternalSecret wired, scrape job present, dashboard exists |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Velero + Schedules land as ArgoCD `Application`s. |
| [ADR-0002](adr-0002-garage-not-minio.md) | Garage is the S3 backend (`s3ForcePathStyle=true`). Never MinIO. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Decoupled: controller + node-agent + Garage are separate components. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard reads real `velero_*` counters; backup ages are live. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Backups are how the lab's "recreate over HA" stays honest for *stateful* workloads — the recreate path includes data, not just manifests. |
| [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) | Different concern (tfstate vs. workload data); the off-host Garage is not the Velero backend. |
| [ADR-0013](adr-0013-longhorn-block-storage.md) | When Longhorn is up, Velero's `EnableCSI` feature uses Longhorn snapshots; otherwise falls back to Kopia FS-snapshot. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `velero` namespace gets default-deny during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Controller `restricted`; node-agent DaemonSet gets the same per-workload carve-out as node-exporter. |

---

## Re-evaluation log

- **2026-09-03 (executor full GHSA sweep — second advisory found, confirmed
  clean).** Extending this run's "check every published advisory directly"
  technique (ADR-0004; already applied to Envoy Gateway, Cilium, ArgoCD,
  cert-manager) to Velero. `github.com/vmware-tanzu/velero/security/
  advisories` lists exactly two published advisories — small enough to sweep
  exhaustively. **GHSA-j2g6-362q-6qc6** was already tracked (2026-08-19
  entry below). The second, **GHSA-72xg-3mcq-52v4** (CVE-2020-3996), had not
  been explicitly checked before: Moderate severity, a PV/PVC binding issue
  allowing a restore to bind a pre-existing PV/PVC pair, affecting all
  `0.*`/`1.*` releases before `1.4.3`/`1.5.2`. This lab's pin (chart
  `12.1.0`, appVersion `1.18.1`) is many majors past both floors. **Decision:
  kept at `12.1.0`/`1.18.1` — no action needed**, both published advisories
  are now accounted for. **Flip condition:** revisit if a new GHSA is filed
  against a version at or above `1.18.1`.

- **2026-08-19 (executor security sweep — same-day GHSA, already patched).**
  Direct GHSA-page audit (ADR-0004: checked
  `github.com/vmware-tanzu/velero/security/advisories` directly, not
  release notes) found **GHSA-j2g6-362q-6qc6** — Moderate severity, path
  traversal when extracting a backup's tarball — published the *same day*
  as this audit, affecting `<1.18.1`. This lab's pin (chart `12.1.0`,
  appVersion `1.18.1`, landed 2026-07-20 via RFC #617 above) is exactly the
  first fixed version. The advisory's own structured "Patched versions"
  field said "None" (drafted before `v1.18.1` shipped, per its prose: "We
  are working on the main branch, then cherry-pick to the release-1.18 for
  v1.18.1 patch") — cross-checked directly against `v1.18.1`'s real
  changelog to confirm the fix actually landed there ("Add check for file
  extraction from tarball", PR #9661) rather than trusting the advisory's
  stale patched-version field. **Decision: kept at `12.1.0`/`1.18.1` — no
  action needed**, the RFC #617 chart-major-jump (decided a month before
  this CVE existed) happened to already be ahead of it. **Flip condition:**
  revisit if a new GHSA is filed against a version above `1.18.1`.

- **2026-07-29 (executor follow-up).** Closed the smaller gap the same-day
  architect gap audit (entry directly below) left open: `inkless` has real
  PVCs (Aiven Inkless broker + Postgres catalog, 2Gi each) but, unlike
  `tidb-daily`'s established on-demand-but-pre-wired-schedule precedent, had
  no Schedule at all. **Decision: add `inkless-daily`** — mechanical, matches
  the existing `tidb` pattern exactly (Schedule CR present now so backups
  start on the first sync window after `make inkless-up`, no further wiring
  needed), no new design trade-off. Cron `0 4 * * *`, the next open 30-minute
  slot after `vault-daily`.

- **2026-07-29 (architect gap audit).** Cross-referenced every namespace
  declaring a PVC or `volumeClaimTemplates` under `gitops/**` against the
  Schedule set and CHARTER O3's "every stateful namespace" claim. Found two
  namespaces with real PVCs outside the original four-namespace scope:
  `observability` (Loki/Mimir/Tempo, 5Gi each) and `storage`/Garage.
  **Decision: add `observability-daily`** — unambiguous, groundable now, same
  mechanism and retention as the existing four schedules, no design trade-off
  (see updated Schedule table above and CHARTER O3). **Decision: defer
  `storage`/Garage** — Garage is simultaneously the workload and the backup
  target, so an fs-snapshot of its own PVC does not protect against the
  scenario that matters most (losing that PVC loses the live data *and*
  every other namespace's stored backups at once); adding a schedule anyway
  would assert protection the design doesn't provide (ADR-0004). Recorded as
  an explicit out-of-scope carve-out above rather than silently omitted, with
  a stated flip condition (see §Scope & exceptions). Also noted: `inkless`
  (on-demand, has PVCs) has no pre-wired schedule, unlike `tidb`'s established
  on-demand-but-pre-wired precedent — left open as a smaller follow-up, not
  addressed in this pass.

- **2026-07-18 (executor currency check).** Verified directly against
  `vmware-tanzu/helm-charts`: every `8.x` chart release (`8.4.0` through the
  current pin `8.7.2`) ships `appVersion: 1.15.2` — no `8.x` release ever
  reached `v1.16.x`. This ADR's original "Velero application version v1.16.x"
  line (above) was an inaccurate assumption at authoring time, now corrected.
  The chart repo's own release history jumps straight from `8.7.2` to `11.x`
  (latest `12.1.0`, `appVersion: 1.18.1`) — a major chart-line bump, consistent
  with an upgrade-drafter cycle the same day deliberately staying on the pinned
  `8.x` line rather than crossing it (see `gitops/platform/velero.yaml`'s own
  comment). **Decision: Keep** the `8.x` pin — no CVE or Objective-O3-blocking
  issue found in `1.15.2`; the chart's values-schema diff between `8.7.2` and
  `1.16.x`-era releases was not fully audited this pass. **Flip condition:** a
  disclosed CVE affecting Velero `<1.16` or Kopia's `1.15.x`-era uploader, or a
  future architect RFC that audits the `11.x`/`12.x` chart's values-schema
  compatibility with this Application's `valuesObject` and decides the major
  bump is worth the migration effort.

- **2026-07-20 (architect fallback — flip condition actioned as RFC).** Performed
  the values-schema audit the 2026-07-18 entry's second flip-condition branch
  named: fetched `velero-12.1.0`'s real `values.yaml`/`Chart.yaml` and checked
  every key this Application's `valuesObject` sets (`credentials.{useSecret,
  existingSecret}`, `configuration.{defaultVolumesToFsBackup,features,
  uploaderType,backupStorageLocation}`, `deployNodeAgent`, `resources`,
  `nodeAgent.resources`) — all present and unchanged across the `8.x` → `12.x`
  jump. No disclosed CVE motivates the bump either; this is purely the
  "worth the migration effort" branch, and the verified migration effort is
  near-zero. **Audited → actioned as [RFC #617](https://github.com/tooming/k8s-anywhere/issues/617).**
  The question is now tracked as buildable work (chart bump only, no
  `valuesObject` schema change needed).

- **2026-07-20 (executor — RFC #617 implemented).** Bumped
  `gitops/platform/velero.yaml`'s `targetRevision` from `8.7.2` to `12.1.0`
  (`appVersion: 1.15.2` → `1.18.1`), per the schema audit above — no
  `valuesObject` change required. `tests/velero.bats` updated to pin the new
  version. **Status: resolved.** Both the "Chart + version" summary above and
  the 2026-07-18/2026-07-20 log entries are now superseded by the live pin;
  this closes the flip condition.
