#!/usr/bin/env bash
# Verify the lab is genuinely healthy end-to-end. Used standalone (`make dr-verify`)
# and as the assertion half of the DR drill (`make dr-test`, see docs/DR.md).
#
# Every check probes REAL state (live API/queries) — no placeholders. Each polls
# until satisfied or its budget expires. Exit 0 = PASS (all green), 1 = FAIL.
set -uo pipefail

# Per-check budgets (seconds). Slow ones cover post-rebuild convergence.
T_NODES="${DR_T_NODES:-120}"
T_ARGO="${DR_T_ARGO:-600}"
T_VAULT="${DR_T_VAULT:-180}"
T_ESO="${DR_T_ESO:-300}"
T_GARAGE="${DR_T_GARAGE:-240}"

# Optionally verify a specific cluster (KCTX=k3d-k8s-lab-green). Unset = current context.
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
note(){ printf '      %s%s%s\n' "$Y" "$1" "$Z"; }

# retry <timeout_s> <interval_s> <predicate-fn> : 0 if predicate succeeds in time
retry() {
  local to=$1 iv=$2 fn=$3
  local end=$((SECONDS + to))
  while :; do
    "$fn" && return 0
    [ "$SECONDS" -ge "$end" ] && return 1
    sleep "$iv"
  done
}

# ---- predicates (quiet; return 0 when the condition holds) ------------------
p_nodes() {
  local total ready
  total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
  ready=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"' | wc -l | tr -d ' ')
  [ "${total:-0}" -ge 1 ] && [ "$total" = "$ready" ]
}

p_argo() {
  local json total green
  json=$(kubectl -n argocd get applications.argoproj.io -o json 2>/dev/null) || return 1
  total=$(jq '.items|length' <<<"$json" 2>/dev/null) || return 1
  [ "${total:-0}" -ge 1 ] || return 1
  green=$(jq '[.items[]|select(.status.sync.status=="Synced" and .status.health.status=="Healthy")]|length' <<<"$json")
  [ "$total" = "$green" ]
}
argo_offenders() {
  kubectl -n argocd get applications.argoproj.io -o json 2>/dev/null \
    | jq -r '.items[]|select(.status.sync.status!="Synced" or .status.health.status!="Healthy")
             | "\(.metadata.name): sync=\(.status.sync.status) health=\(.status.health.status)"'
}

p_vault() {
  local s
  s=$(kubectl -n vault exec vault-0 -- vault status -format=json 2>/dev/null) || true
  [ -n "$s" ] \
    && [ "$(jq -r '.initialized' <<<"$s" 2>/dev/null)" = "true" ] \
    && [ "$(jq -r '.sealed' <<<"$s" 2>/dev/null)" = "false" ]
}

p_eso() {
  kubectl get clustersecretstore vault \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True || return 1
  local json total ready
  json=$(kubectl get externalsecrets.external-secrets.io -A -o json 2>/dev/null) || return 1
  total=$(jq '.items|length' <<<"$json" 2>/dev/null) || return 1
  [ "${total:-0}" -ge 1 ] || return 1
  ready=$(jq '[.items[]|select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))]|length' <<<"$json")
  [ "$total" = "$ready" ]
}
eso_offenders() {
  kubectl get externalsecrets.external-secrets.io -A -o json 2>/dev/null \
    | jq -r '.items[]|select((any(.status.conditions[]?; .type=="Ready" and .status=="True"))|not)
             | "\(.metadata.namespace)/\(.metadata.name): not Ready"'
}

GARAGE_BUCKETS="velero harbor-registry"
p_garage() {
  kubectl -n storage exec sts/garage -- /garage status >/dev/null 2>&1 || return 1
  local list b
  list=$(kubectl -n storage exec sts/garage -- /garage bucket list 2>/dev/null) || return 1
  for b in $GARAGE_BUCKETS; do grep -qw "$b" <<<"$list" || return 1; done
}

# p_mimir / p_grafana (and the curlsh in-cluster-probe helper they used) REMOVED
# 2026-09-06 (ADR-0041, observability stack removed with no replacement) —
# Mimir and Grafana no longer exist to query.

# ---- run --------------------------------------------------------------------
printf '%s== DR verify ==%s  (real end-to-end health checks)\n' "$B" "$Z"

retry "$T_NODES"   10 p_nodes   && ok "Kubernetes nodes Ready"                  || bad "Kubernetes nodes Ready"
retry "$T_ARGO"    10 p_argo    && ok "ArgoCD: all Applications Synced+Healthy" || { bad "ArgoCD: all Applications Synced+Healthy"; argo_offenders | while read -r l; do note "$l"; done; }
retry "$T_VAULT"   5  p_vault   && ok "Vault initialized + unsealed"            || bad "Vault initialized + unsealed"
retry "$T_ESO"     10 p_eso     && ok "External Secrets: all SecretSynced"      || { bad "External Secrets: all SecretSynced"; eso_offenders | while read -r l; do note "$l"; done; }
retry "$T_GARAGE"  10 p_garage  && ok "Garage up + buckets present"             || bad "Garage up + buckets ($GARAGE_BUCKETS)"

echo
if [ "$drift" -eq 0 ]; then
  printf '%s%sDR VERIFY: PASS%s — lab is healthy end-to-end.\n' "$B" "$G" "$Z"
  exit 0
else
  printf '%s%sDR VERIFY: FAIL%s — see ✗ above.\n' "$B" "$R" "$Z"
  exit 1
fi
