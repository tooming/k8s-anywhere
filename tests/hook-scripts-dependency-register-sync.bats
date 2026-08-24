#!/usr/bin/env bats
# Coverage for scripts/dependency-register-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "dependency-register-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/dependency-register-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "dependency-register-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/dependency-register-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "dependency-register-sync-hook: an ADR edit is matched by the filter, currently in sync, exits 0" {
  run bash "$REPO/scripts/dependency-register-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/decisions/adr-0030-pin-k3s-version-explicitly.md")"
  [ "$status" -eq 0 ]
}

@test "dependency-register-sync-hook: docs/dependency-register.md itself is matched by the filter, currently in sync, exits 0" {
  run bash "$REPO/scripts/dependency-register-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/dependency-register.md")"
  [ "$status" -eq 0 ]
}

@test "dependency-register-sync-hook: a drifted register (stale Last-reviewed date) exits 2" {
  run env DEPENDENCYREGISTERCHECK_ROOT="$REPO/tests/fixtures/dependency-register-check/drift" \
      bash "$REPO/scripts/dependency-register-sync-hook.sh" \
      <<<"$(mk_payload "docs/dependency-register.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"no longer matches"* ]]
}
