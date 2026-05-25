#!/usr/bin/env bash
# README drift check: flag when README.md falls out of sync with the lab's sources
# of truth (the Makefile + gitops/). Mechanical + deterministic — it catches the
# things that actually go stale: removed/renamed `make` targets the README still
# mentions, and tool-list drift. It cannot judge prose; for that, re-read the README.
#
# Run by `make readme-check` and by the README-sync hook (.claude/settings.json).
# Exit 0 = in sync; 1 = drift (findings printed). Companion to lab-ui-check.sh (CI 'drift' job).
set -uo pipefail
# ROOT defaults to the repo; tests point READMECHECK_ROOT at a fixture tree.
ROOT="${READMECHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
README="$ROOT/README.md"
MK="$ROOT/Makefile"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }
hint(){ printf '  \033[33m·\033[0m %s\n' "$1"; }

[ -f "$README" ] || { echo "no README.md"; exit 0; }

# --- 1. every `make <target>` the README mentions must exist in the Makefile ---
# Consider only real commands: inline `make x` (backticked) or code-block lines
# starting with `make x` — never prose like "make sure".
mk_targets="$(grep -E '^[a-zA-Z0-9_-]+:.*##' "$MK" | cut -d: -f1 | sort -u)"
readme_targets="$(
  { grep -oE '`make [a-z][a-z0-9-]+' "$README" | sed 's/`make //'
    grep -oE '^make [a-z][a-z0-9-]+'  "$README" | sed 's/make //'
  } | sort -u
)"
for t in $readme_targets; do
  grep -qx "$t" <<<"$mk_targets" || bad "README mentions \`make $t\` but the Makefile has no '$t' target"
done

# --- 2. README's `brew install` line must match Makefile REQUIRED_TOOLS ---
mk_tools="$(grep -E '^REQUIRED_TOOLS' "$MK" | sed -E 's/.*:=//' | tr ' ' '\n' | grep -v '^$' | sort -u)"
readme_tools="$(grep -m1 'brew install' "$README" | sed -E 's/.*brew install//' | tr ' ' '\n' | grep -v '^$' | sort -u)"
if [ -n "$readme_tools" ]; then
  for t in $mk_tools; do
    grep -qx "$t" <<<"$readme_tools" || bad "tool '$t' is in REQUIRED_TOOLS but missing from the README brew-install line"
  done
fi

# --- 3. (hint, non-failing) gitops/platform components not named in the README ---
# Skip infra/glue apps; match on alphanumerics-only (so "envoy-gateway" matches
# "Envoy Gateway", "external-secrets" matches "External Secrets", etc).
norm_readme="$(tr -dc 'a-zA-Z0-9' < "$README" | tr 'A-Z' 'a-z')"
missing=""
for f in "$ROOT"/gitops/platform/*.yaml; do
  [ -e "$f" ] || continue
  name="$(grep -m1 -E '^\s*name:' "$f" | awk '{print $2}')"
  case "$name" in ""|*-config|*-extras|*-resources|*-dashboards|lab-gateway|demo|root|ack-s3) continue;; esac
  nname="$(printf '%s' "$name" | tr -dc 'a-zA-Z0-9' | tr 'A-Z' 'a-z')"
  grep -qF "$nname" <<<"$norm_readme" || missing="$missing $name"
done

if [ "$drift" -eq 0 ]; then
  printf '  \033[32m✓\033[0m README in sync with Makefile targets + required tools\n'
fi
[ -n "$missing" ] && hint "gitops apps not named in README (add to the stack table if user-facing):$missing"
exit "$drift"
