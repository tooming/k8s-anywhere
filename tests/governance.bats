#!/usr/bin/env bats
# Clusterless structural tests for the Platform Governance appset (RFC #293).
# The governance ApplicationSet fans out per-namespace governance objects
# (LimitRange defaults today) from gitops/governance/<namespace>/ leaf overlays,
# mirroring the networkpolicy-appset pattern. Seed namespace: argocd (the
# original second seed, capstone, was removed 2026-09-07 — see below).

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
@test "argocd governance leaf dir has kustomization.yaml" {
  [ -f "$GOV/argocd/kustomization.yaml" ]
}

@test "each seed kustomization references the shared base limitrange" {
  run grep -q 'base/limitrange-standard.yaml' "$GOV/argocd/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "shared base LimitRange is a Container-type standard-tier limit" {
  run grep -q '^kind: LimitRange' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'type: Container' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'cpu: "?500m"?' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'memory: "?512Mi"?' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'cpu: "?50m"?' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
}

# --- RFC #294 LimitRange fan-out (all always-on namespaces) -------------------
# The full standard-tier list from the RFC #294 mapping table.
# `cert-manager` (ADR-0028) and `keda` (ADR-0029) were added in
# auto/governance-cert-manager-keda — both landed after RFC #294's original
# fan-out and were missing a governance leaf until this item.
# `artifactory` is intentionally absent: ADR-0024 supersedes ADR-0011.
# `kiali` is intentionally absent: Kiali co-resides in the `istio-system` namespace
# (RFC #288) rather than getting its own namespace, and `istio-system` is itself
# excluded from governance as an on-demand-heavy namespace too variable for static
# defaults — a `kiali` governance leaf would create an empty, unused namespace no
# workload ever runs in (removed in the chore that added this comment).
# `keda` is likewise now absent (REMOVED 2026-09-06): KEDA was dropped from
# the lab entirely, no replacement (ADR-0029) — same dead-config shape the
# kiali removal above already established.
# `data` is likewise now absent (REMOVED 2026-09-06): RabbitMQ/ADR-0009 and
# Valkey/ADR-0018 were dropped from the lab entirely, no replacement — the
# `data` namespace held nothing else, so it went with them.
# `harbor` is likewise now absent (REMOVED 2026-09-07): Harbor/ADR-0024 was
# dropped from the lab entirely, no replacement — same dead-config shape the
# data/keda removals above already established.
# `capstone`, `kyverno`, `velero`, `argo-rollouts`, `kargo`, and `capstone-pipeline`
# (Kargo's promotion-target namespace) are likewise now absent (REMOVED
# 2026-09-07): Kyverno/ADR-0019, Argo Rollouts/ADR-0020, Velero/ADR-0021, and
# Kargo/ADR-0023 were dropped from the lab entirely, no replacement, alongside
# capstone itself (their only consumer/target) — same dead-config shape the
# harbor removal above already established.
# `trivy-system`, `moto`, `ack-system`, and `kro` are likewise now absent (REMOVED
# 2026-09-07): Trivy Operator/ADR-0022 was dropped from the lab entirely, no
# replacement (user request); ACK/moto/ADR-0038 were dropped the same way (user
# request), and KRO/ADR-0038 went with them as an orphaned dependent (its only
# ResourceGraphDefinition claimed an ACK Bucket) — same dead-config shape the
# capstone/kargo removal above already established.
# `storage` is likewise now absent (REMOVED 2026-09-07): the namespace held only
# Garage and s3manager, both dropped from the lab entirely, no replacement
# (ADR-0002/ADR-0007/ADR-0039) — same dead-config shape the removals above
# already established.
# `external-secrets` and `vault` are likewise now absent (REMOVED 2026-09-07,
# ADR-0042, supersedes ADR-0036/ADR-0037): both were dropped from the lab
# entirely, no replacement — explicit maintainer direction; External Secrets
# Operator had no ExternalSecret consumer left after the removals above, and
# Vault was ESO's only backend.
STANDARD_NS="argocd \
lab-demo lab-gateway \
cert-manager"

@test "every standard-tier namespace has a governance leaf overlay" {
  for ns in $STANDARD_NS; do
    [ -f "$GOV/$ns/kustomization.yaml" ] || { echo "missing kustomization for $ns"; return 1; }
  done
}

@test "shared base limitrange-standard.yaml is a Container-type standard profile" {
  run grep -q 'type: Container' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'cpu: "?50m"?' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'memory: "?512Mi"?' "$GOV/base/limitrange-standard.yaml"
  [ "$status" -eq 0 ]
}

@test "each standard-tier kustomization references the shared base limitrange" {
  for ns in $STANDARD_NS; do
    run grep -q 'base/limitrange-standard.yaml' "$GOV/$ns/kustomization.yaml"
    [ "$status" -eq 0 ] || { echo "$ns: kustomization missing base/limitrange-standard.yaml"; return 1; }
  done
}

@test "observability governance leaf dir no longer exists (ADR-0041)" {
  [ ! -d "$GOV/observability" ]
}

@test "governance-appset lists every standard namespace" {
  for ns in $STANDARD_NS; do
    run grep -q "destNamespace: $ns$" "$APPSET"
    [ "$status" -eq 0 ] || { echo "appset missing destNamespace: $ns"; return 1; }
  done
}

@test "node-exporter governance leaf dir no longer exists (ADR-0041)" {
  [ ! -d "$GOV/node-exporter" ]
}

@test "governance-appset does NOT bless the ADR-0024-rejected registry namespace" {
  # ADR-0024 supersedes ADR-0011 — no governance overlay for the legacy registry.
  run grep -qiw 'artifactory' "$APPSET"
  [ "$status" -ne 0 ]
  [ ! -d "$GOV/artifactory" ]
}

# --- Harbor governance REMOVED 2026-09-07 (ADR-0024): Harbor was dropped from
# the lab entirely, no replacement — same dead-config shape the
# observability/node-exporter removals above already established. -------------
@test "harbor governance leaf dir no longer exists (ADR-0024)" {
  [ ! -d "$GOV/harbor" ]
}

@test "governance-appset does NOT bless the removed harbor namespace (ADR-0024)" {
  run grep -qw 'destNamespace: harbor' "$APPSET"
  [ "$status" -ne 0 ]
  run grep -qw 'appName: harbor-governance' "$APPSET"
  [ "$status" -ne 0 ]
}

# --- capstone/kyverno/velero/argo-rollouts/kargo governance REMOVED 2026-09-07:
# capstone, Kyverno (ADR-0019), Argo Rollouts (ADR-0020), Velero (ADR-0021), and
# Kargo (ADR-0023, plus its capstone-pipeline promotion-target namespace) were
# all dropped from the lab entirely, no replacement — same dead-config shape the
# harbor removal above already established. -----------------------------------
@test "capstone governance leaf dir no longer exists" {
  [ ! -d "$GOV/capstone" ]
}

@test "kyverno governance leaf dir no longer exists (ADR-0019)" {
  [ ! -d "$GOV/kyverno" ]
}

@test "velero governance leaf dir no longer exists (ADR-0021)" {
  [ ! -d "$GOV/velero" ]
}

@test "argo-rollouts governance leaf dir no longer exists (ADR-0020)" {
  [ ! -d "$GOV/argo-rollouts" ]
}

@test "kargo governance leaf dir no longer exists (ADR-0023)" {
  [ ! -d "$GOV/kargo" ]
}

@test "capstone-pipeline governance leaf dir no longer exists (ADR-0023)" {
  [ ! -d "$GOV/capstone-pipeline" ]
}

@test "governance-appset does NOT bless any of the removed capstone/kyverno/velero/argo-rollouts/kargo namespaces" {
  for ns in capstone kyverno velero argo-rollouts kargo capstone-pipeline; do
    run grep -qw "destNamespace: $ns" "$APPSET"
    [ "$status" -ne 0 ] || { echo "appset still blesses destNamespace: $ns"; return 1; }
    run grep -qw "appName: $ns-governance" "$APPSET"
    [ "$status" -ne 0 ] || { echo "appset still has appName: $ns-governance"; return 1; }
  done
}

# --- cert-manager governance (ADR-0028 / RFC #294 follow-up) ------------------
@test "cert-manager governance kustomization.yaml exists" {
  [ -f "$GOV/cert-manager/kustomization.yaml" ]
}

@test "cert-manager governance kustomization references the shared base limitrange" {
  run grep -q 'base/limitrange-standard.yaml' "$GOV/cert-manager/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "governance-appset has cert-manager-governance entry" {
  run grep -q 'destNamespace: cert-manager' "$APPSET"
  [ "$status" -eq 0 ]
  run grep -q 'appName: cert-manager-governance' "$APPSET"
  [ "$status" -eq 0 ]
}

# --- keda governance REMOVED 2026-08-25 (ADR-0029's on-demand conversion) ----
# KEDA's own namespace-creating Application went on-demand alongside the
# engine, so a keda-governance entry would recreate an otherwise-empty
# namespace on every reconciliation — same dead-config shape as the
# kiali-governance removal. Recurrence guards, not feature tests.
@test "gitops/governance/keda leaf directory does not exist (keda is on-demand)" {
  [ ! -d "$GOV/keda" ]
}

@test "governance-appset has NO keda-governance entry (keda is on-demand)" {
  run grep -q 'appName: keda-governance' "$APPSET"
  [ "$status" -ne 0 ]
}
