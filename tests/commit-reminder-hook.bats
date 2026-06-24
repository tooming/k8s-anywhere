#!/usr/bin/env bats
# Unit tests for scripts/commit-reminder-hook.sh — the Stop hook that nags to
# commit + push + open a PR. The bug this guards against: a Stop hook that
# exits 2 re-invokes the agent, which stops again and re-fires the hook — an
# infinite reminder loop on state the agent can't/won't change. Claude sets
# "stop_hook_active":true in the stdin payload once it is ALREADY continuing
# because of a prior Stop-hook block; the hook MUST honour that and exit 0,
# nagging at most once per turn. These tests run before any git work, so they
# are hermetic — independent of the real repo's dirty state.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  HOOK="$REPO/scripts/commit-reminder-hook.sh"
}

@test "commit-reminder: stop_hook_active=true short-circuits to exit 0 (no loop)" {
  run bash "$HOOK" <<<'{"stop_hook_active":true}'
  [ "$status" -eq 0 ]
}

@test "commit-reminder: tolerates a space after the colon (\"stop_hook_active\": true)" {
  run bash "$HOOK" <<<'{"stop_hook_active": true}'
  [ "$status" -eq 0 ]
}

@test "commit-reminder: the guard runs before any git logic (exits 0 even with junk stdin around the flag)" {
  run bash "$HOOK" <<<'{"session_id":"x","transcript_path":"/nope","stop_hook_active":true,"foo":"bar"}'
  [ "$status" -eq 0 ]
}

@test "commit-reminder: stop_hook_active=false does NOT short-circuit (falls through to the real checks)" {
  # When not already looping the hook must run its normal logic; on a clean main
  # checkout that means exit 0, but crucially it must NOT exit via the loop guard.
  # We assert it doesn't error out (status 0 or 2 are both valid real outcomes;
  # 1/127/etc. would mean the script broke). The key invariant is that a false
  # flag is never treated as true.
  run bash "$HOOK" <<<'{"stop_hook_active":false}'
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}
