#!/usr/bin/env bats
# Clusterless structural tests for Aiven Inkless (diskless Kafka).
# Validates GitOps wiring, Vault/Garage bootstrap seams, Makefile targets,
# and the Grafana dashboard — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application policy (on-demand, never auto-synced) ----------------
@test "inkless Application exists" {
  [ -f "$REPO/gitops/platform/inkless.yaml" ]
}

@test "inkless Application is NOT auto-synced (on-demand component)" {
  run grep 'automated:' "$REPO/gitops/platform/inkless.yaml"
  [ "$status" -ne 0 ]
}

@test "inkless Application targets the inkless namespace" {
  run grep -q 'namespace: inkless' "$REPO/gitops/platform/inkless.yaml"
  [ "$status" -eq 0 ]
}

# --- Vault bootstrap seam ----------------------------------------------------
@test "vault-bootstrap.sh seeds secret/inkless/postgres" {
  run grep -q 'secret/inkless/postgres' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "vault-bootstrap.sh inkless/postgres entry uses kv put" {
  run grep 'kv put secret/inkless/postgres' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- Garage bootstrap seam --------------------------------------------------
@test "garage-bootstrap.sh creates inkless-key" {
  run grep -q 'inkless-key' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}


@test "garage-bootstrap.sh stores credentials at secret/inkless/s3" {
  run grep -q 'secret/inkless/s3' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh creates inkless bucket" {
  run grep -q 'bucket create inkless' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- ExternalSecret wiring ---------------------------------------------------
@test "inkless ExternalSecret references Vault key inkless/postgres" {
  run grep -q 'inkless/postgres' "$REPO/gitops/inkless/externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless ExternalSecret references Vault key inkless/s3" {
  run grep -q 'inkless/s3' "$REPO/gitops/inkless/externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- Makefile targets --------------------------------------------------------
@test "Makefile has inkless-up target" {
  run grep -E '^inkless-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile has inkless-down target" {
  run grep -E '^inkless-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "inkless-up recipe calls argocd-sync" {
  run grep -A2 '^inkless-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"argocd-sync"* ]]
}

@test "inkless-down recipe calls argocd-delete" {
  run grep -A2 '^inkless-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"argocd-delete"* ]]
}

# --- Grafana dashboard -------------------------------------------------------
@test "Grafana dashboard file lab-inkless.json exists" {
  [ -f "$REPO/grafana/dashboards/lab-inkless.json" ]
}

@test "Grafana dashboard uid is lab-inkless" {
  run grep -q '"uid": "lab-inkless"' "$REPO/grafana/dashboards/lab-inkless.json"
  [ "$status" -eq 0 ]
}

@test "Grafana dashboard queries inkless namespace" {
  run grep -q 'namespace.*inkless' "$REPO/grafana/dashboards/lab-inkless.json"
  [ "$status" -eq 0 ]
}

@test "Grafana dashboard includes kafka-exporter broker metric queries" {
  run grep -q 'kafka_brokers' "$REPO/grafana/dashboards/lab-inkless.json"
  [ "$status" -eq 0 ]
}

@test "Grafana dashboard includes kafka consumer lag queries" {
  run grep -q 'kafka_consumergroup_lag' "$REPO/grafana/dashboards/lab-inkless.json"
  [ "$status" -eq 0 ]
}

# --- Core manifests ----------------------------------------------------------
@test "inkless StatefulSet manifest exists" {
  [ -f "$REPO/gitops/inkless/inkless-statefulset.yaml" ]
}

@test "inkless uses ghcr.io/aiven/inkless image" {
  run grep -q 'ghcr.io/aiven/inkless' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless broker is pinned to a real release tag, 4.2.1-0.47 (2026-09-03, not :latest)" {
  run grep -q 'image: ghcr.io/aiven/inkless:4.2.1-0.47' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless broker does not pin the stale 4.2.1-0.46 tag" {
  run grep -q 'image: ghcr.io/aiven/inkless:4.2.1-0.46' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -ne 0 ]
}

@test "inkless broker does not use the floating :latest image tag" {
  run grep -q 'image: ghcr.io/aiven/inkless:latest' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -ne 0 ]
}

@test "inkless StatefulSet includes kafka-exporter sidecar" {
  run grep -q 'danielqsj/kafka-exporter' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless-load producer/consumer are pinned to apache/kafka:3.9.2 (patch bump from 3.9.1)" {
  run bash -c "grep -c 'image: apache/kafka:3\.9\.2' '$REPO/gitops/inkless/kafka-load.yaml'"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

@test "inkless Service exposes metrics port for exporter" {
  run grep -q 'port: 9308' "$REPO/gitops/inkless/inkless-service.yaml"
  [ "$status" -eq 0 ]
}

@test "Alloy scrapes inkless exporter metrics" {
  run grep -q 'prometheus.scrape \"inkless\"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "postgres StatefulSet manifest exists" {
  [ -f "$REPO/gitops/inkless/postgres-statefulset.yaml" ]
}

@test "postgres StatefulSet image pinned to explicit patch 17.10" {
  run grep -q 'image: postgres:17.10' "$REPO/gitops/inkless/postgres-statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "postgres StatefulSet does not use the floating postgres:17 tag" {
  run grep -Eq 'image: postgres:17$' "$REPO/gitops/inkless/postgres-statefulset.yaml"
  [ "$status" -ne 0 ]
}

@test "inkless StatefulSet mounts no data PVC for broker logs (diskless)" {
  run grep -c 'volumeClaimTemplates' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -eq 0 ]
  # Should have at most one VCT (KRaft metadata only, no broker data disk)
  [ "$output" -le 1 ]
}

# --- ADR documentation -------------------------------------------------------
@test "ADR-0015 (Inkless) document exists" {
  [ -f "$REPO/docs/decisions/adr-0015-inkless-diskless-kafka.md" ]
}

@test "ADR-0015 is listed in docs/decisions/README.md" {
  run grep -q 'ADR-0015' "$REPO/docs/decisions/README.md"
  [ "$status" -eq 0 ]
}
