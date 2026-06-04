#!/usr/bin/env bats
# Clusterless structural tests for the NetworkPolicy pilot (ADR-0016, RFC #82).
# Asserts the shared baseline templates and the data namespace overlay are
# correctly shaped — policyTypes, selectors, port values — without a cluster.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  POLICIES="$REPO/gitops/network/policies"
  DATA_NP="$REPO/gitops/data/networkpolicy"
}

# --- Shared baseline templates -----------------------------------------------

@test "default-deny.yaml exists under gitops/network/policies/" {
  [ -f "$POLICIES/default-deny.yaml" ]
}

@test "default-deny policy has policyTypes Ingress and Egress" {
  run grep -c 'Ingress\|Egress' "$POLICIES/default-deny.yaml"
  [ "$status" -eq 0 ]
  # at least two occurrences (one each)
  [ "$output" -ge 2 ]
}

@test "default-deny policy has an empty podSelector (matches all pods)" {
  run grep -q 'podSelector: {}' "$POLICIES/default-deny.yaml"
  [ "$status" -eq 0 ]
}

@test "default-deny policy has no egress or ingress rules (full deny)" {
  run grep -q '^\s*egress:\|^\s*ingress:' "$POLICIES/default-deny.yaml"
  [ "$status" -eq 1 ]
}

@test "allow-dns-and-apiserver.yaml exists under gitops/network/policies/" {
  [ -f "$POLICIES/allow-dns-and-apiserver.yaml" ]
}

@test "allow-dns-and-apiserver policy allows UDP port 53" {
  run grep -q 'port: 53' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'UDP' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver policy allows TCP port 6443 to the k3s API CIDR" {
  run grep -q 'port: 6443' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q '10.43.0.1/32' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver policy targets kube-dns pods in kube-system" {
  run grep -q 'k8s-app: kube-dns' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
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

@test "allow-rabbitmq-ingress allows port 15692 (Prometheus metrics)" {
  run grep -q 'port: 15692' "$DATA_NP/allow-rabbitmq-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-rabbitmq-ingress targets pods with app: rabbitmq" {
  run grep -q 'app: rabbitmq' "$DATA_NP/allow-rabbitmq-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-valkey-ingress.yaml exists in data/networkpolicy/" {
  [ -f "$DATA_NP/allow-valkey-ingress.yaml" ]
}

@test "allow-valkey-ingress allows port 6379 (Valkey)" {
  run grep -q 'port: 6379' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-valkey-ingress allows port 9121 (redis_exporter metrics)" {
  run grep -q 'port: 9121' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-valkey-ingress targets pods with app: valkey" {
  run grep -q 'app: valkey' "$DATA_NP/allow-valkey-ingress.yaml"
  [ "$status" -eq 0 ]
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
