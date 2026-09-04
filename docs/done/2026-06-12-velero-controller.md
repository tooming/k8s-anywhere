# 2026-06-12 — Velero controller + Garage S3 backend

**ROADMAP item:** Velero controller + Garage S3 backend (CHARTER Objective O1 + gates Objective O3, RFC #155 / ADR-0021)
**Branch:** auto/velero-controller
**PR:** https://github.com/tooming/k8s-anywhere/pull/189

## What landed

- `gitops/platform/velero.yaml` — auto-synced ArgoCD Application; chart
  `vmware-tanzu/velero` v8.4.1 from `https://vmware-tanzu.github.io/helm-charts`;
  namespace `velero`; Garage S3 backend (`s3ForcePathStyle=true`,
  `s3Url=http://garage.storage.svc.cluster.local:3900`, bucket `velero`);
  Kopia FS-snapshot uploader; `cloud-credentials` ExternalSecret reference.
- `gitops/platform/velero-extras.yaml` — wave-0 Application that pre-creates the
  `velero` namespace with PSA `restricted` labels before the Helm release (mirrors
  `kyverno-extras` / `trivy-extras` pattern).
- `gitops/velero/namespace.yaml` — PSA `restricted` labels (ADR-0017).
- `gitops/secrets/velero-s3-externalsecret.yaml` — ESO ExternalSecret rendering the
  `cloud-credentials` Secret from Vault path `secret/velero/s3`; uses a Go-template
  to produce the AWS-style INI `[default]` block the Velero chart consumes.
- `scripts/garage-bootstrap.sh` — new `velero-key` Garage access key, `velero` bucket
  creation + grant, Vault path `secret/velero/s3` seeding (mirrors `inkless/s3` flow).
- `scripts/vault-bootstrap.sh` — comment updated to document `secret/velero/s3` as
  garage-bootstrap-seeded.
- `gitops/velero/networkpolicy/` — default-deny overlay (ADR-0016): ingress TCP 8085
  from `observability` (metrics scrape), egress TCP 3900 to `storage` (Garage S3),
  egress to `data`/`tidb`/`capstone`/`vault` for Kopia PV reads.
- `gitops/platform/velero-networkpolicy.yaml` — wave-4 Application for the NP overlay.
- `gitops/platform/observability-alloy.yaml` — `prometheus.scrape "velero"` job targeting
  `velero.velero.svc.cluster.local:8085`.
- `gitops/observability/networkpolicy/allow-alloy-egress-external.yaml` — added velero
  egress rule for Alloy on port 8085.
- `grafana/dashboards/lab-velero.json` — "Lab — Velero (Backup & Restore)" dashboard
  with stat-row (controller running, node-agent running, memory, ArgoCD sync), four
  backup-age panels (one per Schedule: data/tidb/capstone/vault using real
  `velero_backup_last_successful_timestamp`), partial-failure + restore success/failure
  stats, and a backup-success-rate timeseries.
- `docs/dependency-tree.md` — VELERO subgraph + Garage S3 edge + Alloy scrape edge +
  ESO `cloud-credentials` edge.
- `tests/velero.bats` — 43 clusterless structural tests covering Application shape,
  chart source + version pin, Garage backend config, kopia uploader, ExternalSecret
  wiring, namespace PSA labels, NetworkPolicy overlay, Alloy scrape job, and dashboard
  panels.

## What's next (follow-up items already in ROADMAP)

- **Velero Schedules** — four `Schedule` CRs (`data-daily`, `tidb-daily`,
  `capstone-daily`, `vault-daily`) in `gitops/velero/schedules/` + `velero-schedules`
  Application (sync-wave 5). Waits for this PR to merge (CRDs need to exist for
  Schedule manifests to validate in `make ci`).
- **`make dr-restore` + `scripts/dr-restore.sh`** — Objective O3 enabler; waits for
  the Schedules PR.
