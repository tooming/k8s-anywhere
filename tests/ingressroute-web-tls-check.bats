#!/usr/bin/env bats
# Tests for scripts/ingressroute-web-tls-check.sh — the drift guard that catches
# a Traefik IngressRoute combining plain-HTTP `web` with a `tls:` stanza, which
# silently breaks matching on `web` entirely (found live 2026-09-06 while
# investigating issue #633 — see that script's header for the full finding).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/ingressroute-web-tls-check"
}

@test "ingressroute-web-tls-check: passes when web-only and websecure+tls are split into separate objects" {
  run env INGRESSROUTE_WEB_TLS_CHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/ingressroute-web-tls-check.sh"
  [ "$status" -eq 0 ]
}

@test "ingressroute-web-tls-check: fails when one object combines web + tls" {
  run env INGRESSROUTE_WEB_TLS_CHECK_ROOT="$FIX/drift" bash "$REPO/scripts/ingressroute-web-tls-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"vault/vault-ui"* ]]
  [[ "$output" == *"combine plain-HTTP"* ]]
}

@test "ingressroute-web-tls-check: a missing gitops/ directory is a clean no-op" {
  run env INGRESSROUTE_WEB_TLS_CHECK_ROOT="$FIX/no-gitops-dir" bash "$REPO/scripts/ingressroute-web-tls-check.sh"
  [ "$status" -eq 0 ]
}

@test "ingressroute-web-tls-check: passes on the real repo's gitops/ tree" {
  run bash "$REPO/scripts/ingressroute-web-tls-check.sh"
  [ "$status" -eq 0 ]
}
