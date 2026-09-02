#!/usr/bin/env bats
# Tests for scripts/dependency-maintenance-check.sh — the DORA-Q15 maintenance-
# health report (docs/dora-audit-readiness.md). Resolved offline via a stub
# resolver (DEPMAINT_RESOLVER) so the suite never hits the network, mirroring
# tests/drift-gitops-manifest-checks.bats's CHARTPIN_RESOLVER pattern. Fixture
# register lives at tests/fixtures/dependency-maintenance-check/docs/
# dependency-register.md.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/dependency-maintenance-check"
}

@test "dependency-maintenance-check: passes and reports a fresh dependency" {
  run env DEPMAINT_ROOT="$FIX" DEPMAINT_RESOLVER="$FIX/resolver-stub.sh" \
          bash "$REPO/scripts/dependency-maintenance-check.sh" --stale-days 365
  [[ "$output" == *"Fresh Tool"* ]]
  [[ "$output" == *"last commit 5d ago"* ]]
}

@test "dependency-maintenance-check: FAILS (exit 1) and flags a dependency past the stale-day window" {
  run env DEPMAINT_ROOT="$FIX" DEPMAINT_RESOLVER="$FIX/resolver-stub.sh" \
          bash "$REPO/scripts/dependency-maintenance-check.sh" --stale-days 365
  [ "$status" -eq 1 ]
  [[ "$output" == *"Stale Tool"* ]]
  [[ "$output" == *"no commit in 500d"* ]]
}

@test "dependency-maintenance-check: SKIPS (does not fail on its own) a row with no github.com source" {
  run env DEPMAINT_ROOT="$FIX" DEPMAINT_RESOLVER="$FIX/resolver-stub.sh" \
          bash "$REPO/scripts/dependency-maintenance-check.sh" --stale-days 365
  [[ "$output" == *"No-Repo Tool: no github.com upstream source in the register — skipped"* ]]
}

@test "dependency-maintenance-check: SKIPS (does not fail) an unreachable repo" {
  run env DEPMAINT_ROOT="$FIX" DEPMAINT_RESOLVER="$FIX/resolver-stub.sh" \
          bash "$REPO/scripts/dependency-maintenance-check.sh" --stale-days 365
  [[ "$output" == *"Unreachable Tool: github.com/example-org/gone-tool unreachable — skipped"* ]]
}

@test "dependency-maintenance-check: passes cleanly (exit 0) when the stale-day window is wide enough" {
  run env DEPMAINT_ROOT="$FIX" DEPMAINT_RESOLVER="$FIX/resolver-stub.sh" \
          bash "$REPO/scripts/dependency-maintenance-check.sh" --stale-days 10000
  [ "$status" -eq 0 ]
  [[ "$output" == *"no dependency exceeds"* ]]
}

@test "dependency-maintenance-check: fails loudly when docs/dependency-register.md is missing" {
  run env DEPMAINT_ROOT="$BATS_TEST_TMPDIR" DEPMAINT_RESOLVER="$FIX/resolver-stub.sh" \
          bash "$REPO/scripts/dependency-maintenance-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}
