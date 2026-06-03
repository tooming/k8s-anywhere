#!/usr/bin/env bash
# PostToolUse hook: after an Edit/Write to a routines/*.prompt.md or routines.yaml,
# remind Claude that the change is NOT complete until it has been applied to the live
# claude.ai trigger (via `RemoteTrigger update`) AND .routines-applied has been
# refreshed (via `make routines-mark-applied`). The drift checker (run by `make ci`)
# will fail the PR otherwise. Non-blocking; just nudges in the same change.
#   exit 0 = nothing to say   |   exit 2 = stderr is shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

case "$fp" in
  */routines/*.prompt.md|*/routines.yaml) ;;
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

# Figure out which trigger this file maps to, if routines.yaml is available.
trigger_id="?"
if [ -f "$ROOT/routines.yaml" ]; then
  trigger_id="$(awk -v f="${rel#routines/}" '
    $1=="prompt_file:" && index($0,f) { found=1 }
    found && $1=="trigger_id:" { gsub(/[\"]/,"",$2); print $2; exit }
  ' "$ROOT/routines.yaml" 2>/dev/null || echo "?")"
fi

{
  echo "Edited $rel — this change is NOT complete until you apply it to the live trigger:"
  echo "  1. Call \`RemoteTrigger update\` (action=update, trigger_id=$trigger_id) with the new prompt content."
  echo "  2. Run \`make routines-mark-applied\` to refresh .routines-applied."
  echo "Without these, \`make ci\` (\`make routines-check\`) will fail the PR."
  echo "See routines/README.md \"Changing a routine\"."
} >&2
exit 2
