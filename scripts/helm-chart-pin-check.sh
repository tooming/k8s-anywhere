#!/usr/bin/env bash
# Helm chart-version pin check: every ArgoCD Application that sources a Helm chart
# must pin a `targetRevision` that ACTUALLY EXISTS in its chart repo. A stale/typo'd
# version (e.g. velero pinned 8.4.1 when only 8.4.0 exists) leaves repo-server unable
# to render manifests — the Application sits Unknown forever with
#   `helm pull --version 8.4.1 ... velero` -> chart "velero" version "8.4.1" not found
# kubeconform/yamllint can't catch this: the manifest is well-formed, the version is
# just wrong. This guard resolves each pin against its repo, mechanically, so a
# nonexistent chart-version pin can't be merged again (binding rule: fix + guard).
#
# Network-tolerant by design — it must never go red on a transient outage, so it only
# FAILS on a definitive "version not found in a REACHABLE repo". An unreachable repo
# or an OCI registry (anonymous pulls 403 on ghcr/ecr/docker.io, so existence can't be
# probed) is SKIPPED with a note, never failed. That keeps it safe to wire into
# `make ci` (pre-push) while still catching the real bug whenever the repo is online.
#
# Run by `make helm-chart-pin-check`, the CI 'drift' gates, and the PostToolUse hook.
# Exit 0 = every reachable pin resolved (or was skipped); 1 = a pin doesn't exist.
set -uo pipefail

# ROOT defaults to the repo; tests point CHARTPINCHECK_ROOT at a fixture tree.
ROOT="${CHARTPINCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HELM_BIN="${HELM_BIN:-helm}"
# Test seam: a resolver stub prints OK|MISSING|UNREACHABLE|OCI for "<repoURL> <chart>
# <version>", so the enumeration/classification/exit logic is testable offline.
RESOLVER="${CHARTPIN_RESOLVER:-}"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
skip() { printf '  %s·%s %s\n' "$Y" "$Z" "$1"; }

SCAN_DIR="$ROOT/gitops"; [ -d "$SCAN_DIR" ] || SCAN_DIR="$ROOT"

# --- enumerate every kind: Application with a non-empty source.chart -----------
# CHARTPINCHECK_FILES (space/newline-separated) restricts the scan to specific files
# — the PostToolUse hook uses it to check only the file just edited.
declare -a FILES=()
if [ -n "${CHARTPINCHECK_FILES:-}" ]; then
  read -r -a FILES <<<"$CHARTPINCHECK_FILES"
else
  mapfile -t FILES < <(grep -rl --include='*.yaml' --include='*.yml' -e 'kind: Application' "$SCAN_DIR" 2>/dev/null)
fi

declare -a PINS=()
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  # Filter to chart-bearing Applications IN yq — git-sourced Apps (path:, no chart:)
  # are not our concern, and excluding them here keeps the @tsv free of empty middle
  # fields (IFS=$'\t' collapses adjacent tabs, which would shift the columns).
  while IFS=$'\t' read -r name chart repo ver; do
    [ -n "$chart" ] || continue
    PINS+=("$name"$'\t'"$chart"$'\t'"$repo"$'\t'"$ver")
  done < <(yq eval-all '
    select(.kind == "Application") |
    select(.spec.source.chart // "" | length > 0) |
    [.metadata.name, .spec.source.chart, (.spec.source.repoURL // ""), (.spec.source.targetRevision // "")] | @tsv
  ' "$f" 2>/dev/null)
done

if [ "${#PINS[@]}" -eq 0 ]; then
  ok "no Helm-chart Application pins to verify"
  exit 0
fi

# --- built-in resolver: dedupe repos into an isolated helm config, one index ---
# fetch per unique repo, then resolve each pin locally with `helm search repo`.
declare -A REPO_ALIAS=()   # repoURL -> aliasN (added once)
declare -A REPO_STATE=()   # repoURL -> ready|unreachable
HELM_HOME=""; ALIAS_IDX=0
cleanup() { [ -n "$HELM_HOME" ] && rm -rf "$HELM_HOME"; }
trap cleanup EXIT

resolve_builtin() {
  local repo="$1" chart="$2" ver="$3" al out
  case "$repo" in http://*|https://*) ;; *) echo OCI; return;; esac
  al="${REPO_ALIAS[$repo]:-}"
  if [ -z "$al" ]; then
    al="pin$ALIAS_IDX"; ALIAS_IDX=$((ALIAS_IDX + 1)); REPO_ALIAS[$repo]="$al"
    # `helm repo add` fetches the index immediately; success == repo reachable.
    if "$HELM_BIN" repo add "$al" "$repo" >/dev/null 2>&1; then
      REPO_STATE[$repo]=ready
    else
      REPO_STATE[$repo]=unreachable
    fi
  fi
  [ "${REPO_STATE[$repo]}" = ready ] || { echo UNREACHABLE; return; }
  out="$("$HELM_BIN" search repo "$al/$chart" --version "$ver" -o json 2>/dev/null)"
  if printf '%s' "$out" | jq -e --arg n "$al/$chart" --arg v "$ver" \
       'any(.[]?; .name == $n and .version == $v)' >/dev/null 2>&1; then
    echo OK
  else
    echo MISSING   # repo is reachable but this exact version isn't in the index
  fi
}

resolve() {
  if [ -n "$RESOLVER" ]; then "$RESOLVER" "$1" "$2" "$3"; else resolve_builtin "$1" "$2" "$3"; fi
}

# Without a resolver stub we need helm + jq. Missing tool: hard-fail in CI (the gate
# must not silently no-op), skip-all locally — mirrors lint.sh / validate-manifests.sh.
if [ -z "$RESOLVER" ]; then
  for t in "$HELM_BIN" jq; do
    command -v "$t" >/dev/null 2>&1 && continue
    if [ "${CI:-}" = "true" ]; then
      bad "$t not installed (required in CI to verify chart-version pins)"; exit 1
    fi
    skip "$t not installed — skipping chart-pin verification (install to check locally)"; exit 0
  done
  HELM_HOME="$(mktemp -d)"
  export HELM_CONFIG_HOME="$HELM_HOME/config" HELM_CACHE_HOME="$HELM_HOME/cache" HELM_DATA_HOME="$HELM_HOME/data"
fi

printf '%s== helm chart-version pins ==%s\n' "$B" "$Z"
fail=0
for pin in "${PINS[@]}"; do
  IFS=$'\t' read -r name chart repo ver <<<"$pin"
  case "$(resolve "$repo" "$chart" "$ver")" in
    OK)          ok   "$name: $chart $ver exists in $repo" ;;
    MISSING)     bad  "$name: chart \"$chart\" version \"$ver\" NOT found in $repo — fix spec.source.targetRevision (repo-server can't render this Application)"; fail=1 ;;
    UNREACHABLE) skip "$name: $repo unreachable (network) — can't verify $chart $ver, skipped" ;;
    OCI)         skip "$name: OCI repo $repo — anonymous version probe unreliable, skipped ($chart $ver)" ;;
    *)           skip "$name: resolver gave an unexpected result — skipped ($chart $ver)" ;;
  esac
done

echo
if [ "$fail" -eq 0 ]; then
  printf '  %s✓%s every reachable Helm-chart pin resolves to an existing version\n' "$G" "$Z"
fi
exit "$fail"
