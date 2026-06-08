#!/usr/bin/env bats
# Clusterless structural tests for the NetworkPolicy pilot (ADR-0016, RFC #82).
# Asserts the shared baseline templates and the data namespace overlay are
# correctly shaped — policyTypes, selectors, port values — without a cluster.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  POLICIES="$REPO/gitops/network/policies"
  DATA_NP="$REPO/gitops/data/networkpolicy"
  CAPSTONE_NP="$REPO/gitops/apps/capstone/networkpolicy"
  OBS_NP="$REPO/gitops/observability/networkpolicy"
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

# --- capstone namespace overlay (ADR-0016 §4 fan-out) ------------------------

@test "capstone networkpolicy kustomization.yaml exists" {
  [ -f "$CAPSTONE_NP/kustomization.yaml" ]
}

@test "capstone kustomization sets namespace: capstone" {
  run grep -q 'namespace: capstone' "$CAPSTONE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$CAPSTONE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$CAPSTONE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway.yaml exists in capstone/networkpolicy/" {
  [ -f "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml" ]
}

@test "allow-capstone-ingress-from-gateway allows port 8080 (capstone HTTP)" {
  run grep -q 'port: 8080' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway targets pods with app: capstone" {
  run grep -q 'app: capstone' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'envoy-gateway-system' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-egress-tempo.yaml exists in capstone/networkpolicy/" {
  [ -f "$CAPSTONE_NP/allow-capstone-egress-tempo.yaml" ]
}

@test "allow-capstone-egress-tempo allows port 4318 (OTLP HTTP)" {
  run grep -q 'port: 4318' "$CAPSTONE_NP/allow-capstone-egress-tempo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-egress-tempo targets pods with app: capstone" {
  run grep -q 'app: capstone' "$CAPSTONE_NP/allow-capstone-egress-tempo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-egress-tempo allows egress to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$CAPSTONE_NP/allow-capstone-egress-tempo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-egress-tempo allows egress to pods with app: tempo" {
  run grep -q 'app: tempo' "$CAPSTONE_NP/allow-capstone-egress-tempo.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/capstone-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/capstone-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-networkpolicy ArgoCD Application targets the capstone namespace" {
  run grep -q 'namespace: capstone' "$REPO/gitops/platform/capstone-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- observability namespace overlay (ADR-0016 §4 fan-out) -----------------------

@test "observability networkpolicy kustomization.yaml exists" {
  [ -f "$OBS_NP/kustomization.yaml" ]
}

@test "observability kustomization sets namespace: observability" {
  run grep -q 'namespace: observability' "$OBS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "observability kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$OBS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "observability kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$OBS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-grafana-ingress-from-gateway.yaml exists in observability/networkpolicy/" {
  [ -f "$OBS_NP/allow-grafana-ingress-from-gateway.yaml" ]
}

@test "allow-grafana-ingress-from-gateway allows TCP port 3000 (Grafana container port)" {
  run grep -q 'port: 3000' "$OBS_NP/allow-grafana-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-grafana-ingress-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'envoy-gateway-system' "$OBS_NP/allow-grafana-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tempo-ingress-otlp.yaml exists in observability/networkpolicy/" {
  [ -f "$OBS_NP/allow-tempo-ingress-otlp.yaml" ]
}

@test "allow-tempo-ingress-otlp allows TCP port 4318 (OTLP HTTP)" {
  run grep -q 'port: 4318' "$OBS_NP/allow-tempo-ingress-otlp.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tempo-ingress-otlp allows ingress from capstone namespace" {
  run grep -q 'kubernetes.io/metadata.name: capstone' "$OBS_NP/allow-tempo-ingress-otlp.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tempo-ingress-otlp allows ingress from lab-demo namespace" {
  run grep -q 'kubernetes.io/metadata.name: lab-demo' "$OBS_NP/allow-tempo-ingress-otlp.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external.yaml exists in observability/networkpolicy/" {
  [ -f "$OBS_NP/allow-alloy-egress-external.yaml" ]
}

@test "allow-alloy-egress-external covers argocd namespace" {
  run grep -q 'kubernetes.io/metadata.name: argocd' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external covers data namespace" {
  run grep -q 'kubernetes.io/metadata.name: data' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external covers kubelet port 10250 via cidr" {
  run grep -q 'port: 10250' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-egress-storage.yaml allows TCP 3900 to storage namespace (Garage S3 backend)" {
  run grep -q 'port: 3900' "$OBS_NP/allow-egress-storage.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: storage' "$OBS_NP/allow-egress-storage.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/observability-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/observability-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-networkpolicy ArgoCD Application targets the observability namespace" {
  run grep -q 'namespace: observability' "$REPO/gitops/platform/observability-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
