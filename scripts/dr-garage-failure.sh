#!/usr/bin/env bash
# Garage-failure drill (DORA Pillar 3 — TLPT concept; a third, distinct
# fault-injection scenario alongside dr-chaos.sh's capstone pod-kill and
# dr-network-partition.sh's capstone NetworkPolicy-delete, per
# docs/dora-audit-readiness.md Q12's own named follow-up: "Simulating Garage
# unavailability... remains a real, separately-scoped future drill if
# wanted — a different failure domain (storage-layer availability)").
#
# Kills the single running Garage pod and asserts Kubernetes self-heals it —
# a fresh pod reaches Ready — within budget. This exercises the same
# self-heal path dr-chaos.sh already proves out for capstone
# (gitops/storage/garage/statefulset.yaml runs a single-replica StatefulSet,
# `app: garage`, in the `storage` namespace), just against Garage instead of
# capstone: a real, previously-uncovered storage-layer failure domain.
#
# This does not change cluster behavior: pod-delete-then-recreate is a
# guarantee Kubernetes already provides for any StatefulSet-managed pod. The
# drill only observes and times that self-heal, so its only real-world side
# effect is one Garage pod restarting — briefly interrupting S3 API
# availability for any in-flight request, an event the lab already tolerates
# (single-replica, no HA, per ADR-0005 — recreate over pretend-HA on one
# host).
#
# Usage: ./scripts/dr-garage-failure.sh
# Exit codes: 0 = a replacement pod reached Ready within budget; 1 = it
# didn't, the confirmation was declined, or no Garage pod was found to kill.
set -uo pipefail

NAMESPACE="storage"
LABEL_SELECTOR="app=garage"
# Garage's StatefulSet has no readinessProbe override and no custom startup
# delay beyond its own process init — reading its config, joining/confirming
# its (single-node) cluster layout, and opening its S3/admin listeners. That's
# normally well under 30s on a healthy node, the same order of magnitude as
# capstone's own recovery per dr-chaos.sh's reasoning. 120s (matching
# dr-chaos.sh's own budget exactly) gives the same 4x headroom for a
# slower-node/cold-start edge case without masking a real regression the way
# a much larger budget would.
BUDGET_S=120

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/budget-check.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dr-results-log.sh"

confirm_or_abort "$(printf '%sThis DELETES the live Garage pod in the %s namespace to test self-heal.%s\n' "$R$B" "$NAMESPACE" "$Z")" \
  "garage-failure"

echo ""
printf '%s== Garage-failure drill: kill the single %s pod, assert self-heal (budget %ds) ==%s\n' \
  "$B" "$NAMESPACE" "$BUDGET_S" "$Z"

PODS=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o name 2>/dev/null || true)
if [ -z "$PODS" ]; then
  printf '  %s✗%s no pods matching %s in namespace %s — is Garage up?\n' \
    "$R" "$Z" "$LABEL_SELECTOR" "$NAMESPACE"
  exit 1
fi

# Garage runs a single replica (gitops/storage/garage/statefulset.yaml
# replicas: 1), so there is exactly one pod to pick — no random selection
# needed here, unlike dr-chaos.sh's capstone drill.
PRE_COUNT=$(wc -l <<<"$PODS" | tr -d ' ')
TARGET=$(sed -n '1p' <<<"$PODS")
OLD_NAME="${TARGET#pod/}"

printf '  → target: %s\n' "$TARGET"
printf '  → deleting...\n'
# --wait=false (not the NetworkPolicy delete's --wait=true, per
# dr-network-partition.sh's own recurrence-guard comment): this deletes a
# POD, which has a terminationGracePeriodSeconds window, so --wait=false
# avoids blocking here for that grace period — the same reasoning dr-chaos.sh
# itself already establishes for its own pod delete. Do NOT copy
# dr-network-partition.sh's --wait=true here; that guard applies to its
# NetworkPolicy object, not to a pod delete.
kubectl delete "$TARGET" -n "$NAMESPACE" --wait=false

# Self-heal check: reuses dr-chaos.sh's own self-review-caught fix rather
# than reintroducing the bug it found — a pod being deleted keeps
# status.phase=Running throughout its terminationGracePeriodSeconds window,
# so the field-selector below excludes the deleted pod's own name AND
# requires the replacement's actual container readiness (not just
# phase=Running, which a pod reaches before its readiness probe, if any, has
# passed).
START=$SECONDS
HEALED=0
while [ "$(( SECONDS - START ))" -lt "$BUDGET_S" ]; do
  READY_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" \
    --field-selector="status.phase=Running,metadata.name!=${OLD_NAME}" \
    -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null \
    | grep -c '^true$' || true)
  if [ "${READY_COUNT:-0}" -ge "$PRE_COUNT" ]; then
    HEALED=1
    break
  fi
  sleep 2
done

ELAPSED=$(( SECONDS - START ))

echo ""
if [ "$HEALED" -eq 1 ]; then
  printf '%s✓ SELF-HEAL CONFIRMED — replacement Garage pod Running in %ds (< %ds budget).%s\n' \
    "$G$B" "$ELAPSED" "$BUDGET_S" "$Z"
  budget_final_line "$ELAPSED" "$BUDGET_S" "garage-failure"
  dr_log_result "dr-garage-failure.sh" "PASS" "$ELAPSED" "$BUDGET_S" "garage-failure"
  exit 0
else
  printf '%s✗ SELF-HEAL NOT CONFIRMED within budget — see pod status above.%s\n' "$R$B" "$Z"
  budget_final_line "$ELAPSED" "$BUDGET_S" "garage-failure" || true
  dr_log_result "dr-garage-failure.sh" "FAIL" "$ELAPSED" "$BUDGET_S" "garage-failure"
  exit 1
fi
