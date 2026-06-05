#!/usr/bin/env bats
# Clusterless structural checks for the Cilium CNI wiring (ADR-0014 follow-on).
# Asserts the Application is NOT auto-synced (bootstrap must happen manually
# before ArgoCD can manage it), that make targets exist, and that the infra
# has been flipped to disable_default_cni (so the cluster comes up ready for Cilium).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- Application must NOT be auto-synced (ADR-0014) -------------------------
@test "cilium Application file exists" {
  [ -f "$REPO/gitops/platform/cilium.yaml" ]
}

@test "cilium Application has no automated: block (bootstrap order requires manual sync)" {
  run grep -E '^[[:space:]]*automated:' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 1 ]
}

@test "cilium Application targets kube-system namespace" {
  run grep 'namespace: kube-system' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 0 ]
}

@test "cilium Application uses helm.cilium.io chart source" {
  run grep 'helm.cilium.io' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 0 ]
}

@test "cilium Application sets kubeProxyReplacement: true" {
  run grep 'kubeProxyReplacement: true' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 0 ]
}

@test "cilium Application has Hubble disabled (12 GB budget)" {
  run grep 'enabled: false' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 0 ]
}

# --- Infra flip: disable_default_cni must be true (ADR-0014) ----------------
@test "terragrunt.hcl has disable_default_cni = true" {
  run grep 'disable_default_cni.*=.*true' "$REPO/infra/live/local/cluster/terragrunt.hcl"
  [ "$status" -eq 0 ]
}

# --- make targets exist ------------------------------------------------------
@test "Makefile has cilium-up target" {
  run grep -E '^cilium-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile has cilium-down target" {
  run grep -E '^cilium-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

# --- DR.md documents the bootstrap ordering --------------------------------
@test "DR.md documents cilium-up bootstrap step" {
  run grep 'cilium-up' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
}
