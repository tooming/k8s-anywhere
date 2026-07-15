#!/usr/bin/env bash
# Refresh .routines-applied — the snapshot the drift checker reads.
# CALL THIS ONLY AFTER you have applied routines.yaml's current fields
# (cron/model/enabled/tools/live_prompt/environment) to the live claude.ai
# trigger via Claude Code's `RemoteTrigger update` (see routines/README.md
# "Changing a routine"). Without that prior apply step this is just lying to
# the drift checker.
#
# Only routines.yaml is tracked here — since the 2026-07-15 pointer-
# architecture change, routines/*.prompt.md files are read live every run and
# never baked into a trigger, so they carry no apply-drift risk at all.
set -uo pipefail
# ROOT defaults to the repo; tests point ROUTINESMARKAPPLIED_ROOT at a fixture tree.
ROOT="${ROUTINESMARKAPPLIED_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SNAP="$ROOT/.routines-applied"

{
  echo "# .routines-applied — sha256 of routines/routines.yaml at last apply."
  echo "# Updated by: scripts/routines-mark-applied.sh (\`make routines-mark-applied\`)."
  echo "# Drift checker: scripts/routines-check.sh (\`make routines-check\`, in \`make ci\`)."
  f="$ROOT/routines/routines.yaml"
  if [ -e "$f" ]; then
    rel="${f#"$ROOT"/}"
    sha="$(shasum -a 256 "$f" | awk '{print $1}')"
    echo "$rel sha256=$sha"
  fi
} > "$SNAP"
echo "Wrote $SNAP"
