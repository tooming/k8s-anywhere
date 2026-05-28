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

@test "redis Application is auto-synced (always-on)" {
  run grep -A3 'syncPolicy:' "$REPO/gitops/platform/redis.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"automated:"* ]]
}

@test "data-demo Application is auto-synced (always-on)" {
  run grep -A3 'syncPolicy:' "$REPO/gitops/platform/data-demo.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"automated:"* ]]
}

# --- Vault -> ESO secret chain ----------------------------------------------
@test "rabbitmq-creds ExternalSecret pulls from vault key rabbitmq/default" {
  run grep -q 'key: rabbitmq/default' "$REPO/gitops/data/rabbitmq/externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "redis-creds ExternalSecret pulls from vault key redis/default" {
  run grep -q 'key: redis/default' "$REPO/gitops/data/redis/externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-bootstrap seeds rabbitmq/default and redis/default" {
  run grep -q 'secret/rabbitmq/default' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
  run grep -q 'secret/redis/default' "$REPO/scripts/vault-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- observability: Alloy must scrape the data layer ------------------------
@test "Alloy scrapes RabbitMQ (:15692) and Redis (:9121)" {
  run grep -q 'rabbitmq.data.svc.cluster.local:15692' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'redis.data.svc.cluster.local:9121' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

# --- security: Redis must require a password --------------------------------
@test "redis enforces auth via --requirepass" {
  run grep -q -- '--requirepass' "$REPO/gitops/data/redis/statefulset.yaml"
  [ "$status" -eq 0 ]
}

# --- ingress: RabbitMQ management UI is routed ------------------------------
@test "RabbitMQ management UI has an HTTPRoute on the nip.io host" {
  run grep -q 'rabbitmq.127.0.0.1.nip.io' "$REPO/gitops/data/rabbitmq/route.yaml"
  [ "$status" -eq 0 ]
}

# --- dashboards exist (ADR-0004 real metrics) -------------------------------
@test "Lab — RabbitMQ and Lab — Redis dashboards exist" {
  [ -f "$REPO/grafana/dashboards/lab-rabbitmq.json" ]
  [ -f "$REPO/grafana/dashboards/lab-redis.json" ]
}
