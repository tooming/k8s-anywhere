#!/usr/bin/env bash
# Schema-validate every Kubernetes/ArgoCD manifest in gitops/ with kubeconform.
# Catches a typo'd field or wrong apiVersion in seconds, before ArgoCD ever tries
# to sync it on a live cluster. CRDs (HTTPRoute, ExternalSecret, ArgoCD Application,
# the ACK/KRO kinds) have no public schema here, so they're skipped, not failed
# (-ignore-missing-schemas) — we still validate the core kinds and that every file
# is well-formed, multi-doc YAML.
#
# kubeconform fetches each resource's schema from raw.githubusercontent.com
# independently — with 300+ resources sharing ~30 distinct kinds, that's 300+
# requests to a host that occasionally times out, so unrelated resources fail
# per run even though nothing is actually wrong. -cache persists downloaded
# schemas to disk (CI persists that dir across runs too, see ci.yml), and
# retrying a failed run reuses the cache and only re-fetches what flaked,
# converging fast instead of re-downloading everything.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

K8S_VERSION="${KUBECONFORM_K8S_VERSION:-1.30.0}"
CACHE_DIR="${KUBECONFORM_CACHE_DIR:-$HOME/.cache/kubeconform-schemas}"
MAX_ATTEMPTS="${KUBECONFORM_MAX_ATTEMPTS:-3}"
rc=0
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi

printf '%s== validate manifests (kubeconform) ==%s\n' "$B" "$Z"

if ! command -v kubeconform >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    printf '  %s✗%s kubeconform not installed (required in CI)\n' "$R" "$Z"; exit 1
  fi
  printf '  %s·%s kubeconform not installed — skipping (install to validate locally)\n' "$Y" "$Z"; exit 0
fi

mkdir -p "$CACHE_DIR"
attempt=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  if kubeconform \
    -kubernetes-version "$K8S_VERSION" \
    -ignore-missing-schemas \
    -strict \
    -summary \
    -cache "$CACHE_DIR" \
    gitops/; then
    rc=0
    break
  fi
  rc=1
  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    wait_s=$((attempt * 10))
    printf '  %s·%s schema fetch flaked (attempt %d/%d) — retrying in %ds\n' "$Y" "$Z" "$attempt" "$MAX_ATTEMPTS" "$wait_s"
    sleep "$wait_s"
  fi
  attempt=$((attempt + 1))
done

echo
[ "$rc" -eq 0 ] && printf '%s%smanifests: PASS%s\n' "$B" "$G" "$Z" || printf '%s%smanifests: FAIL%s\n' "$B" "$R" "$Z"
exit "$rc"
