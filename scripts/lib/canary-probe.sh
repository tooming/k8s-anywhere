# Shared canary-availability-check helpers for the blue/green DR drill —
# sourced, not executed. Deliberately NOT named after scripts/bluegreen-probe.sh
# (a different, pre-existing script: the actual background curl-loop probe
# process this lib's probe() one-shot check complements) to avoid a
# basename collision with tests/*.bats's coverage-recurrence guard.
#
# scripts/dr-bluegreen.sh and scripts/dr-bluegreen-promote.sh each hand-rolled
# byte-identical copies of probe()/stop_probe(); consolidated here so a future
# format tweak only needs one edit, mirroring the colors.sh / budget-check.sh
# / confirm.sh extraction precedent.
#
# Callers must define CANARY_HOST, FRONTDOOR_PORT (probe's target) and
# PROBE_PID (their own background probe-process PID, empty string when none
# running yet) before use.

# probe: one-shot HTTP status check of the front door's canary host.
probe(){ curl -s -o /dev/null -w '%{http_code}' --max-time 8 -H "Host: $CANARY_HOST" "http://localhost:$FRONTDOOR_PORT/" 2>/dev/null || echo 000; }

# stop_probe: terminate the background continuous-availability probe process
# (scripts/bluegreen-probe.sh), if one is running (PROBE_PID set).
stop_probe(){ [ -n "$PROBE_PID" ] && kill -TERM "$PROBE_PID" 2>/dev/null || true; }
