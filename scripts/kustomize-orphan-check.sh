#!/usr/bin/env bash
# Kustomize orphan-file check, two passes over gitops/:
#
# Pass 1 (per-kustomization file): every *.yaml/*.yml file sitting next to a
# kustomization.yaml must actually be referenced by it. A file that's dropped
# from the resources: list (e.g. replaced by a shared template) but never
# deleted from disk becomes dead weight that nothing catches — and, worse, gets
# mistaken for live config: gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml
# was dropped from gitops/harbor/networkpolicy/kustomization.yaml's resources: list
# when the shared zz-dns-clusterip-bridge.yaml template replaced it, but the file
# itself was left behind and was still being edited as if it were live nearly a
# month later (PR #716, 2026-07-24) — kustomize builds ignore it silently, so
# neither `make ci` nor a live cluster ever surfaced the drift.
#
# Pass 2 (whole orphaned directory): a directory with yaml files but NO
# kustomization.yaml at all is invisible to pass 1 entirely. Such a directory
# is legitimately live when something still wires it in — an Application/
# ApplicationSet `path:`/`gitPath:` naming the directory, a sibling
# kustomization.yaml pulling one of its files in by a relative resource path,
# or the Makefile applying a file directly — but if NOTHING references it any
# more, it's exactly the same dead-weight class as pass 1, just at directory
# granularity: PR #1497 (2026-09-07) removed Argo Rollouts (ADR-0020) —
# deleting every Application/ApplicationSet entry that pointed at
# gitops/argo-rollouts/ — but left the two files sitting in that directory on
# disk, unreferenced from anywhere, and pass 1 never saw them because the
# directory had no kustomization.yaml to check them against.
#
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point KUSTOMIZE_ORPHAN_CHECK_ROOT at a fixture tree.
ROOT="${KUSTOMIZE_ORPHAN_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

SCAN_DIR="$ROOT/gitops"
if [ ! -d "$SCAN_DIR" ]; then
  echo "no gitops/ directory — nothing to check"
  exit 0
fi

# --- Pass 1: files not referenced by their own kustomization.yaml ---------
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

pass1_drift="$drift"
[ "$pass1_drift" -eq 0 ] && printf '  %s✓%s every file next to a kustomization.yaml is referenced by it (no orphans)\n' "$G" "$Z"

# --- Pass 2: whole directories with no kustomization.yaml AND no incoming
#     reference from anywhere in the repo's live wiring -------------------
# KUSTOMIZE_ORPHAN_CHECK_DIRS (space/newline-separated directory paths)
# restricts the scan the same way KUSTOMIZE_ORPHAN_CHECK_FILES does for pass 1.
declare -a CHECK_DIRS=()
if [ -n "${KUSTOMIZE_ORPHAN_CHECK_DIRS:-}" ]; then
  read -r -a CHECK_DIRS <<<"$KUSTOMIZE_ORPHAN_CHECK_DIRS"
else
  mapfile -t CHECK_DIRS < <(find "$SCAN_DIR" -type d | sort)
fi

for dir in "${CHECK_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  [ -f "$dir/kustomization.yaml" ] && continue
  [ -f "$dir/kustomization.yml" ] && continue
  mapfile -t dyamls < <(find "$dir" -maxdepth 1 \( -name '*.yaml' -o -name '*.yml' \) | sort)
  [ "${#dyamls[@]}" -eq 0 ] && continue

  relpath="${dir#"$ROOT"/}"

  # Live-wiring search scope: every yaml under gitops/ plus the Makefile,
  # excluding this directory's own files (a file commenting on or describing
  # its sibling in the same removed component doesn't count as a live
  # reference). docs/, ROADMAP.md and CHARTER.md are deliberately excluded
  # too — a historical doc still mentioning a since-removed path must never
  # mask a real orphan (this is exactly how gitops/argo-rollouts/ read before
  # deletion: docs/done/2026-09-07-argo-rollouts-dashboard-basicauth.md still
  # named both files, but nothing live did).
  mapfile -t search_files < <(
    find "$SCAN_DIR" \( -name '*.yaml' -o -name '*.yml' \) -not -path "$dir/*" | sort
    [ -f "$ROOT/Makefile" ] && echo "$ROOT/Makefile"
  )

  # No files anywhere else even *could* reference this directory — that's the
  # strongest possible case of unreferenced, not a reason to skip it. (An
  # empty search_files array would otherwise make `grep` below a no-op that
  # silently reports "not found" as "nothing to check.")
  referenced=0
  if [ "${#search_files[@]}" -gt 0 ]; then
    if grep -qF "$relpath" "${search_files[@]}" 2>/dev/null; then
      referenced=1
    fi
    if [ "$referenced" -eq 0 ]; then
      for f in "${dyamls[@]}"; do
        if grep -qF "$(basename "$f")" "${search_files[@]}" 2>/dev/null; then
          referenced=1
          break
        fi
      done
    fi
  fi

  if [ "$referenced" -eq 0 ]; then
    bad "${relpath}/ has no kustomization.yaml and is not referenced by any Application/ApplicationSet path, kustomize resource, or Makefile target anywhere in the repo (dead directory — delete it, or wire it in)"
  fi
done

pass2_drift=$((drift - pass1_drift))
[ "$pass2_drift" -eq 0 ] && printf '  %s✓%s every kustomization-less gitops/ directory with yaml files is referenced from somewhere live (no orphaned directories)\n' "$G" "$Z"

exit "$drift"
