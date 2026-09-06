#!/usr/bin/env bats
# Tests for scripts/dependency-exit-runbooks-sync-check.sh — the two mechanical
# drift guards docs/dependency-exit-runbooks.md's own "Keeping this in sync"
# section names: phase 1 is concentration.md <-> exit-runbooks.md group coverage
# (guarded since 2026-09-02/03); phase 2 is register.md <-> exit-runbooks.md
# single-tool-row coverage (added 2026-09-06 after that exact gap recurred once
# already — see the script's own header comment). Fixture trees live at
# tests/fixtures/dependency-exit-runbooks-sync-check/{in-sync,drift,register-drift,missing-register}/.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/dependency-exit-runbooks-sync-check"
}

@test "dependency-exit-runbooks-sync-check: passes when every concentration group and register row has a runbook mention" {
  run env DEPRUNBOOKCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/some-org"* ]]
  [[ "$output" == *"Tool C is mentioned"* ]]
}

@test "dependency-exit-runbooks-sync-check: FAILS (exit 1) when a concentration group has no matching runbook section" {
  run env DEPRUNBOOKCHECK_ROOT="$FIX/drift" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"github.com/some-org is a named concentration group"* ]]
  [[ "$output" == *"NO matching section"* ]]
}

@test "dependency-exit-runbooks-sync-check: FAILS (exit 1) when a register single-tool row has no matching runbook mention" {
  run env DEPRUNBOOKCHECK_ROOT="$FIX/register-drift" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Tool C is a row in dependency-register.md's table"* ]]
  [[ "$output" == *"NOT mentioned anywhere"* ]]
  # phase 1 (the concentration group) is unaffected by this fixture's drift
  [[ "$output" == *"github.com/some-org has a runbook section"* ]]
}

@test "dependency-exit-runbooks-sync-check: fails loudly when docs/dependency-concentration.md is missing" {
  run env DEPRUNBOOKCHECK_ROOT="$BATS_TEST_TMPDIR" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"dependency-concentration.md not found"* ]]
}

@test "dependency-exit-runbooks-sync-check: fails loudly when docs/dependency-register.md is missing" {
  run env DEPRUNBOOKCHECK_ROOT="$FIX/missing-register" bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"dependency-register.md not found"* ]]
}

@test "dependency-exit-runbooks-sync-check: passes on the real repo (both concentration groups and all 32 register rows have runbooks)" {
  run bash "$REPO/scripts/dependency-exit-runbooks-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/grafana"* ]]
  [[ "$output" == *"github.com/argoproj"* ]]
  [[ "$output" == *"Kyverno is mentioned"* ]]
  [[ "$output" == *"s3manager is mentioned"* ]]
}
