#!/usr/bin/env bash
# Static lint of the lab's own code: shellcheck over every script + yamllint over
# the manifests/IaC. Fast, clusterless — runs on every commit (locally via
# `make lint`, and in CI). Exit 0 = clean, 1 = findings.
#
# Tools are optional locally (skipped with a note, like `make preflight`), but in
# CI (CI=true) a missing tool is a hard failure so the gate can't silently no-op.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# Severity gate for shellcheck: warnings + errors fail; info/style are advisory.
SHELLCHECK_SEVERITY="${SHELLCHECK_SEVERITY:-warning}"
drift=0

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

# need <tool>: 0 if present. If missing: hard-fail under CI, else mark skip.
need() {
  command -v "$1" >/dev/null 2>&1 && return 0
  if [ "${CI:-}" = "true" ]; then bad "$1 not installed (required in CI)"; else skip "$1 not installed — skipping (install to lint locally)"; fi
  return 1
}

printf '%s== lint ==%s\n' "$B" "$Z"

# --- shellcheck over all scripts --------------------------------------------
if need shellcheck; then
  if shellcheck -S "$SHELLCHECK_SEVERITY" scripts/*.sh; then
    ok "shellcheck (severity>=$SHELLCHECK_SEVERITY) clean across scripts/"
  else
    bad "shellcheck found issues (severity>=$SHELLCHECK_SEVERITY)"
  fi
fi

# --- yamllint over manifests + IaC ------------------------------------------
if need yamllint; then
  targets=()
  # .forgejo joined the scope once ADR-0035's migration added workflow YAML there
  # (.forgejo/workflows/) -- same reasoning as .github: it's real CI config, not a
  # docker-compose file, so it should be linted like .github/workflows already is.
  for d in gitops infra .github .forgejo; do [ -e "$d" ] && targets+=("$d"); done
  if yamllint -c .yamllint.yml "${targets[@]}"; then
    ok "yamllint clean across ${targets[*]}"
  else
    bad "yamllint found issues"
  fi
fi

echo
[ "$drift" -eq 0 ] && printf '%s%slint: PASS%s\n' "$B" "$G" "$Z" || printf '%s%slint: FAIL%s\n' "$B" "$R" "$Z"
exit "$drift"
