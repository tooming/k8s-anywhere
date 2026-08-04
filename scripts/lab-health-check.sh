#!/usr/bin/env bash
# Honest, automated cluster-health gate. No eyeballing, no cherry-picking: it walks
# EVERY pod and every Deployment/StatefulSet/DaemonSet and waits for convergence before
# declaring anything down.
#
# "Healthy" = every pod is Running with all containers Ready (or a Job/Completed pod),
# AND every Deployment/StatefulSet/DaemonSet has all desired replicas Ready.
#
# It deliberately ignores two kinds of pod that are SUPPOSED to be transient/absent:
#   * Job-owned pods (Trivy scans, hook jobs, …) — ephemeral by design; their
#     Completion is what matters, not steady Readiness.
#   * On-demand components — the manual `make *-up` targets (TiDB, Harbor, Istio,
#     Kiali, Longhorn, Inkless, Kargo) + the capstone demo (needs the on-demand
#     Harbor registry). `make up` never starts them, so a missing/unhealthy one isn't a
#     `make up` failure. Override the set with LAB_ONDEMAND_NS="ns1 ns2 …".
#
# Polls up to HEALTH_WAIT seconds (default 90; 0 = single snapshot) so a workload that's
# still converging — pulling an image, downloading a plugin/DB, rolling — isn't reported
# as down. Everything else is always-on and MUST be up.
#
# Exit 0 = every always-on pod + workload healthy. 1 = an always-on workload is down. 2 = tooling/cluster unreachable.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
WAIT="${HEALTH_WAIT:-90}"
IV="${HEALTH_INTERVAL:-10}"
ONDEMAND_NS="${LAB_ONDEMAND_NS:-tidb tidb-admin tidb-demo istio-system kiali longhorn-system inkless kargo ack-system capstone harbor}"
# Front-door UIs to probe (HTTP, from the host) — readiness of the pods behind Envoy
# isn't enough: if the Envoy data plane is down, every :8000 UI is unreachable while the
# pods still look fine. Probes the stable front door (:8000), not a per-cluster Envoy
# port (:8080 blue / :8082 green) — those go away entirely once the cluster they belong
# to is torn down after a blue/green cutover (docs/DR.md), so hardcoding one here would
# make `make health` silently probe the wrong (or a since-removed) backend post-cutover.
# "url|name", space-separated. Set LAB_UI_PROBES= to skip.
UI_PROBES="${LAB_UI_PROBES:-http://localhost:8000/api/health|grafana(:8000) http://argocd.127.0.0.1.nip.io:8000/healthz|argocd(:8000)}"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
note() { printf '      %s%s%s\n' "$Y" "$1" "$Z"; }

for t in kubectl jq; do command -v "$t" >/dev/null 2>&1 || { echo "$t not installed — cannot check cluster health"; exit 2; }; done
kubectl get nodes >/dev/null 2>&1 || { bad "cluster unreachable (kubectl get nodes failed)"; exit 2; }

is_ondemand() { local ns="$1" n; for n in $ONDEMAND_NS; do [ "$n" = "$ns" ] && return 0; done; return 1; }

# Collect the current set of unhealthy ALWAYS-ON things into globals A_POD / A_WL, and
# the informational on-demand offenders into O_POD. Returns 0 if always-on is all green.
scan() {
  A_POD=""; A_WL=""; O_POD=""
  # --- pods: Running+all-ready, skipping Succeeded and Job-owned (ephemeral) ----
  local podjson
  podjson="$(kubectl get pods -A -o json 2>/dev/null)" || return 1
  local bad_pods
  bad_pods="$(jq -r '
    .items[]
    | select(.status.phase != "Succeeded")
    | select((.metadata.ownerReferences // []) | map(.kind) | index("Job") | not)
    | { ns:.metadata.namespace, name:.metadata.name, phase:.status.phase,
        ready: ((.status.containerStatuses // []) | (length>0) and (all(.ready==true))) }
    | select((.phase != "Running") or (.ready == false))
    | "\(.ns)\t\(.name)\t\(.phase)"
  ' <<<"$podjson" 2>/dev/null)"
  while IFS=$'\t' read -r ns name phase; do
    [ -n "$ns" ] || continue
    if is_ondemand "$ns"; then O_POD+="$ns/$name  $phase"$'\n'; else A_POD+="$ns/$name  $phase"$'\n'; fi
  done <<<"$bad_pods"

  # --- workloads: desired replicas all Ready (always-on only) -------------------
  local wl
  wl="$(kubectl get deploy,statefulset,daemonset -A -o json 2>/dev/null | jq -r '
    .items[]
    | { kind:.kind, ns:.metadata.namespace, name:.metadata.name,
        desired:(.status.replicas // .status.desiredNumberScheduled // 0),
        ready:(.status.readyReplicas // .status.numberReady // 0) }
    | select(.desired != .ready)
    | "\(.kind)\t\(.ns)\t\(.name)\t\(.ready)/\(.desired)"
  ' 2>/dev/null)"
  while IFS=$'\t' read -r kind ns name r; do
    [ -n "$ns" ] || continue
    is_ondemand "$ns" && continue
    A_WL+="$kind $ns/$name  ready=$r"$'\n'
  done <<<"$wl"

  # --- front door: the :8000 UIs must actually answer over HTTP -----------------
  F=""
  local p url name code
  for p in $UI_PROBES; do
    url=${p%|*}; name=${p#*|}
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 6 "$url" 2>/dev/null)"
    case "$code" in 2*|3*|401|403) ;; *) F+="$name unreachable via the Envoy front door (HTTP $code) — $url"$'\n' ;; esac
  done

  [ -z "$A_POD" ] && [ -z "$A_WL" ] && [ -z "$F" ]
}

printf '%s== lab health ==%s  (polling up to %ss for every always-on workload to be Running+Ready)\n' "$B" "$Z" "$WAIT"
end=$((SECONDS + WAIT))
while :; do
  if scan; then break; fi
  [ "$SECONDS" -ge "$end" ] && break
  sleep "$IV"
done

fail=0
if [ -z "$A_POD" ] && [ -z "$A_WL" ] && [ -z "${F:-}" ]; then
  ok "every always-on pod Running+Ready, every workload's replicas Ready, and the Envoy front-door UIs answer"
else
  [ -n "$A_POD" ] && { bad "always-on pods NOT Running+Ready:"; printf '%s' "$A_POD" | while read -r l; do [ -n "$l" ] && note "$l"; done; }
  [ -n "$A_WL" ]  && { bad "always-on workloads with replicas not Ready:"; printf '%s' "$A_WL" | while read -r l; do [ -n "$l" ] && note "$l"; done; }
  [ -n "${F:-}" ] && { bad "front-door UIs unreachable (Envoy data path down even if pods look Ready):"; printf '%s' "$F" | while read -r l; do [ -n "$l" ] && note "$l"; done; }
  fail=1
fi
if [ -n "${O_POD:-}" ]; then
  printf '  %s·%s on-demand pods not Running (not part of make up — start with their make target):\n' "$Y" "$Z"
  printf '%s' "$O_POD" | while read -r l; do [ -n "$l" ] && note "$l"; done
fi

echo
if [ "$fail" -eq 0 ]; then printf '%s%sLAB HEALTH: PASS%s — the always-on stack is fully up.\n' "$B" "$G" "$Z"
else printf '%s%sLAB HEALTH: FAIL%s — an always-on workload is down (see ✗).\n' "$B" "$R" "$Z"; fi
exit "$fail"
