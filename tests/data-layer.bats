#!/usr/bin/env bats
# Clusterless checks for the always-on data layer (RabbitMQ + Redis + the demo
# traffic generators). These assert the GitOps wiring is internally consistent —
# auto-sync policy, the Vault→ESO secret chain, the Alloy scrape targets, the Vault
# seeding, and the dashboards — so a broken integration is caught before ArgoCD
# ever tries to sync it. No cluster needed.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- always-on (auto-synced) Applications -----------------------------------
@test "rabbitmq Application is auto-synced (always-on)" {
  run grep -A3 'syncPolicy:' "$REPO/gitops/platform/rabbitmq.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"automated:"* ]]
}

@test "valkey Application is auto-synced (always-on)" {
  run grep -A3 'syncPolicy:' "$REPO/gitops/platform/valkey.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"automated:"* ]]
}

@test "data-demo Application is auto-synced (always-on)" {
  run grep -A3 'syncPolicy:' "$REPO/gitops/platform/data-demo.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"automated:"* ]]
}

# --- image pin (ADR-0009 §Re-evaluation log, RFC #522) ----------------------
@test "rabbitmq image is pinned to a community-supported 4.x series (not 3.13)" {
  run grep -q 'image: rabbitmq:4\.' "$REPO/gitops/data/rabbitmq/statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "rabbitmq image is not pinned to the unsupported 3.13 series" {
  run grep -q 'image: rabbitmq:3\.13' "$REPO/gitops/data/rabbitmq/statefulset.yaml"
  [ "$status" -eq 1 ]
}

@test "rabbitmq image is pinned to 4.3.3-management (patch bump from 4.3.2)" {
  run grep -q 'image: rabbitmq:4\.3\.3-management' "$REPO/gitops/data/rabbitmq/statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "valkey's redis_exporter sidecar is pinned to v1.87.0-alpine (patch bump from v1.84.0)" {
  run grep -q 'image: oliver006/redis_exporter:v1\.87\.0-alpine' "$REPO/gitops/data/valkey/statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "valkey image is pinned to 8.0.10-alpine (CVE-2026-56684, CVE-2026-63639 fix, ADR-0018)" {
  run grep -q 'image: valkey/valkey:8\.0\.10-alpine' "$REPO/gitops/data/valkey/statefulset.yaml"
  [ "$status" -eq 0 ]
}

@test "valkey-load image is pinned to 8.0.10-alpine (matches the valkey StatefulSet pin)" {
  run grep -q 'image: valkey/valkey:8\.0\.10-alpine' "$REPO/gitops/data/demo/valkey-load.yaml"
  [ "$status" -eq 0 ]
}

# --- Vault -> ESO secret chain ----------------------------------------------
@test "rabbitmq-creds ExternalSecret pulls from vault key rabbitmq/default" {
  run grep -q 'key: rabbitmq/default' "$REPO/gitops/data/rabbitmq/externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "valkey-creds ExternalSecret pulls from vault key valkey/default" {
  run grep -q 'key: valkey/default' "$REPO/gitops/data/valkey/externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-bootstrap seeds rabbitmq/default and redis/default" {
  run grep -q 'secret/rabbitmq/default' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
  run grep -q 'secret/redis/default' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- observability: Alloy must scrape the data layer ------------------------
@test "Alloy scrapes RabbitMQ (:15692) and Valkey (:9121)" {
  run grep -q 'rabbitmq.data.svc.cluster.local:15692' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'valkey.data.svc.cluster.local:9121' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

# --- security: Valkey must require a password -------------------------------
@test "valkey enforces auth via --requirepass" {
  run grep -q -- '--requirepass' "$REPO/gitops/data/valkey/statefulset.yaml"
  [ "$status" -eq 0 ]
}

# --- ingress: RabbitMQ management UI is routed ------------------------------
@test "RabbitMQ management UI has an HTTPRoute on the nip.io host" {
  run grep -q 'rabbitmq.127.0.0.1.nip.io' "$REPO/gitops/data/rabbitmq/route.yaml"
  [ "$status" -eq 0 ]
}

# --- dashboards exist (ADR-0004 real metrics) -------------------------------
@test "Lab — RabbitMQ and Lab — Valkey dashboards exist" {
  [ -f "$REPO/grafana/dashboards/lab-rabbitmq.json" ]
  [ -f "$REPO/grafana/dashboards/lab-valkey.json" ]
}
