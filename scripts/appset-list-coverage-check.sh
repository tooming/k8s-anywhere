#!/usr/bin/env bash
# ApplicationSet list-generator coverage check: networkpolicy-appset.yaml and
# governance-appset.yaml each hand-enumerate a `gitPath:` list that must cover
# every real `gitops/**/networkpolicy/` (resp. `gitops/governance/<ns>/`) leaf
# directory, or that directory's manifests are never wired to any ArgoCD
# Application and silently never reach the cluster -- structurally the same
# "hardcoded list drifts from the real thing it enumerates" footgun shape as
# allow-envoy-proxy-backend-egress.yaml's namespace list (harbor incident, PR
# #968; recurred for tidb/longhorn-system/istio-system/kargo, fixed 2026-08-07,
# scripts/envoy-egress-allowlist-check.sh). Closing this proactively, before a
# future namespace addition repeats the same class of gap. Both lists are
# currently in sync (verified directly, ADR-0004) -- this is a preventative
# guard, not a fix for a live drift. Runs in CI (the 'drift' job, a required
# check) and via `make ci`. Exit 0 = in sync; 1 = drift.
set -uo pipefail
ROOT="${APPSETCOVERAGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

# --- networkpolicy-appset.yaml -----------------------------------------------
# Real coverage is (appset list-generator elements) UNION (standalone
# gitops/platform/*-networkpolicy.yaml Applications) -- 9 namespaces are wired
# via their own standalone Application instead of the appset (pre-dates the
# appset; both are valid deployment mechanisms, so both count as "covered").
np_appset="$ROOT/gitops/platform/networkpolicy-appset.yaml"
if [ -f "$np_appset" ]; then
  np_covered="$(grep 'gitPath:' "$np_appset" | awk '{print $2}' | sort -u)"
  np_standalone="$(grep -h 'path:' "$ROOT"/gitops/platform/*-networkpolicy.yaml 2>/dev/null | awk '{print $2}' | sort -u)"
  np_real="$(find "$ROOT/gitops" -type d -name networkpolicy | sed "s#^$ROOT/##" | sort -u)"
  for d in $np_real; do
    if ! grep -qx "$d" <<<"$np_covered" && ! grep -qx "$d" <<<"$np_standalone"; then
      bad "networkpolicy dir '$d' is covered by neither networkpolicy-appset.yaml's list-generator NOR a standalone gitops/platform/*-networkpolicy.yaml Application -- its NetworkPolicy manifests are never deployed"
    fi
  done
else
  skip "no networkpolicy-appset.yaml -- skipping networkpolicy coverage check"
fi

# --- governance-appset.yaml ---------------------------------------------------
# gitops/governance/base/ is a shared kustomize base other overlays reference,
# not a leaf namespace overlay -- excluded, same as the appset's own scope.
gov_appset="$ROOT/gitops/platform/governance-appset.yaml"
gov_dir="$ROOT/gitops/governance"
if [ -f "$gov_appset" ] && [ -d "$gov_dir" ]; then
  gov_covered="$(grep 'gitPath:' "$gov_appset" | awk '{print $2}' | sort -u)"
  gov_real="$(find "$gov_dir" -mindepth 1 -maxdepth 1 -type d ! -name base | sed "s#^$ROOT/##" | sort -u)"
  for d in $gov_real; do
    grep -qx "$d" <<<"$gov_covered" || bad "governance dir '$d' is not covered by governance-appset.yaml's list-generator -- its governance manifests are never deployed"
  done
else
  skip "no governance-appset.yaml / gitops/governance/ -- skipping governance coverage check"
fi

[ "$drift" -eq 0 ] && ok "every networkpolicy/ and governance/ leaf directory is covered by its ApplicationSet list-generator (or, for networkpolicy, a standalone Application)"
exit "$drift"
