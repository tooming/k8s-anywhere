#!/usr/bin/env bash
# ingressroute-web-tls-check.sh — flag any Traefik IngressRoute object that
# combines the plain-HTTP `web` entryPoint with a `tls:` stanza.
#
# Found live 2026-09-06 while investigating issue #633: a `tls:` block (even the
# empty `tls: {}` this repo's IngressRoutes use to opt into the default
# TLSStore cert on `websecure`) makes Traefik's kubernetescrd provider silently
# fail to match that router on ANY plain-HTTP entryPoint also listed —
# `web` included — even though the router shows up as `status: enabled` via
# Traefik's own API with the exact correct rule, and the backend resolves and
# is healthy. No error is logged; the request just gets Traefik's generic
# "404 page not found" with no access-log trace at all, as if the router never
# existed for that entrypoint. Confirmed with a controlled test: an identical
# rule with entryPoints:[web] and NO tls field returns 200; the same rule with
# `tls: {}` added and entryPoints:[web, websecure] 404s on `web` specifically.
#
# This silently broke plain-HTTP access (the lab's documented canonical
# access path, e.g. http://argocd.127.0.0.1.nip.io:8000) for every IngressRoute
# in the repo at once post-ADR-0040 (Envoy Gateway -> Traefik), with no CI
# signal — kustomize/manifest validation has no opinion on Traefik's runtime
# router-matching semantics. The fix (see gitops/network/argocd-ingressroute.yaml's
# header comment) is to split any IngressRoute that wants both `web` and
# `websecure` into two separate objects: one on entryPoints:[web] with NO tls
# field, one on entryPoints:[websecure] with tls:{}. This script is the
# mechanical guard so a future IngressRoute can't reintroduce the combination.
#
# Runs in CI (the 'drift' gate) and as a PostToolUse hook.
set -uo pipefail
ROOT="${INGRESSROUTE_WEB_TLS_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq-variant.sh"
require_mikefarah_yq "ingressroute-web-tls-check.sh"

SCAN_DIR="$ROOT/gitops"
if [ ! -d "$SCAN_DIR" ]; then
  echo "  · $SCAN_DIR not found — skipping"
  exit 0
fi

violations=""
while IFS= read -r -d '' f; do
  grep -q "kind: IngressRoute" "$f" 2>/dev/null || continue
  hits="$(yq eval-all '
      select(.kind == "IngressRoute") |
      select(.spec.entryPoints[] == "web") |
      select(.spec.tls != null) |
      (.metadata.namespace // "?") + "/" + .metadata.name
    ' "$f" 2>/dev/null)"
  [ -n "$hits" ] || continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    violations="${violations}${violations:+$'\n'}  - $hit (${f#"$ROOT/"})"
  done <<<"$hits"
done < <(find "$SCAN_DIR" \( -name '*.yaml' -o -name '*.yml' \) -print0 2>/dev/null)

if [ -n "$violations" ]; then
  bad "IngressRoute(s) combine plain-HTTP \`web\` with a \`tls:\` stanza — this silently breaks matching on \`web\` (see this script's header comment):"
  echo "$violations"
  echo "Fix: split into two IngressRoute objects — one on entryPoints:[web] with no tls field, one on entryPoints:[websecure] with tls:{}."
  exit 1
fi

ok "no IngressRoute combines plain-HTTP web with a tls: stanza"
