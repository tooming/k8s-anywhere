#!/usr/bin/env bats
# Clusterless checks for on-demand platform components. These assert the GitOps
# wiring is internally consistent — no auto-sync (12 GB budget rule #4), the
# HTTPRoute exists, and the make targets are declared — so a mis-wired component
# is caught before ArgoCD ever tries to sync it. No cluster needed.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
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

# --- Kiali must NOT be auto-synced (ADR-0012, 12 GB budget) ------------------
@test "kiali Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/kiali.yaml"
  [ "$status" -eq 1 ]
}

# --- Kiali chart-version pin (ADR-0012 Re-evaluation log, 2026-09-01 audit) --
@test "kiali Application pins kiali-server chart 2.31.0" {
  run grep 'targetRevision: 2.31.0' "$REPO/gitops/platform/kiali.yaml"
  [ "$status" -eq 0 ]
}

@test "kiali Application does not pin the superseded 2.30.0 chart" {
  run grep 'targetRevision: 2.30.0' "$REPO/gitops/platform/kiali.yaml"
  [ "$status" -ne 0 ]
}

@test "kiali-extras Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/kiali-extras.yaml"
  [ "$status" -eq 1 ]
}

# --- Envoy HTTPRoute wiring --------------------------------------------------
@test "Kiali HTTPRoute declares kiali.127.0.0.1.nip.io" {
  run grep -r 'kiali\.127\.0\.0\.1\.nip\.io' "$REPO/gitops/"
  [ "$status" -eq 0 ]
}

# --- make targets exist ------------------------------------------------------
@test "Makefile has kiali-up target" {
  run grep -E '^kiali-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile has kiali-down target" {
  run grep -E '^kiali-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

# --- Longhorn must NOT be auto-synced (ADR-0013, 12 GB budget) ---------------
@test "longhorn Application has no automated: block (on-demand only)" {
  run grep 'automated:' "$REPO/gitops/platform/longhorn.yaml"
  [ "$status" -eq 1 ]
}

# longhorn-extras IS auto-synced — it only pre-creates the longhorn-system
# namespace with PSA privileged labels (ADR-0017) + the Envoy HTTPRoute, so the
# privileged PSA floor is in place before `make longhorn-up` admits any pod.
# (The heavy longhorn.yaml chart stays manual-sync, asserted above.)
@test "longhorn-extras Application is auto-synced (namespace floor before longhorn-up)" {
  run grep 'automated:' "$REPO/gitops/platform/longhorn-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Envoy HTTPRoute wiring --------------------------------------------------
@test "Longhorn HTTPRoute declares longhorn.127.0.0.1.nip.io" {
  run grep -r 'longhorn\.127\.0\.0\.1\.nip\.io' "$REPO/gitops/"
  [ "$status" -eq 0 ]
}

# --- make targets exist ------------------------------------------------------
@test "Makefile has longhorn-up target" {
  run grep -E '^longhorn-up:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile has longhorn-down target" {
  run grep -E '^longhorn-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}
