#!/usr/bin/env bats
# Coverage for scripts/routines-check.sh (`make routines-check`, wired into `make
# ci`) — previously had zero bats coverage despite being the mechanical drift
# guard CLAUDE.md's own bugfix-recurrence template names as the pattern to mirror
# (script + make target + PostToolUse hook + bats coverage, alongside
# readme-check/roadmap-check/securitycontext-tests-check). Mirrors the
# ROADMAPCHECK_ROOT / READMECHECK_ROOT fixture-tree pattern used by those checks:
# ROUTINESCHECK_ROOT points the script at tests/fixtures/routines-check/<scenario>
# instead of the real repo, so no scenario here touches the real .routines-applied.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/routines-check.sh"
  FIX="$REPO/tests/fixtures/routines-check"
}

@test "routines-check.sh exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "routines-check: passes when every routine file's sha matches the snapshot" {
  run env ROUTINESCHECK_ROOT="$FIX/in-sync" bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "routines-check: FAILS when a routine file was edited since the last apply" {
  run env ROUTINESCHECK_ROOT="$FIX/drift" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"edited since last apply"* ]]
}

@test "routines-check: FAILS when .routines-applied is missing entirely" {
  run env ROUTINESCHECK_ROOT="$FIX/missing-snapshot" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *".routines-applied does not exist"* ]]
}

@test "routines-check: FAILS when a routine file exists but has no snapshot entry" {
  run env ROUTINESCHECK_ROOT="$FIX/new-file" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bar.prompt.md is not in .routines-applied"* ]]
}

@test "routines-check: FAILS when the snapshot references a routine file no longer on disk" {
  run env ROUTINESCHECK_ROOT="$FIX/deleted-file" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gone.prompt.md is in .routines-applied but no longer on disk"* ]]
}

@test "routines-check: passes (short-circuits) when there is no routines/ directory" {
  tmp="$(mktemp -d)"
  run env ROUTINESCHECK_ROOT="$tmp" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  rm -rf "$tmp"
}

@test "routines-check: passes on the real repo's routines/ + .routines-applied" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Makefile wiring ----------------------------------------------------------
@test "Makefile declares a routines-check target invoking routines-check.sh" {
  run grep -A1 '^routines-check:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"routines-check.sh"* ]]
}

@test "Makefile ci target runs routines-check.sh" {
  run grep -q "routines-check.sh" "$REPO/Makefile"
  [ "$status" -eq 0 ]
}
