#!/usr/bin/env bash
# Argo Rollouts plugin-list shape check: the controller's `trafficRouterPlugins`
# and `metricProviderPlugins` Helm values MUST be YAML *sequences*, never a string
# (a "|" block scalar or a quoted string). The chart pipes the value through
# `toYaml` into the argo-rollouts-config ConfigMap and the controller unmarshals
# that key as []types.PluginItem — so a string double-encodes (the rendered value
# becomes a nested "|" scalar) and the controller dies on boot with:
#   Failed to init config: failed to unmarshal traffic router plugins ...
#   json: cannot unmarshal string into Go value of type []types.PluginItem
# kubeconform/yamllint can't catch this: the Application is well-formed YAML, the
# value is just the wrong YAML *kind*. This guard asserts the kind mechanically so
# the footgun (it crashlooped argo-rollouts for days) can't return (fix + guard).
#
# Static + offline — pure yq tag inspection, no network, no cluster.
# Run by `make rollouts-plugin-list-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = every plugin value is a sequence (or none present); 1 = a string slipped in.
set -uo pipefail

# ROOT defaults to the repo; tests point ROLLOUTS_PLUGIN_CHECK_ROOT at a fixture tree.
ROOT="${ROLLOUTS_PLUGIN_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq-variant.sh"
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }

require_mikefarah_yq "rollouts-plugin-list-check"

SCAN_DIR="$ROOT/gitops"; [ -d "$SCAN_DIR" ] || SCAN_DIR="$ROOT"

# ROLLOUTS_PLUGIN_CHECK_FILES (space/newline-separated) restricts the scan to specific
# files — the PostToolUse hook uses it to check only the file just edited.
declare -a FILES=()
if [ -n "${ROLLOUTS_PLUGIN_CHECK_FILES:-}" ]; then
  read -r -a FILES <<<"$ROLLOUTS_PLUGIN_CHECK_FILES"
else
  mapfile -t FILES < <(grep -rl --include='*.yaml' --include='*.yml' -e 'kind: Application' "$SCAN_DIR" 2>/dev/null)
fi

# The two controller value keys the chart turns into []types.PluginItem.
PLUGIN_KEYS=(trafficRouterPlugins metricProviderPlugins)

printf '%s== argo-rollouts plugin-list shape ==%s\n' "$B" "$Z"
fail=0
checked=0
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  while IFS=$'\t' read -r name key tag; do
    [ -n "$name" ] || continue
    checked=$((checked + 1))
    if [ "$tag" = "!!seq" ]; then
      ok "$name: controller.$key is a YAML list"
    else
      bad "$name: controller.$key is $tag, must be a YAML list (sequence) — a string double-encodes and the controller can't unmarshal []types.PluginItem"
      fail=1
    fi
  done < <(
    for key in "${PLUGIN_KEYS[@]}"; do
      yq eval-all "
        select(.kind == \"Application\") |
        select(.spec.source.helm.valuesObject.controller.$key != null) |
        [.metadata.name, \"$key\", (.spec.source.helm.valuesObject.controller.$key | tag)] | @tsv
      " "$f" 2>/dev/null
    done
  )
done

echo
if [ "$fail" -eq 0 ]; then
  if [ "$checked" -eq 0 ]; then
    ok "no argo-rollouts plugin values to check"
  else
    ok "every argo-rollouts plugin value is a YAML list"
  fi
fi
exit "$fail"
