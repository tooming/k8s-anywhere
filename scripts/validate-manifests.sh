#!/usr/bin/env bash
# Schema-validate every Kubernetes/ArgoCD manifest in gitops/ with kubeconform.
# Catches a typo'd field or wrong apiVersion in seconds, before ArgoCD ever tries
# to sync it on a live cluster. CRDs (HTTPRoute, ExternalSecret, ArgoCD Application,
# the ACK/KRO kinds) have no public schema here, so they're skipped, not failed
# (-ignore-missing-schemas) — we still validate the core kinds and that every file
# is well-formed, multi-doc YAML.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

K8S_VERSION="${KUBECONFORM_K8S_VERSION:-1.30.0}"
rc=0
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi

printf '%s== validate manifests (kubeconform) ==%s\n' "$B" "$Z"

if ! command -v kubeconform >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    printf '  %s✗%s kubeconform not installed (required in CI)\n' "$R" "$Z"; exit 1
  fi
  printf '  %s·%s kubeconform not installed — skipping (install to validate locally)\n' "$Y" "$Z"; exit 0
fi

kubeconform \
  -kubernetes-version "$K8S_VERSION" \
  -ignore-missing-schemas \
  -strict \
  -summary \
  gitops/ || rc=1

echo
[ "$rc" -eq 0 ] && printf '%s%smanifests: PASS%s\n' "$B" "$G" "$Z" || printf '%s%smanifests: FAIL%s\n' "$B" "$R" "$Z"
exit "$rc"
