#!/usr/bin/env bats
# Coverage for scripts/yqs-lib-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "yqs-lib-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/yqs-lib-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "yqs-lib-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/yqs-lib-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "yqs-lib-sync-hook: a non-.sh file under scripts/ exits 0 (filtered out)" {
  run bash "$REPO/scripts/yqs-lib-sync-hook.sh" <<<"$(mk_payload "$REPO/scripts/lib/yq.sh.md")"
  [ "$status" -eq 0 ]
}

@test "yqs-lib-sync-hook: editing the real, currently-clean scripts/ exits 0" {
  run bash "$REPO/scripts/yqs-lib-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/scripts/adr-chart-version-sync-check.sh")"
  [ "$status" -eq 0 ]
}

@test "yqs-lib-sync-hook: a script defining its own yqs() exits 2" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/scripts"
  cat > "$BATS_TEST_TMPDIR/fixture/scripts/dup-check.sh" <<'SH'
#!/usr/bin/env bash
yqs() { :; }
SH
  run env YQSLIB_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/yqs-lib-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/scripts/dup-check.sh")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"defines its own yqs() helper"* ]]
}
