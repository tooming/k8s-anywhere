#!/usr/bin/env bash
# Refresh .routines-applied — the snapshot the drift checker reads.
# CALL THIS ONLY AFTER you have applied the current routines/* content to the
# live claude.ai triggers via Claude Code's `RemoteTrigger update` (see
# routines/README.md "Changing a routine"). Without that prior apply step
# this is just lying to the drift checker.
set -uo pipefail
# ROOT defaults to the repo; tests point ROUTINESMARKAPPLIED_ROOT at a fixture tree.
ROOT="${ROUTINESMARKAPPLIED_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SNAP="$ROOT/.routines-applied"

{
  echo "# .routines-applied — sha256 of each routines/* file at last apply."
  echo "# Updated by: scripts/routines-mark-applied.sh (\`make routines-mark-applied\`)."
  echo "# Drift checker: scripts/routines-check.sh (\`make routines-check\`, in \`make ci\`)."
  for f in "$ROOT"/routines/*.prompt.md "$ROOT"/routines/routines.yaml; do
    [ -e "$f" ] || continue
    rel="${f#"$ROOT"/}"
    sha="$(shasum -a 256 "$f" | awk '{print $1}')"
    echo "$rel sha256=$sha"
  done
} > "$SNAP"
echo "Wrote $SNAP"
