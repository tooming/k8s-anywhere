#!/usr/bin/env bash
# Idempotent: ensure Grafana's native Git Sync "Repository" exists, so Grafana
# provisions dashboards from GitLab and commits UI edits back (ADR-0006).
#
# The Repository is a provisioning.grafana.app resource that lives in Grafana's
# OWN apiserver/unified-storage — NOT the k3d cluster, so ArgoCD can't reconcile
# it. Creating it is therefore an imperative bootstrap seam, like garage-bootstrap.sh.
# Requires the `provisioning` + `kubernetesDashboards` feature toggles (set in
# gitops/platform/observability-grafana.yaml) to be live on Grafana 13.x.
set -euo pipefail

ONS=observability
VNS=vault
KCTX="${KCTX:-}"
kubectl() { command kubectl ${KCTX:+--context "$KCTX"} "$@"; }

# Grafana front-door (the stable :8000 proxy, not a per-cluster Envoy port —
# scripts/bluegreen-frontdoor.sh, docs/DR.md). Override for port-forward / a
# different route.
GRAFANA_URL="${GRAFANA_URL:-http://localhost:8000}"
NS="${GRAFANA_API_NS:-default}"           # Grafana apiserver namespace (single-org OSS)
REPO_NAME="${REPO_NAME:-lab-dashboards}"
GIT_URL="${GIT_URL:-https://host.k3d.internal:8930/lab/k8s-lab.git}"   # TLS proxy (Pure Git needs https)
GIT_BRANCH="${GIT_BRANCH:-main}"
GIT_PATH="${GIT_PATH:-grafana/dashboards}"
GIT_USER="${GIT_USER:-root}"              # GitLab user owning the PAT

# Grafana admin creds (Vault -> ESO -> grafana-admin Secret).
PW=$(kubectl -n "$ONS" get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d)
USER=$(kubectl -n "$ONS" get secret grafana-admin -o jsonpath='{.data.admin-user}' | base64 -d)

# Wait for Grafana to be healthy before making API calls.  On a from-scratch
# bootstrap Grafana only starts once ESO has synced grafana-admin from Vault, and
# then the init containers must finish: download-dashboards curls each community
# gnetId dashboard from grafana.com (up to --max-time 60s each — 6 dashboards is a
# ~360s worst case), then ca-bundle builds the CA bundle. The wait must clear that
# whole cold start, or `make up` fails its LAST step on a fresh lab even though
# Grafana is fine seconds later. Budget = (#gnetId dashboards x 60s) + startup
# headroom; scripts/grafana-gitsync-wait-check.sh enforces it can't fall short.
WAIT="${GRAFANA_WAIT:-600}"
echo "[grafana-gitsync] waiting up to ${WAIT}s for Grafana to be healthy ($GRAFANA_URL)..."
end=$((SECONDS + WAIT))
while true; do
  health=$(curl -fsS --max-time 10 "$GRAFANA_URL/api/health" 2>/dev/null || true)
  [ "$(printf '%s' "$health" | jq -r '.database' 2>/dev/null)" = "ok" ] && break
  [ "$SECONDS" -ge "$end" ] && { echo "[grafana-gitsync] ERROR: Grafana not healthy after ${WAIT}s"; exit 1; }
  sleep 10
done
echo "[grafana-gitsync] Grafana is healthy."

# GitLab PAT: the api-scoped bootstrap token, read straight from Vault (same seam
# as garage-bootstrap.sh). Grafana stores it encrypted in its own secret store via
# the Repository's `secure.token`, so no runtime k8s Secret is needed.
VT=$(kubectl -n "$VNS" get secret vault-keys -o jsonpath='{.data.root-token}' | base64 -d)
PAT=$(kubectl -n "$VNS" exec vault-0 -- env VAULT_TOKEN="$VT" vault kv get -field=token secret/gitlab/bootstrap)
[ -n "$PAT" ] || { echo "[grafana-gitsync] ERROR: no GitLab token at secret/gitlab/bootstrap (run scripts/gitlab-pat.sh + vault-bootstrap)"; exit 1; }

# Land on the Stack Health dashboard (replaces the removed sidecar default_home_dashboard_path).
# Best-effort + idempotent; the uid resolves once Git Sync imports it.
curl -fsS -u "$USER:$PW" -H 'Content-Type: application/json' -X PATCH \
  "$GRAFANA_URL/api/org/preferences" -d '{"homeDashboardUID":"lab-stack-health"}' >/dev/null 2>&1 \
  && echo "[grafana-gitsync] home dashboard -> lab-stack-health" || echo "[grafana-gitsync] (home dashboard not set yet)"

BASE="$GRAFANA_URL/apis/provisioning.grafana.app/v0alpha1/namespaces/$NS/repositories"

# Already provisioned? (don't clobber UI/token state on re-run)
code=$(curl -fsS -o /dev/null -w '%{http_code}' -u "$USER:$PW" "$BASE/$REPO_NAME" 2>/dev/null || true)
if [ "$code" = "200" ]; then
  echo "[grafana-gitsync] Repository '$REPO_NAME' already exists — leaving it untouched."
  exit 0
fi

echo "[grafana-gitsync] creating Repository '$REPO_NAME' -> $GIT_URL ($GIT_BRANCH:$GIT_PATH)"
resp=$(curl -sS -w $'\n%{http_code}' -u "$USER:$PW" -H 'Content-Type: application/json' \
  -X POST "$BASE" --data-binary @- <<JSON
{
  "apiVersion": "provisioning.grafana.app/v0alpha1",
  "kind": "Repository",
  "metadata": { "name": "$REPO_NAME", "namespace": "$NS" },
  "spec": {
    "title": "Lab dashboards (GitLab, Pure Git)",
    "description": "Dashboards as code, synced bidirectionally with GitLab (ADR-0006).",
    "type": "git",
    "git": { "url": "$GIT_URL", "branch": "$GIT_BRANCH", "path": "$GIT_PATH", "tokenUser": "$GIT_USER" },
    "sync": { "enabled": true, "intervalSeconds": 60, "target": "folder" },
    "workflows": ["write"]
  },
  "secure": { "token": { "create": "$PAT" } }
}
JSON
)
http=$(printf '%s' "$resp" | tail -n1)
body=$(printf '%s' "$resp" | sed '$d')
case "$http" in
  200|201)
    echo "[grafana-gitsync] Repository '$REPO_NAME' created."
    echo "[grafana-gitsync] check sync:  curl -s -u <admin> $BASE/$REPO_NAME/status | jq .status.sync"
    ;;
  *)
    echo "[grafana-gitsync] ERROR: create failed (HTTP $http)" >&2
    printf '%s\n' "$body" >&2
    exit 1
    ;;
esac
