#!/usr/bin/env bash
# Kustomize orphan-file check: every *.yaml/*.yml file sitting next to a
# kustomization.yaml must actually be referenced by it. A file that's dropped
# from the resources: list (e.g. replaced by a shared template) but never
# deleted from disk becomes dead weight that nothing catches — and, worse, gets
# mistaken for live config: gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml
# was dropped from gitops/harbor/networkpolicy/kustomization.yaml's resources: list
# when the shared zz-dns-clusterip-bridge.yaml template replaced it, but the file
# itself was left behind and was still being edited as if it were live nearly a
# month later (PR #716, 2026-07-24) — kustomize builds ignore it silently, so
# neither `make ci` nor a live cluster ever surfaced the drift.
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point KUSTOMIZE_ORPHAN_CHECK_ROOT at a fixture tree.
ROOT="${KUSTOMIZE_ORPHAN_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

SCAN_DIR="$ROOT/gitops"
if [ ! -d "$SCAN_DIR" ]; then
  echo "no gitops/ directory — nothing to check"
  exit 0
fi

# KUSTOMIZE_ORPHAN_CHECK_FILES (space/newline-separated kustomization.yaml paths)
# restricts the scan — the PostToolUse hook uses it to check only the edited
# directory instead of the whole tree.
declare -a KFILES=()
if [ -n "${KUSTOMIZE_ORPHAN_CHECK_FILES:-}" ]; then
  read -r -a KFILES <<<"$KUSTOMIZE_ORPHAN_CHECK_FILES"
else
  mapfile -t KFILES < <(find "$SCAN_DIR" \( -name 'kustomization.yaml' -o -name 'kustomization.yml' \) | sort)
fi

for kfile in "${KFILES[@]}"; do
  [ -f "$kfile" ] || continue
  dir="$(dirname "$kfile")"
  for f in "$dir"/*.yaml "$dir"/*.yml; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    case "$base" in kustomization.yaml|kustomization.yml) continue ;; esac
    if ! grep -qF "$base" "$kfile"; then
      bad "${f#"$ROOT"/} exists but is not referenced anywhere in ${kfile#"$ROOT"/} (dead file — delete it, or add it to resources: if it's meant to be live)"
    fi
  done
done

[ "$drift" -eq 0 ] && printf '  %s✓%s every file next to a kustomization.yaml is referenced by it (no orphans)\n' "$G" "$Z"
exit "$drift"
