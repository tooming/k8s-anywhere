#!/usr/bin/env bats
# Tests for gitops/platform/tidb-admin-extras.yaml — the tidb-admin namespace-floor
# shim, brought in line with the established harbor-extras/longhorn-extras/
# istio-system-extras pattern: an always-on namespace + PSA-label pre-creation
# Application paired with an on-demand heavy component (TiDB Operator stays
# manual-sync; only the empty namespace floor is auto-synced).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APP="$REPO/gitops/platform/tidb-admin-extras.yaml"
}

@test "tidb-admin-extras Application exists" {
  [ -f "$APP" ]
}

@test "tidb-admin-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$APP"
  [ "$status" -eq 0 ]
}

@test "tidb-admin-extras Application is auto-synced (always-on PSA floor)" {
  run grep -q 'automated:' "$APP"
  [ "$status" -eq 0 ]
}

@test "tidb-admin-extras Application sources the gitops/tidb-admin path" {
  run grep -q 'path: gitops/tidb-admin' "$APP"
  [ "$status" -eq 0 ]
}

@test "tidb-operator Application (the heavy component) remains on-demand, not auto-synced" {
  # Match the real YAML key (indented, line-start) — not the file's own
  # "no automated: block" comment prose, which also contains the substring.
  run grep -qE '^\s*automated:' "$REPO/gitops/platform/tidb-operator.yaml"
  [ "$status" -ne 0 ]
}
