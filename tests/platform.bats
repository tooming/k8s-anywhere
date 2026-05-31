#!/usr/bin/env bats
# Clusterless checks for on-demand platform components. These assert the GitOps
# wiring is internally consistent — no auto-sync (12 GB budget rule #4), the
# HTTPRoute exists, and the make targets are declared — so a mis-wired component
# is caught before ArgoCD ever tries to sync it. No cluster needed.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- Artifactory must NOT be auto-synced (ADR-0011, 12 GB budget) -----------
@test "artifactory Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/artifactory.yaml"
  [ "$status" -eq 1 ]
}

@test "artifactory-extras Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/artifactory-extras.yaml"
  [ "$status" -eq 1 ]
}

# --- Envoy HTTPRoute wiring --------------------------------------------------
@test "Artifactory HTTPRoute declares artifactory.127.0.0.1.nip.io" {
  run grep -r 'artifactory\.127\.0\.0\.1\.nip\.io' "$REPO/gitops/"
  [ "$status" -eq 0 ]
}

# --- make targets exist ------------------------------------------------------
@test "Makefile has artifactory-up target" {
  run grep -E '^artifactory-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile has artifactory-down target" {
  run grep -E '^artifactory-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

# --- Istio ambient must NOT be auto-synced (ADR-0012, 12 GB budget) ----------
@test "istio-base Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/istio-base.yaml"
  [ "$status" -eq 1 ]
}

@test "istiod Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/istiod.yaml"
  [ "$status" -eq 1 ]
}

@test "istio-cni Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/istio-cni.yaml"
  [ "$status" -eq 1 ]
}

@test "ztunnel Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/ztunnel.yaml"
  [ "$status" -eq 1 ]
}

# --- make targets exist -------------------------------------------------------
@test "Makefile has istio-up target" {
  run grep -E '^istio-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile has istio-down target" {
  run grep -E '^istio-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}
