#!/usr/bin/env bats
# Coverage for scripts/context-doc-version-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "context-doc-version-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: the real, currently-clean context.md exits 0" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/decisions/context.md")"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: a gitops manifest edit exits 0 when still in sync" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/platform/kro.yaml")"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: a drifted context.md exits 2" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/docs/decisions" "$BATS_TEST_TMPDIR/fixture/gitops/platform"
  cat > "$BATS_TEST_TMPDIR/fixture/docs/decisions/context.md" <<'MD'
Grafana 13.0.1 on the observability stack.
Pyroscope** (chart 2.0.2) continuous profiling.
KRO** (0.4.1) cloud control-plane.
MD
  cat > "$BATS_TEST_TMPDIR/fixture/gitops/platform/observability-grafana.yaml" <<'YAML'
spec:
  source:
    helm:
      valuesObject:
        image:
          tag: "13.0.3"
YAML
  cat > "$BATS_TEST_TMPDIR/fixture/gitops/platform/observability-pyroscope.yaml" <<'YAML'
spec:
  source:
    targetRevision: "2.2.0"
YAML
  cat > "$BATS_TEST_TMPDIR/fixture/gitops/platform/kro.yaml" <<'YAML'
spec:
  source:
    targetRevision: "0.9.2"
YAML
  run env CONTEXTDOCCHECK_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/docs/decisions/context.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"no longer matches its live gitops pin"* ]]
}
