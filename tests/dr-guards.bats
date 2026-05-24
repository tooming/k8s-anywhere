#!/usr/bin/env bats
# Unit tests for the safety guards on the DESTRUCTIVE scripts. These wipe the
# lab, so the two gates that stand between a typo and a wiped cluster matter:
#   1. an unknown SCOPE is rejected (exit 2) before anything is touched;
#   2. running non-interactively without DR_ASSUME_YES=1 refuses (exit 1).
# Both guards fire before any destroy step, so exercising them is safe here.
# DR_ASSUME_YES is stripped from the env so a stray value can't unlock a wipe.

setup() { REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }

@test "dr-destroy.sh: unknown scope exits 2" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-destroy.sh" bogus </dev/null
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown SCOPE"* ]]
}

@test "dr-destroy.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-destroy.sh" cluster </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-test.sh: unknown scope exits 2" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-test.sh" bogus </dev/null
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown SCOPE"* ]]
}

@test "dr-test.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-test.sh" full </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-bluegreen-promote.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-bluegreen-promote.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}
