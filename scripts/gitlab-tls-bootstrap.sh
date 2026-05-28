#!/usr/bin/env bash
# Mint a local TLS cert (mkcert) for the GitLab front door and publish the mkcert
# root CA into the cluster so Grafana's Git Sync client can trust it. Grafana's
# Pure Git Sync requires HTTPS (it rejects http://), but the lab GitLab is http-only,
# so an nginx TLS proxy (gitlab/docker-compose.yml, service `gitlab-tls`, :8930)
# fronts it. Idempotent; safe to re-run. Part of `make up`. See ADR-0006.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ONS=observability
TLS_DIR="$ROOT/gitlab/tls"

command -v mkcert >/dev/null 2>&1 || { echo "[gitlab-tls] ERROR: mkcert not installed (brew install mkcert)" >&2; exit 1; }
mkdir -p "$TLS_DIR"
# Deliberately NOT running `mkcert -install`: we don't need the CA in the host's
# system trust store (Grafana trusts it via the published ConfigMap; host checks pass
# --cacert explicitly). mkcert still auto-creates the CA in CAROOT on first cert gen,
# so this avoids mutating the developer's keychain as a side effect.
CAROOT="$(mkcert -CAROOT)"

if [ -s "$TLS_DIR/tls.crt" ] && [ -s "$TLS_DIR/tls.key" ]; then
  echo "[gitlab-tls] reusing existing cert in $TLS_DIR"
else
  echo "[gitlab-tls] minting cert for host.k3d.internal, localhost, gitlab.local, 127.0.0.1"
  mkcert -cert-file "$TLS_DIR/tls.crt" -key-file "$TLS_DIR/tls.key" \
    host.k3d.internal localhost gitlab.local 127.0.0.1 >/dev/null 2>&1
fi

# Publish the mkcert root CA so Grafana can trust the proxy cert. It is NOT secret
# (a public CA cert), so a ConfigMap is the right home; the Grafana pod mounts it
# and appends it to its CA bundle (see gitops/platform/observability-grafana.yaml).
if kubectl get ns "$ONS" >/dev/null 2>&1; then
  kubectl -n "$ONS" create configmap gitlab-tls-ca \
    --from-file=ca.crt="$CAROOT/rootCA.pem" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  echo "[gitlab-tls] published mkcert root CA -> configmap/gitlab-tls-ca (ns $ONS)"
  # If Grafana is already running its init container already baked a CA bundle that
  # may be missing the mkcert CA (e.g. the CA arrived late, or this is a re-run).
  # Roll the deployment so the init re-runs and appends the CA before Grafana starts.
  ready=$(kubectl -n "$ONS" get deploy grafana -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [ "${ready:-0}" -ge 1 ]; then
    echo "[gitlab-tls] Grafana is running; rolling deployment so the init re-reads the CA bundle..."
    kubectl -n "$ONS" rollout restart deployment/grafana >/dev/null
  fi
else
  echo "[gitlab-tls] WARN: namespace $ONS missing (cluster down?); skipped publishing CA"
fi

echo "[gitlab-tls] starting/refreshing the TLS proxy (compose profile 'tls')"
( cd "$ROOT/gitlab" && docker compose --profile tls up -d gitlab-tls )
echo "[gitlab-tls] done — GitLab HTTPS proxy at https://host.k3d.internal:8930 (and https://localhost:8930)"
