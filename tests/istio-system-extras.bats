#!/usr/bin/env bats
# Tests for gitops/platform/istio-system-extras.yaml, including a recurrence guard
# for the header comment's stated Istio component sync-waves — that comment drifted
# out of sync with the real istiod/ztunnel annotations (istiod actually runs at wave 3,
# ztunnel at wave 4, not wave 2 as the stale comment claimed) until this fix.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  EXTRAS="$REPO/gitops/platform/istio-system-extras.yaml"
}

@test "istio-system-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "istio-system-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "istio-system-extras Application is auto-synced (always-on PSA floor)" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "istio-base Application runs at sync-wave 1 (matches istio-system-extras' header comment)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "1"' "$REPO/gitops/platform/istio-base.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-cni Application runs at sync-wave 2 (matches istio-system-extras' header comment)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "2"' "$REPO/gitops/platform/istio-cni.yaml"
  [ "$status" -eq 0 ]
}

@test "istiod Application runs at sync-wave 3 (matches istio-system-extras' header comment)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "3"' "$REPO/gitops/platform/istiod.yaml"
  [ "$status" -eq 0 ]
}

@test "ztunnel Application runs at sync-wave 4 (matches istio-system-extras' header comment)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/ztunnel.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-system-extras header comment states the correct wave numbers" {
  run grep -q 'istio-base wave 1,' "$EXTRAS"
  [ "$status" -eq 0 ]
  run grep -q 'istio-cni wave 2, istiod wave 3, ztunnel wave 4' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "docs/dependency-tree.md documents istio-system-extras in the apply-order table" {
  run grep -q 'istio-system-extras \*(auto-synced, wave 0)\*' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}
