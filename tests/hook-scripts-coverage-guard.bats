#!/usr/bin/env bats
# Coverage for scripts/hook-scripts-coverage-tests-sync-hook.sh — the PostToolUse
# companion to the hook-scripts-coverage-tests-check 'drift' gate. Lives in its
# own file, NOT in tests/hook-scripts-coverage.bats: that monolith is now FROZEN
# (see its header comment) precisely so new hook-script coverage stops landing
# there. Mirrors the drift-detectors-tests-sync-hook coverage pattern.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "hook-scripts-coverage-tests-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/hook-scripts-coverage-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/networkpolicy.bats")"
  [ "$status" -eq 0 ]
}

@test "hook-scripts-coverage-tests-sync-hook: tests/hook-scripts-coverage.bats (currently frozen/compliant) exits 0" {
  run bash "$REPO/scripts/hook-scripts-coverage-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/hook-scripts-coverage.bats")"
  [ "$status" -eq 0 ]
}
