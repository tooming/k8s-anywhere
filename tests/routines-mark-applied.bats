#!/usr/bin/env bats
# Coverage for scripts/routines-mark-applied.sh (`make routines-mark-applied`) —
# the counterpart to routines-check.sh's drift check. Previously had zero bats
# coverage: routines-check.bats covers the reader/comparator, nothing covered the
# writer that produces .routines-applied in the first place. Mirrors the
# ROUTINESCHECK_ROOT fixture-tree pattern: ROUTINESMARKAPPLIED_ROOT points the
# script at a scratch copy of tests/fixtures/routines-mark-applied/basic, never
# the real repo, so no scenario here touches the real .routines-applied.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/routines-mark-applied.sh"
  FIX="$REPO/tests/fixtures/routines-mark-applied/basic"
  TMP="$(mktemp -d)"
  cp -R "$FIX/routines" "$TMP/"
}

teardown() {
  rm -rf "$TMP"
}

@test "routines-mark-applied.sh exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "routines-mark-applied.sh writes .routines-applied with the documented header" {
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$TMP/.routines-applied" ]
  run grep -q '^# .routines-applied — sha256 of routines/routines.yaml at last apply.$' "$TMP/.routines-applied"
  [ "$status" -eq 0 ]
  run grep -q 'scripts/routines-mark-applied.sh' "$TMP/.routines-applied"
  [ "$status" -eq 0 ]
  run grep -q 'scripts/routines-check.sh' "$TMP/.routines-applied"
  [ "$status" -eq 0 ]
}

@test "routines-mark-applied.sh records the correct sha256 for routines.yaml" {
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  expected_yaml="$(shasum -a 256 "$TMP/routines/routines.yaml" | awk '{print $1}')"
  run grep -q "routines/routines.yaml sha256=$expected_yaml" "$TMP/.routines-applied"
  [ "$status" -eq 0 ]
}

@test "routines-mark-applied.sh does NOT track routines/*.prompt.md (pointer architecture — read live, never baked)" {
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q "executor.prompt.md" "$TMP/.routines-applied"
  [ "$status" -eq 1 ]
}

@test "routines-mark-applied.sh output round-trips clean through routines-check.sh" {
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run env ROUTINESCHECK_ROOT="$TMP" bash "$REPO/scripts/routines-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-check.sh does NOT flag drift when only a *.prompt.md file changes" {
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "edited" >> "$TMP/routines/executor.prompt.md"
  run env ROUTINESCHECK_ROOT="$TMP" bash "$REPO/scripts/routines-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-mark-applied.sh detects drift after routines.yaml is re-marked following an edit" {
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "# edited" >> "$TMP/routines/routines.yaml"
  run env ROUTINESCHECK_ROOT="$TMP" bash "$REPO/scripts/routines-check.sh"
  [ "$status" -eq 1 ]
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run env ROUTINESCHECK_ROOT="$TMP" bash "$REPO/scripts/routines-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-mark-applied.sh does not touch the real .routines-applied" {
  before="$(shasum -a 256 "$REPO/.routines-applied" | awk '{print $1}')"
  run env ROUTINESMARKAPPLIED_ROOT="$TMP" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  after="$(shasum -a 256 "$REPO/.routines-applied" | awk '{print $1}')"
  [ "$before" = "$after" ]
}
