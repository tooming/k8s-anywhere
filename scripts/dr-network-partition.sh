#!/usr/bin/env bash
# Network-partition drill (DORA Pillar 3 — TLPT concept; a second, distinct
# fault-injection scenario from dr-chaos.sh's pod-kill, per
# docs/dora-audit-readiness.md Q12's own named follow-up: "Cutting a
# NetworkPolicy... still real, separately-scoped future drills if wanted").
#
# Deletes capstone's ingress-allow NetworkPolicy live (cutting off all
# Traefik-routed traffic to the app, since ADR-0016's default-deny
# floor then applies with no allow left), and asserts ArgoCD's own selfHeal
# reconciliation restores it within budget — this exercises ArgoCD's
# drift-correction path specifically, distinct from dr-chaos.sh's test of
# Kubernetes' ReplicaSet/Rollout self-heal path. Both are real, injected
# faults with a real, observed recovery — not a planned cutover (that's
# dr-bluegreen.sh's job).
#
# This does not change cluster behavior beyond what ArgoCD's selfHeal
# already guarantees for any drifted live object it manages
# (gitops/platform/networkpolicy-appset.yaml's syncPolicy.automated.selfHeal:
# true) — the drill only observes and times that correction. Its real-world
# side effect: the capstone HTTPRoute is unreachable for the duration of the
# drill, until selfHeal restores the policy.
#
# Usage: ./scripts/dr-network-partition.sh
# Exit codes: 0 = ArgoCD restored the deleted NetworkPolicy within budget;
# 1 = it didn't, the confirmation was declined, or the policy wasn't found.
set -uo pipefail

NAMESPACE="capstone"
POLICY="allow-capstone-ingress-from-gateway"
# ArgoCD's selfHeal reacts to live drift via its resource informer/watch, a
# separate, typically much faster mechanism than the full source-of-truth
# resync timer (which defaults to 180s and governs checking git for new
# commits, not correcting already-known drift on an already-watched
# resource). This remote clusterless session has no live ArgoCD instance to
# time selfHeal against directly (ADR-0004), so 300s is a deliberately
# generous budget — well beyond even a full-resync-timer-bound correction —
# chosen to avoid masking a genuine regression the way an unbounded wait
# would, not because selfHeal is expected to take anywhere near that long.
BUDGET_S=300

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/budget-check.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/dr-results-log.sh"

confirm_or_abort "$(printf '%sThis DELETES a live NetworkPolicy in the %s namespace, cutting off all ingress to capstone until ArgoCD self-heals it.%s\n' "$R$B" "$NAMESPACE" "$Z")" \
  "network-partition"

echo ""
printf '%s== Network-partition drill: delete %s, assert ArgoCD self-heal (budget %ds) ==%s\n' \
  "$B" "$POLICY" "$BUDGET_S" "$Z"

if ! kubectl get networkpolicy "$POLICY" -n "$NAMESPACE" >/dev/null 2>&1; then
  printf '  %s✗%s NetworkPolicy %s not found in namespace %s — is capstone up?\n' \
    "$R" "$Z" "$POLICY" "$NAMESPACE"
  exit 1
fi

printf '  → deleting NetworkPolicy/%s...\n' "$POLICY"
# Deliberately NOT --wait=false (unlike dr-chaos.sh's pod delete, which uses it
# to avoid blocking for a pod's terminationGracePeriodSeconds). A NetworkPolicy
# has no grace period -- it's a plain API object, not a pod -- so the default
# --wait=true blocks only until the object is actually confirmed gone, which is
# effectively instant here. Found live during a self-review pass 2026-08-18:
# --wait=false returns as soon as the delete request is *accepted*, not
# *completed* -- the very first self-heal poll iteration below could then
# still see the not-yet-deleted object and report a false-positive instant
# "self-heal confirmed" without the drill ever actually observing a real
# delete-then-restore cycle. Same failure-mode *class* dr-chaos.sh's own
# recurrence-guard comments describe (a command returning doesn't mean the
# underlying state change is actually done yet), different root cause --
# this script mechanically copied --wait=false from dr-chaos.sh's pod-kill
# pattern without checking whether the reason it's needed there (avoiding a
# block for terminationGracePeriodSeconds) applies to a NetworkPolicy too (it
# doesn't). Found and fixed in this same PR's own self-review, before this
# script had ever run against a live cluster.
kubectl delete networkpolicy "$POLICY" -n "$NAMESPACE"

START=$SECONDS
HEALED=0
while [ "$(( SECONDS - START ))" -lt "$BUDGET_S" ]; do
  if kubectl get networkpolicy "$POLICY" -n "$NAMESPACE" >/dev/null 2>&1; then
    HEALED=1
    break
  fi
  sleep 3
done

ELAPSED=$(( SECONDS - START ))

echo ""
if [ "$HEALED" -eq 1 ]; then
  printf '%s✓ SELF-HEAL CONFIRMED — ArgoCD restored %s in %ds (< %ds budget).%s\n' \
    "$G$B" "$POLICY" "$ELAPSED" "$BUDGET_S" "$Z"
  budget_final_line "$ELAPSED" "$BUDGET_S" "network-partition"
  dr_log_result "dr-network-partition.sh" "PASS" "$ELAPSED" "$BUDGET_S" "network-partition"
  exit 0
else
  printf '%s✗ SELF-HEAL NOT CONFIRMED within budget — check ArgoCD Application health for %s.%s\n' \
    "$R$B" "$NAMESPACE" "$Z"
  budget_final_line "$ELAPSED" "$BUDGET_S" "network-partition" || true
  dr_log_result "dr-network-partition.sh" "FAIL" "$ELAPSED" "$BUDGET_S" "network-partition"
  exit 1
fi
