#!/usr/bin/env bash
# Mimir read-only-root path check: Mimir runs with readOnlyRootFilesystem: true
# (ADR-0017 PSS restricted), so the working dir is read-only and any file Mimir
# tries to write outside a mounted writable volume crashes it on boot. That bit us:
# the activity tracker's default ./metrics-activity.log can't be created ->
#   error running application err="open ./metrics-activity.log: read-only file system"
# and Mimir CrashLoopBackOff'd for days. yamllint/kubeconform can't see it: the
# manifest is valid, the path just lands on a read-only mount.
#
# This guard mechanically ties Mimir's config to its writable volumes so the class
# can't recur (fix + guard). For the mimir Deployment + ConfigMap it asserts:
#   1. activity_tracker.filepath is set explicitly (its default ./metrics-activity.log
#      is the read-only-root footgun) and lands on a writable mount.
#   2. every absolute path the config writes to (any "/..." scalar) is under a
#      writable volumeMount (emptyDir / PVC) — configMap/secret mounts are read-only.
#
# Static + offline — python3/PyYAML inspection, no network, no cluster.
# Uses python3 instead of yq+jq to be portable across yq variants: mikefarah/yq
# (Go) uses -o=json and select(tag=="!!str") syntax; kislyuk/python-yq (the jq
# wrapper installed in CI) doesn't understand those flags and produces empty output
# with 2>/dev/null, turning every assertion into a silent false-negative/false-positive.
# python3's yaml module is stable regardless of what yq is on PATH.
# Run by `make mimir-readonly-root-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = every Mimir write path is writable; 1 = a path lands on the read-only root.
set -uo pipefail

# ROOT defaults to the repo; tests point MIMIR_RWCHECK_ROOT at a fixture tree.
ROOT="${MIMIR_RWCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DIR="$ROOT/gitops/observability/mimir"
DEPLOY="$DIR/deployment.yaml"
CM="$DIR/configmap.yaml"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
skip(){ printf '  %s·%s %s\n' "$Y" "$Z" "$1"; }

# Requires python3 + PyYAML (standard on any Linux CI box).
# Replaces the original yq+jq dependency — see comment at the top of this file.
python3 -c "import yaml" 2>/dev/null || { echo "python3-yaml not installed — skipping mimir read-only-root check"; exit 0; }

if [ ! -f "$DEPLOY" ] || [ ! -f "$CM" ]; then
  skip "no mimir deployment/configmap at $DIR — nothing to check"; exit 0
fi

printf '%s== mimir read-only-root write paths ==%s\n' "$B" "$Z"
fail=0

# --- writable mounts: volumeMounts backed by an emptyDir or PVC volume ----------
# configMap/secret/projected mounts are read-only, so they don't count.
mapfile -t WRITABLE < <(
  python3 - "$DEPLOY" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    spec = yaml.safe_load(f)['spec']['template']['spec']
w = {v['name'] for v in spec.get('volumes', [])
     if 'emptyDir' in v or 'persistentVolumeClaim' in v}
mounts = sorted({vm['mountPath']
                 for c in spec.get('containers', [])
                 for vm in c.get('volumeMounts', [])
                 if vm['name'] in w})
# Print nothing (not even a blank line) when there are zero writable mounts.
# `print('\n'.join(mounts))` on an empty list still emits one newline, which
# `mapfile -t WRITABLE` below reads back as a single empty-string element
# (array length 1, not 0) -- that silently defeats BOTH the "${#WRITABLE[@]}
# -eq 0" early-exit below AND under_writable(), whose `"$m"/*` glob becomes
# the literal pattern `/*` when m="", matching every absolute path as
# "writable". Only print when there's something real to print.
if mounts:
    print('\n'.join(mounts))
PYEOF
)
if [ "${#WRITABLE[@]}" -eq 0 ]; then
  bad "mimir Deployment declares no writable (emptyDir/PVC) volumeMounts — every write path will hit the read-only root"
  echo; exit 1
fi
ok "writable mounts: ${WRITABLE[*]}"

# Is a path under one of the writable mounts?
under_writable() {
  local p="$1" m
  for m in "${WRITABLE[@]}"; do
    case "$p" in "$m"/*|"$m") return 0 ;; esac
  done
  return 1
}

# --- pull mimir.yaml out of the ConfigMap and parse it -------------------------
MIMIR_YAML="$(python3 - "$CM" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    cm = yaml.safe_load(f)
print((cm.get('data') or {}).get('mimir.yaml', ''), end='')
PYEOF
)"
if [ -z "$MIMIR_YAML" ]; then
  bad "configmap.yaml has no data[\"mimir.yaml\"] — can't verify write paths"
  echo; exit 1
fi

# --- 1. settings whose DEFAULT is a ./ path on the read-only root MUST be set ----
# These don't appear as a "/..." value when unset, so the path scan in step 2 can't
# catch them — each silently defaults to the working dir and crashes -target=all on
# boot. Pin every one under a writable mount. (key | dotted-path | default it falls to)
declare -a REQUIRED=(
  "activity_tracker.filepath|activity_tracker.filepath|./metrics-activity.log"
  "ruler.rule_path|ruler.rule_path|./data-ruler/"
)
declare -a REQVALS=()   # collected so step 2 doesn't double-report them
for spec in "${REQUIRED[@]}"; do
  IFS='|' read -r label path def <<<"$spec"
  # Pass MIMIR_YAML via env var — avoids the bash pipe-vs-heredoc stdin conflict
  # (printf '%s' "$VAR" | python3 - arg <<'EOF' doesn't work: the heredoc wins
  # and the pipe is silently dropped; the env-var route sidesteps that entirely).
  v="$(MIMIR_CONTENT="$MIMIR_YAML" python3 - "$path" <<'PYEOF'
import sys, os, yaml
parts = sys.argv[1].split('.')
data = yaml.safe_load(os.environ['MIMIR_CONTENT'])
for p in parts:
    data = data.get(p, '') if isinstance(data, dict) else ''
print(data or '', end='')
PYEOF
)"
  if [ -z "$v" ]; then
    bad "$label is unset — Mimir defaults to $def on the read-only root and crashes on boot; set it under a writable mount (${WRITABLE[*]})"
    fail=1
  elif under_writable "$v"; then
    ok "$label ($v) is on a writable mount"
    REQVALS+=("$v")
  else
    bad "$label ($v) is not under a writable mount (${WRITABLE[*]})"
    fail=1
    REQVALS+=("$v")
  fi
done

# --- 2. every absolute "/..." path in the config must be writable --------------
# Host/endpoint/bucket values aren't absolute paths, so they don't start with "/".
mapfile -t PATHS < <(MIMIR_CONTENT="$MIMIR_YAML" python3 <<'PYEOF'
import os, yaml
data = yaml.safe_load(os.environ['MIMIR_CONTENT'])
def walk(obj):
    if isinstance(obj, str):
        if obj.startswith('/'): yield obj
    elif isinstance(obj, dict):
        for v in obj.values(): yield from walk(v)
    elif isinstance(obj, list):
        for v in obj: yield from walk(v)
print('\n'.join(sorted(set(walk(data)))))
PYEOF
)
for p in "${PATHS[@]}"; do
  [ -n "$p" ] || continue
  skip_p=0; for rv in "${REQVALS[@]}"; do [ "$p" = "$rv" ] && skip_p=1; done
  [ "$skip_p" -eq 1 ] && continue   # already reported above
  if under_writable "$p"; then
    ok "config path $p is on a writable mount"
  else
    bad "config path $p is not under a writable mount (${WRITABLE[*]}) — readOnlyRootFilesystem will make Mimir crash writing it"
    fail=1
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  ok "every Mimir write path lands on a writable volume"
fi
exit "$fail"
