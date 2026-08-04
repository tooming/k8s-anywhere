#!/usr/bin/env bash
# Blue/green DR drill: stand up a fresh GREEN cluster alongside the live BLUE one,
# then cut traffic over with ZERO downtime — proving the whole system keeps working
# throughout. A stable front door (:8000) fronts whichever cluster is active; a
# continuous availability probe hammers it across the cutover and must stay ~100%.
#
# Unlike `make dr-test` (destroy + rebuild, has an outage), this never touches blue:
# green comes up on its own cluster/ports/network and the cutover is a graceful
# nginx reload on a separate port. See docs/DR.md.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SC="$ROOT_DIR/scripts"

BLUE_NET="${BLUE_NET:-k3d-k8s-lab}"
BLUE_LB="${BLUE_LB:-k3d-k8s-lab-serverlb}"
GREEN="${GREEN_CLUSTER:-k8s-lab-green}"
GREEN_NET="k3d-$GREEN"
GREEN_LB="k3d-$GREEN-serverlb"
GCTX="k3d-$GREEN"
FRONTDOOR_PORT="${FRONTDOOR_PORT:-8000}"
CANARY_HOST="${CANARY_HOST:-argocd.127.0.0.1.nip.io}"
PROBE_STATS="${PROBE_STATS:-/tmp/bg-probe.stats}"
PROBE_LOG="${PROBE_LOG:-/tmp/bg-probe.log}"
MIN_UPTIME="${MIN_UPTIME:-99.0}"   # PASS threshold (%)
MAX_OUTAGE="${MAX_OUTAGE:-2.0}"    # PASS threshold (seconds)

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/canary-probe.sh"

START=$SECONDS
PROBE_PID=""
fail(){ stop_probe; printf '\n%s%sBLUE/GREEN DR FAILED%s at: %s  (elapsed %ds)\n' "$B" "$R" "$Z" "$1" "$((SECONDS-START))"; exit 1; }

printf '%s== BLUE/GREEN DR DRILL ==%s  stable endpoint :%s, canary Host %s\n' "$B" "$Z" "$FRONTDOOR_PORT" "$CANARY_HOST"

phase "1/5  Front door up -> BLUE"
bash "$SC/bluegreen-frontdoor.sh" up "$BLUE_NET" "$BLUE_LB" || fail "front door up"
[ "$(probe)" = "200" ] || fail "canary not serving via front door before drill"

phase "2/5  Start continuous availability probe"
PROBE_URL="http://localhost:$FRONTDOOR_PORT/" PROBE_HOST="$CANARY_HOST" \
  PROBE_STATS="$PROBE_STATS" PROBE_LOG="$PROBE_LOG" \
  bash "$SC/bluegreen-probe.sh" >/tmp/bg-probe.out 2>&1 &
PROBE_PID=$!
sleep 2

phase "3/5  Bring up GREEN (fresh cluster + ArgoCD + serving tier from GitLab)"
bash "$SC/bluegreen-up.sh" || fail "green bring-up"

phase "4/5  CUTOVER — repoint front door BLUE -> GREEN (graceful reload)"
# distinguisher: blue serves a vault route, green (serving-tier only) does NOT.
blue_vault=$(curl -s -o /dev/null -w '%{http_code}' --max-time 6 -H 'Host: vault.127.0.0.1.nip.io' "http://localhost:$FRONTDOOR_PORT/" 2>/dev/null || echo 000)
bash "$SC/bluegreen-frontdoor.sh" connect "$GREEN_NET" || fail "connect green network"
bash "$SC/bluegreen-frontdoor.sh" point "$GREEN_LB" || fail "cutover"
sleep 2
# the canary still serves (now from green)...
[ "$(probe)" = "200" ] || fail "canary not serving after cutover"
# ...and the front-door config now actually targets green's load balancer (hard proof)
bash "$SC/bluegreen-frontdoor.sh" target | grep -q "$GREEN_LB" || fail "front door not pointing at $GREEN_LB after cutover"
kubectl --context "$GCTX" -n argocd get deploy argocd-server >/dev/null 2>&1 || fail "green ArgoCD not present (cutover not really green)"
# distinguisher proof: same vault-route host now misses on green (no such route there)
green_vault=$(curl -s -o /dev/null -w '%{http_code}' --max-time 6 -H 'Host: vault.127.0.0.1.nip.io' "http://localhost:$FRONTDOOR_PORT/" 2>/dev/null || echo 000)
printf '   cutover proof: front door -> %s; vault-route host %s (blue) -> %s (green, route absent)\n' "$GREEN_LB" "$blue_vault" "$green_vault"

phase "5/5  Stop probe + evaluate continuous availability"
stop_probe; wait "$PROBE_PID" 2>/dev/null; PROBE_PID=""
cat "$PROBE_STATS" 2>/dev/null
uptime=$(grep '^uptime_pct=' "$PROBE_STATS" 2>/dev/null | cut -d= -f2); uptime="${uptime:-0}"
outage=$(grep '^approx_outage_s=' "$PROBE_STATS" 2>/dev/null | cut -d= -f2); outage="${outage:-99}"
ok_up=$(awk "BEGIN{print ($uptime>=$MIN_UPTIME)?1:0}")
ok_out=$(awk "BEGIN{print ($outage<=$MAX_OUTAGE)?1:0}")
ELAPSED=$((SECONDS-START))

echo
if [ "$ok_up" = 1 ] && [ "$ok_out" = 1 ]; then
  printf '%s%s✅ BLUE/GREEN DR PASSED%s — cut blue->green in %ds; uptime %s%%, longest outage ~%ss.\n' "$B" "$G" "$Z" "$ELAPSED" "$uptime" "$outage"
  printf '   The whole system kept working during the drill. Front door :%s now serves GREEN; blue still runs for rollback.\n' "$FRONTDOOR_PORT"
  printf '   Reclaim RAM with: make dr-bluegreen-down\n'
  exit 0
else
  printf '%s%s❌ BLUE/GREEN DR FAILED%s — uptime %s%% (need >=%s%%), outage ~%ss (need <=%ss). See %s\n' \
    "$B" "$R" "$Z" "$uptime" "$MIN_UPTIME" "$outage" "$MAX_OUTAGE" "$PROBE_LOG"
  exit 1
fi
