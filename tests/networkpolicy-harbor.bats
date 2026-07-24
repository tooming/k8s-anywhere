#!/usr/bin/env bats
# Clusterless structural tests for the harbor namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out, ADR-0024). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- harbor namespace overlay (ADR-0016 §4 fan-out, ADR-0024) --------------------
@test "harbor networkpolicy kustomization.yaml exists" {
  [ -f "$HARBOR_NP/kustomization.yaml" ]
}

@test "harbor kustomization sets namespace: harbor" {
  run grep -q 'namespace: harbor' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}


# --- ingress allow (Envoy Gateway → Harbor TCP 80) --------------------------------
@test "allow-harbor-ingress.yaml exists in harbor/networkpolicy/" {
  [ -f "$HARBOR_NP/allow-harbor-ingress.yaml" ]
}

@test "harbor kustomization references the ingress allow file" {
  run grep -q 'allow-harbor-ingress.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-ingress allows ingress on port 80" {
  run grep -q 'port: 80' "$HARBOR_NP/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-ingress restricts source to envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$HARBOR_NP/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-ingress uses Ingress policyType" {
  run grep -q 'Ingress' "$HARBOR_NP/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage S3 egress allow (Harbor → Garage TCP 3900) ---------------------------
@test "allow-harbor-garage-egress.yaml exists in harbor/networkpolicy/" {
  [ -f "$HARBOR_NP/allow-harbor-garage-egress.yaml" ]
}

@test "harbor kustomization references the garage egress allow file" {
  run grep -q 'allow-harbor-garage-egress.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-garage-egress allows egress on port 3900 (Garage S3 API)" {
  run grep -q 'port: 3900' "$HARBOR_NP/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-garage-egress uses Egress policyType" {
  run grep -q 'Egress' "$HARBOR_NP/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-garage-egress targets the storage namespace" {
  run grep -q 'kubernetes.io/metadata.name: storage' "$HARBOR_NP/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

# Valkey cache egress allow removed 2026-07-21 (#632): Harbor's external-Redis
# wiring never rendered under ArgoCD (Helm `lookup()` always nil in `helm
# template`), so Harbor now uses its own bundled redis-photon cache and never
# talks to the data namespace. See gitops/platform/harbor.yaml's ADR-0018
# exception note.
@test "harbor kustomization does not reference the removed valkey egress allow file" {
  run grep -q 'allow-harbor-valkey-egress.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -ne 0 ]
}

# --- intra-namespace allow (Harbor component-to-component + internal Postgres) ----
@test "allow-harbor-intra-namespace.yaml exists in harbor/networkpolicy/" {
  [ -f "$HARBOR_NP/allow-harbor-intra-namespace.yaml" ]
}

@test "harbor kustomization references the intra-namespace allow file" {
  run grep -q 'allow-harbor-intra-namespace.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-intra-namespace allows Ingress and Egress within the namespace" {
  run grep -qE 'Ingress|Egress' "$HARBOR_NP/allow-harbor-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- metrics allow (Alloy → Harbor TCP 9090) --------------------------------------
@test "allow-harbor-metrics-ingress.yaml exists in harbor/networkpolicy/" {
  [ -f "$HARBOR_NP/allow-harbor-metrics-ingress.yaml" ]
}

@test "harbor kustomization references the metrics allow file" {
  run grep -q 'allow-harbor-metrics-ingress.yaml' "$HARBOR_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-metrics-ingress allows ingress on port 9090" {
  run grep -q 'port: 9090' "$HARBOR_NP/allow-harbor-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-metrics-ingress restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$HARBOR_NP/allow-harbor-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

# --- harbor-networkpolicy appset entry (networkpolicy-appset.yaml wave 4) ----------
@test "harbor-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'harbor-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-networkpolicy appset entry references gitops/harbor/networkpolicy" {
  run grep -q 'gitops/harbor/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
