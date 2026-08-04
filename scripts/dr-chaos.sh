#!/usr/bin/env bash
# Chaos / fault-injection drill (DORA Pillar 3 — TLPT concept, distinct from
# dr-bluegreen's *planned* failover): kill one running capstone pod and assert
# Kubernetes/the Rollout self-heals — a fresh pod reaches Ready — within budget.
#
# This does not change cluster behavior: pod-delete-then-recreate is a guarantee
# Kubernetes already provides for any ReplicaSet-managed pod. The drill only
# observes and times that self-heal, so its only real-world side effect is one
# capstone pod restarting — an event the lab already tolerates routinely.
#
# Usage: ./scripts/dr-chaos.sh
# Exit codes: 0 = a replacement pod reached Ready within budget; 1 = it didn't,
# the confirmation was declined, or no capstone pod was found to kill.
set -uo pipefail

NAMESPACE="capstone"
LABEL_SELECTOR="app=capstone"
# capstone's Rollout runs a single replica (no HA, per ADR-0005 — recreate over
# pretend-HA on one host) with no readinessProbe override and no
# progressDeadlineSeconds override, so recovery time is just:
# schedule + (already-cached image, since the pod we killed was running it) +
# container start. That's normally well under 30s on a healthy node. 120s gives
# 4x headroom for a slower node/cold-start edge case without masking a real
# regression the way a much larger budget would.
BUDGET_S=120

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/budget-check.sh"

# confirmation (DR_ASSUME_YES=1 bypasses for non-interactive/scripted use,
# mirrors dr-destroy.sh's confirmation-prompt precedent for a destructive action)
if [ "${DR_ASSUME_YES:-0}" != "1" ]; then
  printf '%sThis DELETES a live pod in the %s namespace to test self-heal.%s\n' "$R$B" "$NAMESPACE" "$Z"
  if [ -t 0 ]; then
    read -r -p "Type 'chaos' to continue: " ans
    [ "$ans" = "chaos" ] || { echo "aborted."; exit 1; }
  else
    echo "Refusing non-interactively without DR_ASSUME_YES=1." >&2
    exit 1
  fi
fi

echo ""
printf '%s== Chaos drill: kill a random %s pod, assert self-heal (budget %ds) ==%s\n' \
  "$B" "$NAMESPACE" "$BUDGET_S" "$Z"

PODS=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o name 2>/dev/null || true)
if [ -z "$PODS" ]; then
  printf '  %s✗%s no pods matching %s in namespace %s — is the capstone Rollout up?\n' \
    "$R" "$Z" "$LABEL_SELECTOR" "$NAMESPACE"
  exit 1
fi

# Pick one at random using bash's built-in $RANDOM, so this doesn't depend on
# an external random-line-picker tool being present on the runner.
PRE_COUNT=$(wc -l <<<"$PODS" | tr -d ' ')
PICK_LINE=$(( (RANDOM % PRE_COUNT) + 1 ))
TARGET=$(sed -n "${PICK_LINE}p" <<<"$PODS")

printf '  → target: %s\n' "$TARGET"
printf '  → deleting...\n'
kubectl delete "$TARGET" -n "$NAMESPACE" --wait=false

START=$SECONDS
HEALED=0
while [ "$(( SECONDS - START ))" -lt "$BUDGET_S" ]; do
  READY_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" \
    --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
  if [ "${READY_COUNT:-0}" -ge "$PRE_COUNT" ]; then
    HEALED=1
    break
  fi
  sleep 2
done

ELAPSED=$(( SECONDS - START ))

echo ""
if [ "$HEALED" -eq 1 ]; then
  printf '%s✓ SELF-HEAL CONFIRMED — replacement pod Running in %ds (< %ds budget).%s\n' \
    "$G$B" "$ELAPSED" "$BUDGET_S" "$Z"
  budget_final_line "$ELAPSED" "$BUDGET_S" "chaos"
  exit 0
else
  printf '%s✗ SELF-HEAL NOT CONFIRMED within budget — see pod status above.%s\n' "$R$B" "$Z"
  budget_final_line "$ELAPSED" "$BUDGET_S" "chaos" || true
  exit 1
fi
