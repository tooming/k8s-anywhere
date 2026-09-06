#!/usr/bin/env bash
# Probe-timeout sanity check: no livenessProbe/readinessProbe/startupProbe in this
# repo's own YAML (raw manifests OR an ArgoCD Application's Helm valuesObject
# override) may have timeoutSeconds < 5, or an explicit httpGet/exec/tcpSocket/grpc
# handler with timeoutSeconds unset at all (which silently falls back to
# Kubernetes' own 1s default).
#
# Found live 2026-08-11: the identical bug pattern — a probe timeout too tight for
# this lab's real host latency, causing chronic multi-day CrashLoopBackOff/restart
# storms or readiness flapping — recurred independently in SEVEN components before
# this guard existed: Harbor (PR #1040/#1102), ArgoCD's repo-server (PR #1103),
# Kyverno's admissionController (PR #1115), then in the same sweep that added this
# script: ArgoCD's server/applicationSet, cert-manager's webhook, KEDA's operator/
# metricServer/webhooks, node-exporter, Alloy, Valkey, Mimir/Loki/Tempo, the vault
# unsealer, and moto (see the git history of the files this check covers for the
# per-component root-cause comments). Mechanical guard so this stops recurring
# component-by-component (CLAUDE.md's every-bugfix-needs-a-guard rule).
#
# Two layers, because a values-only override (timeoutSeconds with no handler
# alongside it — the shape of most of this session's fixes) is indistinguishable,
# once silently deleted, from "this component never had an override": a structural
# walk alone can flag a *wrong* value but not a *missing* key it has no record ever
# existed. So:
#   1. A structural walk over every parsed YAML document catches any explicit probe
#      (a raw manifest's handler-bearing block, or a chart Application's
#      values-only override) with timeoutSeconds unset or under the floor.
#   2. A required-presence registry (below) pins the exact dotted path of every
#      values-only override this session's fixes added, so silently deleting one
#      (not just weakening its value) fails loudly too.
#
# NOT covered even by (2), and can't be mechanically from this repo's own git
# content alone: a Helm chart whose *template* hardcodes a tight probe timeout with
# NO `.Values` override AT ALL (cilium-operator, Envoy Gateway — see those
# Applications' own comments) has nothing to pin, register, or find in this repo's
# YAML — there is no key here for either layer to see. Catching that class requires
# an out-of-band `helm show values <chart> --version <pin>` cross-reference against
# every pinned chart, which is what this script's own 2026-08-11 audit did by hand
# — it is not repeated automatically on every CI run.
#
# Static + offline — python3/PyYAML, not yq+jq, to stay yq-variant-portable (see
# mimir-readonly-root-check.sh's header comment for why).
#
# Run by `make probe-timeout-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = every explicit/registered probe in gitops/+infra/ has timeoutSeconds >=
# 5 and every registered override is still present; 1 = a violation was found.
set -uo pipefail

# ROOT defaults to the repo; tests point PROBETIMEOUTCHECK_ROOT at a fixture tree.
ROOT="${PROBETIMEOUTCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MIN_TIMEOUT="${PROBETIMEOUTCHECK_MIN:-5}"

# bad() deliberately kept local (no `drift` side effect) rather than sourced from
# lib/colors.sh — this script tracks failure via its own `fail` variable, matching
# the argocd-crd-ssa-check.sh/helm-chart-pin-check.sh/mimir-readonly-root-check.sh
# precedent (see lib/colors.sh's own header comment for why). skip() has no side
# effect either way, so it's sourced, not redefined (tests/colors-lib.bats guards
# against a script re-defining it).
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }

python3 -c "import yaml" 2>/dev/null || { echo "python3-yaml not installed — skipping probe-timeout check"; exit 0; }

printf '%s== probe-timeout sanity (gitops/ + infra/) ==%s\n' "$B" "$Z"

# PROBETIMEOUTCHECK_FILES (space/newline-separated, repo-relative) restricts the
# scan to specific files — the PostToolUse hook uses it to check only the file just
# edited, instead of re-walking the whole tree on every save.
declare -a FILES=()
if [ -n "${PROBETIMEOUTCHECK_FILES:-}" ]; then
  read -r -a FILES <<<"$PROBETIMEOUTCHECK_FILES"
else
  mapfile -t FILES < <(cd "$ROOT" && find gitops infra -type f \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort)
fi
if [ "${#FILES[@]}" -eq 0 ]; then
  skip "no YAML under gitops/ or infra/ — nothing to check"
  exit 0
fi

# --- required-presence registry --------------------------------------------------
# A chart-values-only override (timeoutSeconds with no handler alongside it) is
# indistinguishable, once deleted, from "this component never had an override" —
# the walk above can only flag a *wrong* value, not a *missing* key it has no
# record ever existed. That's exactly this session's real fixes for cert-manager's
# webhook, KEDA, ArgoCD server/applicationSet, Alloy, and node-exporter: each is a
# values-only override with no handler in this repo's YAML, so a future edit that
# silently deletes the block (reverting the fix) would leave `checked` merely
# lower, not `fail`. This explicit registry pins each one's dotted path so the
# check can positively assert "this key must still resolve", closing that gap the
# structural walk can't close on its own. Path syntax: dot-separated map keys;
# `[N]` for a list index. New values-only override fixes should add an entry here.
# PROBETIMEOUTCHECK_REQUIRED (newline-separated "relpath|dotted.path", relative to
# ROOT) overrides this list — the test suite uses it to point at fixture files
# instead of mutating the real repo to prove this layer actually fires. Checked
# with `+set` (not `-n`) so a test can pass an EMPTY override (no registered
# entries at all) without falling back to the real-repo default below.
if [ -n "${PROBETIMEOUTCHECK_REQUIRED+set}" ]; then
  REQUIRED_TSV="$PROBETIMEOUTCHECK_REQUIRED"
else
  declare -a REQUIRED=(
    "gitops/platform/cert-manager.yaml|spec.source.helm.valuesObject.webhook.livenessProbe"
    "gitops/platform/cert-manager.yaml|spec.source.helm.valuesObject.webhook.readinessProbe"
    "gitops/platform/keda.yaml|spec.source.helm.valuesObject.operator.livenessProbe"
    "gitops/platform/keda.yaml|spec.source.helm.valuesObject.operator.readinessProbe"
    "gitops/platform/keda.yaml|spec.source.helm.valuesObject.metricsServer.livenessProbe"
    "gitops/platform/keda.yaml|spec.source.helm.valuesObject.metricsServer.readinessProbe"
    "gitops/platform/keda.yaml|spec.source.helm.valuesObject.webhooks.livenessProbe"
    "gitops/platform/keda.yaml|spec.source.helm.valuesObject.webhooks.readinessProbe"
    # Alloy / node-exporter probe-timeout requirements REMOVED 2026-09-06
    # (ADR-0041): both components (and gitops/platform/observability-alloy.yaml,
    # gitops/platform/observability-node-exporter.yaml) are gone — the entire
    # observability stack was removed with no replacement.
    "infra/modules/argocd/values.yaml|server.livenessProbe"
    "infra/modules/argocd/values.yaml|server.readinessProbe"
    "infra/modules/argocd/values.yaml|applicationSet.livenessProbe"
    "infra/modules/argocd/values.yaml|applicationSet.readinessProbe"
  )
  REQUIRED_TSV="$(printf '%s\n' "${REQUIRED[@]}")"
fi

RESULT="$(cd "$ROOT" && MIN_TIMEOUT="$MIN_TIMEOUT" REQUIRED_SPECS="$REQUIRED_TSV" python3 - "${FILES[@]}" <<'PYEOF'
import sys, os, yaml

min_timeout = int(os.environ["MIN_TIMEOUT"])
HANDLERS = ("httpGet", "exec", "tcpSocket", "grpc")
PROBE_KEYS = ("livenessProbe", "readinessProbe", "startupProbe")

violations = []  # (file, breadcrumb, reason)
checked = 0
parse_errors = []

def walk(node, breadcrumb, fname, require_handler):
    global checked
    if isinstance(node, dict):
        for k, v in node.items():
            here = f"{breadcrumb}.{k}" if breadcrumb else str(k)
            if k in PROBE_KEYS and isinstance(v, dict):
                # Raw K8s workload manifests (Deployment/StatefulSet/DaemonSet/...)
                # must carry exactly one real handler per the API schema, so require
                # one here to avoid false-flagging an unrelated same-named key. An
                # ArgoCD Application's Helm valuesObject override is different: it's
                # legitimately allowed to set only `timeoutSeconds` and leave the
                # handler (httpGet/exec/...) to the chart's own hardcoded template —
                # exactly the shape of most of this repo's real fixes (cert-manager's
                # webhook, KEDA, ArgoCD server/applicationSet, Alloy, node-exporter),
                # so requiring a handler there would make this check blind to the
                # most common case it exists to catch.
                if (not require_handler) or any(h in v for h in HANDLERS):
                    checked += 1
                    ts = v.get("timeoutSeconds")
                    if ts is None:
                        violations.append((fname, here, "timeoutSeconds unset (falls back to Kubernetes' 1s default)"))
                    elif not isinstance(ts, (int, float)) or ts < min_timeout:
                        violations.append((fname, here, f"timeoutSeconds: {ts} (< {min_timeout}s)"))
            walk(v, here, fname, require_handler)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{breadcrumb}[{i}]", fname, require_handler)

for fname in sys.argv[1:]:
    try:
        with open(fname) as f:
            docs = list(yaml.safe_load_all(f))
    except Exception as e:
        parse_errors.append((fname, str(e)))
        continue
    for doc in docs:
        if not isinstance(doc, dict):
            continue
        # An ArgoCD Application sourcing a Helm chart: its valuesObject may
        # legitimately override just timeoutSeconds, relying on the chart's own
        # template for the handler -- don't require one. Everything else (raw
        # workload manifests) must show a real handler to count as a probe.
        is_chart_app = (
            doc.get("kind") == "Application"
            and isinstance(doc.get("spec"), dict)
            and isinstance(doc["spec"].get("source"), dict)
            and bool(doc["spec"]["source"].get("chart"))
        )
        walk(doc, "", fname, require_handler=not is_chart_app)

# --- required-presence registry: catches silent deletion of a values-only fix ----
import re

def tokenize(path):
    tokens = []
    for part in path.split("."):
        m = re.match(r"^([^\[]+)((?:\[\d+\])*)$", part)
        if not m:
            tokens.append(part)
            continue
        tokens.append(m.group(1))
        tokens.extend(int(i) for i in re.findall(r"\[(\d+)\]", m.group(2)))
    return tokens

def resolve(doc, path):
    node = doc
    for tok in tokenize(path):
        if isinstance(tok, int):
            if not isinstance(node, list) or tok >= len(node):
                return None, False
        else:
            if not isinstance(node, dict) or tok not in node:
                return None, False
        node = node[tok]
    return node, True

required_ok = 0
specs_raw = os.environ.get("REQUIRED_SPECS", "")
for line in specs_raw.splitlines():
    line = line.strip()
    if not line:
        continue
    relpath, path = line.split("|", 1)
    try:
        with open(relpath) as f:
            reqdocs = list(yaml.safe_load_all(f))
    except Exception as e:
        violations.append((relpath, path, f"required probe-timeout override could not be checked: {e}"))
        continue
    resolved = None
    found = False
    for doc in reqdocs:
        if not isinstance(doc, dict):
            continue
        resolved, found = resolve(doc, path)
        if found:
            break
    if not found:
        violations.append((relpath, path, "required probe-timeout override is MISSING (looks like a prior fix was reverted — see this file's own history for why it's required)"))
        continue
    # Already counted by the structural walk above (same key, same file) if this
    # particular override happened to be in the scanned FILES set -- don't
    # double-count it in the headline total, just confirm it's still compliant.
    required_ok += 1
    if isinstance(resolved, dict):
        ts = resolved.get("timeoutSeconds")
    elif isinstance(resolved, (int, float)):
        ts = resolved
    else:
        ts = None
    if ts is None:
        violations.append((relpath, path, "required probe-timeout override is missing timeoutSeconds"))
    elif not isinstance(ts, (int, float)) or ts < min_timeout:
        violations.append((relpath, path, f"required probe-timeout override has timeoutSeconds: {ts} (< {min_timeout}s)"))

for fname, err in parse_errors:
    print(f"PARSEERR\t{fname}\t{err}")
for fname, breadcrumb, reason in violations:
    print(f"BAD\t{fname}\t{breadcrumb}\t{reason}")
print(f"CHECKED\t{checked}")
print(f"REQUIRED_OK\t{required_ok}")
PYEOF
)"

fail=0
checked_count=0
required_ok_count=0
while IFS=$'\t' read -r kind a b c; do
  case "$kind" in
    BAD)
      bad "$a: $b — $c"
      fail=1
      ;;
    PARSEERR)
      skip "$a: could not parse as YAML ($b) — skipped (yamllint/kubeconform own this)"
      ;;
    CHECKED)
      checked_count="$a"
      ;;
    REQUIRED_OK)
      required_ok_count="$a"
      ;;
  esac
done <<<"$RESULT"

echo
if [ "$checked_count" -eq 0 ] && [ "$required_ok_count" -eq 0 ]; then
  skip "no explicit probes or registered overrides found to check"
elif [ "$fail" -eq 0 ]; then
  ok "all $checked_count explicit probe(s) have timeoutSeconds >= ${MIN_TIMEOUT}s ($required_ok_count registered override(s) still present)"
fi
exit "$fail"
