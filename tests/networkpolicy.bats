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

@test "allow-dns-and-apiserver is a plain NetworkPolicy (Cilium removed 2026-09-07, no replacement)" {
  run grep -q 'kind: NetworkPolicy' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kind: CiliumNetworkPolicy' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 1 ]
}

@test "allow-dns-and-apiserver policy allows DNS on port 53 (UDP+TCP)" {
  run grep -qE 'port: 53' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'UDP' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver policy targets kube-dns pods in kube-system" {
  run grep -q 'k8s-app: kube-dns' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-dns-and-apiserver allows egress to the apiserver on 443 and 6443" {
  # k3s embeds the apiserver in the node's own process (not a selectable pod), and
  # its real address isn't practically pinnable from a Kustomize template — see the
  # file's own header for why this is an ipBlock 0.0.0.0/0 egress scoped by port.
  run grep -qE 'port: 443' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -qE 'port: 6443' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'ipBlock' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# --- O2 NP completeness gate: every overlay has a per-scope bats file ----------
@test "every NP overlay dir has a per-scope networkpolicy-<ns>.bats file (O2 recurrence guard)" {
  # Prevent a future namespace from gaining a default-deny NP overlay without a
  # corresponding per-scope bats file. The namespace is read from the kustomization's
  # 'namespace:' field (authoritative K8s name) and the expected file is
  # tests/networkpolicy-<namespace>.bats. Closes ROADMAP auto/o2-np-coverage-loop.
  local fail=0
  local kfile ns
  while IFS= read -r kfile; do
    ns="$(grep "^namespace:" "$kfile" | awk '{print $2}')"
    [ -n "$ns" ] || continue
    if [ ! -f "$BATS_TEST_DIRNAME/networkpolicy-${ns}.bats" ]; then
      printf 'MISSING tests/networkpolicy-%s.bats for overlay: %s\n' "$ns" "$kfile" >&2
      fail=1
    fi
  done < <(find "$REPO/gitops" -name "kustomization.yaml" -path "*/networkpolicy/*" | sort)
  [ "$fail" -eq 0 ]
}

# --- NetworkPolicy ApplicationSet (global) ------------------------------------
@test "networkpolicy-appset.yaml has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-appset.yaml uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# --- Sync-wave ordering: connectivity policy must land before default-deny ----
# Neither ArgoCD's Application-level sync-wave (all *-networkpolicy apps share
# wave 4) nor its default resource-kind ordering guarantee one NetworkPolicy
# applies before another in the same sync. Observed on a real from-scratch
# `make up` (twice, reproducibly, back when both were CiliumNetworkPolicy):
# default-deny-all landed alone, cutting the namespace off from DNS/apiserver
# before allow-dns-and-apiserver existed — self-fatal when the namespace is
# argocd itself, since the controller then can't reach the apiserver to finish
# applying the rest of its own sync. Per-resource sync-wave is the fix: this
# shared template must carry a wave strictly earlier than default-deny.yaml's
# (0/unset). Still enforced now that both are plain NetworkPolicy — nothing
# about the ordering risk changed when Cilium was removed 2026-09-07.

@test "allow-dns-and-apiserver.yaml has a sync-wave strictly before default-deny (0)" {
  run grep -oE 'argocd\.argoproj\.io/sync-wave: "-?[0-9]+"' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  wave="$(echo "$output" | grep -oE -- '-?[0-9]+')"
  [ "$wave" -lt 0 ]
}

@test "default-deny.yaml carries no sync-wave override (stays at implicit wave 0)" {
  run grep -q 'sync-wave' "$POLICIES/default-deny.yaml"
  [ "$status" -ne 0 ]
}
