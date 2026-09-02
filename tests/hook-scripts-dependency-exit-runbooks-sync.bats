#!/usr/bin/env bats
# Coverage for scripts/dependency-exit-runbooks-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "dependency-exit-runbooks-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/dependency-exit-runbooks-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "dependency-exit-runbooks-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/dependency-exit-runbooks-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "dependency-exit-runbooks-sync-hook: docs/dependency-concentration.md itself is matched by the filter, currently in sync, exits 0" {
  run bash "$REPO/scripts/dependency-exit-runbooks-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/dependency-concentration.md")"
  [ "$status" -eq 0 ]
}

@test "dependency-exit-runbooks-sync-hook: docs/dependency-exit-runbooks.md itself is matched by the filter, currently in sync, exits 0" {
  run bash "$REPO/scripts/dependency-exit-runbooks-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/dependency-exit-runbooks.md")"
  [ "$status" -eq 0 ]
}

@test "dependency-exit-runbooks-sync-hook: a drifted runbooks file (missing group) exits 2" {
  run env DEPRUNBOOKCHECK_ROOT="$REPO/tests/fixtures/dependency-exit-runbooks-sync-check/drift" \
      bash "$REPO/scripts/dependency-exit-runbooks-sync-hook.sh" \
      <<<"$(mk_payload "docs/dependency-concentration.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing a section"* ]]
}
