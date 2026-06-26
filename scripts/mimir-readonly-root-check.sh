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
# Static + offline — pure yq/jq inspection, no network, no cluster.
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

for t in yq jq; do
  command -v "$t" >/dev/null 2>&1 || { echo "$t not installed — skipping mimir read-only-root check"; exit 0; }
done

if [ ! -f "$DEPLOY" ] || [ ! -f "$CM" ]; then
  skip "no mimir deployment/configmap at $DIR — nothing to check"; exit 0
fi

printf '%s== mimir read-only-root write paths ==%s\n' "$B" "$Z"
fail=0

# --- writable mounts: volumeMounts backed by an emptyDir or PVC volume ----------
# configMap/secret/projected mounts are read-only, so they don't count.
mapfile -t WRITABLE < <(
  yq -o=json '.spec.template.spec' "$DEPLOY" 2>/dev/null | jq -r '
    (.volumes // [] | map(select(.emptyDir or .persistentVolumeClaim) | .name)) as $w
    | (.containers // [])[].volumeMounts // [] | .[]
    | select(.name as $n | $w | index($n)) | .mountPath' 2>/dev/null | sort -u
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
MIMIR_YAML="$(yq '.data["mimir.yaml"]' "$CM" 2>/dev/null)"
if [ -z "$MIMIR_YAML" ] || [ "$MIMIR_YAML" = "null" ]; then
  bad "configmap.yaml has no data[\"mimir.yaml\"] — can't verify write paths"
  echo; exit 1
fi

# --- 1. settings whose DEFAULT is a ./ path on the read-only root MUST be set ----
# These don't appear as a "/..." value when unset, so the path scan in step 2 can't
# catch them — each silently defaults to the working dir and crashes -target=all on
# boot. Pin every one under a writable mount. (key | yq-path | default it falls to)
declare -a REQUIRED=(
  "activity_tracker.filepath|.activity_tracker.filepath|./metrics-activity.log"
  "ruler.rule_path|.ruler.rule_path|./data-ruler/"
)
declare -a REQVALS=()   # collected so step 2 doesn't double-report them
for spec in "${REQUIRED[@]}"; do
  IFS='|' read -r label path def <<<"$spec"
  v="$(printf '%s' "$MIMIR_YAML" | yq "$path // \"\"" - 2>/dev/null)"
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
mapfile -t PATHS < <(printf '%s' "$MIMIR_YAML" | yq '.. | select(tag == "!!str") | select(test("^/"))' - 2>/dev/null | sort -u)
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
