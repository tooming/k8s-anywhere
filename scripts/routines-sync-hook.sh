#!/usr/bin/env bash
# PostToolUse hook: after an Edit/Write to routines/routines.yaml, remind Claude
# that the change is NOT complete until it has been applied to the live claude.ai
# trigger (via `RemoteTrigger update`) AND .routines-applied has been refreshed
# (via `make routines-mark-applied`). The drift checker (run by `make ci`) will
# fail the PR otherwise. Non-blocking; just nudges in the same change.
#
# Only routines.yaml triggers this — since the 2026-07-15 pointer-architecture
# change, routines/*.prompt.md files are read live every run and never baked
# into a trigger, so editing one needs no apply step and no nudge.
#   exit 0 = nothing to say   |   exit 2 = stderr is shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"

case "$fp" in
  */routines/routines.yaml) ;;
  *) exit 0 ;;
esac

# Decide whether to nudge: the file is dirty AND the snapshot doesn't match the new content yet.
SNAP="$ROOT/.routines-applied"
rel="${fp#"$ROOT"/}"
current="$(shasum -a 256 "$fp" 2>/dev/null | awk '{print $1}' || true)"
stored="$([ -f "$SNAP" ] && awk -v k="$rel" '$1==k {sub(/^sha256=/,"",$2); print $2}' "$SNAP" || true)"

if [ -n "$current" ] && [ "$current" = "$stored" ]; then
  exit 0  # already in sync — no nudge
fi

# The edited file is routines.yaml itself, so its own trigger_id field is right there.
trigger_id="$(awk '$1=="trigger_id:" { gsub(/["]/,"",$2); print $2; exit }' "$fp" 2>/dev/null)"
trigger_id="${trigger_id:-?}"

{
  echo "Edited $rel — this change is NOT complete until you apply it to the live trigger:"
  echo "  1. Call \`RemoteTrigger update\` (action=update, trigger_id=$trigger_id) with the new cron/model/enabled/tools/live_prompt/environment fields."
  echo "  2. Run \`make routines-mark-applied\` to refresh .routines-applied."
  echo "Without these, \`make ci\` (\`make routines-check\`) will fail the PR."
  echo "See routines/README.md \"Changing a routine\"."
} >&2
exit 2
