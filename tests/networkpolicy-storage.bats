#!/usr/bin/env bats
# Clusterless structural tests for the storage namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
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

@test "storage-networkpolicy ArgoCD Application targets the storage namespace" {
  run grep -q 'destNamespace: storage' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
