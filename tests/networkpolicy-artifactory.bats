#!/usr/bin/env bats
# Clusterless structural tests for the artifactory namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out, RFC #287, ROADMAP auto/pss-np-artifactory). Lives in its own
# per-scope file — NOT appended to the frozen tests/networkpolicy.bats monolith — so
# parallel NetworkPolicy fan-out PRs never collide at the monolith's EOF (the conflict
# that hit #247 vs #248). One scope = one file = no shared append anchor.
# See scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

@test "artifactory/networkpolicy/kustomization.yaml exists" {
  [ -f "$ARTIFACTORY_NP/kustomization.yaml" ]
}

@test "artifactory networkpolicy overlay references default-deny.yaml baseline" {
  run grep -q 'default-deny.yaml' "$ARTIFACTORY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "artifactory networkpolicy overlay references allow-dns-and-apiserver.yaml baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$ARTIFACTORY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-artifactory-ingress.yaml exists" {
  [ -f "$ARTIFACTORY_NP/allow-artifactory-ingress.yaml" ]
}

@test "allow-artifactory-ingress targets port 8082 (Envoy HTTPRoute backend)" {
  run grep -q 'port: 8082' "$ARTIFACTORY_NP/allow-artifactory-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-artifactory-ingress targets the envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$ARTIFACTORY_NP/allow-artifactory-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-artifactory-garage-egress.yaml exists" {
  [ -f "$ARTIFACTORY_NP/allow-artifactory-garage-egress.yaml" ]
}

@test "allow-artifactory-garage-egress targets port 3900 (Garage S3 endpoint)" {
  run grep -q 'port: 3900' "$ARTIFACTORY_NP/allow-artifactory-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-artifactory-garage-egress targets the storage namespace" {
  run grep -q 'kubernetes.io/metadata.name: storage' "$ARTIFACTORY_NP/allow-artifactory-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-artifactory-intra-namespace.yaml exists in artifactory/networkpolicy/" {
  [ -f "$ARTIFACTORY_NP/allow-artifactory-intra-namespace.yaml" ]
}

@test "artifactory kustomization references the intra-namespace allow file" {
  run grep -q 'allow-artifactory-intra-namespace.yaml' "$ARTIFACTORY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-artifactory-intra-namespace allows Ingress and Egress within the namespace" {
  run grep -qE 'Ingress|Egress' "$ARTIFACTORY_NP/allow-artifactory-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "artifactory-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'artifactory-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "artifactory-networkpolicy appset entry references gitops/artifactory/networkpolicy" {
  run grep -q 'gitops/artifactory/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
