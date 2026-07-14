#!/usr/bin/env bats
# Clusterless structural tests for the blue/green DR scripts and Makefile targets.
# No running cluster required — these verify declared structure, key thresholds, and
# wiring without executing any live command. Pattern mirrors tests/dr-restore.bats.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DRSCRIPT="$REPO/scripts/dr-bluegreen.sh"
  UPSCRIPT="$REPO/scripts/bluegreen-up.sh"
  FRONTDOOR="$REPO/scripts/bluegreen-frontdoor.sh"
  DOWNSCRIPT="$REPO/scripts/bluegreen-down.sh"
  PROBESCRIPT="$REPO/scripts/bluegreen-probe.sh"
  PROMOTE="$REPO/scripts/dr-bluegreen-promote.sh"
}

# --- Script existence + permissions ------------------------------------------

@test "dr-bluegreen.sh exists" {
  [ -f "$DRSCRIPT" ]
}

@test "dr-bluegreen.sh is executable" {
  [ -x "$DRSCRIPT" ]
}

@test "bluegreen-up.sh exists" {
  [ -f "$UPSCRIPT" ]
}

@test "bluegreen-up.sh is executable" {
  [ -x "$UPSCRIPT" ]
}

@test "bluegreen-frontdoor.sh exists" {
  [ -f "$FRONTDOOR" ]
}

@test "bluegreen-frontdoor.sh is executable" {
  [ -x "$FRONTDOOR" ]
}

@test "bluegreen-down.sh exists" {
  [ -f "$DOWNSCRIPT" ]
}

@test "bluegreen-down.sh is executable" {
  [ -x "$DOWNSCRIPT" ]
}

@test "bluegreen-probe.sh exists" {
  [ -f "$PROBESCRIPT" ]
}

@test "bluegreen-probe.sh is executable" {
  [ -x "$PROBESCRIPT" ]
}

@test "dr-bluegreen-promote.sh exists" {
  [ -f "$PROMOTE" ]
}

@test "dr-bluegreen-promote.sh is executable" {
  [ -x "$PROMOTE" ]
}

# --- Pass thresholds (must not drift silently) --------------------------------

@test "dr-bluegreen.sh defines MIN_UPTIME default of 99.0" {
  run grep -q 'MIN_UPTIME.*99\.0' "$DRSCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen.sh defines MAX_OUTAGE default of 2.0" {
  run grep -q 'MAX_OUTAGE.*2\.0' "$DRSCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen-promote.sh defines MIN_UPTIME default of 99.0" {
  run grep -q 'MIN_UPTIME.*99\.0' "$PROMOTE"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen-promote.sh defines MAX_OUTAGE default of 2.0" {
  run grep -q 'MAX_OUTAGE.*2\.0' "$PROMOTE"
  [ "$status" -eq 0 ]
}

# --- Green app-of-apps root manifest referenced in bluegreen-up.sh -----------

@test "gitops/bluegreen/green-root.yaml exists" {
  [ -f "$REPO/gitops/bluegreen/green-root.yaml" ]
}

@test "bluegreen-up.sh references gitops/bluegreen/green-root.yaml" {
  run grep -q 'gitops/bluegreen/green-root.yaml' "$UPSCRIPT"
  [ "$status" -eq 0 ]
}

# --- Sub-script delegation (orchestrator wires the right helpers) -------------

@test "dr-bluegreen.sh delegates to bluegreen-frontdoor.sh" {
  run grep -q 'bluegreen-frontdoor.sh' "$DRSCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen.sh delegates to bluegreen-up.sh" {
  run grep -q 'bluegreen-up.sh' "$DRSCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen.sh delegates to bluegreen-probe.sh" {
  run grep -q 'bluegreen-probe.sh' "$DRSCRIPT"
  [ "$status" -eq 0 ]
}

@test "bluegreen-down.sh delegates to bluegreen-frontdoor.sh" {
  run grep -q 'bluegreen-frontdoor.sh' "$DOWNSCRIPT"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen-promote.sh delegates to bluegreen-frontdoor.sh" {
  run grep -q 'bluegreen-frontdoor.sh' "$PROMOTE"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen-promote.sh delegates to bluegreen-up.sh" {
  run grep -q 'bluegreen-up.sh' "$PROMOTE"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen-promote.sh delegates to bluegreen-probe.sh" {
  run grep -q 'bluegreen-probe.sh' "$PROMOTE"
  [ "$status" -eq 0 ]
}

# --- Non-interactive safety guard in promote script --------------------------

@test "dr-bluegreen-promote.sh refuses non-interactive run without DR_ASSUME_YES=1" {
  run grep -q 'DR_ASSUME_YES' "$PROMOTE"
  [ "$status" -eq 0 ]
}

@test "dr-bluegreen-promote.sh exits non-zero when run non-interactively without guard" {
  run grep -q 'Refusing non-interactively' "$PROMOTE"
  [ "$status" -eq 0 ]
}

# --- Makefile targets wired correctly ----------------------------------------

@test "Makefile defines dr-bluegreen target" {
  run grep -q '^dr-bluegreen:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile dr-bluegreen target invokes dr-bluegreen.sh" {
  run grep -A1 '^dr-bluegreen:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dr-bluegreen.sh"* ]]
}

@test "Makefile dr-bluegreen .PHONY is declared" {
  run grep -q '\.PHONY: dr-bluegreen$' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile defines dr-bluegreen-down target" {
  run grep -q '^dr-bluegreen-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile dr-bluegreen-down target invokes bluegreen-down.sh" {
  run grep -A1 '^dr-bluegreen-down:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bluegreen-down.sh"* ]]
}

@test "Makefile dr-bluegreen-down .PHONY is declared" {
  run grep -q '\.PHONY: dr-bluegreen-down' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile defines dr-bluegreen-promote target" {
  run grep -q '^dr-bluegreen-promote:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "Makefile dr-bluegreen-promote target invokes dr-bluegreen-promote.sh" {
  run grep -A1 '^dr-bluegreen-promote:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dr-bluegreen-promote.sh"* ]]
}

@test "Makefile dr-bluegreen-promote .PHONY is declared" {
  run grep -q '\.PHONY: dr-bluegreen-promote' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}
