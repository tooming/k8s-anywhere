#!/usr/bin/env bats
# O5 dashboard-coverage sweep — one existence + datasource-uid assertion per
# always-on service application (CHARTER Objective O5, auto/o5-dashboard-coverage-bats).
#
# Purpose: verify that every always-on ArgoCD Application has a corresponding
# grafana/dashboards/lab-<name>.json that references at least one real datasource
# panel (ADR-0004 — no fabricated/placeholder content). These are additive to the
# per-component bats files; they do not replace the detailed per-dashboard tests.
#
# Datasource uid check per panel type:
#   metric panels  → "uid": "mimir"
#   log panels     → "uid": "loki"   (observability-loki)
#   trace panels   → "uid": "tempo"  (observability-tempo)
#   profile panels → "uid": "pyroscope" (observability-pyroscope)

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DASHBOARDS="$REPO/grafana/dashboards"
}

# ---------------------------------------------------------------------------
# argo-rollouts
# ---------------------------------------------------------------------------

@test "lab-argo-rollouts.json exists (argo-rollouts coverage)" {
  [ -f "$DASHBOARDS/lab-argo-rollouts.json" ]
}

@test "lab-argo-rollouts.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# capstone
# ---------------------------------------------------------------------------

@test "lab-capstone.json exists (capstone coverage)" {
  [ -f "$DASHBOARDS/lab-capstone.json" ]
}

@test "lab-capstone.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-capstone.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# data-demo
# ---------------------------------------------------------------------------

@test "lab-data-demo.json exists (data-demo coverage)" {
  [ -f "$DASHBOARDS/lab-data-demo.json" ]
}

@test "lab-data-demo.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-data-demo.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# demo (HotROD)
# ---------------------------------------------------------------------------

@test "lab-demo.json exists (demo coverage)" {
  [ -f "$DASHBOARDS/lab-demo.json" ]
}

@test "lab-demo.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-demo.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# envoy-gateway
# ---------------------------------------------------------------------------

@test "lab-envoy.json exists (envoy-gateway coverage)" {
  [ -f "$DASHBOARDS/lab-envoy.json" ]
}

@test "lab-envoy.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-envoy.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# external-secrets
# ---------------------------------------------------------------------------

@test "lab-external-secrets.json exists (external-secrets coverage)" {
  [ -f "$DASHBOARDS/lab-external-secrets.json" ]
}

@test "lab-external-secrets.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-external-secrets.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# garage (S3 object storage)
# ---------------------------------------------------------------------------

@test "lab-garage.json exists (garage coverage)" {
  [ -f "$DASHBOARDS/lab-garage.json" ]
}

@test "lab-garage.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-garage.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# kro + moto + ack-s3 → shared lab-cloud-control-plane.json
# ---------------------------------------------------------------------------

@test "lab-cloud-control-plane.json exists (kro/moto/ack-s3 coverage)" {
  [ -f "$DASHBOARDS/lab-cloud-control-plane.json" ]
}

@test "lab-cloud-control-plane.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# kyverno
# ---------------------------------------------------------------------------

@test "lab-kyverno.json exists (kyverno coverage)" {
  [ -f "$DASHBOARDS/lab-kyverno.json" ]
}

@test "lab-kyverno.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-alloy
# ---------------------------------------------------------------------------

@test "lab-alloy.json exists (observability-alloy coverage)" {
  [ -f "$DASHBOARDS/lab-alloy.json" ]
}

@test "lab-alloy.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-alloy.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-grafana
# ---------------------------------------------------------------------------

@test "lab-grafana.json exists (observability-grafana coverage)" {
  [ -f "$DASHBOARDS/lab-grafana.json" ]
}

@test "lab-grafana.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-grafana.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-ksm (Kube State Metrics)
# ---------------------------------------------------------------------------

@test "lab-ksm.json exists (observability-ksm coverage)" {
  [ -f "$DASHBOARDS/lab-ksm.json" ]
}

@test "lab-ksm.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-ksm.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-loki
# Loki dashboards use the Loki datasource, not Mimir; check "uid": "loki".
# ---------------------------------------------------------------------------

@test "lab-logs.json exists (observability-loki coverage)" {
  [ -f "$DASHBOARDS/lab-logs.json" ]
}

@test "lab-logs.json has real Loki datasource panel (ADR-0004)" {
  run grep -q '"uid": "loki"' "$DASHBOARDS/lab-logs.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-mimir
# ---------------------------------------------------------------------------

@test "lab-mimir.json exists (observability-mimir coverage)" {
  [ -f "$DASHBOARDS/lab-mimir.json" ]
}

@test "lab-mimir.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-mimir.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-node-exporter
# ---------------------------------------------------------------------------

@test "lab-node-exporter.json exists (observability-node-exporter coverage)" {
  [ -f "$DASHBOARDS/lab-node-exporter.json" ]
}

@test "lab-node-exporter.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-pyroscope
# Pyroscope dashboards use the Pyroscope datasource; check "uid": "pyroscope".
# ---------------------------------------------------------------------------

@test "lab-profiles.json exists (observability-pyroscope coverage)" {
  [ -f "$DASHBOARDS/lab-profiles.json" ]
}

@test "lab-profiles.json has real Pyroscope datasource panel (ADR-0004)" {
  run grep -q '"uid": "pyroscope"' "$DASHBOARDS/lab-profiles.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-tempo
# Tempo dashboards use the Tempo datasource; check "uid": "tempo".
# ---------------------------------------------------------------------------

@test "lab-traces.json exists (observability-tempo coverage)" {
  [ -f "$DASHBOARDS/lab-traces.json" ]
}

@test "lab-traces.json has real Tempo datasource panel (ADR-0004)" {
  run grep -q '"uid": "tempo"' "$DASHBOARDS/lab-traces.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# rabbitmq
# ---------------------------------------------------------------------------

@test "lab-rabbitmq.json exists (rabbitmq coverage)" {
  [ -f "$DASHBOARDS/lab-rabbitmq.json" ]
}

@test "lab-rabbitmq.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-rabbitmq.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# s3manager
# ---------------------------------------------------------------------------

@test "lab-s3manager.json exists (s3manager coverage)" {
  [ -f "$DASHBOARDS/lab-s3manager.json" ]
}

@test "lab-s3manager.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-s3manager.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# trivy-operator
# ---------------------------------------------------------------------------

@test "lab-trivy.json exists (trivy-operator coverage)" {
  [ -f "$DASHBOARDS/lab-trivy.json" ]
}

@test "lab-trivy.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-trivy.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# valkey
# ---------------------------------------------------------------------------

@test "lab-valkey.json exists (valkey coverage)" {
  [ -f "$DASHBOARDS/lab-valkey.json" ]
}

@test "lab-valkey.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-valkey.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# vault
# ---------------------------------------------------------------------------

@test "lab-vault.json exists (vault coverage)" {
  [ -f "$DASHBOARDS/lab-vault.json" ]
}

@test "lab-vault.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-vault.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# velero
# ---------------------------------------------------------------------------

@test "lab-velero.json exists (velero coverage)" {
  [ -f "$DASHBOARDS/lab-velero.json" ]
}

@test "lab-velero.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-velero.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# cilium (CNI)
# ---------------------------------------------------------------------------

@test "lab-cilium.json exists (cilium coverage)" {
  [ -f "$DASHBOARDS/lab-cilium.json" ]
}

@test "lab-cilium.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-cilium.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# argocd
# ---------------------------------------------------------------------------

@test "lab-argocd.json exists (argocd coverage)" {
  [ -f "$DASHBOARDS/lab-argocd.json" ]
}

@test "lab-argocd.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-argocd.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# gitsync
# ---------------------------------------------------------------------------

@test "lab-gitsync.json exists (gitsync coverage)" {
  [ -f "$DASHBOARDS/lab-gitsync.json" ]
}

@test "lab-gitsync.json has real Mimir datasource panel (ADR-0004)" {
  run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-gitsync.json"
  [ "$status" -eq 0 ]
}
