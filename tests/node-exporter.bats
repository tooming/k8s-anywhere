#!/usr/bin/env bats
# Clusterless structural tests for the node-exporter PSA-privileged carve-out (ADR-0017).
# node-exporter needs /proc + /sys hostPath (forbidden by PSS restricted AND baseline —
# only privileged admits it), so it lives in its own privileged namespace instead of the
# restricted observability namespace.
# Own file per the one-scope-one-file rule.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/node-exporter/namespace.yaml"
  APP="$REPO/gitops/platform/observability-node-exporter.yaml"
  EXTRAS="$REPO/gitops/platform/node-exporter-extras.yaml"
  NP="$REPO/gitops/node-exporter/networkpolicy"
}

# --- namespace PSA baseline carve-out -----------------------------------------
@test "node-exporter namespace manifest exists" {
  [ -f "$NS" ]
}

@test "node-exporter namespace enforces PSS privileged (hostPath forbidden under baseline+restricted)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "node-exporter namespace pins enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

# --- app targets the carve-out namespace --------------------------------------
@test "node-exporter DaemonSet Application deploys into the node-exporter namespace" {
  run grep -q 'namespace: node-exporter' "$APP"
  [ "$status" -eq 0 ]
}

@test "node-exporter DaemonSet Application no longer targets observability" {
  run grep -qE '^\s*namespace: observability\s*$' "$APP"
  [ "$status" -ne 0 ]
}

# --- extras app pre-creates the labelled namespace (wave 0) -------------------
@test "node-exporter-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "node-exporter-extras runs at sync-wave 0 (before the DaemonSet)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "node-exporter-extras is auto-synced (always-on PSA floor)" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy floor ------------------------------------------------------
@test "node-exporter networkpolicy kustomization exists" {
  [ -f "$NP/kustomization.yaml" ]
}

@test "node-exporter NP overlay pulls the default-deny + dns baselines" {
  run grep -q 'default-deny.yaml' "$NP/kustomization.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'allow-dns-and-apiserver.yaml' "$NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "node-exporter metrics-ingress allows Alloy (observability) on 9100" {
  F="$NP/allow-node-exporter-metrics-ingress.yaml"
  [ -f "$F" ]
  run grep -q 'port: 9100' "$F"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: observability' "$F"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-appset wires the node-exporter overlay" {
  run grep -q 'gitops/node-exporter/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# --- Alloy egress to the moved namespace --------------------------------------
@test "Alloy egress permits scraping node-exporter (9100) in its new namespace" {
  F="$REPO/gitops/observability/networkpolicy/allow-alloy-egress-external.yaml"
  run grep -q 'kubernetes.io/metadata.name: node-exporter' "$F"
  [ "$status" -eq 0 ]
  run grep -q 'port: 9100' "$F"
  [ "$status" -eq 0 ]
}
