#!/usr/bin/env bash
# Complete blue/green DR on a single 16 GB host: migrate to GREEN and RETIRE BLUE
# with the serving path never dropping. Two FULL stacks don't fit 16 GB, so the
# order is chosen to never overlap them:
#
#   serving-green up  ->  cut over (zero downtime)  ->  RETIRE BLUE (frees ~7 GB)
#   ->  THEN promote green to a FULL stack + verify  (now there's headroom)
#
# Serving stays up throughout (a probe proves it). The unavoidable single-host
# tradeoff: a brief observability/Vault/Garage gap between retiring blue and green
# finishing its full sync — the *serving* path is continuous. See docs/DR.md, ADR-0005.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SC="$ROOT_DIR/scripts"

BLUE_CLUSTER="${BLUE_CLUSTER:-k8s-lab}"
BLUE_NET="k3d-$BLUE_CLUSTER"
BLUE_LB="k3d-$BLUE_CLUSTER-serverlb"
GREEN="${GREEN_CLUSTER:-k8s-lab-green}"
GREEN_NET="k3d-$GREEN"
GREEN_LB="k3d-$GREEN-serverlb"
GCTX="k3d-$GREEN"
FRONTDOOR_PORT="${FRONTDOOR_PORT:-8000}"
CANARY_HOST="${CANARY_HOST:-argocd.127.0.0.1.nip.io}"
PROBE_STATS="${PROBE_STATS:-/tmp/bg-probe.stats}"
PROBE_LOG="${PROBE_LOG:-/tmp/bg-probe.log}"
MIN_UPTIME="${MIN_UPTIME:-99.0}"
MAX_OUTAGE="${MAX_OUTAGE:-2.0}"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
phase(){ printf '\n%s========== %s ==========%s\n' "$B" "$1" "$Z"; }
probe(){ curl -s -o /dev/null -w '%{http_code}' --max-time 8 -H "Host: $CANARY_HOST" "http://localhost:$FRONTDOOR_PORT/" 2>/dev/null || echo 000; }

printf '%s== COMPLETE BLUE/GREEN DR (migrate to green, retire blue) ==%s\n' "$B" "$Z"
printf '  order : serving-green -> cutover -> %sDELETE BLUE%s -> promote green to FULL\n' "$R" "$Z"
printf '  guard : serving stays up the whole time (probe must show >=%s%% uptime)\n' "$MIN_UPTIME"
printf '  note  : brief observability gap after blue is gone until green finishes full sync\n'

if [ "${DR_ASSUME_YES:-0}" != "1" ]; then
  if [ -t 0 ]; then
    printf '%sThis DELETES the blue cluster (after a verified cutover).%s ' "$R$B" "$Z"
    read -r -p "Type 'promote' to run: " ans
    [ "$ans" = "promote" ] || { echo "aborted."; exit 1; }
  else
    echo "Refusing non-interactively without DR_ASSUME_YES=1." >&2; exit 1
  fi
fi
export DR_ASSUME_YES=1

START=$SECONDS
PROBE_PID=""
stop_probe(){ [ -n "$PROBE_PID" ] && kill -TERM "$PROBE_PID" 2>/dev/null || true; }
fail(){ stop_probe; printf '\n%s%sPROMOTE FAILED%s at: %s  (elapsed %ds)\n' "$B" "$R" "$Z" "$1" "$((SECONDS-START))"; exit 1; }

phase "1/7  Front door up -> BLUE"
bash "$SC/bluegreen-frontdoor.sh" up "$BLUE_NET" "$BLUE_LB" || fail "front door up"
[ "$(probe)" = "200" ] || fail "canary not serving via front door before drill"

phase "2/7  Start continuous availability probe (serving must stay up)"
PROBE_URL="http://localhost:$FRONTDOOR_PORT/" PROBE_HOST="$CANARY_HOST" \
  PROBE_STATS="$PROBE_STATS" PROBE_LOG="$PROBE_LOG" \
  bash "$SC/bluegreen-probe.sh" >/tmp/bg-probe.out 2>&1 &
PROBE_PID=$!
sleep 2

phase "3/7  Bring up GREEN (serving tier — light, fits alongside blue)"
bash "$SC/bluegreen-up.sh" serving || fail "green serving bring-up"

phase "4/7  CUTOVER — front door BLUE -> GREEN (graceful reload)"
bash "$SC/bluegreen-frontdoor.sh" connect "$GREEN_NET" || fail "connect green network"
bash "$SC/bluegreen-frontdoor.sh" point "$GREEN_LB" || fail "cutover"
sleep 2
[ "$(probe)" = "200" ] || fail "canary not serving after cutover"
bash "$SC/bluegreen-frontdoor.sh" target | grep -q "$GREEN_LB" || fail "front door not pointing at green"

phase "5/7  RETIRE BLUE — frees ~7 GB so green can grow to full"
bash "$SC/bluegreen-frontdoor.sh" disconnect "$BLUE_NET" || true
k3d cluster delete "$BLUE_CLUSTER" || fail "deleting blue cluster"
kubectl config use-context "$GCTX" >/dev/null 2>&1 || true
[ "$(probe)" = "200" ] || fail "serving dropped after retiring blue"

phase "6/7  PROMOTE GREEN to a FULL stack + verify (RAM is free now)"
bash "$SC/bluegreen-up.sh" full || fail "green promote-to-full/verify"

phase "7/7  Stop probe + evaluate continuous availability"
stop_probe; wait "$PROBE_PID" 2>/dev/null; PROBE_PID=""
cat "$PROBE_STATS" 2>/dev/null
uptime=$(grep '^uptime_pct=' "$PROBE_STATS" 2>/dev/null | cut -d= -f2); uptime="${uptime:-0}"
outage=$(grep '^approx_outage_s=' "$PROBE_STATS" 2>/dev/null | cut -d= -f2); outage="${outage:-99}"
ok_up=$(awk "BEGIN{print ($uptime>=$MIN_UPTIME)?1:0}")
ok_out=$(awk "BEGIN{print ($outage<=$MAX_OUTAGE)?1:0}")
ELAPSED=$((SECONDS-START))

echo
if [ "$ok_up" = 1 ] && [ "$ok_out" = 1 ]; then
  printf '%s%s✅ COMPLETE BLUE/GREEN DR PASSED%s in %ds; serving uptime %s%%, longest outage ~%ss.\n' "$B" "$G" "$Z" "$ELAPSED" "$uptime" "$outage"
  printf '   Green is now the sole, full, verified environment; blue is gone; serving never dropped.\n'
  printf '   Canonical endpoint: http://localhost:%s (front door -> green); green direct: :8082.\n' "$FRONTDOOR_PORT"
  exit 0
else
  printf '%s%s❌ PROMOTE FAILED%s — uptime %s%% (need >=%s%%), outage ~%ss (need <=%ss). See %s\n' \
    "$B" "$R" "$Z" "$uptime" "$MIN_UPTIME" "$outage" "$MAX_OUTAGE" "$PROBE_LOG"
  exit 1
fi
