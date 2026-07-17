#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the vault
# namespace (ADR-0017 §Per-namespace profile / §Re-evaluation log, RFC #478).
# The flip landed once vault-helm v0.34.0 (default Vault v2.0.3) dropped the
# cap_ipc_lock requirement that justified the prior `baseline` carve-out;
# `disable_mlock = true` is the required config-side counterpart. Both the
# chart-managed server StatefulSet and the hand-written vault-unsealer
# Deployment run in this namespace, so both need a restricted-compliant
# securityContext — the unsealer had none before (the baseline namespace
# didn't require one).
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh. Replaces the removed
# "vault namespace.yaml enforces PSS baseline" monolith test.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/vault/namespace.yaml"
  APP="$REPO/gitops/platform/vault.yaml"
  UNSEALER="$REPO/gitops/vault/unsealer.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "vault namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "vault namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "vault namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "vault namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "vault namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "vault namespace does NOT enforce baseline or privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- vault Application: chart bump + disable_mlock ---------------------------

@test "vault Application chart bumped to 0.34.0" {
  run grep -q 'targetRevision: 0.34.0' "$APP"
  [ "$status" -eq 0 ]
}

@test "vault Application server config sets disable_mlock = true" {
  run grep -q 'disable_mlock = true' "$APP"
  [ "$status" -eq 0 ]
}

# --- vault Application: Layer 1 securityContext (ADR-0017) -------------------

@test "vault Application server statefulSet securityContext sets runAsNonRoot" {
  run grep -q 'runAsNonRoot: true' "$APP"
  [ "$status" -eq 0 ]
}

@test "vault Application server statefulSet securityContext sets seccompProfile RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$APP"
  [ "$status" -eq 0 ]
}

@test "vault Application server statefulSet securityContext disallows privilege escalation" {
  run grep -q 'allowPrivilegeEscalation: false' "$APP"
  [ "$status" -eq 0 ]
}

@test "vault Application server statefulSet securityContext drops all capabilities" {
  run grep -q 'drop: \["ALL"\]' "$APP"
  [ "$status" -eq 0 ]
}

@test "vault Application server statefulSet securityContext sets readOnlyRootFilesystem" {
  run grep -q 'readOnlyRootFilesystem: true' "$APP"
  [ "$status" -eq 0 ]
}

@test "vault Application adds a tmp emptyDir volume for the read-only root fs" {
  run grep -q 'name: tmp' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'mountPath: /tmp' "$APP"
  [ "$status" -eq 0 ]
}

# --- vault-unsealer Deployment: image bump + securityContext -----------------

@test "vault-unsealer image bumped to hashicorp/vault:2.0.3" {
  run grep -q 'image: hashicorp/vault:2.0.3' "$UNSEALER"
  [ "$status" -eq 0 ]
}

@test "vault-unsealer pod securityContext sets runAsNonRoot" {
  run grep -q 'runAsNonRoot: true' "$UNSEALER"
  [ "$status" -eq 0 ]
}

@test "vault-unsealer pod securityContext sets seccompProfile RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$UNSEALER"
  [ "$status" -eq 0 ]
}

@test "vault-unsealer container securityContext disallows privilege escalation" {
  run grep -q 'allowPrivilegeEscalation: false' "$UNSEALER"
  [ "$status" -eq 0 ]
}

@test "vault-unsealer container securityContext drops all capabilities" {
  run grep -q 'drop: \["ALL"\]' "$UNSEALER"
  [ "$status" -eq 0 ]
}

@test "vault-unsealer container securityContext sets readOnlyRootFilesystem" {
  run grep -q 'readOnlyRootFilesystem: true' "$UNSEALER"
  [ "$status" -eq 0 ]
}

@test "vault-unsealer mounts home and tmp emptyDir volumes for the read-only root fs" {
  run grep -q 'mountPath: /home/vault' "$UNSEALER"
  [ "$status" -eq 0 ]
  run grep -q 'mountPath: /tmp' "$UNSEALER"
  [ "$status" -eq 0 ]
}
