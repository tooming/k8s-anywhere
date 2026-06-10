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
  VAULT_NP="$REPO/gitops/vault/networkpolicy"
  STORAGE_NP="$REPO/gitops/storage/networkpolicy"
  ARGOCD_NP="$REPO/gitops/argocd/networkpolicy"
  MOTO_NP="$REPO/gitops/moto/networkpolicy"
  ACK_NP="$REPO/gitops/ack/networkpolicy"
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

# --- vault namespace overlay (ADR-0016 §4 fan-out) ----------------------------

@test "vault networkpolicy kustomization.yaml exists" {
  [ -f "$VAULT_NP/kustomization.yaml" ]
}

@test "vault kustomization sets namespace: vault" {
  run grep -q 'namespace: vault' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "vault kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "vault kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso.yaml exists in vault/networkpolicy/" {
  [ -f "$VAULT_NP/allow-vault-from-eso.yaml" ]
}

@test "allow-vault-from-eso allows port 8200 (Vault API)" {
  run grep -q 'port: 8200' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso targets Vault server pods" {
  run grep -q 'app.kubernetes.io/name: vault' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'component: server' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso allows ingress from external-secrets namespace" {
  run grep -q 'kubernetes.io/metadata.name: external-secrets' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso allows ingress from ESO controller pods" {
  run grep -q 'app.kubernetes.io/name: external-secrets' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway.yaml exists in vault/networkpolicy/" {
  [ -f "$VAULT_NP/allow-vault-from-gateway.yaml" ]
}

@test "allow-vault-from-gateway allows port 8200 (Vault API)" {
  run grep -q 'port: 8200' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/vault-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/vault-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application targets the vault namespace" {
  run grep -q 'namespace: vault' "$REPO/gitops/platform/vault-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- storage namespace overlay (ADR-0016 §4 fan-out) --------------------------

@test "storage networkpolicy kustomization.yaml exists" {
  [ -f "$STORAGE_NP/kustomization.yaml" ]
}

@test "storage kustomization sets namespace: storage" {
  run grep -q 'namespace: storage' "$STORAGE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "storage kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$STORAGE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "storage kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$STORAGE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-observability.yaml exists in storage/networkpolicy/" {
  [ -f "$STORAGE_NP/allow-garage-s3-from-observability.yaml" ]
}

@test "allow-garage-s3-from-observability allows port 3900 (Garage S3 API)" {
  run grep -q 'port: 3900' "$STORAGE_NP/allow-garage-s3-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-observability allows port 3903 (Garage admin metrics)" {
  run grep -q 'port: 3903' "$STORAGE_NP/allow-garage-s3-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-observability targets Garage pods (app: garage)" {
  run grep -q 'app: garage' "$STORAGE_NP/allow-garage-s3-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-observability allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$STORAGE_NP/allow-garage-s3-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-inkless.yaml exists in storage/networkpolicy/" {
  [ -f "$STORAGE_NP/allow-garage-s3-from-inkless.yaml" ]
}

@test "allow-garage-s3-from-inkless allows port 3900 (Garage S3 API)" {
  run grep -q 'port: 3900' "$STORAGE_NP/allow-garage-s3-from-inkless.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-inkless targets Garage pods (app: garage)" {
  run grep -q 'app: garage' "$STORAGE_NP/allow-garage-s3-from-inkless.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-inkless allows ingress from inkless namespace" {
  run grep -q 'kubernetes.io/metadata.name: inkless' "$STORAGE_NP/allow-garage-s3-from-inkless.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-garage-s3-from-inkless allows ingress from Inkless broker pods (app: inkless)" {
  run grep -q 'app: inkless' "$STORAGE_NP/allow-garage-s3-from-inkless.yaml"
  [ "$status" -eq 0 ]
}

@test "storage-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/storage-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "storage-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/storage-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "storage-networkpolicy ArgoCD Application targets the storage namespace" {
  run grep -q 'namespace: storage' "$REPO/gitops/platform/storage-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- argocd namespace overlay (ADR-0016 §4 fan-out) ---------------------------

@test "argocd networkpolicy kustomization.yaml exists" {
  [ -f "$ARGOCD_NP/kustomization.yaml" ]
}

@test "argocd kustomization sets namespace: argocd" {
  run grep -q 'namespace: argocd' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml" ]
}

@test "allow-argocd-server-from-gateway allows port 8080 (ArgoCD server HTTP)" {
  run grep -q 'port: 8080' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway targets argocd-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-server' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'envoy-gateway-system' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-from-alloy.yaml" ]
}

@test "allow-argocd-from-alloy allows metrics port 8082 (application-controller)" {
  run grep -q 'port: 8082' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows metrics port 8083 (argocd-server-metrics)" {
  run grep -q 'port: 8083' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows metrics port 8084 (repo-server-metrics)" {
  run grep -q 'port: 8084' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows ingress from Alloy pods" {
  run grep -q 'app.kubernetes.io/name: alloy' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-intra-namespace.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-intra-namespace.yaml" ]
}

@test "allow-argocd-intra-namespace allows both Ingress and Egress policyTypes" {
  run grep -c 'Ingress\|Egress' "$ARGOCD_NP/allow-argocd-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-argocd-intra-namespace uses an empty podSelector (matches all pods)" {
  run grep -q 'podSelector: {}' "$ARGOCD_NP/allow-argocd-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-gitlab.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-repo-server-egress-gitlab.yaml" ]
}

@test "allow-argocd-repo-server-egress-gitlab allows port 8929 (GitLab HTTP)" {
  run grep -q 'port: 8929' "$ARGOCD_NP/allow-argocd-repo-server-egress-gitlab.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-gitlab targets argocd-repo-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-repo-server' "$ARGOCD_NP/allow-argocd-repo-server-egress-gitlab.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-gitlab uses an ipBlock for the host CIDR" {
  run grep -q 'ipBlock:' "$ARGOCD_NP/allow-argocd-repo-server-egress-gitlab.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/argocd-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/argocd-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-networkpolicy ArgoCD Application targets the argocd namespace" {
  run grep -q 'namespace: argocd' "$REPO/gitops/platform/argocd-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- moto namespace overlay (ADR-0016 §4 fan-out) --------------------------------

@test "moto networkpolicy kustomization.yaml exists" {
  [ -f "$MOTO_NP/kustomization.yaml" ]
}

@test "moto kustomization sets namespace: moto" {
  run grep -q 'namespace: moto' "$MOTO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "moto kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$MOTO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "moto kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$MOTO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-ack.yaml exists in moto/networkpolicy/" {
  [ -f "$MOTO_NP/allow-moto-from-ack.yaml" ]
}

@test "allow-moto-from-ack allows port 5000 (moto HTTP API)" {
  run grep -q 'port: 5000' "$MOTO_NP/allow-moto-from-ack.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-ack targets pods with app: moto" {
  run grep -q 'app: moto' "$MOTO_NP/allow-moto-from-ack.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-ack allows ingress from ack-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: ack-system' "$MOTO_NP/allow-moto-from-ack.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-gateway.yaml exists in moto/networkpolicy/" {
  [ -f "$MOTO_NP/allow-moto-from-gateway.yaml" ]
}

@test "allow-moto-from-gateway allows port 5000 (moto HTTP API)" {
  run grep -q 'port: 5000' "$MOTO_NP/allow-moto-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$MOTO_NP/allow-moto-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$MOTO_NP/allow-moto-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "moto-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/moto-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "moto-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/moto-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "moto-networkpolicy ArgoCD Application targets the moto namespace" {
  run grep -q 'namespace: moto' "$REPO/gitops/platform/moto-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- ack-system namespace overlay (ADR-0016 §4 fan-out) --------------------------

@test "ack networkpolicy kustomization.yaml exists" {
  [ -f "$ACK_NP/kustomization.yaml" ]
}

@test "ack kustomization sets namespace: ack-system" {
  run grep -q 'namespace: ack-system' "$ACK_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "ack kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ACK_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "ack kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ACK_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-ack-egress-moto.yaml exists in ack/networkpolicy/" {
  [ -f "$ACK_NP/allow-ack-egress-moto.yaml" ]
}

@test "allow-ack-egress-moto allows egress to port 5000 (moto HTTP API)" {
  run grep -q 'port: 5000' "$ACK_NP/allow-ack-egress-moto.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-ack-egress-moto allows egress to moto namespace" {
  run grep -q 'kubernetes.io/metadata.name: moto' "$ACK_NP/allow-ack-egress-moto.yaml"
  [ "$status" -eq 0 ]
}

@test "ack-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/ack-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "ack-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/ack-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "ack-networkpolicy ArgoCD Application targets the ack-system namespace" {
  run grep -q 'namespace: ack-system' "$REPO/gitops/platform/ack-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
