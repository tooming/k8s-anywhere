# Shared PostToolUse-hook implementation for the repo's "frozen monolith" test
# checks (securitycontext, observability, drift-detectors,
# hook-scripts-coverage) — sourced, not executed. Companion to
# frozen-monolith-check.sh's CI-side dedup; same rationale (see that file's
# header). Each thin *-tests-sync-hook.sh wrapper sources this and calls
# frozen_monolith_sync_hook with its own file/check-script/label.
source "$(dirname "${BASH_SOURCE[0]}")/hook-payload.sh"

# Args: $1 monolith bats path (repo-relative, e.g. tests/securitycontext.bats),
# $2 its check script (repo-relative), $3 `make` mark-target name, $4 where
# NEW tests should go instead, $5 repo root.
frozen_monolith_sync_hook() {
  local bats_rel="$1" check_script="$2" mark_target="$3" scope_hint="$4" root="$5"
  local fp out
  fp="$(hook_file_path)"

  # React only to edits of the frozen monolith itself.
  case "$fp" in
    */"$bats_rel"|"$bats_rel") ;;
    *) return 0 ;;
  esac

  if ! out="$(bash "$root/$check_script" 2>&1)"; then
    {
      echo "$bats_rel is FROZEN — put new tests in $scope_hint instead of appending here (prevents the recurring parallel-PR merge conflict):"
      echo "$out"
      echo "(intentional rename/edit of an existing monolith test? run: make $mark_target — re-check: make ${mark_target%-mark}-check)"
    } >&2
    return 2
  fi
  return 0
}
