#!/usr/bin/env bash
# Guards docs/00-architecture.md's documented resource ceiling: "A 12 GB Colima VM
# holds the always-on stack at ~7 GB. Heavy components (Harbor, Kargo) each add
# 1-4 GB. Running two full stacks at once would exhaust the VM." Nothing enforced
# that until now (2026-08-05 incident): a chain of live-debugging sessions each ran
# a `make <name>-up` and never the matching `-down`, so Harbor, Istio, Kiali,
# Longhorn, Kargo, and TiDB ended up running SIMULTANEOUSLY — plus a fully orphaned
# `artifactory` namespace with no owning ArgoCD Application at all, left over from
# before the Harbor migration (ADR-0024) decommissioned it. The Colima VM hit
# 11Gi/11Gi memory used, load average 30+ on 6 cores, kubelet couldn't
# garbage-collect ("Attempted to free 3.3GB, found 0 bytes eligible"), the node flapped
# NodeNotReady, envoy-gateway lost leader election against a starved apiserver and
# crashlooped, and every front-door UI in README.md's table 502'd. (TiDB, Istio, and
# Longhorn were removed from the lab entirely 2026-09-06 — see the incident log —
# so only Harbor and Kargo remain as heavy on-demand units this guard tracks.)
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

# unit -> space-separated ArgoCD Application names that make up that unit
declare -A UNIT_APPS=(
  [harbor]="harbor harbor-extras"
  [kargo]="kargo-extras kargo kargo-networkpolicy kargo-project"
)
# unit -> space-separated namespace(s) actually holding its workload pods. Used as the
# authoritative "is it really consuming host resources" signal (see unit_is_up()).
declare -A UNIT_NS=(
  [harbor]="harbor"
  [kargo]="kargo"
)
# unit -> documented size (Makefile `##` comments / docs/00-architecture.md). Harbor has
# no committed estimate anywhere in the repo — don't invent one (ADR-0004); flag it as
# heavy-but-undocumented instead.
declare -A UNIT_SIZE=(
  [harbor]="undocumented size — treat as heavy (Garage-backed registry + DB + jobservice)"
  [kargo]="~250-450 MB"
)
# on-demand namespaces, for orphan detection — kept in sync with
# scripts/lab-health-check.sh's LAB_ONDEMAND_NS default plus the historical
# artifactory carve-out (decommissioned, ADR-0024, but namespaces aren't
# self-deleting, so a stray manual `make artifactory-up` can still leave one behind)
# and the historical tidb/tidb-admin/istio-system/kiali/longhorn-system carve-outs
# (all three components removed from the lab entirely 2026-09-06, same reasoning).
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

echo "On-demand resource budget (docs/00-architecture.md: 12 GB VM, ~7 GB always-on baseline,"
echo "each heavy unit adds 1-4 GB — the doc's own tolerance is ONE unit up at a time):"
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
