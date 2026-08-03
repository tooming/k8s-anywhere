#!/usr/bin/env bash
# yqs-lib drift check: no scripts/*.sh may define its own local `yqs()` helper
# — every script needing yq-variant-robust scalar reads must instead source
# the one shared copy in scripts/lib/yq.sh.
#
# Why: scripts/adr-chart-version-sync-check.sh and
# scripts/context-doc-version-sync-check.sh each defined their own
# byte-identical copy of this helper (found during a duplication sweep,
# 2026-08-03) — harmless today, but the kind of copy-paste that drifts the
# moment one copy gets a fix the other doesn't. This guard makes that
# recurrence impossible: no new script can add its own `yqs()` definition
# instead of sourcing scripts/lib/yq.sh, mirroring the
# yq-variant-guard-check.sh / adr-chart-version-sync-check.sh drift-guard
# pattern already used elsewhere in this repo.
#
# Static + offline — pure grep, no network, no cluster.
# Run by `make yqs-lib-check`, `make ci`, and the PostToolUse hook.
# Exit 0 = no script defines its own yqs(); 1 = one does.
set -uo pipefail

# ROOT defaults to the repo; tests point YQSLIB_ROOT at a fixture tree.
ROOT="${YQSLIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIPTS_DIR="$ROOT/scripts"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

[ -d "$SCRIPTS_DIR" ] || { echo "no scripts/ dir — nothing to check"; exit 0; }

for f in "$SCRIPTS_DIR"/*.sh; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  grep -qE '^yqs\(\) \{' "$f" || continue
  bad "$base defines its own yqs() helper — source scripts/lib/yq.sh instead (the one shared copy)"
done

[ "$drift" -eq 0 ] && printf '  %s✓%s no script defines its own yqs() (all source scripts/lib/yq.sh)\n' "$G" "$Z"
exit "$drift"
