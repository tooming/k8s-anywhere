#!/usr/bin/env bats
# Tests for scripts/o5-dashboard-coverage-check.sh — a new drift-check scope, per
# the drift-detectors-tests-check convention (tests/drift-detectors.bats itself is
# frozen; new scopes go in their own tests/drift-<scope>.bats file, mirroring
# tests/drift-envoy-egress-allowlist-check.bats). Added because CHARTER Objective
# O5 promised "Measured by: a drift check wired into make ci" with no such check
# actually existing (found live 2026-08-13).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/o5-dashboard-coverage-check"
}

@test "o5-dashboard-coverage-check: passes on the real repo's gitops/platform + dashboards" {
  run bash "$REPO/scripts/o5-dashboard-coverage-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every auto-synced Application"* ]]
}

@test "o5-dashboard-coverage-check: fails when a mapped component's dashboard is missing" {
  run env O5DASHCHECK_ROOT="$FIX/missing-dashboard" bash "$REPO/scripts/o5-dashboard-coverage-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"lab-alloy.json"* ]]
}

@test "o5-dashboard-coverage-check: fails when a new auto-synced Application has no dashboard mapping" {
  tmp="$BATS_TEST_TMPDIR/o5-new-component"
  mkdir -p "$tmp/gitops/platform" "$tmp/grafana/dashboards"
  cp "$REPO"/grafana/dashboards/*.json "$tmp/grafana/dashboards/"
  cat > "$tmp/gitops/platform/newthing.yaml" <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: newthing
  namespace: argocd
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
  run env O5DASHCHECK_ROOT="$tmp" bash "$REPO/scripts/o5-dashboard-coverage-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"newthing"* ]]
}

@test "o5-dashboard-coverage-check: does not flag an on-demand (non-automated) Application" {
  tmp="$BATS_TEST_TMPDIR/o5-on-demand"
  mkdir -p "$tmp/gitops/platform" "$tmp/grafana/dashboards"
  cp "$REPO"/grafana/dashboards/*.json "$tmp/grafana/dashboards/"
  cat > "$tmp/gitops/platform/heavything.yaml" <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: heavything
  namespace: argocd
spec:
  syncPolicy: {}
EOF
  run env O5DASHCHECK_ROOT="$tmp" bash "$REPO/scripts/o5-dashboard-coverage-check.sh"
  [ "$status" -eq 0 ]
}

@test "o5-dashboard-coverage-check: does not flag a plumbing (-extras suffixed) Application" {
  tmp="$BATS_TEST_TMPDIR/o5-plumbing"
  mkdir -p "$tmp/gitops/platform" "$tmp/grafana/dashboards"
  cp "$REPO"/grafana/dashboards/*.json "$tmp/grafana/dashboards/"
  cat > "$tmp/gitops/platform/newthing-extras.yaml" <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: newthing-extras
  namespace: argocd
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
  run env O5DASHCHECK_ROOT="$tmp" bash "$REPO/scripts/o5-dashboard-coverage-check.sh"
  [ "$status" -eq 0 ]
}
