#!/usr/bin/env bash
# PostToolUse hook: after editing a Helm-chart ArgoCD Application, render it and, if
# any bundled CRD is too big for kubectl's client-side apply (262144-byte annotation
# cap), check the Application syncs with ServerSideApply=true — otherwise repo-server
# fails forever ("metadata.annotations: Too long") and the workload CrashLoopBackOffs
# on its missing CRDs (Kyverno did, for days). Local companion to the
# `make argocd-crd-ssa-check` gate. Scoped to the edited file. Network-tolerant: an
# unrenderable chart is silently skipped. Reads the hook payload on stdin; non-blocking.
#   exit 0 = nothing to say | exit 2 = stderr shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0

# tests/fixtures/ holds deliberately-broken examples for the drift detectors — skip.
case "$fp" in */tests/fixtures/*) exit 0 ;; esac
case "$fp" in *.yaml|*.yml) ;; *) exit 0 ;; esac
grep -q 'kind: Application' "$fp" 2>/dev/null || exit 0
grep -qE '^\s*chart:\s*\S' "$fp" 2>/dev/null || exit 0

if ! out="$(CRDSSA_CHECK_FILES="$fp" bash "$ROOT/scripts/argocd-crd-ssa-check.sh" 2>&1)"; then
  {
    echo "This Application bundles a CRD too large for client-side apply but doesn't set ServerSideApply=true — repo-server can't apply it and the workload will crashloop on its missing CRDs. Add '- ServerSideApply=true' to spec.syncPolicy.syncOptions:"
    echo "$out"
    echo "(re-check: make argocd-crd-ssa-check)"
  } >&2
  exit 2
fi
exit 0
