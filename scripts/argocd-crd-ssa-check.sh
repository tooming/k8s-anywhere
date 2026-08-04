#!/usr/bin/env bash
# ArgoCD large-CRD server-side-apply check: an Application whose Helm chart bundles a
# CRD too big for kubectl's client-side apply MUST sync with ServerSideApply=true.
# Client-side apply stuffs the whole manifest into the
# kubectl.kubernetes.io/last-applied-configuration annotation, which the API server
# caps at 262144 bytes. Kyverno's clusterpolicies.kyverno.io / policies.kyverno.io
# CRDs are ~650 KB each, so without server-side apply repo-server fails forever with:
#   CustomResourceDefinition ... is invalid: metadata.annotations: Too long: may not
#   be more than 262144 bytes
# The policy CRDs never install and the admission controller CrashLoopBackOffs on its
# CRD sanity check (it did, for days). kubeconform can't catch this — the manifest is
# valid, the sync *strategy* is wrong.
#
# This guard renders each chart-bearing Application and, for any CRD whose serialized
# size would blow the client-side-apply budget, requires ServerSideApply=true. That
# makes the class impossible by construction: no oversized-CRD chart can be added
# without SSA (fix + guard).
#
# Network-tolerant by design (mirrors helm-chart-pin-check): a chart that can't be
# pulled (unreachable repo, OCI registry, render error) is SKIPPED, never failed, so
# it's safe in `make ci` / pre-push. It only FAILS on a definitively oversized CRD in
# a renderable chart whose Application lacks SSA.
#
# Run by `make argocd-crd-ssa-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = every oversized-CRD Application uses SSA (or was skipped); 1 = one doesn't.
set -uo pipefail

# Client-side-apply annotation cap (bytes). A CRD serialized larger than this can't be
# applied client-side; we leave headroom under the hard 262144 limit for apiVersion/
# kind/wrapper bytes kubectl adds around the annotation value.
LIMIT="${CRDSSA_LIMIT:-250000}"

# ROOT defaults to the repo; tests point CRDSSA_CHECK_ROOT at a fixture tree.
ROOT="${CRDSSA_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HELM_BIN="${HELM_BIN:-helm}"
# Test seam: a renderer stub prints rendered manifests for "<repo> <chart> <ver>
# <valuesfile>" (exit 0) or skips (exit non-zero), so the size/SSA logic is testable
# offline without pulling real charts.
RENDERER="${CRDSSA_RENDERER:-}"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq-variant.sh"
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }

SCAN_DIR="$ROOT/gitops"; [ -d "$SCAN_DIR" ] || SCAN_DIR="$ROOT"

# CRDSSA_CHECK_FILES (space/newline-separated) restricts the scan — the PostToolUse
# hook uses it to check only the file just edited.
declare -a FILES=()
if [ -n "${CRDSSA_CHECK_FILES:-}" ]; then
  read -r -a FILES <<<"$CRDSSA_CHECK_FILES"
else
  mapfile -t FILES < <(grep -rl --include='*.yaml' --include='*.yml' -e 'kind: Application' "$SCAN_DIR" 2>/dev/null)
fi

WORK=""
cleanup() { [ -n "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
WORK="$(mktemp -d)"

# Does an Application sync with ServerSideApply=true? (syncOptions list or the
# argocd.argoproj.io/sync-options annotation both count.)
app_uses_ssa() {
  local f="$1" idx="$2"
  yq eval-all "
    select(.kind == \"Application\") | select(documentIndex == $idx) |
    ((.spec.syncPolicy.syncOptions // []) | join(\",\")) +
    \",\" + (.metadata.annotations.\"argocd.argoproj.io/sync-options\" // \"\")
  " "$f" 2>/dev/null | grep -qiE 'ServerSideApply=true'
}

render() {
  local repo="$1" chart="$2" ver="$3" vf="$4"
  if [ -n "$RENDERER" ]; then "$RENDERER" "$repo" "$chart" "$ver" "$vf"; return; fi
  case "$repo" in http://*|https://*) ;; *) return 2 ;; esac   # OCI → skip
  local al="crdssa"
  rm -rf "$WORK/helm"; mkdir -p "$WORK/helm"
  HELM_CONFIG_HOME="$WORK/helm/config" HELM_CACHE_HOME="$WORK/helm/cache" HELM_DATA_HOME="$WORK/helm/data" \
    "$HELM_BIN" repo add "$al" "$repo" >/dev/null 2>&1 || return 2
  HELM_CONFIG_HOME="$WORK/helm/config" HELM_CACHE_HOME="$WORK/helm/cache" HELM_DATA_HOME="$WORK/helm/data" \
    "$HELM_BIN" template "$chart" "$al/$chart" --version "$ver" --include-crds -f "$vf" 2>/dev/null || return 2
}

# Without a renderer stub we need helm + yq + jq. Missing tool: hard-fail in CI (the
# gate must not silently no-op), skip-all locally — mirrors helm-chart-pin-check.
if [ -z "$RENDERER" ]; then
  for t in "$HELM_BIN" jq; do
    command -v "$t" >/dev/null 2>&1 && continue
    if [ "${CI:-}" = "true" ]; then bad "$t not installed (required in CI to render CRDs)"; exit 1; fi
    skip "$t not installed — skipping large-CRD SSA check (install to check locally)"; exit 0
  done
else
  command -v jq >/dev/null 2>&1 || { skip "jq not installed — skipping"; exit 0; }
fi
require_mikefarah_yq "argocd-crd-ssa-check"

printf '%s== argocd large-CRD server-side-apply ==%s\n' "$B" "$Z"
fail=0
checked=0
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  # Enumerate chart-bearing Applications in this file, with their document index so
  # multi-doc files map each render back to the right Application for the SSA lookup.
  while IFS=$'\t' read -r idx name chart repo ver; do
    [ -n "$chart" ] || continue
    checked=$((checked + 1))

    # Extract this Application's valuesObject so the render reflects real config.
    vf="$WORK/values.yaml"
    yq eval-all "
      select(.kind == \"Application\") | select(documentIndex == $idx) |
      .spec.source.helm.valuesObject // {}
    " "$f" > "$vf" 2>/dev/null

    rendered="$(render "$repo" "$chart" "$ver" "$vf")"
    if [ $? -ne 0 ] || [ -z "$rendered" ]; then
      skip "$name: $chart $ver not renderable here (unreachable/OCI/no CRDs) — skipped"
      continue
    fi

    # Largest CRD in the render, by serialized JSON size (the client-side-apply proxy).
    mapfile -t crdnames < <(printf '%s' "$rendered" | yq ea 'select(.kind == "CustomResourceDefinition") | .metadata.name' - 2>/dev/null | sed '/^---$/d;/^null$/d' | sort -u)
    if [ "${#crdnames[@]}" -eq 0 ]; then
      skip "$name: $chart renders no CRDs — nothing to size"
      continue
    fi

    ssa=no; app_uses_ssa "$f" "$idx" && ssa=yes
    biggest=0; biggest_name=""
    for n in "${crdnames[@]}"; do
      [ -n "$n" ] || continue
      sz="$(printf '%s' "$rendered" | yq ea "select(.kind == \"CustomResourceDefinition\" and .metadata.name == \"$n\")" -o=json - 2>/dev/null | jq -c . 2>/dev/null | wc -c | tr -d ' ')"
      [ -n "$sz" ] || sz=0
      if [ "$sz" -gt "$biggest" ]; then biggest="$sz"; biggest_name="$n"; fi
      if [ "$sz" -gt "$LIMIT" ] && [ "$ssa" = no ]; then
        bad "$name: CRD $n is ${sz}B (> ${LIMIT}B client-side-apply cap) but the Application doesn't set ServerSideApply=true — repo-server can't apply it; add '- ServerSideApply=true' to spec.syncPolicy.syncOptions"
        fail=1
      fi
    done
    if [ "$ssa" = yes ]; then
      ok "$name: SSA enabled (largest CRD $biggest_name ${biggest}B)"
    elif [ "$biggest" -le "$LIMIT" ]; then
      ok "$name: largest CRD $biggest_name ${biggest}B is within the client-side-apply cap"
    fi
  done < <(yq eval-all '
    select(.kind == "Application") |
    select(.spec.source.chart // "" | length > 0) |
    [documentIndex, .metadata.name, .spec.source.chart, (.spec.source.repoURL // ""), (.spec.source.targetRevision // "")] | @tsv
  ' "$f" 2>/dev/null)
done

echo
if [ "$fail" -eq 0 ]; then
  if [ "$checked" -eq 0 ]; then
    ok "no chart-bearing Applications to check"
  else
    ok "every renderable oversized-CRD Application uses server-side apply"
  fi
fi
exit "$fail"
