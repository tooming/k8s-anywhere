#!/usr/bin/env bats
# Structural coverage for scripts/ensure-lint-tools-hook.sh (SessionStart hook —
# installs shellcheck/yamllint if missing, so make ci's lint step actually runs
# instead of silently soft-skipping in a remote/autonomous session with no other
# backstop). Own file per tests/hook-scripts-coverage.bats's own frozen-monolith
# rule (new hook-script coverage goes in tests/hook-scripts-<scope>.bats, never
# appended to the monolith). Mirrors tests/hook-scripts-ensure-bats.bats's own
# structure for the sibling ensure-bats-hook.sh (same footgun class, same fix
# shape, 2026-09-06).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  HOOK="$REPO/scripts/ensure-lint-tools-hook.sh"
}

@test "ensure-lint-tools-hook.sh exists and is executable" {
  [ -x "$HOOK" ]
}

@test "ensure-lint-tools-hook.sh exits 0 when shellcheck/yamllint are already installed" {
  command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed in this test environment"
  command -v yamllint >/dev/null 2>&1 || skip "yamllint not installed in this test environment"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"shellcheck already installed"* ]]
  [[ "$output" == *"yamllint already installed"* ]]
}

@test "ensure-lint-tools-hook.sh never fails even if apt-get/tools are unavailable" {
  # Same technique as tests/hook-scripts-ensure-bats.bats's equivalent test: a
  # minimal PATH containing only a symlinked bash binary, so `command -v
  # shellcheck`/`command -v yamllint`/`command -v apt-get` all correctly fail
  # without also breaking env's own ability to resolve bash.
  local fakebin
  fakebin="$(mktemp -d)"
  ln -s "$(command -v bash)" "$fakebin/bash"
  run env -i PATH="$fakebin" bash "$HOOK"
  rm -rf "$fakebin"
  [ "$status" -eq 0 ]
}

@test "ensure-lint-tools-hook.sh is wired into .claude/settings.json's SessionStart hooks" {
  run grep -q 'ensure-lint-tools-hook.sh' "$REPO/.claude/settings.json"
  [ "$status" -eq 0 ]
}

@test ".claude/settings.json is still valid JSON after the wiring" {
  command -v python3 >/dev/null 2>&1 || skip "python3 not available"
  run python3 -c "import json; json.load(open('$REPO/.claude/settings.json'))"
  [ "$status" -eq 0 ]
}
