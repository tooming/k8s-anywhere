#!/usr/bin/env bats
# Clusterless structural tests for scripts/capstone-demo.sh and the Makefile target.
# CHARTER Objective O6 — RFC #215 acceptance criteria.
# No running cluster required: these tests verify script structure and safety
# checks without executing argocd, kubectl, curl, or any live-cluster tool.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/capstone-demo.sh"
  MK="$REPO/Makefile"
}

# --- Script existence + permissions ------------------------------------------

@test "capstone-demo.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "capstone-demo.sh is executable" {
  [ -x "$SCRIPT" ]
}

# --- 900 s budget (Objective O6) ---------------------------------------------

@test "capstone-demo.sh defines the 900 s budget constant" {
  run grep -q 'BUDGET_S=900' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh sources the shared budget-check lib" {
  run grep -q 'lib/budget-check.sh' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh fails when budget is exceeded" {
  run grep -qE 'BUDGET EXCEEDED|OVER BUDGET' "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh exits 1 on failure" {
  run grep -q 'exit 1' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- ArgoCD health check (Step 1) --------------------------------------------

@test "capstone-demo.sh invokes argocd app wait capstone" {
  run grep -q 'argocd app wait capstone' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh uses --health flag for argocd app wait" {
  run grep -q '\-\-health' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh sets a 120 s timeout for argocd app wait" {
  run grep -q '\-\-timeout 120' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- ExternalSecret check (Step 2) -------------------------------------------

@test "capstone-demo.sh checks capstone namespace ExternalSecret" {
  run grep -q 'externalsecret' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh checks ExternalSecret Ready condition" {
  run grep -q 'Ready' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- HTTP 200 check (Step 3) -------------------------------------------------

@test "capstone-demo.sh curls capstone.127.0.0.1.nip.io" {
  run grep -q 'capstone.127.0.0.1.nip.io' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh asserts HTTP 200 response code" {
  run grep -q '"200"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Tempo trace check (Step 4) ----------------------------------------------

@test "capstone-demo.sh port-forwards tempo-query-frontend" {
  run grep -q 'tempo-query-frontend' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh queries Tempo for service.name=capstone" {
  run grep -q 'service.name=capstone' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh uses OS-portable date arithmetic for 5-minute look-back" {
  # Both macOS (-v-5M) and Linux (date +%s - 300) paths must be present
  run grep -q '\-v-5M' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q '300' "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Summary table -----------------------------------------------------------

@test "capstone-demo.sh prints a summary table" {
  run grep -q 'Capstone demo summary' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "capstone-demo.sh prints total elapsed vs budget" {
  run grep -q 'Total elapsed' "$REPO/scripts/lib/budget-check.sh"
  [ "$status" -eq 0 ]
}

# --- Makefile wiring (RFC #215) ----------------------------------------------

@test "Makefile defines a capstone-demo target" {
  run grep -q '^capstone-demo:' "$MK"
  [ "$status" -eq 0 ]
}

@test "Makefile capstone-demo target invokes capstone-demo.sh" {
  run grep -A1 '^capstone-demo:' "$MK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"capstone-demo.sh"* ]]
}

@test "Makefile capstone-demo .PHONY is declared" {
  run grep -q '\.PHONY: capstone-demo' "$MK"
  [ "$status" -eq 0 ]
}
