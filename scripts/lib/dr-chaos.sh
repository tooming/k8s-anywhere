#!/usr/bin/env bash
# Shared helpers for the dr-chaos-*.sh fault-injection drills — sourced, not
# executed. dr-chaos-argocd.sh, dr-chaos-cert-manager.sh, dr-chaos-traefik.sh,
# and dr-chaos-lab-demo.sh each hand-rolled a byte-identical copy of the
# "fail()"/"retry()" helpers and a near-identical "capture BEFORE_UID, delete
# the matching pod, poll for a new Ready pod" sequence — only the final
# recovery predicate (ArgoCD sync health / cert-manager issuer chain /
# Traefik HTTP probe / lab-demo content check) actually differs between them.
# Consolidated here so a future format tweak (the FAILED banner, the retry
# loop's polling shape) only needs one edit, mirroring lib/kctx.sh's and
# lib/confirm.sh's own consolidation of an identical duplication pattern
# across this same scripts/ directory. Depends on lib/colors.sh ($B/$R/$Z)
# and lib/confirm.sh (phase()) already being sourced by the caller.

# dr_chaos_fail <message> : prints the FAILED banner (with elapsed time
# since dr_chaos_start was called) and exits 1. Never returns.
dr_chaos_fail() {
  printf '\n%s%sDR CHAOS FAILED%s at: %s  (elapsed %ss)\n' \
    "$B" "$R" "$Z" "$1" "$((SECONDS - DR_CHAOS_START))"
  exit 1
}

# dr_chaos_start : records the drill's start time for dr_chaos_fail's
# elapsed-time reporting. Call once, right after confirm_or_abort returns.
dr_chaos_start() { DR_CHAOS_START=$SECONDS; }

# dr_chaos_retry <timeout_s> <interval_s> <predicate-fn> : polls
# <predicate-fn> every <interval_s> seconds until it succeeds (0) or
# <timeout_s> elapses (returns 1).
dr_chaos_retry() {
  local to=$1 iv=$2 fn=$3 end
  end=$((SECONDS + to))
  while :; do
    "$fn" && return 0
    [ "$SECONDS" -ge "$end" ] && return 1
    sleep "$iv"
  done
}

# dr_chaos_kill_and_wait <namespace> <selector> <timeout_s> <label>
# Captures the matching pod's current UID, deletes it, then polls (every 3s,
# up to <timeout_s>) for a NEW pod matching the same selector that is Ready.
# <label> is a human-readable component name used only in phase/fail output
# (e.g. "argocd-application-controller", "Traefik", "lab-demo (hello)") —
# every dr-chaos-*.sh caller already spells its own label consistently
# between its confirm_or_abort prompt and its old inline fail messages, so
# passing the same string through here preserves each script's exact,
# bats-asserted "no live <label> pod found"/"no new Ready <label> pod
# within ..." wording. On success, sets DR_CHAOS_NEW_POD_NAME to the new
# pod's name (needed by callers, like dr-chaos-lab-demo.sh, whose recovery
# predicate execs into the specific new pod rather than probing over HTTP).
dr_chaos_kill_and_wait() {
  local ns=$1 selector=$2 timeout=$3 label=$4
  local before_uid

  before_uid=$(kubectl -n "$ns" get pod -l "$selector" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
  [ -n "$before_uid" ] || dr_chaos_fail "no live $label pod found (selector: $selector)"

  phase "1/3  CHAOS — deleting the live $label pod"
  kubectl -n "$ns" delete pod -l "$selector" --wait=false || dr_chaos_fail "kubectl delete pod"

  phase "2/3  SELF-HEAL — waiting for Kubernetes to recreate + ready a new pod"
  # Consumed by callers after this function returns (e.g.
  # dr-chaos-lab-demo.sh's own recovery predicate) — shellcheck can't see
  # that cross-file usage, hence the disable on both assignments below.
  # shellcheck disable=SC2034
  DR_CHAOS_NEW_POD_NAME=""
  _dr_chaos_p_new_pod_ready() {
    local uid ready name
    name=$(kubectl -n "$ns" get pod -l "$selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    uid=$(kubectl -n "$ns" get pod -l "$selector" -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null)
    [ -n "$uid" ] && [ "$uid" != "$before_uid" ] || return 1
    ready=$(kubectl -n "$ns" get pod -l "$selector" -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
    [ "$ready" = "true" ] || return 1
    # shellcheck disable=SC2034
    DR_CHAOS_NEW_POD_NAME="$name"
  }
  dr_chaos_retry "$timeout" 3 _dr_chaos_p_new_pod_ready \
    || dr_chaos_fail "no new Ready $label pod within ${timeout}s"
}
