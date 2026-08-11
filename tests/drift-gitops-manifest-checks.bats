#!/usr/bin/env bats
# Tests for the gitops-manifest-structural-correctness drift checks — split
# out of the now-frozen tests/drift-detectors.bats monolith (see that file's
# header comment) into its own scope, per the drift-detectors-tests-check
# convention: new drift-check coverage goes in its own tests/drift-<scope>.bats
# file. Grouped together here because all three guard structural correctness
# of live gitops/ manifests (a resolvable Helm chart pin, ServerSideApply on
# oversized-CRD Applications, Argo Rollouts plugin lists staying real YAML
# lists) rather than any one component's own configuration.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- helm-chart-pin-check --------------------------------------------------------
# Resolved offline via a stub resolver (CHARTPIN_RESOLVER) so the suite never hits
# the network; helm's real "not found" vs "cannot be reached" strings are verified
# by hand. STUB="$FIX/helm-chart-pin/resolver-stub.sh".
@test "helm-chart-pin-check: passes when every chart pin resolves (git-sourced apps ignored)" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/in-sync" \
          CHARTPIN_RESOLVER="$FIX/helm-chart-pin/resolver-stub.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"good-chart"* ]]
}

@test "helm-chart-pin-check: FAILS when a chart pins a version missing from a reachable repo" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/drift" \
          CHARTPIN_RESOLVER="$FIX/helm-chart-pin/resolver-stub.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bad-pin"* ]]
  [[ "$output" == *"NOT found"* ]]
}

@test "helm-chart-pin-check: SKIPS (does not fail) when the repo is unreachable" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/unreachable" \
          CHARTPIN_RESOLVER="$FIX/helm-chart-pin/resolver-stub.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"offline-repo"* ]]
  [[ "$output" == *"skipped"* ]]
}

# Found 2026-08-11: cert-manager's real "1.21.1" pin (a chart whose repo index lists
# versions with a "v" prefix, e.g. "v1.21.1") was failing this check even though
# `helm search repo --version 1.21.1` resolves it fine -- the bug was in
# resolve_builtin's own jq comparison, which echoed the index's "v"-prefixed string
# back and string-compared it against the un-prefixed query. This exercises that real
# comparison path (HELM_BIN fake, no CHARTPIN_RESOLVER stub) so the fix can't regress.
@test "helm-chart-pin-check: resolves a pin against a repo whose index is v-prefixed" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/v-prefix" \
          HELM_BIN="$FIX/helm-chart-pin/fake-helm-v-prefix.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"v-prefixed-chart"* ]]
  [[ "$output" == *"exists in"* ]]
}

# --- argocd-crd-ssa-check ---------------------------------------------------------
# Rendered offline via a stub renderer (CRDSSA_RENDERER) so the suite never pulls a
# real chart; the stub emits an oversized CRD for "big-crd-chart" and a tiny one for
# "small-crd-chart". This proves the size-vs-SSA logic without helm/network.
@test "argocd-crd-ssa-check: passes when an oversized-CRD Application uses ServerSideApply" {
  run env CRDSSA_CHECK_ROOT="$FIX/argocd-crd-ssa/in-sync" \
          CRDSSA_RENDERER="$FIX/argocd-crd-ssa/renderer-stub.sh" \
          bash "$REPO/scripts/argocd-crd-ssa-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bigcrd-app: SSA enabled"* ]]
}

@test "argocd-crd-ssa-check: FAILS when an oversized-CRD Application lacks ServerSideApply" {
  run env CRDSSA_CHECK_ROOT="$FIX/argocd-crd-ssa/drift" \
          CRDSSA_RENDERER="$FIX/argocd-crd-ssa/renderer-stub.sh" \
          bash "$REPO/scripts/argocd-crd-ssa-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bigcrd-app"* ]]
  [[ "$output" == *"ServerSideApply"* ]]
}

# --- rollouts-plugin-list-check ----------------------------------------------------
@test "rollouts-plugin-list-check: passes when plugin values are YAML lists" {
  run env ROLLOUTS_PLUGIN_CHECK_ROOT="$FIX/rollouts-plugin-list-check/in-sync" \
          bash "$REPO/scripts/rollouts-plugin-list-check.sh"
  [ "$status" -eq 0 ]
}

@test "rollouts-plugin-list-check: FAILS when a plugin value is a block-scalar string" {
  run env ROLLOUTS_PLUGIN_CHECK_ROOT="$FIX/rollouts-plugin-list-check/drift" \
          bash "$REPO/scripts/rollouts-plugin-list-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"must be a YAML list"* ]]
}

@test "rollouts-plugin-list-check: passes on the real repo gitops" {
  run bash "$REPO/scripts/rollouts-plugin-list-check.sh"
  [ "$status" -eq 0 ]
}
