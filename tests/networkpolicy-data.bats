#!/usr/bin/env bats
# Clusterless structural tests for the data namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- data namespace overlay --------------------------------------------------
@test "data networkpolicy kustomization.yaml exists" {
  [ -f "$DATA_NP/kustomization.yaml" ]
}

@test "data kustomization sets namespace: data" {
  run grep -q 'namespace: data' "$DATA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "data kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$DATA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "data kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$DATA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-rabbitmq-ingress.yaml exists in data/networkpolicy/" {
  [ -f "$DATA_NP/allow-rabbitmq-ingress.yaml" ]
}

@test "allow-rabbitmq-ingress allows port 5672 (AMQP)" {
  run grep -q 'port: 5672' "$DATA_NP/allow-rabbitmq-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-rabbitmq-ingress no longer allows port 15692 (ADR-0041: Prometheus metrics rule removed)" {
  run grep -q 'port: 15692' "$DATA_NP/allow-rabbitmq-ingress.yaml"
  [ "$status" -ne 0 ]
}

@test "allow-rabbitmq-ingress targets pods with app: rabbitmq" {
  run grep -q 'app: rabbitmq' "$DATA_NP/allow-rabbitmq-ingress.yaml"
  [ "$status" -eq 0 ]
}

# 2026-08-05: found live that this policy never allowed the gateway's pods, so
# the rabbitmq.127.0.0.1.nip.io front-door route (gitops/data/rabbitmq/route.yaml)
# had never actually worked — same bug class as the harbor carve-out.
@test "allow-rabbitmq-ingress allows kube-system (Traefik) on port 15672 (front-door route)" {
  run grep -B6 'kubernetes.io/metadata.name: kube-system' "$DATA_NP/allow-rabbitmq-ingress.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"15672"* ]]
}

@test "allow-valkey-ingress.yaml exists in data/networkpolicy/" {
  [ -f "$DATA_NP/allow-valkey-ingress.yaml" ]
}

@test "allow-valkey-ingress allows port 6379 (Valkey)" {
  run grep -q 'port: 6379' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-valkey-ingress no longer allows port 9121 (ADR-0041: redis_exporter metrics rule removed)" {
  run grep -q 'port: 9121' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -ne 0 ]
}

@test "allow-valkey-ingress targets pods with app: valkey" {
  run grep -q 'app: valkey' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-valkey-ingress no longer permits the harbor namespace (Harbor uses bundled redis-photon, #632)" {
  # Harbor's external-Redis wiring never rendered under ArgoCD (Helm lookup()
  # always nil in helm template); Harbor now runs its own bundled cache and
  # doesn't reach the data namespace. See gitops/platform/harbor.yaml.
  run grep -q 'kubernetes.io/metadata.name: harbor' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -ne 0 ]
}

@test "allow-data-demo-egress.yaml exists in data/networkpolicy/" {
  [ -f "$DATA_NP/allow-data-demo-egress.yaml" ]
}

@test "allow-data-demo-egress selects rabbitmq-load and valkey-load pods" {
  run grep -q 'rabbitmq-load' "$DATA_NP/allow-data-demo-egress.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'valkey-load' "$DATA_NP/allow-data-demo-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-data-demo-egress allows egress to port 15672 (RabbitMQ management)" {
  run grep -q 'port: 15672' "$DATA_NP/allow-data-demo-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-data-demo-egress allows egress to port 6379 (Redis)" {
  run grep -q 'port: 6379' "$DATA_NP/allow-data-demo-egress.yaml"
  [ "$status" -eq 0 ]
}
