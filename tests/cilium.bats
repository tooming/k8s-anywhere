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

# --- Chart pin (RFC #501, CVE-2026-49445 — world-accessible Envoy admin.sock) --
@test "cilium Application pins chart version 1.17.18 (CVE-2026-49445 fix)" {
  run grep -q 'targetRevision: 1.17.18' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 0 ]
}

@test "cilium Application does not pin the pre-CVE-fix 1.16.6 version" {
  run grep -q 'targetRevision: 1.16.6' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -ne 0 ]
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

# --- make up wires cilium-up in the right place (ADR-0014) ------------------
# Regression guard: a fresh cluster has NO CNI, so cilium-up must run inside the
# 'up' recipe, after cluster-up and before coredns-host-alias (CoreDNS can't
# schedule until pod networking exists). Commit f81f172 disabled Flannel but
# forgot this wiring, breaking from-scratch `make up`.
@test "make up calls cilium-up" {
  run grep -n 'MAKE) cilium-up' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "make up calls cilium-up after cluster-up and before coredns-host-alias" {
  cluster_line=$(grep -n 'MAKE) cluster-up' "$REPO/Makefile" | head -1 | cut -d: -f1)
  cilium_line=$(grep -n 'MAKE) cilium-up' "$REPO/Makefile" | head -1 | cut -d: -f1)
  coredns_line=$(grep -n 'MAKE) coredns-host-alias' "$REPO/Makefile" | head -1 | cut -d: -f1)
  [ -n "$cluster_line" ] && [ -n "$cilium_line" ] && [ -n "$coredns_line" ]
  [ "$cluster_line" -lt "$cilium_line" ]
  [ "$cilium_line" -lt "$coredns_line" ]
}

# --- DR.md documents the bootstrap ordering --------------------------------
@test "DR.md documents cilium-up bootstrap step" {
  run grep 'cilium-up' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
}

# --- Observability: scrape config + dashboard (RFC #358, O5) ----------------
@test "cilium Application enables prometheus metrics (prometheus.enabled: true)" {
  run grep 'enabled: true' "$REPO/gitops/platform/cilium.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml has cilium_agent scrape block" {
  run grep -q 'prometheus.scrape "cilium_agent"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml cilium_agent relabel filters by kube-system namespace" {
  run grep -q 'kube-system' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external.yaml permits TCP 9962 egress (Cilium metrics port)" {
  run grep -q '9962' "$REPO/gitops/observability/networkpolicy/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-cilium.json dashboard exists" {
  [ -f "$REPO/grafana/dashboards/lab-cilium.json" ]
}

@test "lab-cilium.json references cilium_policy_count" {
  run grep -q 'cilium_policy_count' "$REPO/grafana/dashboards/lab-cilium.json"
  [ "$status" -eq 0 ]
}

@test "lab-cilium.json references cilium_drop_count_total" {
  run grep -q 'cilium_drop_count_total' "$REPO/grafana/dashboards/lab-cilium.json"
  [ "$status" -eq 0 ]
}

@test "lab-cilium.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-cilium.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions Cilium metrics scrape" {
  run grep -q 'cilium.*metrics\|lab-cilium' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}
