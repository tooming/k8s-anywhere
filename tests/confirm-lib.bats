#!/usr/bin/env bats
# Clusterless structural + functional tests for scripts/lib/confirm.sh — the
# shared "type-to-confirm" destructive-action gate extracted from
# near-identical inline copies in scripts/dr-chaos.sh, scripts/dr-destroy.sh,
# scripts/dr-test.sh, and scripts/dr-bluegreen-promote.sh (janitor cleanup,
# mirrors the earlier scripts/lib/colors.sh / scripts/lib/budget-check.sh
# extractions). Guards against the duplicate pattern creeping back in as new
# destructive DR scripts get added.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  source "$REPO/scripts/lib/colors.sh"
  source "$REPO/scripts/lib/confirm.sh"
}

@test "scripts/lib/confirm.sh exists" {
  [ -f "$REPO/scripts/lib/confirm.sh" ]
}

@test "confirm.sh defines confirm_or_abort()" {
  run grep -q "^confirm_or_abort()" "$REPO/scripts/lib/confirm.sh"
  [ "$status" -eq 0 ]
}

@test "confirm.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/confirm.sh"
  [ "$status" -eq 0 ]
}

@test "confirm_or_abort() is a no-op and returns 0 when DR_ASSUME_YES=1" {
  DR_ASSUME_YES=1 run confirm_or_abort "should not print" "word"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "confirm_or_abort() refuses non-interactively without DR_ASSUME_YES=1" {
  run env -u DR_ASSUME_YES bash -c '
    source "'"$REPO"'/scripts/lib/colors.sh"
    source "'"$REPO"'/scripts/lib/confirm.sh"
    confirm_or_abort "warning message" "word"
  ' </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"warning message"* ]]
  [[ "$output" == *"Refusing non-interactively without DR_ASSUME_YES=1."* ]]
}

@test "confirm_or_abort() defaults the prompt verb to 'to continue' when omitted" {
  run grep -q 'verb="\${3:-to continue}"' "$REPO/scripts/lib/confirm.sh"
  [ "$status" -eq 0 ]
}

# --- recurrence guard: no destructive script re-inlines the duplicated ------
# pattern. Every scripts/*.sh that hand-checks DR_ASSUME_YES for a
# "Type '...' to ..." read -r -p confirmation must source lib/confirm.sh
# rather than re-declaring its own copy inline.
@test "every script with a 'Type ... to' confirmation prompt sources lib/confirm.sh" {
  hits=""
  for f in "$REPO"/scripts/*.sh; do
    grep -q "Type '" "$f" || continue
    grep -q 'lib/confirm\.sh' "$f" || hits="$hits $f"
  done
  [ -z "$hits" ]
}

@test "dr-chaos.sh, dr-destroy.sh, dr-test.sh, and dr-bluegreen-promote.sh all source lib/confirm.sh" {
  for f in dr-chaos.sh dr-destroy.sh dr-test.sh dr-bluegreen-promote.sh; do
    run grep -q 'lib/confirm.sh' "$REPO/scripts/$f"
    [ "$status" -eq 0 ]
  done
}
