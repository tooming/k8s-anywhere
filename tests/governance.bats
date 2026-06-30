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

# --- RFC #294 LimitRange fan-out (all always-on namespaces) -------------------
# The full standard-tier list from the RFC #294 mapping table. `artifactory` is
# intentionally absent: ADR-0024 supersedes ADR-0011 and selects Harbor over the
# legacy registry, so its governance overlay is deferred until the Harbor
# namespace lands (see governance-appset.yaml note + the docs/done entry).
STANDARD_NS="argocd capstone kyverno external-secrets velero argo-rollouts \
trivy-system moto ack-system kro kargo lab-demo data storage vault lab-gateway kiali"

@test "every standard-tier namespace has a governance leaf overlay" {
  for ns in $STANDARD_NS; do
    [ -f "$GOV/$ns/kustomization.yaml" ] || { echo "missing kustomization for $ns"; return 1; }
    [ -f "$GOV/$ns/limitrange.yaml" ]    || { echo "missing limitrange for $ns"; return 1; }
  done
}

@test "every standard-tier limitrange is a Container-type standard profile" {
  for ns in $STANDARD_NS; do
    run grep -q 'type: Container' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ] || { echo "$ns: no type: Container"; return 1; }
    run grep -qE 'cpu: "?50m"?' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ] || { echo "$ns: no defaultRequest cpu 50m"; return 1; }
    run grep -qE 'memory: "?512Mi"?' "$GOV/$ns/limitrange.yaml"
    [ "$status" -eq 0 ] || { echo "$ns: no default memory 512Mi"; return 1; }
  done
}

@test "each standard-tier kustomization lists limitrange.yaml as a resource" {
  for ns in $STANDARD_NS; do
    run grep -q 'limitrange.yaml' "$GOV/$ns/kustomization.yaml"
    [ "$status" -eq 0 ] || { echo "$ns: kustomization missing limitrange.yaml"; return 1; }
  done
}

@test "observability has the heavy-tier LimitRange profile" {
  [ -f "$GOV/observability/kustomization.yaml" ]
  [ -f "$GOV/observability/limitrange.yaml" ]
  run grep -q 'type: Container' "$GOV/observability/limitrange.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'memory: "?2Gi"?' "$GOV/observability/limitrange.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'cpu: "?2000m"?' "$GOV/observability/limitrange.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'memory: "?8Gi"?' "$GOV/observability/limitrange.yaml"
  [ "$status" -eq 0 ]
}

@test "governance-appset lists every standard namespace plus observability" {
  for ns in $STANDARD_NS observability; do
    run grep -q "destNamespace: $ns$" "$APPSET"
    [ "$status" -eq 0 ] || { echo "appset missing destNamespace: $ns"; return 1; }
  done
}

@test "governance-appset does NOT bless the ADR-0024-rejected registry namespace" {
  # ADR-0024 supersedes ADR-0011 — no governance overlay for the legacy registry.
  run grep -qiw 'artifactory' "$APPSET"
  [ "$status" -ne 0 ]
  [ ! -d "$GOV/artifactory" ]
}
