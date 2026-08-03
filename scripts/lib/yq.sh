# Shared yq-variant-robust scalar read for scripts/*.sh — sourced, not executed.
#
# yq implementations disagree on how they print scalar output: mikefarah yq
# prints them raw (250m), while python-yq (a jq wrapper) JSON-quotes them
# ("250m"). scripts/adr-chart-version-sync-check.sh and
# scripts/context-doc-version-sync-check.sh each defined their own
# byte-identical copy of this helper (found during a duplication sweep,
# 2026-08-03) — this file is the one shared copy both now source instead.
#
# Mirrors tests/lib/yq.bash's yqs() for bats tests. That one omits
# `2>/dev/null` on the yq call (bats tests want a failure to surface); this one
# keeps it, matching the two shell scripts' original behavior of swallowing
# yq's stderr on a failed read and returning yq's exit code to the caller.
yqs() {
  local out rc
  out="$(yq "$@" 2>/dev/null)"; rc=$?
  [ "$rc" -eq 0 ] || return "$rc"
  out="${out%\"}"
  out="${out#\"}"
  printf '%s\n' "$out"
}
