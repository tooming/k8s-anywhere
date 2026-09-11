#!/usr/bin/env bash
# Guards ROADMAP.md rule #4's documented resource ceiling: a 12 GB Colima VM,
# always-on baseline last measured at ~7 GB pre-2026-09-06/07-simplification and
# not remeasured since at the current, much smaller scope (docs/00-architecture.md
# used to state this same figure before its own 2026-09-07 rewrite dropped it).
# Nothing enforced the ceiling until this script was added (2026-08-05 incident):
# a chain of live-debugging sessions each ran
# a `make <name>-up` and never the matching `-down`, so Harbor, Istio, Kiali,
# Longhorn, Kargo, and TiDB ended up running SIMULTANEOUSLY — plus a fully orphaned
# `artifactory` namespace with no owning ArgoCD Application at all, left over from
# before the Harbor migration (ADR-0024) decommissioned it. The Colima VM hit
# 11Gi/11Gi memory used, load average 30+ on 6 cores, kubelet couldn't
# garbage-collect ("Attempted to free 3.3GB, found 0 bytes eligible"), the node flapped
# NodeNotReady, envoy-gateway lost leader election against a starved apiserver and
# crashlooped, and every front-door UI in README.md's table 502'd. (TiDB, Istio, and
# Longhorn were removed from the lab entirely 2026-09-06; Harbor and Kargo — the last
# two heavy on-demand units this guard tracked — were both removed entirely 2026-09-07,
# no replacement. UNIT_APPS/UNIT_NS/UNIT_SIZE below are therefore empty: no heavy
# on-demand unit currently exists in this lab. The mechanism (and the orphan-namespace
# detection below, which still matters) is kept ready for the next heavy on-demand
# component rather than deleted — don't remove it just because it's momentarily unused.)
#
# This script is the mechanical guard: it reports which on-demand units are currently
# live, flags budget overruns (docs' own stated tolerance is ONE heavy unit at a time),
# and flags orphaned on-demand namespaces (running pods with no owning Application —
# exactly the artifactory bug). Wired as a blocking pre-check in every `make <name>-up`
# target (see Makefile's `ondemand-guard` macro) and as an informational section in
# `make health`.
#
# Usage:
#   ondemand-budget-check.sh                 report + exit 1 if >1 unit is up, or any orphan found
#   ondemand-budget-check.sh --pre <unit>     same, but excludes <unit> from the "already up" count
#                                              (used by the `-up` targets to check the OTHER units)
#   ondemand-budget-check.sh --list           machine-readable: one "<unit> <up|down>" line per unit
#
# Override: ONDEMAND_BUDGET_FORCE=1 skips the exit-1 (still prints the report) — for a
# deliberate multi-component demo session. Never silently skip the report itself.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
note() { printf '      %s%s%s\n' "$Y" "$1" "$Z"; }

# unit -> space-separated ArgoCD Application names that make up that unit.
# Empty: Harbor and Kargo (the last two heavy on-demand units) were both removed
# entirely 2026-09-07, no replacement. Add the next heavy on-demand component here.
declare -A UNIT_APPS=(
)
# unit -> space-separated namespace(s) actually holding its workload pods. Used as the
# authoritative "is it really consuming host resources" signal (see unit_is_up()).
declare -A UNIT_NS=(
)
# unit -> documented size (Makefile `##` comments / docs/00-architecture.md).
declare -A UNIT_SIZE=(
)
# on-demand namespaces, for orphan detection — kept in sync with
# scripts/lab-health-check.sh's LAB_ONDEMAND_NS default. All of these are now
# permanently-orphaned-if-present: kargo/harbor (removed 2026-09-07), artifactory
# (decommissioned, ADR-0024), and tidb/tidb-admin/istio-system/kiali/longhorn-system
# (removed 2026-09-06) — namespaces aren't self-deleting, so a stray manual
# `make <x>-up` from before removal can still leave one behind.
ONDEMAND_NS="kargo harbor artifactory tidb tidb-admin istio-system kiali longhorn-system"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl not installed"; exit 2; }
kubectl get nodes >/dev/null 2>&1 || { bad "cluster unreachable (kubectl get nodes failed)"; exit 2; }

unit_is_up() {
  # NOT mere existence: the "root" app-of-apps (gitops/platform/*.yaml) declares
  # these Application objects in git, so ArgoCD's own auto-sync/selfHeal recreates
  # them the moment `make X-down` deletes one — existence alone is true FOREVER once
  # a unit has ever been brought up, permanently false-positiving the guard (found
  # live 2026-08-05 recovering the very incident this script guards against: kiali/
  # longhorn/tidb-demo Applications reappeared with health=Missing minutes after
  # being deleted). health=Missing means no live resources — genuinely down.
  #
  # health!=Missing alone isn't sufficient either (found live 2026-08-07): a
  # freshly-recreated Application with a single leftover resource ArgoCD's
  # foreground-cascade delete didn't remove (observed: a PersistentVolumeClaim,
  # which `kubectl delete` intentionally preserves unless the PVC itself is
  # targeted) rolls the aggregate health up to "Healthy" even though every
  # Deployment/StatefulSet/Pod is gone — `harbor` reported health=Healthy for
  # hours after `make harbor-down` with zero pods actually running. The
  # authoritative signal for "is this unit consuming host resources right now"
  # is whether it has any live Pod in its own namespace(s), not ArgoCD's
  # resource-rollup health, which reflects git-desired state as much as live
  # state. Require both: a non-Missing Application AND at least one real Pod.
  local unit="$1" app health ns pod_count=0
  local any_healthy=1
  for app in ${UNIT_APPS[$unit]}; do
    health="$(kubectl get application -n argocd "$app" -o jsonpath='{.status.health.status}' 2>/dev/null)"
    [ -n "$health" ] && [ "$health" != "Missing" ] && any_healthy=0
  done
  [ "$any_healthy" -eq 1 ] && return 1
  for ns in ${UNIT_NS[$unit]}; do
    pod_count=$(( pod_count + $(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l) ))
  done
  [ "$pod_count" -gt 0 ]
}

MODE="report"; EXCLUDE=""
case "${1:-}" in
  --pre) MODE="pre"; EXCLUDE="${2:-}" ;;
  --list) MODE="list" ;;
esac

UP_UNITS=()
for unit in "${!UNIT_APPS[@]}"; do
  [ "$MODE" = "pre" ] && [ "$unit" = "$EXCLUDE" ] && continue
  if unit_is_up "$unit"; then
    UP_UNITS+=("$unit")
    [ "$MODE" = "list" ] && echo "$unit up"
  else
    [ "$MODE" = "list" ] && echo "$unit down"
  fi
done
[ "$MODE" = "list" ] && exit 0

# --- orphan detection: on-demand namespace with live pods but no owning Application ---
ORPHANS=()
for ns in $ONDEMAND_NS; do
  kubectl get ns "$ns" >/dev/null 2>&1 || continue
  pods="$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [ "$pods" -gt 0 ] || continue
  # namespace name doesn't map 1:1 to an app name in all cases (istio-system, tidb-admin,
  # kiali(ns)==kiali(app), harbor(ns)==harbor(app)) — treat "no unit reporting up whose
  # namespace-ish name matches" as orphaned; this intentionally over-flags rather than
  # under-flags, since a false "check this" is cheap and a missed orphan burns RAM for days.
  is_owned=1
  case "$ns" in
    kargo) unit_is_up kargo || is_owned=0 ;;
    harbor) unit_is_up harbor || is_owned=0 ;;
    # No unit owns these anymore — always orphaned if present. artifactory:
    # decommissioned, ADR-0024. tidb/tidb-admin/istio-system/kiali/longhorn-system:
    # TiDB, Istio+Kiali, and Longhorn removed from the lab entirely 2026-09-06.
    artifactory|tidb|tidb-admin|istio-system|kiali|longhorn-system) is_owned=0 ;;
  esac
  [ "$is_owned" -eq 0 ] && ORPHANS+=("$ns ($pods pods)")
done

echo "On-demand resource budget (12 GB VM; the always-on baseline was last measured"
echo "at ~7 GB pre-2026-09-06/07-simplification and hasn't been remeasured at the"
echo "current, much smaller scope — ROADMAP.md rule #4; each heavy unit adds 1-4 GB,"
echo "tolerance is ONE unit up at a time):"
echo
if [ "${#UP_UNITS[@]}" -eq 0 ]; then
  ok "no on-demand units currently up"
else
  for unit in "${UP_UNITS[@]}"; do
    note "$unit is up — ${UNIT_SIZE[$unit]} (bring down with: make $unit-down)"
  done
fi

drift=0
if [ "${#UP_UNITS[@]}" -gt 1 ]; then
  bad "${#UP_UNITS[@]} on-demand units up simultaneously — over the documented budget"
  drift=1
elif [ "$MODE" = "pre" ] && [ "${#UP_UNITS[@]}" -ge 1 ]; then
  bad "bringing up '$EXCLUDE' alongside ${UP_UNITS[*]} would exceed the documented"
  note "  one-unit-at-a-time budget — run 'make ${UP_UNITS[0]}-down' first, or set"
  note "  ONDEMAND_BUDGET_FORCE=1 if you deliberately need both up together"
  drift=1
fi

if [ "${#ORPHANS[@]}" -gt 0 ]; then
  bad "orphaned on-demand namespace(s) — pods running, no owning ArgoCD Application:"
  for o in "${ORPHANS[@]}"; do note "$o — was this left running from a manual debugging session?"; done
  drift=1
fi

if [ "$drift" -eq 1 ] && [ "${ONDEMAND_BUDGET_FORCE:-0}" = "1" ]; then
  note "ONDEMAND_BUDGET_FORCE=1 set — not blocking, but the report above is still real"
  drift=0
fi

exit "$drift"
