#!/usr/bin/env bats
# Clusterless structural tests for the argocd namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- argocd namespace overlay (ADR-0016 §4 fan-out) ---------------------------
@test "argocd networkpolicy kustomization.yaml exists" {
  [ -f "$ARGOCD_NP/kustomization.yaml" ]
}

@test "argocd kustomization sets namespace: argocd" {
  run grep -q 'namespace: argocd' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml" ]
}

@test "allow-argocd-server-from-gateway allows port 8080 (ArgoCD server HTTP)" {
  run grep -q 'port: 8080' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway targets argocd-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-server' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from kube-system namespace" {
  run grep -q 'kube-system' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from Traefik pods" {
  run grep -q 'app.kubernetes.io/name: traefik' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy.yaml no longer exists (ADR-0041)" {
  [ ! -f "$ARGOCD_NP/allow-argocd-from-alloy.yaml" ]
}

@test "allow-argocd-intra-namespace.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-intra-namespace.yaml" ]
}

@test "allow-argocd-intra-namespace allows both Ingress and Egress policyTypes" {
  run grep -c 'Ingress\|Egress' "$ARGOCD_NP/allow-argocd-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-argocd-intra-namespace uses an empty podSelector (matches all pods)" {
  run grep -q 'podSelector: {}' "$ARGOCD_NP/allow-argocd-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-forgejo.yaml no longer exists (Forgejo removed 2026-09-07, no replacement — ArgoCD clones GitHub directly now)" {
  [ ! -f "$ARGOCD_NP/allow-argocd-repo-server-egress-forgejo.yaml" ]
}

@test "allow-argocd-repo-server-egress-charts.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml" ]
}

@test "allow-argocd-repo-server-egress-charts allows TCP 443 (Helm/OCI chart pull)" {
  run grep -qE 'port: "?443"?' "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-charts targets argocd-repo-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-repo-server' "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-service-frontends.yaml no longer exists (dropped 2026-09-07, subsumed by intra-namespace)" {
  # Cilium's socket-LB pre-DNAT quirk (ADR-0014, removed 2026-09-07, no
  # replacement) was the only reason ArgoCD's own Service frontends needed a
  # separate ClusterIP-CIDR policy — kube-router enforces NetworkPolicy
  # post-DNAT, so allow-argocd-intra-namespace.yaml's podSelector:{} egress
  # rule already matches those same backend pods directly.
  [ ! -f "$ARGOCD_NP/allow-argocd-service-frontends.yaml" ]
}

@test "argocd networkpolicy kustomization wires the repo-server egress policy in its resources: list" {
  run grep -q 'allow-argocd-repo-server-egress-charts.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
  # Scoped to the resources: list, not the whole file — the header comment
  # legitimately still names allow-argocd-service-frontends.yaml as history
  # (why it was dropped 2026-09-07), which a whole-file grep would false-positive on.
  run bash -c "awk '/^resources:/{f=1} f' '$ARGOCD_NP/kustomization.yaml' | grep -q 'allow-argocd-service-frontends.yaml'"
  [ "$status" -eq 1 ]
}

@test "argocd-networkpolicy ArgoCD Application targets the argocd namespace" {
  run grep -q 'destNamespace: argocd' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# --- Sync-wave ordering: argocd's own allow rules must not land after the DNS/
# apiserver floor (repo-server deadlock guard) ---------------------------------
# Confirmed live on a genuinely from-scratch `make up` post-Cilium-removal
# (2026-09-07): allow-dns-and-apiserver.yaml (wave -1, podSelector:{} egress
# restricted to DNS+apiserver only) landing a wave before allow-argocd-intra-
# namespace.yaml (which permits argocd-application-controller -> argocd-repo-
# server/argocd-cache) cuts the controller off from repo-server before its own
# allow-rule exists. Since repo-server is what every Application — including this
# NetworkPolicy kustomization's own next sync — needs to generate manifests, that
# gap is a deadlock the cluster can never recover from on its own: ArgoCD's wave
# gate holds wave 0 back until wave -1 is Synced+Healthy, and once repo-server is
# unreachable nothing else in the whole bootstrap can get manifests generated
# either. Deleting the standalone allow-dns-and-apiserver object live let the sync
# proceed and converge normally, confirming this exact ordering as the cause.
#
# This is a static/structural assertion, not a live-cluster timing test — it
# cannot prove kube-router actually programs these waves' iptables rules
# atomically (that's inherently a live-cluster behavior, see the PR that added
# this test for why no stronger mechanical guard is possible here). What it CAN
# and does guard mechanically: nobody re-introduces the specific wave-ordering
# shape that caused the deadlock — an argocd-specific allow rule sitting at a
# later (or unset/default) wave than the shared DNS+apiserver floor rule it
# depends on.
@test "every argocd-specific allow rule shares allow-dns-and-apiserver's sync-wave (not a later/default wave)" {
  run grep -oE 'argocd\.argoproj\.io/sync-wave: "-?[0-9]+"' "$POLICIES/allow-dns-and-apiserver.yaml"
  [ "$status" -eq 0 ]
  local floor_wave
  floor_wave="$(echo "$output" | grep -oE -- '-?[0-9]+')"

  local f
  for f in "$ARGOCD_NP/allow-argocd-intra-namespace.yaml" \
           "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml" \
           "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"; do
    run grep -oE 'argocd\.argoproj\.io/sync-wave: "-?[0-9]+"' "$f"
    [ "$status" -eq 0 ]
    local wave
    wave="$(echo "$output" | grep -oE -- '-?[0-9]+')"
    [ "$wave" -eq "$floor_wave" ]
  done
}
