#!/usr/bin/env bash
# One-command disaster-recovery drill: destroy the lab, rebuild it entirely from
# code with `make up`, then assert it came back healthy end-to-end. See docs/DR.md.
#
#   ./scripts/dr-test.sh [cluster|full|machine]   (default: full)
#
# This is the real thing — it tears the running lab down. Exit 0 only if the
# rebuilt lab passes every check in scripts/dr-verify.sh.
set -uo pipefail

SCOPE="${1:-${DR_SCOPE:-full}}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

case "$SCOPE" in
  cluster) EST="~3-6 min";   WIPE="k3d cluster (GitLab + Colima survive)";;
  full)    EST="~8-15 min";  WIPE="k3d cluster + GitLab container & volumes (Colima survives)";;
  machine) EST="~15-30 min"; WIPE="cluster + GitLab + Colima VM (re-pulls all images)";;
  *) echo "unknown SCOPE '$SCOPE' (cluster|full|machine)" >&2; exit 2;;
esac

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi
phase(){ printf '\n%s========== %s ==========%s\n' "$B" "$1" "$Z"; }
hms(){ printf '%dm%02ds' $(( $1/60 )) $(( $1%60 )); }

printf '%s== DR DRILL (scope=%s) ==%s\n' "$B" "$SCOPE" "$Z"
printf '  will wipe : %s\n' "$WIPE"
printf '  rebuild   : make up (from code)\n'
printf '  est. time : %s\n' "$EST"

if [ "${DR_ASSUME_YES:-0}" != "1" ]; then
  if [ -t 0 ]; then
    printf '%sThis destroys the running lab.%s ' "$R$B" "$Z"
    read -r -p "Type 'dr' to start the drill: " ans
    [ "$ans" = "dr" ] || { echo "aborted."; exit 1; }
  else
    echo "Refusing non-interactively without DR_ASSUME_YES=1." >&2; exit 1
  fi
fi
export DR_ASSUME_YES=1   # children inherit the go-ahead

START=$SECONDS
fail(){ printf '\n%s%sDR TEST FAILED%s at: %s  (elapsed %s)\n' "$B" "$R" "$Z" "$1" "$(hms $((SECONDS-START)))"; exit 1; }

phase "1/3  DISASTER — tearing the lab down"
bash scripts/dr-destroy.sh "$SCOPE" || fail "destroy"

phase "2/3  RECOVERY — make up (one-command rebuild from code)"
make up || fail "make up (rebuild)"

phase "3/3  VERIFY — end-to-end health of the rebuilt lab"
bash scripts/dr-verify.sh || fail "verify (lab rebuilt but unhealthy)"

ELAPSED=$((SECONDS-START))
printf '\n%s%s✅ DR TEST PASSED%s — destroyed and rebuilt from scratch in %s (scope=%s).\n' "$B" "$G" "$Z" "$(hms "$ELAPSED")" "$SCOPE"
printf '   The lab is back up and verified healthy. Recovery is one command: make up\n'
