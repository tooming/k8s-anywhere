#!/usr/bin/env bats
# Structural coverage for scripts/ensure-manifest-tools-hook.sh (SessionStart hook
# — installs kustomize/terraform/tflint/kubeconform if missing, so make ci's
# kustomize/terraform/manifests gates actually run instead of silently
# soft-skipping in a remote/autonomous session with no other backstop). Own file
# per tests/hook-scripts-coverage.bats's frozen-monolith rule. Mirrors
# tests/hook-scripts-ensure-bats.bats / tests/hook-scripts-ensure-lint-tools.bats's
# structure for the sibling hooks (same footgun class, 2026-09-06).
#
# Network-dependent install paths (the actual curl/tar/install sequences) are NOT
# re-exercised here -- that would make this suite flaky/slow and duplicate what
# `make ci`'s own kustomize/terraform/manifests steps already prove once the
# tools are present. This file only proves the hook's structure and its
# always-safe (offline) behavior.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  HOOK="$REPO/scripts/ensure-manifest-tools-hook.sh"
}

@test "ensure-manifest-tools-hook.sh exists and is executable" {
  [ -x "$HOOK" ]
}

@test "ensure-manifest-tools-hook.sh reports each tool already installed when present" {
  command -v kustomize >/dev/null 2>&1 || skip "kustomize not installed in this test environment"
  command -v terraform >/dev/null 2>&1 || skip "terraform not installed in this test environment"
  command -v tflint >/dev/null 2>&1 || skip "tflint not installed in this test environment"
  command -v kubeconform >/dev/null 2>&1 || skip "kubeconform not installed in this test environment"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kustomize already installed"* ]]
  [[ "$output" == *"terraform already installed"* ]]
  [[ "$output" == *"tflint already installed"* ]]
  [[ "$output" == *"kubeconform already installed"* ]]
}

@test "ensure-manifest-tools-hook.sh never fails even with no network/tools available" {
  # Same technique as the sibling ensure-*-hook.sh tests: a minimal PATH
  # containing only symlinked bash/timeout/mktemp/rm binaries (the hook's own
  # non-network coreutils calls), so every `command -v` check correctly fails
  # and every curl call fails fast with "command not found" -- no actual
  # network calls happen -- without breaking the shell's own ability to run.
  local fakebin
  fakebin="$(mktemp -d)"
  for bin in bash timeout mktemp rm; do
    ln -s "$(command -v "$bin")" "$fakebin/$bin"
  done
  run env -i PATH="$fakebin" timeout 30 bash "$HOOK"
  rm -rf "$fakebin"
  [ "$status" -eq 0 ]
}

@test "ensure-manifest-tools-hook.sh explicitly explains why helm is not covered" {
  run grep -q 'helm intentionally skipped' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "ensure-manifest-tools-hook.sh is wired into .claude/settings.json's SessionStart hooks" {
  run grep -q 'ensure-manifest-tools-hook.sh' "$REPO/.claude/settings.json"
  [ "$status" -eq 0 ]
}

@test ".claude/settings.json is still valid JSON after the wiring" {
  command -v python3 >/dev/null 2>&1 || skip "python3 not available"
  run python3 -c "import json; json.load(open('$REPO/.claude/settings.json'))"
  [ "$status" -eq 0 ]
}
