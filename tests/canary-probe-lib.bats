#!/usr/bin/env bats
# Clusterless structural + functional tests for scripts/lib/canary-probe.sh —
# the shared blue/green DR-drill availability-check helpers extracted from
# near-identical inline copies in scripts/dr-bluegreen.sh and
# scripts/dr-bluegreen-promote.sh (janitor cleanup, mirrors the earlier
# scripts/lib/colors.sh / scripts/lib/budget-check.sh / scripts/lib/confirm.sh
# extractions). Named canary-probe.sh, NOT bluegreen-probe.sh, to avoid a
# basename collision with the pre-existing scripts/bluegreen-probe.sh (a
# different script — the actual background curl-loop probe process this
# lib's probe() one-shot check complements).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  source "$REPO/scripts/lib/canary-probe.sh"
}

@test "scripts/lib/canary-probe.sh exists" {
  [ -f "$REPO/scripts/lib/canary-probe.sh" ]
}

@test "canary-probe.sh defines probe() and stop_probe()" {
  run grep -q '^probe()' "$REPO/scripts/lib/canary-probe.sh"
  [ "$status" -eq 0 ]
  run grep -q '^stop_probe()' "$REPO/scripts/lib/canary-probe.sh"
  [ "$status" -eq 0 ]
}

@test "canary-probe.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/canary-probe.sh"
  [ "$status" -eq 0 ]
}

@test "probe(): reports failure (no '200') when the front door is unreachable" {
  # curl's -w '%{http_code}' writes "000" on total connection failure, and
  # its own non-zero exit additionally triggers the "|| echo 000" fallback
  # (pre-existing behavior of the exact copied one-liner, unchanged by this
  # extraction) — so the output is "000000", not "000". Either way it's never
  # "200", which is the only thing every real call site actually checks.
  CANARY_HOST="example.invalid" FRONTDOOR_PORT="1" run probe
  [ "$status" -eq 0 ]
  [ "$output" != "200" ]
  [[ "$output" == *"000"* ]]
}

@test "stop_probe(): is a safe no-op when PROBE_PID is empty" {
  PROBE_PID="" run stop_probe
  [ "$status" -eq 0 ]
}

@test "stop_probe(): terminates the process named by PROBE_PID" {
  sleep 30 &
  PROBE_PID=$!
  run stop_probe
  [ "$status" -eq 0 ]
  # give the TERM signal a moment to land, then confirm the process is gone
  sleep 0.2
  ! kill -0 "$PROBE_PID" 2>/dev/null
}

# --- recurrence guard: no script re-inlines the duplicated pattern ----------
# scripts/*.sh only (not scripts/lib/*.sh, which is where the shared copy
# legitimately lives) — mirrors the non-recursive glob budget-check-lib.bats
# uses for the same reason.
@test "no script under scripts/*.sh re-inlines probe()/stop_probe() (source lib/canary-probe.sh instead)" {
  run grep -l '^probe(){' "$REPO"/scripts/*.sh
  [ "$status" -ne 0 ]
  run grep -l '^stop_probe(){' "$REPO"/scripts/*.sh
  [ "$status" -ne 0 ]
}

@test "dr-bluegreen.sh and dr-bluegreen-promote.sh both source lib/canary-probe.sh" {
  run grep -q 'lib/canary-probe.sh' "$REPO/scripts/dr-bluegreen.sh"
  [ "$status" -eq 0 ]
  run grep -q 'lib/canary-probe.sh' "$REPO/scripts/dr-bluegreen-promote.sh"
  [ "$status" -eq 0 ]
}
