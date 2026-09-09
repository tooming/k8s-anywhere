#!/usr/bin/env bash
# CoreDNS custom override for in-cluster clients: rewrites
# *.127.0.0.1.nip.io -> Traefik's in-cluster Service (ADR-0040, supersedes
# Envoy Gateway/ADR-0008). nip.io's real wildcard DNS resolves any of its
# subdomains to the literal IP embedded in the name, 127.0.0.1 — which is
# a *pod's own loopback* for any in-cluster client, not the ingress
# controller. Every IngressRoute hostname in this lab needs this
# to be reachable from another pod. Found live and first
# patched out-of-band (not committed anywhere) in PR #1323 while
# investigating issue #633; this brings that fix under GitOps/`make up`
# management instead of living only as a manual live kubectl patch.
#
# Traefik ships with k3s itself, so this Service exists from cluster boot
# with no ArgoCD-sync dependency at all (unlike Envoy Gateway's per-Gateway
# proxy Service, which was dynamically discovered via labels). Not
# live-cluster-verified against every k3s version's chart — see ADR-0040's
# "Known risk".
#
# This script used to also manage a second, independent rewrite —
# host.k3d.internal -> the docker host gateway, needed because k3d 5.x
# doesn't inject that into the node container's /etc/hosts under Colima/
# Docker on macOS. That alias was load-bearing only for ArgoCD's old
# Forgejo repoURL (http://host.k3d.internal:2223/...); Forgejo was removed
# entirely 2026-09-07 (ADR-0035), gitops/bootstrap/root-app.yaml's repoURL
# is now a public GitHub HTTPS URL, and a repo-wide grep found zero
# remaining consumers. Removed 2026-09-09 after live verification that
# `make argocd` + `make root-app` succeed against the GitHub repoURL
# without it (issue #1517) — k3d's own CoreDNS injection now also handles
# host.k3d.internal natively (`k3d cluster create` logs "Injecting records
# for hostAliases (incl. host.k3d.internal)..."), so even a future consumer
# wouldn't need this script's help for that hostname.
#
# Idempotent: only restarts CoreDNS when the ConfigMap actually changed.

set -euo pipefail

NS=kube-system
TRAEFIK_NS=kube-system
TRAEFIK_SVC=traefik

get_key() {
  kubectl -n "$NS" get cm coredns-custom -o jsonpath="{.data.$1}" 2>/dev/null || true
}
# strip optional trailing newline that kubectl ConfigMap values often carry
OLD_NIPIO="$(get_key 'nip-io-rewrite\.server')"
OLD_NIPIO="${OLD_NIPIO%$'\n'}"

# Traefik ships with k3s itself (ADR-0040) — no ArgoCD-sync dependency the way
# Envoy Gateway's per-Gateway proxy Service had, but k3s still takes a moment to
# schedule it after cluster creation, so a short existence-wait is kept rather
# than assuming it's already up.
WAIT="${COREDNS_NIPIO_WAIT:-300}"
echo "[coredns] waiting up to ${WAIT}s for Traefik's Service ($TRAEFIK_NS/$TRAEFIK_SVC) to exist..."
end=$((SECONDS + WAIT))
until kubectl -n "$TRAEFIK_NS" get svc "$TRAEFIK_SVC" >/dev/null 2>&1; do
  if [ "$SECONDS" -ge "$end" ]; then
    echo "[coredns] ERROR: no Traefik Service $TRAEFIK_NS/$TRAEFIK_SVC appeared within ${WAIT}s — has k3s finished bootstrapping?" >&2
    exit 1
  fi
  sleep 5
done
TARGET="$TRAEFIK_SVC.$TRAEFIK_NS.svc.cluster.local."
echo "[coredns] rewriting *.127.0.0.1.nip.io -> $TARGET"
NEW_NIPIO="nip-io-rewrite.server {
    rewrite name regex (.*)\.127\.0\.0\.1\.nip\.io $TARGET answer auto
}"

if [ "$NEW_NIPIO" = "$OLD_NIPIO" ]; then
  echo "[coredns] coredns-custom already up to date — nothing to do"
  exit 0
fi

kubectl -n "$NS" create configmap coredns-custom --dry-run=client -o yaml \
  --from-literal="nip-io-rewrite.server=$NEW_NIPIO" \
  | kubectl apply -f -

kubectl -n "$NS" rollout restart deploy/coredns >/dev/null
kubectl -n "$NS" rollout status deploy/coredns --timeout=60s >/dev/null
echo "[coredns] coredns-custom updated"
