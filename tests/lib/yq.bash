#!/usr/bin/env bash
# yq-variant-robust scalar extraction for bats tests.
#
# yq implementations disagree on how they print scalar output: mikefarah yq
# prints them raw (250m), while python-yq (a jq wrapper) JSON-quotes them
# ("250m"). A bare `$(yq …)` consumed by a numeric/string comparison silently
# breaks on whichever variant is on PATH — this is exactly the cpu_millis
# regression in argocd-resources.bats, where a container yq returned "250m" and
# crashed the millicore arithmetic ("250m" * 1000 → syntax error).
#
# Always read scalars through yqs() so a test never has to care which yq is
# installed. It strips one layer of surrounding double quotes, normalising both
# variants to raw output. The scripts/yq-raw-check.sh drift gate enforces that no
# bats test calls a bare `yq` and bypasses this helper.
yqs() {
  local out rc
  out="$(yq "$@")"; rc=$?
  [ "$rc" -eq 0 ] || return "$rc"
  out="${out%\"}"   # strip trailing quote, if any
  out="${out#\"}"   # strip leading quote, if any
  printf '%s\n' "$out"
}
