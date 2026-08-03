#!/usr/bin/env bats
# Coverage for scripts/ok-bad-lib-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "ok-bad-lib-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/ok-bad-lib-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "ok-bad-lib-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/ok-bad-lib-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "ok-bad-lib-sync-hook: editing the real, currently-clean scripts/ exits 0" {
  run bash "$REPO/scripts/ok-bad-lib-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/scripts/lint.sh")"
  [ "$status" -eq 0 ]
}

@test "ok-bad-lib-sync-hook: a script defining its own drift-setting bad() exits 2" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/scripts"
  cat > "$BATS_TEST_TMPDIR/fixture/scripts/dup-check.sh" <<'SH'
#!/usr/bin/env bash
drift=0
bad() { printf '%s\n' "$1"; drift=1; }
SH
  run env OKBADLIB_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/ok-bad-lib-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/scripts/dup-check.sh")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"defines its own drift-setting bad()"* ]]
}
