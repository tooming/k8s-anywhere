#!/usr/bin/env bash
# Honest, automated cluster-health gate. No eyeballing, no cherry-picking: it walks
# EVERY pod and fails if any always-on workload isn't actually up.
#
# "Healthy" = every pod is Running with all containers Ready (or a Job pod that
# Completed/Succeeded), AND every Deployment/StatefulSet/DaemonSet has all its desired
# replicas Ready.
#
# On-demand components are NOT started by `make up` — they're deployed by hand via a
# `make <x>-up` target (see the Makefile), so a missing/unhealthy pod there is expected,
# not a `make up` failure. The list is the on-demand `*-up` targets + capstone (a demo
# whose image lives in the on-demand Artifactory and is built by a pipeline, so it can't
# run on a bare lab). Everything else is ALWAYS-ON and must be healthy.
#
# Exit 0 = every always-on pod + workload is healthy. Exit 1 = something `make up` owns
# is down (printed, with the offender). Run by `make health` and the tail of `make up`.
set -uo pipefail

KCTX="${KCTX:-}"
kubectl() { command kubectl ${KCTX:+--context "$KCTX"} "$@"; }

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
note() { printf '      %s%s%s\n' "$Y" "$1" "$Z"; }

for t in kubectl jq; do command -v "$t" >/dev/null 2>&1 || { echo "$t not installed — cannot check cluster health"; exit 2; }; done
kubectl get nodes >/dev/null 2>&1 || { bad "cluster unreachable (kubectl get nodes failed)"; exit 1; }

# --- on-demand / demo namespaces (deployed manually, NOT by `make up`) -----------
# Override with LAB_ONDEMAND_NS="ns1 ns2 …" if your on-demand set differs.
ONDEMAND_NS="${LAB_ONDEMAND_NS:-tidb tidb-admin tidb-demo artifactory istio-system kiali longhorn-system inkless kargo ack-system capstone}"
is_always_on() { local ns="$1" n; for n in $ONDEMAND_NS; do [ "$n" = "$ns" ] && return 1; done; return 0; }

printf '%s== lab health ==%s  (every always-on pod Running+Ready)\n' "$B" "$Z"

# --- 1. pods ---------------------------------------------------------------------
total=0; healthy=0
declare -a ALWAYS_BAD=() ONDEMAND_BAD=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  ns=$(awk '{print $1}' <<<"$line"); name=$(awk '{print $2}' <<<"$line")
  ready=$(awk '{print $3}' <<<"$line"); status=$(awk '{print $4}' <<<"$line"); restarts=$(awk '{print $5}' <<<"$line")
  total=$((total + 1))
  case "$status" in Completed|Succeeded) healthy=$((healthy + 1)); continue;; esac
  rcur=${ready%%/*}; rtot=${ready##*/}
  if [ "$status" = "Running" ] && [ "$rcur" = "$rtot" ]; then healthy=$((healthy + 1)); continue; fi
  entry="$ns/$name  $ready  $status  (restarts=$restarts)"
  if is_always_on "$ns"; then ALWAYS_BAD+=("$entry"); else ONDEMAND_BAD+=("$entry"); fi
done < <(kubectl get pods -A --no-headers 2>/dev/null)

# --- 2. workloads (desired replicas all Ready) -----------------------------------
declare -a WL_BAD=()
while IFS=$'\t' read -r kind ns name desired ready; do
  [ -n "$name" ] || continue
  desired=${desired:-0}; ready=${ready:-0}
  [ "$desired" = "$ready" ] && continue
  is_always_on "$ns" || continue
  WL_BAD+=("$kind $ns/$name  ready=$ready/$desired")
done < <(
  kubectl get deploy,statefulset,daemonset -A -o json 2>/dev/null | jq -r '
    .items[] | [.kind, .metadata.namespace, .metadata.name,
      ((.status.replicas // .status.desiredNumberScheduled // 0)|tostring),
      ((.status.readyReplicas // .status.numberReady // 0)|tostring)] | @tsv'
)

# --- report ----------------------------------------------------------------------
fail=0
if [ "${#ALWAYS_BAD[@]}" -eq 0 ] && [ "${#WL_BAD[@]}" -eq 0 ]; then
  ok "all $healthy/$total pods Running+Ready (or Completed); every always-on workload Ready"
else
  if [ "${#ALWAYS_BAD[@]}" -gt 0 ]; then
    bad "always-on pods NOT Running+Ready (${#ALWAYS_BAD[@]}):"; printf '%s\n' "${ALWAYS_BAD[@]}" | while read -r l; do note "$l"; done
  fi
  if [ "${#WL_BAD[@]}" -gt 0 ]; then
    bad "always-on workloads with replicas not Ready:"; printf '%s\n' "${WL_BAD[@]}" | while read -r l; do note "$l"; done
  fi
  fail=1
fi

# on-demand offenders are informational — make up never started them.
if [ "${#ONDEMAND_BAD[@]}" -gt 0 ]; then
  printf '  %s·%s on-demand pods not Running (not part of make up — start with their make target):\n' "$Y" "$Z"
  printf '%s\n' "${ONDEMAND_BAD[@]}" | while read -r l; do note "$l"; done
fi

echo
if [ "$fail" -eq 0 ]; then
  printf '%s%sLAB HEALTH: PASS%s — the always-on stack is fully up.\n' "$B" "$G" "$Z"
else
  printf '%s%sLAB HEALTH: FAIL%s — an always-on workload is down (see ✗).\n' "$B" "$R" "$Z"
fi
exit "$fail"
