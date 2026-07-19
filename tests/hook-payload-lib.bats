#!/usr/bin/env bats
# Clusterless structural tests for scripts/lib/hook-payload.sh — the shared
# PostToolUse-hook payload-parsing snippet extracted from 15 near-identical
# inline copies across scripts/*-hook.sh (janitor cleanup, mirrors the earlier
# scripts/lib/colors.sh extraction). Guards against the duplicate pattern
# creeping back in as new hooks get added.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "scripts/lib/hook-payload.sh exists" {
  [ -f "$REPO/scripts/lib/hook-payload.sh" ]
}

@test "hook-payload.sh defines hook_file_path()" {
  run grep -q "^hook_file_path()" "$REPO/scripts/lib/hook-payload.sh"
  [ "$status" -eq 0 ]
}

@test "hook-payload.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/hook-payload.sh"
  [ "$status" -eq 0 ]
}

@test "hook_file_path() extracts tool_input.file_path from a JSON payload on stdin" {
  source "$REPO/scripts/lib/hook-payload.sh"
  out="$(echo '{"tool_input":{"file_path":"/tmp/example.yaml"}}' | hook_file_path)"
  [ "$out" = "/tmp/example.yaml" ]
}

@test "hook_file_path() falls back to tool_input.path when file_path is absent" {
  source "$REPO/scripts/lib/hook-payload.sh"
  out="$(echo '{"tool_input":{"path":"/tmp/fallback.yaml"}}' | hook_file_path)"
  [ "$out" = "/tmp/fallback.yaml" ]
}

@test "hook_file_path() returns empty on an empty payload (no crash)" {
  source "$REPO/scripts/lib/hook-payload.sh"
  out="$(echo '{}' | hook_file_path)"
  [ -z "$out" ]
}

# --- recurrence guard: no hook re-inlines the duplicated pattern -------------
# Every scripts/*-hook.sh that extracts tool_input.file_path/.path from stdin
# must source lib/hook-payload.sh rather than re-declaring the two-line
# payload+jq snippet inline. Only hook-payload.sh itself should ever contain
# that literal jq filter.
@test "no *-hook.sh script re-inlines the tool_input.file_path jq pattern (source lib/hook-payload.sh instead)" {
  run grep -rl '\.tool_input\.file_path // \.tool_input\.path // empty' "$REPO/scripts" --include='*-hook.sh'
  [ "$status" -ne 0 ]
}

@test "every hook sourcing lib/hook-payload.sh does so via ROOT-relative path" {
  run grep -rl 'source "\$ROOT/scripts/lib/hook-payload.sh"' "$REPO/scripts"
  [ "$status" -eq 0 ]
  # Spot-check a sample: at least 10 hooks adopted the shared lib.
  count="$(grep -rl 'source "\$ROOT/scripts/lib/hook-payload.sh"' "$REPO/scripts" | wc -l)"
  [ "$count" -ge 10 ]
}
