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
    <<<"$(mk_payload "$REPO/gitops/platform/argocd-extras.yaml")"
  [ "$status" -eq 0 ]
}

# The KRO/ACK s3-controller check_one calls this test used to exercise (and, before
# them, the Grafana/Pyroscope calls) were all removed as their components were removed
# (ADR-0041 2026-09-06, ADR-0038 2026-09-07) — context-doc-version-sync-check.sh
# currently tracks zero prose version citations, so a context.md edit can no longer
# produce a "drift" exit 2 no matter how stale-looking its content is. This documents
# that current behavior explicitly rather than leaving a test asserting a code path
# nothing can reach; re-add a real drift-detection test once a new self-tracking
# citation gets its own check_one call in the script.
@test "context-doc-version-sync-hook: a context.md edit exits 0 (checker currently tracks zero citations)" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/docs/decisions" "$BATS_TEST_TMPDIR/fixture/gitops/platform"
  cat > "$BATS_TEST_TMPDIR/fixture/docs/decisions/context.md" <<'MD'
Some stale-looking prose that no check_one call parses.
MD
  run env CONTEXTDOCCHECK_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/docs/decisions/context.md")"
  [ "$status" -eq 0 ]
}
