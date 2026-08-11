#!/usr/bin/env bash
# PostToolUse hook: after editing a manifest or ArgoCD Application under gitops/ or
# infra/, verify any livenessProbe/readinessProbe/startupProbe it declares has
# timeoutSeconds >= 5 (not unset, not chart-default-1s). Local companion to the
# `make probe-timeout-check` gate — see scripts/probe-timeout-check.sh's header for
# the 2026-08-11 multi-component incident this guards against. Reads the hook
# payload on stdin; non-blocking. Scoped to the edited file so it's fast.
#   exit 0 = nothing to say | exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0

# tests/fixtures/ holds deliberately-broken examples for the drift detectors — skip.
case "$fp" in */tests/fixtures/*) exit 0 ;; esac
# Only react to YAML under gitops/ or infra/ (where this check actually scans).
case "$fp" in */gitops/*|*/infra/*) ;; *) exit 0 ;; esac
case "$fp" in *.yaml|*.yml) ;; *) exit 0 ;; esac

if ! out="$(PROBETIMEOUTCHECK_FILES="$fp" bash "$ROOT/scripts/probe-timeout-check.sh" 2>&1)"; then
  {
    echo "A probe here has timeoutSeconds unset or set too tight (<5s) — under this lab's real host latency that's a chronic CrashLoopBackOff/readiness-flap footgun, not a hypothetical one (found live in 7+ components 2026-08-11: Harbor, ArgoCD, Kyverno, cert-manager, KEDA, node-exporter, Alloy, Valkey, Mimir/Loki/Tempo). Set timeoutSeconds explicitly (>=5s, 15s for admission webhooks/control-plane):"
    echo "$out"
    echo "(re-check: make probe-timeout-check)"
  } >&2
  exit 2
fi
exit 0
