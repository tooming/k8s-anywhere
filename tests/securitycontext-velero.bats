#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# velero namespace (ADR-0017 §Per-namespace profile, ADR-0021,
# ROADMAP auto/velero-controller). restricted because the Velero controller and
# node-agent both run as non-root UID 65534; the node-agent DaemonSet uses a
# per-workload annotation for its hostPath mount (matches the node-exporter
# carve-out pattern in ADR-0017 §"Per-workload field carve-outs").
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/velero/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/velero-extras.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "velero namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "velero namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "velero namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "velero namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "velero namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "velero namespace does NOT enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
}

@test "velero namespace does NOT enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- velero-extras Application ------------------------------------------------

@test "velero-extras Application exists (PSA floor)" {
  [ -f "$EXTRAS" ]
}

@test "velero-extras Application targets gitops/velero" {
  run grep -q 'path: gitops/velero' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "velero-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}
