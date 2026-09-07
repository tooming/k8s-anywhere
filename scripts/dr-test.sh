#!/usr/bin/env bash
# One-command disaster-recovery drill: destroy the lab, rebuild it entirely from
# code with `make up`, then assert it came back healthy end-to-end. See docs/DR.md.
#
#   ./scripts/dr-test.sh [cluster|machine]   (default: cluster)
#
# A third scope, "full" (also wiping the self-hosted Forgejo git remote),
# existed until 2026-09-07 — Forgejo was removed entirely that day, no
# replacement, so it collapsed into "cluster" and was dropped (see
# scripts/dr-destroy.sh's header for the full reasoning).
#
# This is the real thing — it tears the running lab down. Exit 0 only if the
# rebuilt lab passes every check in scripts/dr-verify.sh.
set -uo pipefail

SCOPE="${1:-${DR_SCOPE:-cluster}}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR" || exit 1

case "$SCOPE" in
  cluster) EST="~3-6 min";   WIPE="k3d cluster (Colima survives)";;
  machine) EST="~15-30 min"; WIPE="cluster + Colima VM (re-pulls all images)";;
  *) echo "unknown SCOPE '$SCOPE' (cluster|machine)" >&2; exit 2;;
esac

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"
hms(){ printf '%dm%02ds' $(( $1/60 )) $(( $1%60 )); }

printf '%s== DR DRILL (scope=%s) ==%s\n' "$B" "$SCOPE" "$Z"
printf '  will wipe : %s\n' "$WIPE"
printf '  rebuild   : make up (from code)\n'
printf '  est. time : %s\n' "$EST"

confirm_or_abort "$(printf '%sThis destroys the running lab.%s ' "$R$B" "$Z")" \
  "dr" "to start the drill"
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
