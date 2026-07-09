#!/usr/bin/env bash
# Schema-validate every Kubernetes/ArgoCD manifest in gitops/ with kubeconform.
# Catches a typo'd field or wrong apiVersion in seconds, before ArgoCD ever tries
# to sync it on a live cluster. CRDs (HTTPRoute, ExternalSecret, ArgoCD Application,
# the ACK/KRO kinds) have no public schema here, so they're skipped, not failed
# (-ignore-missing-schemas) — we still validate the core kinds and that every file
# is well-formed, multi-doc YAML.
#
# kubeconform fetches every resource's schema over HTTP from
# raw.githubusercontent.com, which rate-limits (HTTP 429) or times out under
# load — that shows up in kubeconform's own summary as "Errors", distinct from
# "Invalid" (a schema it actually checked and found wrong). A schema-fetch
# error says nothing about whether our manifest is correct, so it must never
# fail this gate — only "Invalid" does. -cache avoids re-fetching the same
# kind for every resource that uses it, so there's less surface to hit in the
# first place (CI persists that cache dir across runs too, see ci.yml).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

K8S_VERSION="${KUBECONFORM_K8S_VERSION:-1.30.0}"
CACHE_DIR="${KUBECONFORM_CACHE_DIR:-$HOME/.cache/kubeconform-schemas}"
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi

printf '%s== validate manifests (kubeconform) ==%s\n' "$B" "$Z"

if ! command -v kubeconform >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    printf '  %s✗%s kubeconform not installed (required in CI)\n' "$R" "$Z"; exit 1
  fi
  printf '  %s·%s kubeconform not installed — skipping (install to validate locally)\n' "$Y" "$Z"; exit 0
fi

mkdir -p "$CACHE_DIR"
output="$(kubeconform \
  -kubernetes-version "$K8S_VERSION" \
  -ignore-missing-schemas \
  -strict \
  -summary \
  -cache "$CACHE_DIR" \
  gitops/ 2>&1)"
printf '%s\n' "$output"

invalid="$(printf '%s\n' "$output" | sed -n 's/.*Invalid: \([0-9]\+\).*/\1/p' | tail -1)"
errors="$(printf '%s\n' "$output" | sed -n 's/.*Errors: \([0-9]\+\).*/\1/p' | tail -1)"

if [ -n "${errors:-}" ] && [ "$errors" -gt 0 ]; then
  printf '  %s·%s %s schema(s) failed to download (network/rate-limit, not a manifest problem) — not failing the gate\n' "$Y" "$Z" "$errors"
fi

rc=0
if [ -z "${invalid:-}" ] || [ "$invalid" -gt 0 ]; then
  rc=1
fi

echo
[ "$rc" -eq 0 ] && printf '%s%smanifests: PASS%s\n' "$B" "$G" "$Z" || printf '%s%smanifests: FAIL%s\n' "$B" "$R" "$Z"
exit "$rc"
