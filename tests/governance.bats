#!/usr/bin/env bats
# Clusterless structural tests for the Platform Governance appset (RFC #293).
# The governance ApplicationSet fans out per-namespace governance objects
# (LimitRange defaults today) from gitops/governance/<namespace>/ leaf overlays,
# mirroring the networkpolicy-appset pattern. Seed namespaces: argocd + capstone.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APPSET="$REPO/gitops/platform/governance-appset.yaml"
  GOV="$REPO/gitops/governance"
}

# --- ApplicationSet shape ----------------------------------------------------
@test "governance-appset.yaml exists under gitops/platform/" {
  [ -f "$APPSET" ]
}

@test "governance-appset is an ApplicationSet" {
  run grep -q '^kind: ApplicationSet' "$APPSET"
  [ "$status" -eq 0 ]
}

@test "governance-appset uses a list generator" {
  run grep -qE '^\s*-\s*list:' "$APPSET"
  [ "$status" -eq 0 ]
}

@test "governance-appset object is planted at sync-wave 3" {
  # The sync-wave "3" annotation must sit on the ApplicationSet metadata.
  run grep -q 'argocd.argoproj.io/sync-wave: "3"' "$APPSET"
  [ "$status" -eq 0 ]
}

@test "governance-appset generates Applications at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$APPSET"
  [ "$status" -eq 0 ]
}

@test "governance-appset template has an auto-sync policy" {
  run grep -q 'automated:' "$APPSET"
  [ "$status" -eq 0 ]
  run grep -q 'selfHeal: true' "$APPSET"
  [ "$status" -eq 0 ]
}

# --- Seed namespace leaf overlays --------------------------------------------
@test "argocd governance leaf dir has kustomization.yaml and limitrange.yaml" {
  [ -f "$GOV/argocd/kustomization.yaml" ]
  [ -f "$GOV/argocd/limitrange.yaml" ]
}

@test "capstone governance leaf dir has kustomization.yaml and limitrange.yaml" {
  [ -f "$GOV/capstone/kustomization.yaml" ]
  [ -f "$GOV/capstone/limitrange.yaml" ]
}

@test "each seed kustomization lists limitrange.yaml as a resource" {
  run grep -q 'limitrange.yaml' "$GOV/argocd/kustomization.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'limitrange.yaml' "$GOV/capstone/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "each seed LimitRange is a Container-type standard-tier limit" {
  for ns in argocd capstone; do
    run grep -q '^kind: LimitRange' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ]
    run grep -q 'type: Container' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ]
    run grep -qE 'cpu: "?500m"?' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ]
    run grep -qE 'memory: "?512Mi"?' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ]
    run grep -qE 'cpu: "?50m"?' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ]
  done
}
