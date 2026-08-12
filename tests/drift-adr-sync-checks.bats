#!/usr/bin/env bats
# Tests for the ADR governance drift checks — split out of the now-frozen
# tests/drift-detectors.bats monolith (see that file's header comment) into
# its own scope, per the drift-detectors-tests-check convention: new
# drift-check coverage goes in its own tests/drift-<scope>.bats file. Grouped
# together here because all three guard the same governance surface —
# docs/decisions/ ADRs staying honest about their own stated claims (no stale
# "Follow-up:" promise, no self-tracking chart-version/image-pin note that has
# drifted from the live gitops manifest it describes).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- adr-followup-check ----------------------------------------------------------
@test "adr-followup-check: passes when no governance doc carries a Follow-up note" {
  run env ADRFOLLOWUPCHECK_ROOT="$FIX/adr-followup-check/in-sync" bash "$REPO/scripts/adr-followup-check.sh"
  [ "$status" -eq 0 ]
}

@test "adr-followup-check: fails on an unchecked Follow-up note in an ADR" {
  run env ADRFOLLOWUPCHECK_ROOT="$FIX/adr-followup-check/drift-adr" bash "$REPO/scripts/adr-followup-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Follow-up"* ]]
}

@test "adr-followup-check: fails on an unchecked Follow-up note in CHARTER.md" {
  run env ADRFOLLOWUPCHECK_ROOT="$FIX/adr-followup-check/drift-charter" bash "$REPO/scripts/adr-followup-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"CHARTER.md"* ]]
}

@test "adr-followup-check: fails on a '(follow-up item)' table-cell annotation in an ADR" {
  run env ADRFOLLOWUPCHECK_ROOT="$FIX/adr-followup-check/drift-adr-parenthetical" bash "$REPO/scripts/adr-followup-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"follow-up item"* ]]
}

@test "adr-followup-check: passes on the real repo's ADRs/CHARTER.md/WAYS-OF-WORKING.md" {
  run bash "$REPO/scripts/adr-followup-check.sh"
  [ "$status" -eq 0 ]
}

# --- adr-chart-version-sync-check --------------------------------------------------
@test "adr-chart-version-sync-check: passes when a self-tracking ADR matches its live gitops pin" {
  run env ADRCHARTVERSIONCHECK_ROOT="$FIX/adr-chart-version-sync/in-sync" bash "$REPO/scripts/adr-chart-version-sync-check.sh"
  [ "$status" -eq 0 ]
}

@test "adr-chart-version-sync-check: fails when a self-tracking ADR's chart version no longer matches the live gitops pin" {
  run env ADRCHARTVERSIONCHECK_ROOT="$FIX/adr-chart-version-sync/drift" bash "$REPO/scripts/adr-chart-version-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Chart + version says"* ]]
}

@test "adr-chart-version-sync-check: ignores an ADR using the point-in-time (non-self-tracking) phrasing" {
  run env ADRCHARTVERSIONCHECK_ROOT="$FIX/adr-chart-version-sync/no-self-tracking" bash "$REPO/scripts/adr-chart-version-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no ADR uses the self-tracking"* ]]
}

@test "adr-chart-version-sync-check: passes on the real repo's ADRs (ADR-0020/0021/0023 match their live pins)" {
  run bash "$REPO/scripts/adr-chart-version-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"adr-0020"* ]]
  [[ "$output" == *"adr-0021"* ]]
  [[ "$output" == *"adr-0023"* ]]
}

# --- adr-image-pin-sync-check -------------------------------------------------------
@test "adr-image-pin-sync-check: passes when a self-tracking ADR matches its live manifest image tag" {
  run env ADRIMAGEPINCHECK_ROOT="$FIX/adr-image-pin-sync/in-sync" bash "$REPO/scripts/adr-image-pin-sync-check.sh"
  [ "$status" -eq 0 ]
}

@test "adr-image-pin-sync-check: fails when a self-tracking ADR's pinned image tag no longer matches the live manifest" {
  run env ADRIMAGEPINCHECK_ROOT="$FIX/adr-image-pin-sync/drift" bash "$REPO/scripts/adr-image-pin-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"says pinned image is"* ]]
}

@test "adr-image-pin-sync-check: ignores an ADR using the point-in-time (non-self-tracking) phrasing" {
  run env ADRIMAGEPINCHECK_ROOT="$FIX/adr-image-pin-sync/no-self-tracking" bash "$REPO/scripts/adr-image-pin-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no ADR uses the self-tracking"* ]]
}

@test "adr-image-pin-sync-check: passes on the real repo's ADRs (ADR-0009/0018 match their live image tags)" {
  run bash "$REPO/scripts/adr-image-pin-sync-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"adr-0009"* ]]
  [[ "$output" == *"adr-0018"* ]]
}

# --- context-doc-version-sync-check -------------------------------------------------
@test "context-doc-version-sync-check: passes when context.md's citations match the live gitops pins" {
  run env CONTEXTDOCCHECK_ROOT="$FIX/context-doc-version-sync/in-sync" bash "$REPO/scripts/context-doc-version-sync-check.sh"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-check: fails when context.md's Grafana citation no longer matches the live image tag" {
  run env CONTEXTDOCCHECK_ROOT="$FIX/context-doc-version-sync/drift" bash "$REPO/scripts/context-doc-version-sync-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"context.md says"* ]]
}

@test "context-doc-version-sync-check: passes on the real repo's context.md (Grafana/Pyroscope/KRO all match their live pins)" {
  run bash "$REPO/scripts/context-doc-version-sync-check.sh"
  [ "$status" -eq 0 ]
}
