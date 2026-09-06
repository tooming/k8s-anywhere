#!/usr/bin/env bats
# Structural coverage for scripts/ensure-bats-hook.sh (SessionStart hook — installs
# `bats` if missing, so `make ci`'s unit-test step actually runs instead of silently
# soft-skipping in a remote/autonomous session with no other backstop). Own file per
# tests/hook-scripts-coverage.bats's own frozen-monolith rule (new hook-script
# coverage goes in tests/hook-scripts-<scope>.bats, never appended to the monolith).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  HOOK="$REPO/scripts/ensure-bats-hook.sh"
}

@test "ensure-bats-hook.sh exists and is executable" {
  [ -x "$HOOK" ]
}

@test "ensure-bats-hook.sh exits 0 when bats is already installed" {
  # bats is running this test, so it's on PATH by definition — this exercises the
  # already-installed branch without needing network/apt-get.
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "ensure-bats-hook.sh never fails even if apt-get is unavailable" {
  # Simulate an environment with no bats and no apt-get on PATH: a bare PATH
  # override would also break `env`'s own ability to resolve `bash` (exit 127,
  # not a real test of the hook), so build a minimal PATH containing only a
  # symlink to the real bash binary -- enough to execute the script, nothing
  # else -- so `command -v bats`/`command -v apt-get` inside it both correctly
  # fail. The hook must still exit 0 (best-effort only, never blocks the
  # session).
  local fakebin
  fakebin="$(mktemp -d)"
  ln -s "$(command -v bash)" "$fakebin/bash"
  run env -i PATH="$fakebin" bash "$HOOK"
  rm -rf "$fakebin"
  [ "$status" -eq 0 ]
}

@test "ensure-bats-hook.sh is wired into .claude/settings.json's SessionStart hooks" {
  run grep -q 'ensure-bats-hook.sh' "$REPO/.claude/settings.json"
  [ "$status" -eq 0 ]
}

@test ".claude/settings.json is still valid JSON after the wiring" {
  command -v python3 >/dev/null 2>&1 || skip "python3 not available"
  run python3 -c "import json; json.load(open('$REPO/.claude/settings.json'))"
  [ "$status" -eq 0 ]
}
