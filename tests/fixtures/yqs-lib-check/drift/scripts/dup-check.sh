#!/usr/bin/env bash
# Fixture: a script defining its own local yqs() helper — the drift case.
set -uo pipefail
yqs() {
  local out rc
  out="$(yq "$@" 2>/dev/null)"; rc=$?
  [ "$rc" -eq 0 ] || return "$rc"
  out="${out%\"}"; out="${out#\"}"
  printf '%s\n' "$out"
}
yqs '.foo' file.yaml
