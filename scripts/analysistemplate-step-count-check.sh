#!/usr/bin/env bash
# Argo Rollouts step-analysis `count` check: an AnalysisTemplate referenced from a
# Rollout's `spec.strategy.canary.steps[].analysis.templates[]` (a STEP-GATING
# analysis, must terminate so the step can proceed) is invalid if any of its metrics
# sets `interval` without `count` — Argo Rollouts treats that combination as running
# indefinitely, which is only legal for a BACKGROUND analysis
# (spec.strategy.canary.analysis), not a step gate. The controller then hits this
# reconcile error on every sync of the offending Rollout:
#   The Rollout "<name>" is invalid: spec.strategy.canary.steps[N].analysis.templates:
#   Invalid value: "<template>": AnalysisTemplate <template> has metric <metric> which
#   runs indefinitely. Invalid value for count: <nil>
# which spams the controller's error log every reconcile and eventually crashlooped
# the whole argo-rollouts controller pod on OOM/backoff (regression: capstone's
# success-rate template, ADR-0020 §"Re-evaluation log" 2026-08-06 entry — 145 restarts
# over 45h). kubeconform/yamllint can't catch this: both manifests are individually
# valid YAML/schema, the bug is a cross-file *semantic* mismatch (step-gating usage
# vs. a background-shaped metric).
#
# Static + offline — python3/PyYAML, no network, no cluster. Mirrors
# scripts/mimir-readonly-root-check.sh's approach (python3+yaml over yq, so CI's
# python-yq/jq-wrapper `yq` binary can't silently defeat this like it did there).
# Run by `make analysistemplate-step-count-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = every step-referenced AnalysisTemplate metric has count (or no interval);
# 1 = an indefinite metric is wired into a step gate.
set -uo pipefail

# ROOT defaults to the repo; tests point ANALYSISTEMPLATE_STEP_COUNT_CHECK_ROOT at a
# fixture tree.
ROOT="${ANALYSISTEMPLATE_STEP_COUNT_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCAN_DIR="$ROOT/gitops"; [ -d "$SCAN_DIR" ] || SCAN_DIR="$ROOT"

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
skip(){ printf '  %s·%s %s\n' "$Y" "$Z" "$1"; }

python3 -c "import yaml" 2>/dev/null || { echo "python3-yaml not installed — skipping analysistemplate step-count check"; exit 0; }

printf '%s== Argo Rollouts step-analysis AnalysisTemplate count ==%s\n' "$B" "$Z"

RESULT="$(python3 - "$SCAN_DIR" <<'PYEOF'
import sys, os, glob, yaml

scan_dir = sys.argv[1]
files = sorted(
    f for pat in ("**/*.yaml", "**/*.yml")
    for f in glob.glob(os.path.join(scan_dir, pat), recursive=True)
)

step_refs = []          # (rollout_name, file, templateName)
templates = {}          # name -> list of (file, metric dict)

for f in files:
    try:
        with open(f) as fh:
            docs = list(yaml.safe_load_all(fh))
    except yaml.YAMLError:
        continue
    for doc in docs or []:
        if not isinstance(doc, dict):
            continue
        kind = doc.get("kind")
        if kind == "Rollout":
            name = (doc.get("metadata") or {}).get("name", "<unnamed>")
            steps = (((doc.get("spec") or {}).get("strategy") or {}).get("canary") or {}).get("steps") or []
            for step in steps:
                if not isinstance(step, dict):
                    continue
                analysis = step.get("analysis")
                if not isinstance(analysis, dict):
                    continue
                for tmpl in analysis.get("templates") or []:
                    tn = (tmpl or {}).get("templateName")
                    if tn:
                        step_refs.append((name, f, tn))
        elif kind == "AnalysisTemplate":
            name = (doc.get("metadata") or {}).get("name")
            if not name:
                continue
            metrics = ((doc.get("spec") or {}).get("metrics")) or []
            templates.setdefault(name, []).append((f, metrics))

fail = False
out = []

if not step_refs:
    out.append(("skip", "no Rollout step-gating analysis references found — nothing to check"))
else:
    for rollout_name, rf, tn in step_refs:
        defs = templates.get(tn)
        if not defs:
            out.append(("skip", f"Rollout {rollout_name} ({rf}) references AnalysisTemplate '{tn}' — not found in {scan_dir}, can't verify (may be a ClusterAnalysisTemplate or live elsewhere)"))
            continue
        for tf, metrics in defs:
            for m in metrics:
                if not isinstance(m, dict):
                    continue
                mname = m.get("name", "<unnamed>")
                if "interval" in m and m.get("count") is None:
                    fail = True
                    out.append(("bad", f"AnalysisTemplate '{tn}' ({tf}) metric '{mname}' has interval but no count, "
                                        f"and is referenced from Rollout {rollout_name}'s ({rf}) step-gating "
                                        f"steps[].analysis — Argo Rollouts rejects this as \"runs indefinitely\" "
                                        f"on every reconcile"))
                else:
                    out.append(("ok", f"AnalysisTemplate '{tn}' ({tf}) metric '{mname}' is valid for step-gating use"))

for kind, msg in out:
    print(f"{kind}\t{msg}")
sys.exit(1 if fail else 0)
PYEOF
)"
status=$?

fail=0
if [ -n "$RESULT" ]; then
  while IFS=$'\t' read -r kind msg; do
    case "$kind" in
      ok)   ok "$msg" ;;
      bad)  bad "$msg"; fail=1 ;;
      skip) skip "$msg" ;;
    esac
  done <<<"$RESULT"
fi

echo
if [ "$fail" -eq 0 ] && [ "$status" -eq 0 ]; then
  ok "every step-referenced AnalysisTemplate metric terminates (count set, or no interval)"
fi
exit "$status"
