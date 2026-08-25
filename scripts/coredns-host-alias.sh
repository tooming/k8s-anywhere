#!/usr/bin/env bash
# CoreDNS custom overrides needed for in-cluster clients. Two independent
# rewrites live in the same coredns-custom ConfigMap (kube-system):
#
#  1. host.k3d.internal -> the docker host gateway. k3d 5.x does NOT inject
#     this into the node container's /etc/hosts when running under Colima/
#     Docker on macOS, so without it every ArgoCD Application (whose repoURL
#     points at the local GitLab via http://host.k3d.internal:8929/...)
#     silently fails to fetch on refresh and drifts away from desired state.
#
#  2. *.127.0.0.1.nip.io -> the Envoy Gateway's in-cluster proxy Service.
#     nip.io's real wildcard DNS resolves any of its subdomains to the literal
#     IP embedded in the name, 127.0.0.1 — which is a *pod's own loopback* for
#     any in-cluster client, not the gateway. Every HTTPRoute hostname in this
#     lab (argocd, capstone, grafana, harbor, kargo, kiali, longhorn, moto,
#     rabbitmq, rollouts, s3, tidb-demo, vault — all route through the one
#     shared Gateway, ADR-0008) needs this to be reachable from another pod —
#     e.g. Kargo's Warehouse polling Harbor for image digests. Found live and
#     first patched out-of-band (not committed anywhere) in PR #1323 while
#     investigating issue #633; this brings that fix under GitOps/`make up`
#     management instead of living only as a manual live kubectl patch.
#
# Usage: coredns-host-alias.sh [host-alias|nip-io-rewrite]
#   host-alias (default)  — (re)compute ONLY the host.k3d.internal key, from
#                            the docker network gateway. Run early in `make up`
#                            (step 5, `make coredns-host-alias`) — before
#                            ArgoCD has synced anything, so Envoy Gateway's
#                            proxy Service does not exist yet.
#   nip-io-rewrite         — (re)compute ONLY the *.nip.io key, by discovering
#                            Envoy Gateway's generated proxy Service via its
#                            documented `gateway.envoyproxy.io/owning-gateway-
#                            {name,namespace}` labels. Run later in `make up`
#                            (`make coredns-nip-io-rewrite`, after `root-app`
#                            has had time to sync Envoy Gateway).
#
# Whichever mode runs carries the OTHER key's current live value forward
# unchanged, rather than omitting it: `kubectl apply` replaces a ConfigMap's
# `data` map against its own last-applied-configuration, so a call that only
# included one key would silently DELETE the other key on apply instead of
# leaving it alone. Both keys are always included in every apply this script
# makes (when a value — freshly computed or carried-forward — exists for it).
#
# Idempotent: only restarts CoreDNS when the ConfigMap actually changed.

set -euo pipefail

NS=kube-system
NET=k3d-k8s-lab
EG_NS=envoy-gateway-system
GW_NAME=eg
GW_NS=lab-gateway

MODE="${1:-host-alias}"
case "$MODE" in
  host-alias | nip-io-rewrite) ;;
  *)
    echo "[coredns] unknown mode: $MODE (expected host-alias or nip-io-rewrite)" >&2
    exit 1
    ;;
esac

get_key() {
  kubectl -n "$NS" get cm coredns-custom -o jsonpath="{.data.$1}" 2>/dev/null || true
}
# strip optional trailing newline that kubectl ConfigMap values often carry
OLD_HOST_ALIAS="$(get_key 'host-k3d-internal\.server')"
OLD_HOST_ALIAS="${OLD_HOST_ALIAS%$'\n'}"
OLD_NIPIO="$(get_key 'nip-io-rewrite\.server')"
OLD_NIPIO="${OLD_NIPIO%$'\n'}"

NEW_HOST_ALIAS="$OLD_HOST_ALIAS"
NEW_NIPIO="$OLD_NIPIO"

if [ "$MODE" = "host-alias" ]; then
  GW="$(docker network inspect "$NET" --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || true)"
  if [ -z "$GW" ]; then
    echo "[coredns] could not resolve docker network $NET gateway — is the cluster up?" >&2
    exit 1
  fi
  echo "[coredns] mapping host.k3d.internal -> $GW"
  NEW_HOST_ALIAS="host.k3d.internal:53 {
    hosts {
        $GW host.k3d.internal
        fallthrough
    }
}"
else
  # root-app (make up step) only plants the app-of-apps and returns immediately —
  # ArgoCD's own sync of envoy-gateway (and its generation of this proxy Service)
  # can still be in flight when this runs, so poll rather than check once.
  WAIT="${COREDNS_NIPIO_WAIT:-300}"
  echo "[coredns] waiting up to ${WAIT}s for Envoy Gateway's proxy Service (owning-gateway=$GW_NS/$GW_NAME) to be created by ArgoCD..."
  end=$((SECONDS + WAIT))
  PROXY_SVC=""
  until [ -n "$PROXY_SVC" ]; do
    PROXY_SVC="$(kubectl -n "$EG_NS" get svc \
      -l "gateway.envoyproxy.io/owning-gateway-namespace=$GW_NS,gateway.envoyproxy.io/owning-gateway-name=$GW_NAME" \
      -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
    if [ -z "$PROXY_SVC" ]; then
      if [ "$SECONDS" -ge "$end" ]; then
        echo "[coredns] ERROR: no Envoy Gateway proxy Service appeared in $EG_NS within ${WAIT}s (owning-gateway=$GW_NS/$GW_NAME) — has Envoy Gateway synced?" >&2
        exit 1
      fi
      sleep 5
    fi
  done
  TARGET="$PROXY_SVC.$EG_NS.svc.cluster.local."
  echo "[coredns] rewriting *.127.0.0.1.nip.io -> $TARGET"
  NEW_NIPIO="nip-io-rewrite.server {
    rewrite name regex (.*)\.127\.0\.0\.1\.nip\.io $TARGET answer auto
}"
fi

if [ "$NEW_HOST_ALIAS" = "$OLD_HOST_ALIAS" ] && [ "$NEW_NIPIO" = "$OLD_NIPIO" ]; then
  echo "[coredns] coredns-custom already up to date — nothing to do"
  exit 0
fi

ARGS=(-n "$NS" create configmap coredns-custom --dry-run=client -o yaml)
if [ -n "$NEW_HOST_ALIAS" ]; then
  ARGS+=(--from-literal="host-k3d-internal.server=$NEW_HOST_ALIAS")
fi
if [ -n "$NEW_NIPIO" ]; then
  ARGS+=(--from-literal="nip-io-rewrite.server=$NEW_NIPIO")
fi

kubectl "${ARGS[@]}" | kubectl apply -f -

kubectl -n "$NS" rollout restart deploy/coredns >/dev/null
kubectl -n "$NS" rollout status deploy/coredns --timeout=60s >/dev/null
echo "[coredns] coredns-custom updated"
