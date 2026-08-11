#!/usr/bin/env bats
# Coverage for scripts/lib/dr-results-log.sh (docs/dora-audit-readiness.md Q13's
# gap: pass/fail is enforced by exit codes but there was no historical log of
# past run results over time). Clusterless, structural + a scratch-dir
# functional round-trip — mirrors tests/budget-check-lib.bats's shape for the
# lib itself, plus grep-based wiring assertions per script (mirrors
# tests/hook-scripts-*.bats's style).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  source "$REPO/scripts/lib/colors.sh"
  source "$REPO/scripts/lib/dr-results-log.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

# --- lib itself ---------------------------------------------------------

@test "scripts/lib/dr-results-log.sh exists" {
  [ -f "$REPO/scripts/lib/dr-results-log.sh" ]
}

@test "dr-results-log.sh defines dr_log_result()" {
  run grep -q "^dr_log_result()" "$REPO/scripts/lib/dr-results-log.sh"
  [ "$status" -eq 0 ]
}

@test "dr-results-log.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/dr-results-log.sh"
  [ "$status" -eq 0 ]
}

# --- functional: scratch-dir round-trip ---------------------------------

@test "dr_log_result() creates the log with a header on first write" {
  LOG="$TMP/dr-results-log.md"
  DR_RESULTS_LOG="$LOG" dr_log_result "dr-restore.sh" "PASS" "120" "600" "O3"
  [ -f "$LOG" ]
  run grep -q '| Date (UTC) | Script | Status | Elapsed (s) | Budget (s) | Objective |' "$LOG"
  [ "$status" -eq 0 ]
  run grep -q '| dr-restore.sh | PASS | 120 | 600 | O3 |' "$LOG"
  [ "$status" -eq 0 ]
}

@test "dr_log_result() appends a well-formed row for a FAIL result" {
  LOG="$TMP/dr-results-log.md"
  DR_RESULTS_LOG="$LOG" dr_log_result "dr-chaos.sh" "FAIL" "125" "120" "chaos"
  run grep -q '| dr-chaos.sh | FAIL | 125 | 120 | chaos |' "$LOG"
  [ "$status" -eq 0 ]
}

@test "dr_log_result() called twice grows the file by exactly two rows under a single header (no header re-write)" {
  LOG="$TMP/dr-results-log.md"
  DR_RESULTS_LOG="$LOG" dr_log_result "dr-restore.sh" "PASS" "100" "600" "O3"
  DR_RESULTS_LOG="$LOG" dr_log_result "capstone-demo.sh" "PASS" "200" "900" "O6"

  header_count=$(grep -c '| Date (UTC) | Script | Status | Elapsed (s) | Budget (s) | Objective |' "$LOG")
  [ "$header_count" -eq 1 ]

  row_count=$(grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$LOG")
  [ "$row_count" -eq 2 ]
}

@test "dr_log_result() row date is a real UTC ISO-8601 timestamp" {
  LOG="$TMP/dr-results-log.md"
  DR_RESULTS_LOG="$LOG" dr_log_result "dr-bluegreen.sh" "PASS" "45" "300" "bluegreen"
  run grep -E '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| dr-bluegreen\.sh \|' "$LOG"
  [ "$status" -eq 0 ]
}

# --- wiring: every DR/capstone-demo script logs on both its pass and fail
# exit paths, per this item's own contract, so a real run is never dropped ---

@test "dr-restore.sh sources lib/dr-results-log.sh and calls dr_log_result on both PASS and FAIL" {
  run grep -q 'lib/dr-results-log.sh' "$REPO/scripts/dr-restore.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "dr-restore.sh" "PASS"' "$REPO/scripts/dr-restore.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "dr-restore.sh" "FAIL"' "$REPO/scripts/dr-restore.sh"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen.sh sources lib/dr-results-log.sh and calls dr_log_result on both PASS and FAIL" {
  run grep -q 'lib/dr-results-log.sh' "$REPO/scripts/dr-bluegreen.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "dr-bluegreen.sh" "PASS"' "$REPO/scripts/dr-bluegreen.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "dr-bluegreen.sh" "FAIL"' "$REPO/scripts/dr-bluegreen.sh"
  [ "$status" -eq 0 ]
}

@test "dr-chaos.sh sources lib/dr-results-log.sh and calls dr_log_result on both PASS and FAIL" {
  run grep -q 'lib/dr-results-log.sh' "$REPO/scripts/dr-chaos.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "dr-chaos.sh" "PASS"' "$REPO/scripts/dr-chaos.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "dr-chaos.sh" "FAIL"' "$REPO/scripts/dr-chaos.sh"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh sources lib/dr-results-log.sh and calls dr_log_result on both PASS and FAIL" {
  run grep -q 'lib/dr-results-log.sh' "$REPO/scripts/capstone-demo.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "capstone-demo.sh" "PASS"' "$REPO/scripts/capstone-demo.sh"
  [ "$status" -eq 0 ]
  run grep -q 'dr_log_result "capstone-demo.sh" "FAIL"' "$REPO/scripts/capstone-demo.sh"
  [ "$status" -eq 0 ]
}

# --- the real docs/dr-results-log.md ships as an empty table (header only) —
# this remote clusterless session cannot generate a real logged run
# (ADR-0004); an empty/near-empty log is truthful, not a placeholder ---------

@test "docs/dr-results-log.md exists, links from docs/DR.md, and has no fabricated rows" {
  [ -f "$REPO/docs/dr-results-log.md" ]
  run grep -q '| Date (UTC) | Script | Status | Elapsed (s) | Budget (s) | Objective |' "$REPO/docs/dr-results-log.md"
  [ "$status" -eq 0 ]
  run grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$REPO/docs/dr-results-log.md"
  [ "$output" = "0" ]
  run grep -q 'dr-results-log.md' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
}
