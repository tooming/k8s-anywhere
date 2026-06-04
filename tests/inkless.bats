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

# --- Core manifests ----------------------------------------------------------
@test "inkless StatefulSet manifest exists" {
  [ -f "$REPO/gitops/inkless/inkless-statefulset.yaml" ]
}

@test "inkless uses ghcr.io/aiven/inkless image" {
  run grep -q 'ghcr.io/aiven/inkless' "$REPO/gitops/inkless/inkless-statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "postgres StatefulSet manifest exists" {
  [ -f "$REPO/gitops/inkless/postgres-statefulset.yaml" ]
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
