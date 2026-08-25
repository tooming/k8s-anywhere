#!/usr/bin/env bash
# Dry-build every kustomization in gitops/ to catch broken cross-directory
# references and missing files before ArgoCD syncs them on the cluster.
# Mirrors the global kustomize.buildOptions in configs.cm (argocd values).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

printf '%s== validate kustomize builds ==%s\n' "$B" "$Z"

if ! command -v kustomize >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    printf '  %s✗%s kustomize not installed (required in CI)\n' "$R" "$Z"; exit 1
  fi
  printf '  %s·%s kustomize not installed — skipping (install: brew install kustomize)\n' "$Y" "$Z"; exit 0
fi

# --enable-helm added 2026-08-25: gitops/envoy-gateway/ vendors a Helm chart
# via Kustomize's helmCharts inflator (mirrors the global argocd-cm
# kustomize.buildOptions this script's own header comment already promises to
# mirror — see infra/modules/argocd/values.yaml). Needs the `helm` binary,
# same as ArgoCD's repo-server image already has.
if ! command -v helm >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then
    printf '  %s✗%s helm not installed (required in CI for --enable-helm)\n' "$R" "$Z"; exit 1
  fi
  printf '  %s·%s helm not installed — skipping (install: brew install helm)\n' "$Y" "$Z"; exit 0
fi

rc=0
while IFS= read -r kfile; do
  dir="$(dirname "$kfile")"
  reldir="${dir#"$ROOT"/}"
  if kustomize build --enable-helm --load-restrictor LoadRestrictionsNone "$dir" >/dev/null 2>/tmp/kustomize-err; then
    printf '  %s✓%s %s\n' "$G" "$Z" "$reldir"
  else
    printf '  %s✗%s %s\n' "$R" "$Z" "$reldir"
    sed 's/^/      /' /tmp/kustomize-err >&2
    rc=1
  fi
done < <(find "$ROOT/gitops" -name 'kustomization.yaml' | sort)

echo
[ "$rc" -eq 0 ] && printf '%s%skustomize: PASS%s\n' "$B" "$G" "$Z" || printf '%s%skustomize: FAIL%s\n' "$B" "$R" "$Z"
exit "$rc"
