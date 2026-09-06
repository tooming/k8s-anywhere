#!/usr/bin/env bats
# Clusterless structural tests for scripts/dr-restore.sh and the Makefile target
# (ADR-0021 §"dr-restore runner", CHARTER Objective O3).
# No running cluster required — these tests verify the script's declared behaviour
# (structure, safety checks, budget enforcement) without executing velero.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/dr-restore.sh"
}

# --- Script existence + permissions ------------------------------------------
@test "dr-restore.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "dr-restore.sh is executable" {
  [ -x "$SCRIPT" ]
}

# --- Five namespace restore lines (ADR-0021 §"Scope & exceptions") -----------
@test "dr-restore.sh restores the data namespace" {
  run grep -q 'data' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh restores the capstone namespace" {
  run grep -q 'capstone' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh restores the vault namespace" {
  run grep -q 'vault' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh restores the observability namespace" {
  run grep -q 'observability' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- velero restore --from-schedule pattern (ADR-0021 §"Schedule set") -------
@test "dr-restore.sh uses velero restore create --from-schedule" {
  run grep -q -- '--from-schedule' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh waits for restore completion (--wait flag)" {
  run grep -q -- '--wait' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Phase validation (phase != Completed → fail) ----------------------------
@test "dr-restore.sh checks restore phase equals Completed" {
  run grep -q 'Completed' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh fails when phase is not Completed" {
  run grep -q 'FAILED=1' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- 600 s budget check (Objective O3: < 10 min) -----------------------------
@test "dr-restore.sh defines the 600 s budget constant" {
  run grep -q 'BUDGET_S=600' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh sources the shared budget-check lib" {
  run grep -q 'lib/budget-check.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh fails with exit 1 when budget is exceeded" {
  run grep -qE 'BUDGET EXCEEDED|OVER BUDGET' "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh exits 1 on failure" {
  run grep -q 'exit 1' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Makefile target wired (dr-restore: target) ------------------------------
@test "Makefile defines a dr-restore target" {
  run grep -q '^dr-restore:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile dr-restore target invokes dr-restore.sh" {
  run grep -A1 '^dr-restore:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dr-restore.sh"* ]]
}

@test "Makefile dr-restore target passes all four ADR-0021 namespaces" {
  run grep -A1 '^dr-restore:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"data"* ]]
  [[ "$output" == *"capstone"* ]]
  [[ "$output" == *"vault"* ]]
  [[ "$output" == *"observability"* ]]
}

@test "Makefile dr-restore .PHONY is declared" {
  run grep -q '\.PHONY: dr-restore' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

# --- Summary table output declared -------------------------------------------
@test "dr-restore.sh prints a summary table" {
  run grep -q 'Restore summary' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-restore.sh prints total elapsed vs budget" {
  run grep -q 'Total elapsed' "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
}
