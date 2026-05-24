#!/usr/bin/env bash
# Continuous availability probe for the blue/green DR drill. Hammers the stable
# front door (:8000) at the canary host throughout the cutover and records uptime.
# The orchestrator runs this in the background and stops it with SIGTERM, which
# prints a summary and writes machine-readable stats to $PROBE_STATS.
#
# This is the evidence for "the whole system keeps working during the drill":
# if the blue->green cutover is truly zero-downtime, uptime stays ~100%.
set -uo pipefail

URL="${PROBE_URL:-http://localhost:8000/}"
HOST_HDR="${PROBE_HOST:-argocd.127.0.0.1.nip.io}"
INTERVAL="${PROBE_INTERVAL:-0.3}"
STATS="${PROBE_STATS:-/tmp/bg-probe.stats}"
LOG="${PROBE_LOG:-/tmp/bg-probe.log}"

# Counters the summary reads. Unit tests source this file and set them directly.
total=0; ok=0; fail=0; run=0; maxrun=0
stop=0

# Pure: turns the counters into the uptime/outage stats file + a one-line summary.
# No I/O beyond $STATS and stdout, so it's testable in isolation.
summary() {
  local up="0.00" outage
  [ "$total" -gt 0 ] && up=$(awk "BEGIN{printf \"%.2f\", $ok/$total*100}")
  outage=$(awk "BEGIN{printf \"%.1f\", $maxrun*$INTERVAL}")
  { echo "total=$total"; echo "ok=$ok"; echo "fail=$fail"
    echo "uptime_pct=$up"; echo "max_consec_fail=$maxrun"; echo "approx_outage_s=$outage"; } > "$STATS"
  printf '[probe] samples=%d ok=%d fail=%d uptime=%s%% longest-outage~%ss\n' \
    "$total" "$ok" "$fail" "$up" "$outage"
}

probe_loop() {
  : > "$LOG"
  trap 'stop=1' TERM INT
  trap summary EXIT
  printf '[probe] watching %s (Host: %s) every %ss — SIGTERM to stop\n' "$URL" "$HOST_HDR" "$INTERVAL"
  while [ "$stop" -eq 0 ]; do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 -H "Host: $HOST_HDR" "$URL" 2>/dev/null || echo 000)
    total=$((total+1))
    if { [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; } 2>/dev/null; then
      ok=$((ok+1)); run=0
    else
      fail=$((fail+1)); run=$((run+1)); [ "$run" -gt "$maxrun" ] && maxrun=$run
      printf '%s FAIL http=%s\n' "$(date +%H:%M:%S)" "$code" >> "$LOG"
    fi
    sleep "$INTERVAL"
  done
}

# Run the probe only when executed directly; `source` loads functions for tests.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  probe_loop
fi
