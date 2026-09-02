#!/usr/bin/env bats
# Tests for scripts/dependency-concentration-sync-check.sh — the register <->
# concentration.md mechanical drift guard (DORA Q14/Q16/Q17 "no mechanical drift
# guard yet" gap). Fixture trees live at tests/fixtures/
# dependency-concentration-sync-check/{in-sync,drift}/.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/dependency-concentration-sync-check"
}

@test "dependency-concentration-sync-check: passes when every 2+-row org is named" {
  run env DEPCONCCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/some-org"* ]]
}

@test "dependency-concentration-sync-check: FAILS (exit 1) when a 2+-row org is missing from concentration.md" {
  run env DEPCONCCHECK_ROOT="$FIX/drift" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"github.com/some-org backs 2 rows"* ]]
  [[ "$output" == *"NOT named"* ]]
}

@test "dependency-concentration-sync-check: a single-row org is never flagged (not a concentration point)" {
  run env DEPCONCCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [[ "$output" != *"other-org"* ]]
}

@test "dependency-concentration-sync-check: fails loudly when docs/dependency-register.md is missing" {
  run env DEPCONCCHECK_ROOT="$BATS_TEST_TMPDIR" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"dependency-register.md not found"* ]]
}

@test "dependency-concentration-sync-check: passes on the real repo (register in sync with concentration.md)" {
  run bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/grafana"* ]]
  [[ "$output" == *"github.com/argoproj"* ]]
  [[ "$output" == *"github.com/pingcap"* ]]
}
