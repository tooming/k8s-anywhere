#!/usr/bin/env bash
# PostToolUse hook: after editing an HTTPRoute manifest or the envoy backend-egress
# allowlist itself, check whether a routed namespace drifted out of sync with the
# allowlist and, if so, surface a reminder so it's fixed in the same change (the
# local companion to the CI envoy-egress-allowlist-check 'drift' gate). Reads the
# Claude Code hook payload on stdin; non-blocking. Mirrors lab-ui-sync-hook.sh's
# shape exactly.
#   exit 0 = nothing to say   |   exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

# React only to the allowlist file itself, or a gitops file that declares an HTTPRoute.
case "$fp" in
  */allow-envoy-proxy-backend-egress.yaml) ;;
  */gitops/*.yaml) grep -q 'kind: HTTPRoute' "$fp" 2>/dev/null || exit 0 ;;
  *) exit 0 ;;
esac

if ! out="$(bash "$ROOT/scripts/envoy-egress-allowlist-check.sh" 2>&1)"; then
  {
    echo "Envoy backend-egress allowlist looks stale after editing ${fp##*/} — add the namespace to allow-envoy-proxy-backend-egress.yaml (gitops/envoy-gateway-system/networkpolicy/), or its HTTPRoute responses will be silently dropped by the default-deny floor (same bug class as the harbor incident, PR #968):"
    echo "$out"
    echo "(re-check: make envoy-egress-allowlist-check)"
  } >&2
  exit 2
fi
exit 0
