#!/usr/bin/env bats
# Clusterless structural tests for the keda namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out, ADR-0029). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at
# a shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- keda namespace overlay (ADR-0016 §4 fan-out, ADR-0029) ------------------
@test "keda networkpolicy kustomization.yaml exists" {
  [ -f "$KEDA_NP/kustomization.yaml" ]
}

@test "keda kustomization sets namespace: keda" {
  run grep -q 'namespace: keda' "$KEDA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "keda kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$KEDA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "keda kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$KEDA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- webhook allow (kube-apiserver -> keda TCP 9443) --------------------------
@test "allow-keda-webhook-from-apiserver.yaml exists in keda/networkpolicy/" {
  [ -f "$KEDA_NP/allow-keda-webhook-from-apiserver.yaml" ]
}

@test "keda kustomization references the webhook allow file" {
  run grep -q 'allow-keda-webhook-from-apiserver.yaml' "$KEDA_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-keda-webhook-from-apiserver allows ingress on port 9443" {
  run grep -q 'port: "9443"' "$KEDA_NP/allow-keda-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# fromEntities remote-node, not ipBlock 10.43.0.1/32: k3s embeds the apiserver in
# the server node's own process, so its outbound webhook call carries Cilium's
# remote-node identity + the node's real pod-network IP as source — the apiserver
# Service ClusterIP is never the actual source address on an outbound connection,
# so an ipBlock rule against it silently never matches (verified live with
# `cilium monitor --type drop` while fixing the identical bug for ESO's webhook).
@test "allow-keda-webhook-from-apiserver is a CiliumNetworkPolicy using fromEntities remote-node" {
  run grep -q 'kind: CiliumNetworkPolicy' "$KEDA_NP/allow-keda-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'remote-node' "$KEDA_NP/allow-keda-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-keda-webhook-from-apiserver does not regress to the broken ipBlock 10.43.0.1 pattern" {
  run grep -q -- '- ipBlock:' "$KEDA_NP/allow-keda-webhook-from-apiserver.yaml"
  [ "$status" -ne 0 ]
}

# --- metrics allow (Alloy -> keda TCP 8080) REMOVED 2026-09-06 (ADR-0041,
# observability stack removed with no replacement) -----------------------------------
@test "allow-keda-metrics-from-observability.yaml no longer exists (ADR-0041)" {
  [ ! -f "$KEDA_NP/allow-keda-metrics-from-observability.yaml" ]
}

# --- keda-networkpolicy Application (wave 6) ----------------------------------
@test "keda-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/keda-networkpolicy.yaml" ]
}

@test "keda-networkpolicy Application targets keda namespace" {
  run grep -q 'namespace: keda' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "keda-networkpolicy Application sources from gitops/keda/networkpolicy" {
  run grep -q 'gitops/keda/networkpolicy' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# Converted always-on -> on-demand 2026-08-25 alongside keda itself
# (ADR-0029's Re-evaluation log).
@test "keda-networkpolicy Application is manual sync only (on-demand, alongside keda)" {
  run grep -q 'automated:' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 1 ]
}

@test "keda-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "keda-networkpolicy Application is at sync-wave 6 (moved alongside keda, ADR-0029 webhook-TLS follow-up)" {
  run grep -q 'sync-wave: "6"' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
