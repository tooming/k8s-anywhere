#!/usr/bin/env bats
# Unit tests for bluegreen-probe.sh's summary() — the math behind the
# zero-downtime claim (uptime %, longest outage). If this arithmetic is wrong,
# the DR drill's verdict is wrong. No cluster or network needed: we source the
# script (the probe loop is guarded so it won't run), set the counters by hand,
# and assert the stats it writes.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export PROBE_STATS="$BATS_TEST_TMPDIR/stats"
  export PROBE_LOG="$BATS_TEST_TMPDIR/log"
  export PROBE_INTERVAL="0.3"
  # shellcheck source=/dev/null
  source "$REPO/scripts/bluegreen-probe.sh"
}

stat() { grep "^$1=" "$PROBE_STATS" | cut -d= -f2; }

@test "summary: zero samples does not divide by zero" {
  total=0; ok=0; fail=0; run=0; maxrun=0
  summary >/dev/null
  [ "$(stat uptime_pct)" = "0.00" ]
  [ "$(stat approx_outage_s)" = "0.0" ]
}

@test "summary: perfect run reports 100% uptime and no outage" {
  total=100; ok=100; fail=0; run=0; maxrun=0
  summary >/dev/null
  [ "$(stat uptime_pct)" = "100.00" ]
  [ "$(stat approx_outage_s)" = "0.0" ]
}

@test "summary: partial failures compute uptime% and outage from interval" {
  total=100; ok=97; fail=3; run=0; maxrun=3
  summary >/dev/null
  [ "$(stat uptime_pct)" = "97.00" ]      # 97/100
  [ "$(stat max_consec_fail)" = "3" ]
  [ "$(stat approx_outage_s)" = "0.9" ]   # 3 * 0.3s interval
}

@test "summary: uptime% is rounded to two decimals" {
  total=3; ok=2; fail=1; run=0; maxrun=1
  summary >/dev/null
  [ "$(stat uptime_pct)" = "66.67" ]
}

@test "summary: counters are echoed back verbatim" {
  total=42; ok=40; fail=2; run=0; maxrun=2
  summary >/dev/null
  [ "$(stat total)" = "42" ]
  [ "$(stat ok)" = "40" ]
  [ "$(stat fail)" = "2" ]
}

@test "summary: all failures reports 0% uptime" {
  total=50; ok=0; fail=50; run=0; maxrun=10
  summary >/dev/null
  [ "$(stat uptime_pct)" = "0.00" ]
}

@test "summary: single passing sample reports 100% uptime and no outage" {
  total=1; ok=1; fail=0; run=0; maxrun=0
  summary >/dev/null
  [ "$(stat uptime_pct)" = "100.00" ]
  [ "$(stat approx_outage_s)" = "0.0" ]
}

@test "summary: single failing sample reports 0% uptime and one interval of outage" {
  total=1; ok=0; fail=1; run=0; maxrun=1
  summary >/dev/null
  [ "$(stat uptime_pct)" = "0.00" ]
  [ "$(stat approx_outage_s)" = "0.3" ]   # 1 * 0.3s interval
}

@test "summary: outage uses max consecutive run, not total fail count" {
  # 3 total failures but the worst consecutive streak was only 2,
  # so the estimated outage is 2×0.3s = 0.6s (not 3×0.3s = 0.9s).
  total=10; ok=7; fail=3; run=0; maxrun=2
  summary >/dev/null
  [ "$(stat approx_outage_s)" = "0.6" ]
  [ "$(stat max_consec_fail)" = "2" ]
}
