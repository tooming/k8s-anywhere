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
  # github.com/grafana was removed from the register + concentration.md 2026-09-06
  # (ADR-0041, observability stack removed with no replacement) — no longer a live
  # concentration group, so it's no longer expected in this check's output.
  [[ "$output" == *"github.com/argoproj"* ]]
  [[ "$output" == *"stated count"* ]]
}

# Reverse-direction check (2026-09-03, JANITOR-fallback): a concentration.md group
# whose stated count has drifted from the register's real row count, in either
# direction — closes the gap this script's own header comment named as open since
# it first landed (#1379).

@test "dependency-concentration-sync-check: FAILS when a concentration.md group has dropped below the 2-row threshold" {
  run env DEPCONCCHECK_ROOT="$FIX/reverse-stale" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"github.com/some-org is named as a concentration group"* ]]
  [[ "$output" == *"backs only 1 row(s)"* ]]
  [[ "$output" == *"below the 2-row threshold"* ]]
}

@test "dependency-concentration-sync-check: FAILS when a concentration.md group's stated count no longer matches the register" {
  run env DEPCONCCHECK_ROOT="$FIX/reverse-mismatch" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"github.com/some-org's stated count in dependency-concentration.md (2 tools)"* ]]
  [[ "$output" == *"real row count (3)"* ]]
}

@test "dependency-concentration-sync-check: passes when a concentration.md group's stated count matches the register exactly" {
  run env DEPCONCCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"github.com/some-org's stated count (2 tools) matches"* ]]
}
