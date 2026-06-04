#!/usr/bin/env bash
# Add a CoreDNS custom override so `host.k3d.internal` resolves to the docker
# host gateway from inside the cluster. k3d 5.x does NOT inject this into the
# node container's /etc/hosts when running under Colima/Docker on macOS, so
# without this fix every ArgoCD Application (whose repoURL points at the local
# GitLab via http://host.k3d.internal:8929/...) silently fails to fetch on
# refresh and drifts away from the desired state.
#
# Idempotent: only restarts CoreDNS when the ConfigMap actually changed.

set -euo pipefail

NS=kube-system
NET=k3d-k8s-lab

GW="$(docker network inspect "$NET" --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || true)"
if [ -z "$GW" ]; then
  echo "[coredns] could not resolve docker network $NET gateway — is the cluster up?" >&2
  exit 1
fi

echo "[coredns] mapping host.k3d.internal -> $GW"

DESIRED="host.k3d.internal:53 {
    hosts {
        $GW host.k3d.internal
        fallthrough
    }
}"

CURRENT="$(kubectl -n "$NS" get cm coredns-custom -o jsonpath='{.data.host-k3d-internal\.server}' 2>/dev/null || true)"
# strip optional trailing newline that kubectl ConfigMap values often carry
CURRENT="${CURRENT%$'\n'}"
if [ "$CURRENT" = "$DESIRED" ]; then
  echo "[coredns] coredns-custom already up to date — nothing to do"
  exit 0
fi

kubectl -n "$NS" create configmap coredns-custom \
  --from-literal=host-k3d-internal.server="$DESIRED" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NS" rollout restart deploy/coredns >/dev/null
kubectl -n "$NS" rollout status deploy/coredns --timeout=60s >/dev/null
echo "[coredns] host.k3d.internal alias installed"
