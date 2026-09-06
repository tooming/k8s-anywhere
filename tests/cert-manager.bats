#!/usr/bin/env bats
# Clusterless structural tests for cert-manager (TLS certificate lifecycle
# manager, ADR-0028). Validates GitOps wiring (Application shape, namespace PSA
# labels, NetworkPolicy overlay, self-signed root-CA bootstrap chain), the Alloy
# metrics scrape job, and the Grafana dashboard — no running cluster required.
# New CHARTER Goal ("automated TLS certificate lifecycle") — first item.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
}

# --- ArgoCD Application shape (always-on, auto-synced) ------------------------
@test "cert-manager Application exists" {
  [ -f "$REPO/gitops/platform/cert-manager.yaml" ]
}

@test "cert-manager Application sources the chart from charts.jetstack.io" {
  run grep -q 'repoURL: https://charts.jetstack.io' "$REPO/gitops/platform/cert-manager.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager Application pins chart version 1.21.1" {
  run grep -q 'targetRevision: 1.21.1' "$REPO/gitops/platform/cert-manager.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/cert-manager.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager Application targets the cert-manager namespace" {
  run grep -q 'namespace: cert-manager' "$REPO/gitops/platform/cert-manager.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager Application installs CRDs via the chart (crds.enabled: true)" {
  [ "$(yqs '.spec.source.helm.valuesObject.crds.enabled' "$REPO/gitops/platform/cert-manager.yaml")" = "true" ]
}

@test "cert-manager Application sets memory limits per ADR-0028 footprint controls" {
  run grep -q 'memory: 128Mi' "$REPO/gitops/platform/cert-manager.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'memory: 64Mi' "$REPO/gitops/platform/cert-manager.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager cainjector memory limit is 128Mi (live-verified OOMKill fix, ADR-0028; issue #1345)" {
  # 64Mi OOMKilled cainjector 464x/7d once the lab's CRD/webhook footprint grew,
  # silently breaking Kargo's admission webhooks. Raised to 128Mi 2026-08-18.
  [ "$(yqs '.spec.source.helm.valuesObject.cainjector.resources.limits.memory' "$REPO/gitops/platform/cert-manager.yaml")" = "128Mi" ]
}

@test "cert-manager Application syncs with ServerSideApply (its issuer CRDs exceed the client-side-apply cap)" {
  # clusterissuers.cert-manager.io / issuers.cert-manager.io are ~325 KB each,
  # over the 262144-byte client-side-apply annotation limit — same failure class
  # ADR-0019 hit for Kyverno. See scripts/argocd-crd-ssa-check.sh.
  [ "$(yqs '.spec.syncPolicy.syncOptions | contains(["ServerSideApply=true"])' "$REPO/gitops/platform/cert-manager.yaml")" = "true" ]
}

# --- cert-manager-extras (namespace pre-creation, wave 0) ---------------------
# "cert-manager-extras Application exists" lives in tests/securitycontext-cert-manager.bats
# (removed here 2026-08-27 — exact duplicate, same target file, found in a
# cross-file duplication sweep).
@test "cert-manager-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/cert-manager-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (restricted — no carve-out needed, ADR-0028) --------
# "cert-manager namespace enforces PSS restricted" and "...has enforce-version:
# latest" live in tests/securitycontext-cert-manager.bats (removed here
# 2026-08-27 — exact duplicates, same target file).
@test "cert-manager namespace manifest exists" {
  [ -f "$REPO/gitops/cert-manager/namespace.yaml" ]
}

@test "cert-manager namespace has warn and audit at restricted too" {
  run grep -q 'warn: restricted' "$REPO/gitops/cert-manager/namespace.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'audit: restricted' "$REPO/gitops/cert-manager/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 fan-out, wave 4) --------------------------
@test "cert-manager networkpolicy kustomization exists" {
  [ -f "$REPO/gitops/cert-manager/networkpolicy/kustomization.yaml" ]
}

@test "cert-manager networkpolicy overlay references default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/cert-manager/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager networkpolicy overlay references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/cert-manager/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager allow-webhook-from-apiserver rule permits TCP 10250" {
  run grep -q 'port: "10250"' "$REPO/gitops/cert-manager/networkpolicy/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager allow-metrics-from-observability rule permits TCP 9402" {
  run grep -q 'port: 9402' "$REPO/gitops/cert-manager/networkpolicy/allow-cert-manager-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager allow-metrics rule selects Alloy pods from observability namespace" {
  run grep -q 'name: alloy' "$REPO/gitops/cert-manager/networkpolicy/allow-cert-manager-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'observability' "$REPO/gitops/cert-manager/networkpolicy/allow-cert-manager-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/cert-manager-networkpolicy.yaml" ]
}

@test "cert-manager-networkpolicy Application runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager-networkpolicy uses LoadRestrictionsNone" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- Self-signed root-CA bootstrap chain (wave 5, ADR-0028) --------------------
@test "selfsigned-bootstrap ClusterIssuer exists and is type selfSigned" {
  [ -f "$REPO/gitops/cert-manager/root-ca/selfsigned-bootstrap-issuer.yaml" ]
  [ "$(yqs '.spec.selfSigned' "$REPO/gitops/cert-manager/root-ca/selfsigned-bootstrap-issuer.yaml")" = "{}" ]
}

@test "root CA Certificate requests isCA: true from the selfsigned-bootstrap issuer" {
  [ -f "$REPO/gitops/cert-manager/root-ca/root-ca-certificate.yaml" ]
  [ "$(yqs '.spec.isCA' "$REPO/gitops/cert-manager/root-ca/root-ca-certificate.yaml")" = "true" ]
  [ "$(yqs '.spec.issuerRef.name' "$REPO/gitops/cert-manager/root-ca/root-ca-certificate.yaml")" = "selfsigned-bootstrap" ]
}

@test "root CA Certificate stores its output in k8s-lab-root-ca-secret" {
  [ "$(yqs '.spec.secretName' "$REPO/gitops/cert-manager/root-ca/root-ca-certificate.yaml")" = "k8s-lab-root-ca-secret" ]
}

@test "k8s-lab-ca ClusterIssuer (type ca) references the root CA secret" {
  [ -f "$REPO/gitops/cert-manager/root-ca/ca-issuer.yaml" ]
  [ "$(yqs '.spec.ca.secretName' "$REPO/gitops/cert-manager/root-ca/ca-issuer.yaml")" = "k8s-lab-root-ca-secret" ]
}

@test "cert-manager-root-ca Application exists and runs at sync-wave 5" {
  [ -f "$REPO/gitops/platform/cert-manager-root-ca.yaml" ]
  run grep -q 'argocd.argoproj.io/sync-wave: "5"' "$REPO/gitops/platform/cert-manager-root-ca.yaml"
  [ "$status" -eq 0 ]
}

@test "k8s-lab-ca is referenced only by gitops/cert-manager/ and its deliberate consumers (wildcard Certificate, ADR-0028; KEDA webhook TLS, ADR-0029)" {
  run grep -rl 'k8s-lab-ca\|k8s-lab-root-ca' "$REPO/gitops" --include="*.yaml"
  [ "$status" -eq 0 ]
  while IFS= read -r f; do
    case "$f" in
      "$REPO/gitops/cert-manager/"*) ;;
      "$REPO/gitops/network/certificates/wildcard-certificate.yaml") ;;
      "$REPO/gitops/platform/lab-gateway-certificate.yaml") ;;
      "$REPO/gitops/platform/keda.yaml") ;;
      *) echo "unexpected reference outside gitops/cert-manager/ and the known consumers: $f"; return 1 ;;
    esac
  done <<< "$output"
}

# --- Observability: Alloy scrape + Grafana dashboard --------------------------
@test "observability-alloy has a cert_manager scrape job" {
  run grep -q 'prometheus.scrape "cert_manager"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "cert_manager scrape targets the controller Service on port 9402" {
  run grep -q 'cert-manager.cert-manager.svc.cluster.local:9402' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-cert-manager.json dashboard exists" {
  [ -f "$REPO/grafana/dashboards/lab-cert-manager.json" ]
}

@test "lab-cert-manager.json is valid JSON" {
  run python3 -c "import json; json.load(open('$REPO/grafana/dashboards/lab-cert-manager.json'))"
  [ "$status" -eq 0 ]
}

@test "lab-cert-manager.json uid is lab-cert-manager" {
  [ "$(yqs '.uid' "$REPO/grafana/dashboards/lab-cert-manager.json")" = "lab-cert-manager" ]
}

@test "lab-cert-manager.json uses the Mimir datasource (ADR-0004 — real data only)" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-cert-manager.json"
  [ "$status" -eq 0 ]
}

@test "lab-cert-manager.json charts certmanager_certificate_ready_status" {
  run grep -q 'certmanager_certificate_ready_status' "$REPO/grafana/dashboards/lab-cert-manager.json"
  [ "$status" -eq 0 ]
}

@test "lab-cert-manager.json charts certificate expiry (certmanager_certificate_expiration_timestamp_seconds)" {
  run grep -q 'certmanager_certificate_expiration_timestamp_seconds' "$REPO/grafana/dashboards/lab-cert-manager.json"
  [ "$status" -eq 0 ]
}

@test "docs/dependency-tree.md documents the cert-manager component" {
  run grep -q 'cert-manager' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

# --- ADR-0017 amendment --------------------------------------------------------
@test "ADR-0017 has a cert-manager: restricted row" {
  run grep -q '`cert-manager` | `restricted`' "$REPO/docs/decisions/adr-0017-pod-security-standards-restricted.md"
  [ "$status" -eq 0 ]
}

# --- Traefik TLSStore + wildcard Certificate (ADR-0028 follow-up, ADR-0040 —
# supersedes the shared Gateway's http/https listeners under Envoy Gateway) ---
@test "shared TLSStore is a traefik.io/v1alpha1 object named default" {
  [ "$(yqs '.apiVersion' "$REPO/gitops/network/traefik-tls-store.yaml")" = "traefik.io/v1alpha1" ]
  [ "$(yqs '.kind' "$REPO/gitops/network/traefik-tls-store.yaml")" = "TLSStore" ]
  [ "$(yqs '.metadata.name' "$REPO/gitops/network/traefik-tls-store.yaml")" = "default" ]
}

@test "shared TLSStore terminates TLS using the wildcard Certificate's Secret" {
  [ "$(yqs '.spec.defaultCertificate.secretName' "$REPO/gitops/network/traefik-tls-store.yaml")" = "wildcard-127-0-0-1-nip-io-tls" ]
}

@test "shared TLSStore lives in the lab-gateway namespace" {
  [ "$(yqs '.metadata.namespace' "$REPO/gitops/network/traefik-tls-store.yaml")" = "lab-gateway" ]
}

@test "every IngressRoute opts into the shared TLSStore with an empty tls stanza" {
  while IFS= read -r f; do
    run grep -q '^  tls: {}$' "$f"
    [ "$status" -eq 0 ] || { echo "missing tls: {} in $f"; return 1; }
  done < <(find "$REPO/gitops" -name 'ingressroute.yaml')
}

@test "wildcard Certificate manifest exists in lab-gateway namespace" {
  [ -f "$REPO/gitops/network/certificates/wildcard-certificate.yaml" ]
  [ "$(yqs '.metadata.namespace' "$REPO/gitops/network/certificates/wildcard-certificate.yaml")" = "lab-gateway" ]
}

@test "wildcard Certificate covers *.127.0.0.1.nip.io and produces the Secret the Gateway references" {
  [ "$(yqs '.spec.secretName' "$REPO/gitops/network/certificates/wildcard-certificate.yaml")" = "wildcard-127-0-0-1-nip-io-tls" ]
  run grep -q '"\*.127.0.0.1.nip.io"' "$REPO/gitops/network/certificates/wildcard-certificate.yaml"
  [ "$status" -eq 0 ]
}

@test "wildcard Certificate is issued by k8s-lab-ca, not the selfsigned-bootstrap issuer" {
  [ "$(yqs '.spec.issuerRef.name' "$REPO/gitops/network/certificates/wildcard-certificate.yaml")" = "k8s-lab-ca" ]
  [ "$(yqs '.spec.issuerRef.kind' "$REPO/gitops/network/certificates/wildcard-certificate.yaml")" = "ClusterIssuer" ]
}

@test "lab-gateway-certificate Application exists and runs after cert-manager-root-ca (sync-wave 6)" {
  APP="$REPO/gitops/platform/lab-gateway-certificate.yaml"
  [ -f "$APP" ]
  run grep -q 'argocd.argoproj.io/sync-wave: "6"' "$APP"
  [ "$status" -eq 0 ]
}

@test "lab-gateway-certificate Application sources gitops/network/certificates into lab-gateway" {
  APP="$REPO/gitops/platform/lab-gateway-certificate.yaml"
  run grep -q 'path: gitops/network/certificates' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'namespace: lab-gateway' "$APP"
  [ "$status" -eq 0 ]
}

@test "lab-gateway-certificate Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/lab-gateway-certificate.yaml"
  [ "$status" -eq 0 ]
}
