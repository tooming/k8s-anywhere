#!/usr/bin/env bats
# Clusterless structural tests for Velero (backup/restore controller, ADR-0021,
# CHARTER O1 + O3). Validates GitOps wiring (Application shape, namespace PSA labels,
# NetworkPolicy overlay, ExternalSecret) and the Garage bootstrap seam — no running
# cluster required. The Alloy metrics scrape job and Grafana dashboard this file
# used to also test were removed 2026-09-06 (ADR-0041, observability stack removed
# with no replacement).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application shape (always-on, auto-synced) ------------------------
@test "velero Application exists" {
  [ -f "$REPO/gitops/platform/velero.yaml" ]
}

@test "velero Application sources the vmware-tanzu chart from vmware-tanzu.github.io" {
  run grep -q 'repoURL: https://vmware-tanzu.github.io/helm-charts' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application pins a specific 12.x chart version" {
  run grep -qE 'targetRevision: 12\.[0-9]+\.' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application pins chart version 12.1.0 (RFC #617, appVersion 1.18.1)" {
  run grep -q 'targetRevision: 12.1.0' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application targets the velero namespace" {
  run grep -q 'namespace: velero' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage S3 backend (ADR-0002 binding) ------------------------------------
@test "velero Application configures Garage S3 URL (ADR-0002 + ADR-0021)" {
  run grep -q 's3Url: http://garage.storage.svc.cluster.local:3900' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application enables s3ForcePathStyle for Garage compatibility" {
  run grep -q 's3ForcePathStyle: "true"' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application targets bucket named velero" {
  run grep -q 'bucket: velero' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

# --- Kopia uploader (NOT restic — deprecated Velero 1.14+) -------------------
@test "velero Application uses kopia uploader (not restic, per ADR-0021)" {
  run grep -q 'uploaderType: kopia' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -eq 0 ]
}

@test "velero Application does not reference restic (deprecated Velero 1.14+)" {
  run grep -q 'restic' "$REPO/gitops/platform/velero.yaml"
  [ "$status" -ne 0 ]
}

# --- velero-extras (namespace pre-creation, wave 0) --------------------------
@test "velero-extras Application exists" {
  [ -f "$REPO/gitops/platform/velero-extras.yaml" ]
}

@test "velero-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/velero-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (ADR-0017: restricted) ------------------------------
@test "velero namespace manifest exists" {
  [ -f "$REPO/gitops/velero/namespace.yaml" ]
}

@test "velero namespace enforces PSA restricted (ADR-0017)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/velero/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "velero namespace has audit label at restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$REPO/gitops/velero/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- ExternalSecret (cloud-credentials from Vault secret/velero/s3) ----------
@test "velero ExternalSecret file exists" {
  [ -f "$REPO/gitops/secrets/velero-s3-externalsecret.yaml" ]
}

@test "velero ExternalSecret references Vault path velero/s3" {
  run grep -q 'key: velero/s3' "$REPO/gitops/secrets/velero-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "velero ExternalSecret renders the cloud-credentials Secret (Helm chart consumed name)" {
  run grep -q 'name: cloud-credentials' "$REPO/gitops/secrets/velero-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "velero ExternalSecret template produces an AWS-style INI cloud key" {
  run grep -q 'aws_access_key_id' "$REPO/gitops/secrets/velero-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- garage-bootstrap.sh seam (ADR-0021 §"Garage backend") -------------------
@test "garage-bootstrap.sh creates the velero-key Garage access key" {
  run grep -q 'velero-key' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh creates the velero bucket" {
  run grep -q 'bucket create velero' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh writes secret/velero/s3 to Vault" {
  run grep -q 'secret/velero/s3' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- vault-bootstrap.sh seam -------------------------------------------------
@test "vault-bootstrap.sh documents secret/velero/s3 as garage-bootstrap-seeded" {
  run grep -q 'secret/velero/s3' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 §4 fan-out) -----------------------------
@test "velero networkpolicy kustomization exists" {
  [ -f "$REPO/gitops/velero/networkpolicy/kustomization.yaml" ]
}

@test "velero networkpolicy overlay references default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/velero/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "velero networkpolicy overlay references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/velero/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "velero allow-velero-metrics-from-observability rule no longer exists (ADR-0041)" {
  [ ! -f "$REPO/gitops/velero/networkpolicy/allow-velero-metrics-from-observability.yaml" ]
}

@test "velero allow-velero-egress-storage rule exists" {
  [ -f "$REPO/gitops/velero/networkpolicy/allow-velero-egress-storage.yaml" ]
}

@test "velero storage egress rule permits TCP 3900 (Garage S3 API)" {
  run grep -q 'port: 3900' "$REPO/gitops/velero/networkpolicy/allow-velero-egress-storage.yaml"
  [ "$status" -eq 0 ]
}

@test "velero allow-velero-egress-kopia-pv rule exists" {
  [ -f "$REPO/gitops/velero/networkpolicy/allow-velero-egress-kopia-pv.yaml" ]
}

@test "velero kopia-pv egress rule allows egress to data namespace" {
  run grep -q -- '- data' "$REPO/gitops/velero/networkpolicy/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

@test "velero kopia-pv egress rule allows egress to vault namespace" {
  run grep -q -- '- vault' "$REPO/gitops/velero/networkpolicy/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

@test "velero kopia-pv egress rule no longer allows egress to the observability namespace (ADR-0041)" {
  run grep -q -- '- observability' "$REPO/gitops/velero/networkpolicy/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -ne 0 ]
}

# --- velero-networkpolicy Application (wave 4) --------------------------------
@test "velero-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/velero-networkpolicy.yaml" ]
}

@test "velero-networkpolicy Application runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-networkpolicy uses LoadRestrictionsNone" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- Alloy scrape job (ADR-0021 §"Observability") + Grafana dashboard REMOVED
# 2026-09-06 (ADR-0041, observability stack removed with no replacement) --------
@test "grafana/dashboards/lab-velero.json no longer exists (ADR-0041)" {
  [ ! -f "$REPO/grafana/dashboards/lab-velero.json" ]
}

# --- Schedules (ADR-0021 §"Schedule set"; one per stateful namespace) ---------
@test "velero-schedules Application exists" {
  [ -f "$REPO/gitops/platform/velero-schedules.yaml" ]
}

@test "velero-schedules Application runs at sync-wave 5 (after the controller + CRD)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "5"' "$REPO/gitops/platform/velero-schedules.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-schedules Application targets the gitops/velero/schedules path" {
  run grep -q 'path: gitops/velero/schedules' "$REPO/gitops/platform/velero-schedules.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-schedules Application is auto-synced (always-on; Schedules are cheap CRs)" {
  run grep -q 'automated:' "$REPO/gitops/platform/velero-schedules.yaml"
  [ "$status" -eq 0 ]
}

# Each Schedule: exists, is a velero.io/v1 Schedule, has the documented cron + TTL +
# namespace, and sets defaultVolumesToFsBackup so PVCs are captured via Kopia.
@test "observability-daily Schedule no longer exists (ADR-0041)" {
  [ ! -f "$REPO/gitops/velero/schedules/observability-daily.yaml" ]
}

@test "capstone-daily Schedule exists with cron 0 3, ttl 168h, namespace capstone" {
  f="$REPO/gitops/velero/schedules/capstone-daily.yaml"
  [ -f "$f" ]
  grep -q 'kind: Schedule' "$f"
  grep -q 'schedule: "0 3 \* \* \*"' "$f"
  grep -q 'ttl: 168h' "$f"
  grep -qE '^[[:space:]]*- capstone$' "$f"
  grep -q 'defaultVolumesToFsBackup: true' "$f"
}

@test "vault-daily Schedule exists with cron 30 3, ttl 168h, namespace vault" {
  f="$REPO/gitops/velero/schedules/vault-daily.yaml"
  [ -f "$f" ]
  grep -q 'kind: Schedule' "$f"
  grep -q 'schedule: "30 3 \* \* \*"' "$f"
  grep -q 'ttl: 168h' "$f"
  grep -qE '^[[:space:]]*- vault$' "$f"
  grep -q 'defaultVolumesToFsBackup: true' "$f"
}

# --- ADR documentation -------------------------------------------------------
@test "ADR-0021 (Velero) document exists" {
  run sh -c "ls $REPO/docs/decisions/adr-0021-*.md"
  [ "$status" -eq 0 ]
}
