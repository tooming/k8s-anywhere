#!/usr/bin/env bats
# Clusterless structural tests for the SHARED NetworkPolicy baseline templates
# (ADR-0016, RFC #82): the default-deny + allow-dns-and-apiserver templates every
# namespace overlay composes. Per-namespace overlay tests live in their own
# tests/networkpolicy-<scope>.bats file — the monolith was split so parallel fan-out
# PRs never collide at a shared EOF (the #247 vs #248 conflict). Overlay paths:
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- Shared baseline templates -----------------------------------------------
@test "default-deny.yaml exists under gitops/network/policies/" {
  [ -f "$POLICIES/default-deny.yaml" ]
}

@test "default-deny policy has policyTypes Ingress and Egress" {
  run grep -c 'Ingress\|Egress' "$POLICIES/default-deny.yaml"
  [ "$status" -eq 0 ]
  # at least two occurrences (one each)
  [ "$output" -ge 2 ]
}

@test "default-deny policy has an empty podSelector (matches all pods)" {
  run grep -q 'podSelector: {}' "$POLICIES/default-deny.yaml"
  [ "$status" -eq 0 ]
}

@test "default-deny policy has no egress or ingress rules (full deny)" {
  run grep -q '^\s*egress:\|^\s*ingress:' "$POLICIES/default-deny.yaml"
  [ "$status" -eq 1 ]
}

@test "allow-dns-and-apiserver.yaml exists under gitops/network/policies/" {
  [ -f "$POLICIES/allow-dns-and-apiserver.yaml" ]
}

@test "allow-dns-and-apiserver is a CiliumNetworkPolicy (kube-proxy-free entity match)" {
  # ADR-0014: a plain-NetworkPolicy ipBlock can't match the apiserver's reserved
  # Cilium identity under kube-proxy-free, so this baseline must be a CNP.
  run grep -q 'kind: CiliumNetworkPolicy' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver policy allows DNS on port 53 (UDP)" {
  run grep -qE 'port: "?53"?' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'UDP' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver allows the apiserver via the kube-apiserver entity on 6443" {
  run grep -qE 'port: "?6443"?' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kube-apiserver' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver does NOT gate the apiserver behind an ipBlock CIDR (regression guard)" {
  # The ipBlock approach silently cuts every deny-all namespace off from the
  # apiserver under Cilium kube-proxy-free — see ADR-0014 / the fix commit.
  # Inspect rule lines only (skip the explanatory comment block).
  run bash -c "grep -v '^[[:space:]]*#' '$POLICIES/allow-dns-and-apiserver.yaml' | grep -q 'ipBlock'"
  [ "$status" -eq 1 ]
}

@test "allow-dns-and-apiserver policy targets kube-dns pods in kube-system" {
  run grep -q 'k8s-app: kube-dns' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver permits DNS to the kube-proxy-free service CIDR" {
  # kube-proxy-free Cilium can evaluate the kube-dns ClusterIP frontend before pod
  # identity, so DNS ports must also be allowed to the service CIDR (toCIDR, not ipBlock).
  run grep -q '10.43.0.0/16' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver service-CIDR allowance is DNS-port scoped" {
  run bash -c "grep -A6 '10.43.0.0/16' '$POLICIES/allow-dns-and-apiserver.yaml' | grep -q 'port: \"53\"'"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver permits the apiserver service frontend on 443" {
  # In-cluster clients reach the apiserver via the 10.43.0.1:443 ClusterIP frontend.
  run grep -q '10.43.0.1/32' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'port: "?443"?' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# --- ClusterIP bridge shared template ----------------------------------------
@test "zz-dns-clusterip-bridge.yaml exists under gitops/network/policies/" {
  [ -f "$POLICIES/zz-dns-clusterip-bridge.yaml" ]
}

@test "zz-dns-clusterip-bridge is a CiliumNetworkPolicy with no endpointSelector restriction" {
  run grep -q 'kind: CiliumNetworkPolicy' "$POLICIES/zz-dns-clusterip-bridge.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'endpointSelector: {}' "$POLICIES/zz-dns-clusterip-bridge.yaml"
  [ "$status" -eq 0 ]
}

@test "zz-dns-clusterip-bridge allows egress to the Service ClusterIP CIDR without port restriction" {
  run grep -q '10.43.0.0/16' "$POLICIES/zz-dns-clusterip-bridge.yaml"
  [ "$status" -eq 0 ]
  # No toPorts block — full CIDR unrestricted (per-service pod-selector rules still gate backends)
  run grep -q 'toPorts' "$POLICIES/zz-dns-clusterip-bridge.yaml"
  [ "$status" -eq 1 ]
}

@test "zz-dns-clusterip-bridge has metadata.name zz-dns-clusterip-bridge (matches live out-of-band name)" {
  run grep -q 'name: zz-dns-clusterip-bridge' "$POLICIES/zz-dns-clusterip-bridge.yaml"
  [ "$status" -eq 0 ]
}

# --- CI drift guard: every default-deny overlay must include the bridge -------
@test "every networkpolicy overlay with default-deny.yaml also references zz-dns-clusterip-bridge (drift guard, closes #315)" {
  # Prevent new namespaces from inheriting the same gap that caused issue #315:
  # a default-deny namespace without the ClusterIP bridge silently breaks ClusterIP
  # egress for all pods in that namespace when Cilium socket-LB evaluates the
  # service IP before translating it to a backend pod IP.
  local fail=0
  local kfile
  while IFS= read -r kfile; do
    if grep -q 'default-deny.yaml' "$kfile"; then
      if ! grep -q 'zz-dns-clusterip-bridge' "$kfile"; then
        echo "MISSING zz-dns-clusterip-bridge in: $kfile" >&2
        fail=1
      fi
    fi
  done < <(find "$REPO/gitops" -name "kustomization.yaml" -path "*/networkpolicy/*" | sort)
  [ "$fail" -eq 0 ]
}
