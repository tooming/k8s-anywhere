#!/usr/bin/env bats
# Tests for scripts/dependency-exit-runbooks-sync-check.sh — the concentration.md
# <-> exit-runbooks.md mechanical drift guard (the second half of DORA Q17's "no
# mechanical drift guard yet" gap; the first half, register <-> concentration.md,
# is tests/dependency-concentration-sync-check.bats). Fixture trees live at
# tests/fixtures/dependency-exit-runbooks-sync-check/{in-sync,drift}/.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/dependency-exit-runbooks-sync-check"
}

@test "dependency-exit-runbooks-sync-check: passes when every concentration group has a runbook section" {
  run env DEPRUNBOOKCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/some-org"* ]]
}

@test "dependency-exit-runbooks-sync-check: FAILS (exit 1) when a concentration group has no matching runbook section" {
  run env DEPRUNBOOKCHECK_ROOT="$FIX/drift" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"github.com/some-org is a named concentration group"* ]]
  [[ "$output" == *"NO matching section"* ]]
}

@test "dependency-exit-runbooks-sync-check: fails loudly when docs/dependency-concentration.md is missing" {
  run env DEPRUNBOOKCHECK_ROOT="$BATS_TEST_TMPDIR" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"dependency-concentration.md not found"* ]]
}

@test "dependency-exit-runbooks-sync-check: passes on the real repo (both concentration groups have runbooks)" {
  run bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/grafana"* ]]
  [[ "$output" == *"github.com/argoproj"* ]]
}
