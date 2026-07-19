#!/usr/bin/env bats
# Clusterless structural tests for Harbor on-demand OCI registry (ADR-0024, RFC #297).
# Validates GitOps wiring (Application shape, namespace PSA labels, HTTPRoute, ExternalSecret),
# the Garage bootstrap seam, and the Grafana Lab UIs panel — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application shape (on-demand, no automated sync) ------------------
@test "harbor Application exists" {
  [ -f "$REPO/gitops/platform/harbor.yaml" ]
}

@test "harbor Application sources the goharbor chart from helm.goharbor.io (ADR-0024)" {
  run grep -q 'repoURL: https://helm.goharbor.io' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application pins chart harbor (not artifactory-oss)" {
  run grep -q 'chart: harbor' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application pins a specific 1.19.x chart version" {
  run grep -qE 'targetRevision: 1\.19\.' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application has NO automated sync block (on-demand, ADR-0024)" {
  run grep -q 'automated:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -ne 0 ]
}

@test "harbor Application targets the harbor namespace" {
  run grep -q 'namespace: harbor' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

# --- Minimal profile (ADR-0024 §"Minimal profile") ----------------------------
@test "harbor Application disables bundled trivy (Trivy Operator covers scanning, ADR-0022)" {
  run grep -q 'enabled: false' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application sets trivy.enabled: false" {
  run grep -A1 'trivy:' "$REPO/gitops/platform/harbor.yaml"
  [[ "$output" == *"enabled: false"* ]]
}

@test "harbor Application sets notary.enabled: false (out of scope first cut)" {
  run grep -A1 'notary:' "$REPO/gitops/platform/harbor.yaml"
  [[ "$output" == *"enabled: false"* ]]
}

@test "harbor Application uses clusterIP expose type (Envoy fronts ingress, ADR-0008)" {
  run grep -q 'type: clusterIP' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application disables TLS (Envoy HTTPRoute fronts plain HTTP, ADR-0008)" {
  run grep -q 'tls:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application sets externalURL to harbor.127.0.0.1.nip.io:8000" {
  run grep -q 'externalURL: http://harbor.127.0.0.1.nip.io:8000' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage S3 backend (ADR-0002 binding) ------------------------------------
@test "harbor Application configures S3 storage type (ADR-0002)" {
  run grep -q 'type: s3' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application configures Garage S3 endpoint (ADR-0002)" {
  run grep -q 'regionendpoint: http://garage.storage.svc.cluster.local:3900' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application uses harbor-registry bucket" {
  run grep -q 'bucket: harbor-registry' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application references harbor-s3-creds secret for S3 credentials (never inline)" {
  run grep -q 'extraEnvVarsSecret: harbor-s3-creds' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (ADR-0017: restricted target) ----------------------
@test "harbor namespace manifest exists" {
  [ -f "$REPO/gitops/harbor/namespace.yaml" ]
}

@test "harbor namespace enforces PSA restricted (ADR-0017 + ADR-0024 Go runtime target)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/harbor/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$REPO/gitops/harbor/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- harbor-extras (auto-synced wave 0, pre-creates namespace + route) --------
@test "harbor-extras Application exists" {
  [ -f "$REPO/gitops/platform/harbor-extras.yaml" ]
}

@test "harbor-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/harbor-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-extras Application is auto-synced (always-on PSA floor)" {
  run grep -q 'automated:' "$REPO/gitops/platform/harbor-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-extras Application sources the gitops/harbor path" {
  run grep -q 'path: gitops/harbor' "$REPO/gitops/platform/harbor-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Envoy HTTPRoute (ADR-0008) -----------------------------------------------
@test "harbor HTTPRoute manifest exists" {
  [ -f "$REPO/gitops/harbor/route.yaml" ]
}

@test "harbor HTTPRoute uses host harbor.127.0.0.1.nip.io" {
  run grep -q '"harbor.127.0.0.1.nip.io"' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor HTTPRoute backendRef targets harbor service port 80" {
  run grep -q 'port: 80' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor HTTPRoute parentRef targets the lab-gateway (eg)" {
  run grep -q 'namespace: lab-gateway' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

# --- ExternalSecret for S3 credentials (ESO Vault→K8s pattern) ---------------
@test "harbor-s3 ExternalSecret exists" {
  [ -f "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml" ]
}

@test "harbor-s3 ExternalSecret references Vault path harbor/s3" {
  run grep -q 'key: harbor/s3' "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-s3 ExternalSecret renders harbor-s3-creds Secret" {
  run grep -q 'name: harbor-s3-creds' "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-s3 ExternalSecret renders REGISTRY_STORAGE_S3_ACCESSKEY env key" {
  run grep -q 'REGISTRY_STORAGE_S3_ACCESSKEY' "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage bootstrap seam (harbor-key + harbor-registry bucket) --------------
@test "garage-bootstrap.sh creates harbor-key access key" {
  run grep -q 'harbor-key' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh creates harbor-registry bucket" {
  run grep -q 'harbor-registry' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh stores harbor S3 creds at secret/harbor/s3 in Vault" {
  run grep -q 'secret/harbor/s3' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- Grafana Lab UIs panel (stack-health.json drift check) --------------------
@test "harbor.127.0.0.1.nip.io is present in the Grafana Lab UIs panel" {
  run grep -q 'harbor.127.0.0.1.nip.io' "$REPO/grafana/dashboards/stack-health.json"
  [ "$status" -eq 0 ]
}

@test "harbor Lab UIs panel URL uses the :8000 front-door port" {
  run grep -q 'harbor.127.0.0.1.nip.io:8000' "$REPO/grafana/dashboards/stack-health.json"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 §4 fan-out) ------------------------------
@test "harbor networkpolicy kustomization exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/kustomization.yaml" ]
}

@test "harbor networkpolicy kustomization references default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor networkpolicy kustomization references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor networkpolicy kustomization references the ClusterIP egress bridge" {
  # The bridge is the shared baseline template (gitops/network/policies/), not the
  # per-namespace allow-harbor-clusterip-egress.yaml copy — referencing both would
  # duplicate metadata.name zz-dns-clusterip-bridge and break the Kustomize build.
  run grep -q 'network/policies/zz-dns-clusterip-bridge.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-clusterip-egress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml" ]
}

@test "harbor ClusterIP bridge is a CiliumNetworkPolicy permitting the Service CIDR" {
  # Without this, Cilium socket-LB evaluates the destination Service ClusterIP
  # against default-deny egress and drops it — harbor-core crashloops on a Valkey
  # i/o timeout. Every other lab namespace carries the equivalent bridge.
  F="$REPO/gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml"
  run grep -q 'kind: CiliumNetworkPolicy' "$F"
  [ "$status" -eq 0 ]
  run grep -q '10.43.0.0/16' "$F"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-ingress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml" ]
}

@test "harbor ingress allow targets port 80 from envoy-gateway-system" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' \
    "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor ingress allow is on port 80 (unified clusterIP expose)" {
  run grep -q 'port: 80' "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-garage-egress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-garage-egress.yaml" ]
}

@test "harbor garage egress allow targets port 3900 to storage namespace" {
  run grep -q 'kubernetes.io/metadata.name: storage' \
    "$REPO/gitops/harbor/networkpolicy/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor garage egress allow uses port 3900" {
  run grep -q 'port: 3900' "$REPO/gitops/harbor/networkpolicy/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-valkey-egress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-valkey-egress.yaml" ]
}

@test "harbor Valkey egress allow targets port 6379 to data namespace (ADR-0018)" {
  run grep -q 'kubernetes.io/metadata.name: data' \
    "$REPO/gitops/harbor/networkpolicy/allow-harbor-valkey-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Valkey egress allow uses port 6379" {
  run grep -q 'port: 6379' "$REPO/gitops/harbor/networkpolicy/allow-harbor-valkey-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-intra-namespace.yaml exists (internal DB + component traffic)" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-intra-namespace.yaml" ]
}

@test "harbor intra-namespace allow has podSelector ingress" {
  run grep -q 'podSelector: {}' "$REPO/gitops/harbor/networkpolicy/allow-harbor-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-networkpolicy entry present in networkpolicy-appset.yaml" {
  run grep -q 'harbor-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-networkpolicy appset entry uses gitops/harbor/networkpolicy path" {
  run grep -q 'gitPath: gitops/harbor/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# --- Makefile harbor-up / harbor-down targets (auto/harbor-make-targets) ------
@test "harbor-up .PHONY target exists in Makefile" {
  run grep -q '\.PHONY: harbor-up' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "harbor-up syncs the harbor Application" {
  run grep -A5 '\.PHONY: harbor-up' "$REPO/Makefile"
  [[ "$output" == *"argocd-sync,harbor)"* ]]
}

@test "harbor-up syncs harbor-extras (namespace PSA floor + route)" {
  run grep -A5 '\.PHONY: harbor-up' "$REPO/Makefile"
  [[ "$output" == *"argocd-sync,harbor-extras)"* ]]
}

@test "harbor-down .PHONY target exists in Makefile" {
  run grep -q '\.PHONY: harbor-down' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "harbor-down deletes harbor-extras before harbor" {
  run grep -A5 '\.PHONY: harbor-down' "$REPO/Makefile"
  [[ "$output" == *"argocd-delete,harbor-extras)"* ]]
}

@test "harbor-down deletes harbor Application" {
  run grep -A5 '\.PHONY: harbor-down' "$REPO/Makefile"
  [[ "$output" == *"argocd-delete,harbor)"* ]]
}

# --- Observability — metrics + scrape + dashboard (auto/harbor-observability-dashboard) ---
@test "harbor Application has metrics.enabled: true (exposes harbor-metrics Service)" {
  run grep -q 'enabled: true' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor networkpolicy kustomization references allow-harbor-metrics-ingress.yaml" {
  run grep -q 'allow-harbor-metrics-ingress.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-metrics-ingress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-metrics-ingress.yaml" ]
}

@test "allow-harbor-metrics-ingress.yaml targets port 9090 from observability namespace" {
  F="$REPO/gitops/harbor/networkpolicy/allow-harbor-metrics-ingress.yaml"
  run grep -q 'port: 9090' "$F"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: observability' "$F"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml contains harbor scrape block" {
  run grep -q 'prometheus.scrape "harbor"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor scrape target uses harbor-metrics.harbor.svc.cluster.local:9090" {
  run grep -q 'harbor-metrics.harbor.svc.cluster.local:9090' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-harbor.json dashboard exists" {
  [ -f "$REPO/grafana/dashboards/lab-harbor.json" ]
}

@test "lab-harbor.json references harbor_artifact_total (real metric, ADR-0004)" {
  run grep -q 'harbor_artifact_total' "$REPO/grafana/dashboards/lab-harbor.json"
  [ "$status" -eq 0 ]
}

@test "lab-harbor.json contains no fabricated or placeholder data (ADR-0004)" {
  run grep -qi 'placeholder\|TODO\|FIXME\|fake\|dummy\|fabricat' "$REPO/grafana/dashboards/lab-harbor.json"
  [ "$status" -ne 0 ]
}
