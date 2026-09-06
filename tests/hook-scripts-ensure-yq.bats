#!/usr/bin/env bats
# Structural coverage for scripts/ensure-yq-hook.sh (SessionStart hook —
# installs mikefarah/yq if the yq on PATH isn't that variant, so make ci's
# mikefarah-yq-only gates actually run instead of silently soft-skipping in a
# remote/autonomous session with no other backstop). Own file per
# tests/hook-scripts-coverage.bats's frozen-monolith rule. Mirrors
# tests/hook-scripts-ensure-bats.bats / tests/hook-scripts-ensure-lint-tools.bats /
# tests/hook-scripts-ensure-manifest-tools.bats's structure for the sibling
# hooks (same footgun class, 2026-09-06).
#
# The network-dependent install path (the actual curl download) is NOT
# re-exercised here -- that would make this suite flaky/slow and duplicate
# what `make ci`'s own mikefarah-yq-only steps already prove once the tool is
# present. This file only proves the hook's structure and its always-safe
# (offline) behavior.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  HOOK="$REPO/scripts/ensure-yq-hook.sh"
}

@test "ensure-yq-hook.sh exists and is executable" {
  [ -x "$HOOK" ]
}

@test "ensure-yq-hook.sh reports already installed when mikefarah/yq is present" {
  command -v yq >/dev/null 2>&1 || skip "yq not installed in this test environment"
  yq --version 2>&1 | grep -qi mikefarah || skip "yq on PATH isn't the mikefarah variant in this test environment"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mikefarah/yq already on PATH"* ]]
}

@test "ensure-yq-hook.sh never fails even with no network/yq available" {
  # Same technique as the sibling ensure-*-hook.sh tests: a minimal PATH
  # containing only symlinked bash/grep/chmod binaries (the hook's own
  # non-network calls), so `command -v yq` correctly fails and the curl call
  # fails fast with "command not found" -- no actual network calls happen --
  # without breaking the shell's own ability to run.
  local fakebin
  fakebin="$(mktemp -d)"
  for bin in bash grep chmod; do
    ln -s "$(command -v "$bin")" "$fakebin/$bin"
  done
  run env -i PATH="$fakebin" bash "$HOOK"
  rm -rf "$fakebin"
  [ "$status" -eq 0 ]
}

@test "ensure-yq-hook.sh is wired into .claude/settings.json's SessionStart hooks" {
  run grep -q 'ensure-yq-hook.sh' "$REPO/.claude/settings.json"
  [ "$status" -eq 0 ]
}

@test ".claude/settings.json is still valid JSON after the wiring" {
  command -v python3 >/dev/null 2>&1 || skip "python3 not available"
  run python3 -c "import json; json.load(open('$REPO/.claude/settings.json'))"
  [ "$status" -eq 0 ]
}
