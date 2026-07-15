#!/usr/bin/env bash
# Routines sync check: catch edits to routines/routines.yaml that haven't been
# "applied" to the live claude.ai trigger. The "apply" step is when Claude Code
# calls `RemoteTrigger update` with routines.yaml's cron/model/enabled/tools/
# live_prompt/environment fields — see routines/README.md "Changing a routine".
# After applying, refresh the snapshot with `make routines-mark-applied`.
#
# Why only routines.yaml: since the 2026-07-15 pointer-architecture change, a
# live trigger's actual content is `live_prompt` — a short, static instruction
# to read `prompt_file` (e.g. executor.prompt.md) from the checked-out repo and
# follow it in full. `prompt_file` content is NEVER baked into a trigger, so
# editing routines/*.prompt.md carries no drift risk and needs no apply step at
# all; only routines.yaml itself is ever pushed to the live API.
#
# Why this script: the claude.ai trigger backend cannot be reached from CI
# (no exposed token — see routines/README.md). So we can't fetch the live
# state from a shell. Instead we record, in-repo, the sha256 of routines.yaml
# as-of the last successful apply. CI then enforces "did anyone edit
# routines.yaml without re-applying?" by diffing current content vs snapshot.
#
# Exit 0 = in sync; 1 = drift (instructions printed).
set -uo pipefail
# ROOT defaults to the repo; tests point ROUTINESCHECK_ROOT at a fixture tree.
ROOT="${ROUTINESCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SNAP="$ROOT/.routines-applied"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -d "$ROOT/routines" ] || exit 0

if [ ! -f "$SNAP" ]; then
  bad ".routines-applied does not exist. After applying routines.yaml via Claude Code (\`RemoteTrigger update\`), run \`make routines-mark-applied\`."
  exit 1
fi

sha_of(){ shasum -a 256 "$1" | awk '{print $1}'; }

f="$ROOT/routines/routines.yaml"
if [ -e "$f" ]; then
  rel="${f#"$ROOT"/}"
  current="$(sha_of "$f")"
  stored="$(awk -v k="$rel" '$1==k {sub(/^sha256=/,"",$2); print $2}' "$SNAP")"
  if [ -z "$stored" ]; then
    bad "$rel is not in .routines-applied — new routine? Apply via Claude Code, then \`make routines-mark-applied\`."
  elif [ "$current" != "$stored" ]; then
    bad "$rel has been edited since last apply. Apply via Claude Code (\`RemoteTrigger update\` with the new fields), then \`make routines-mark-applied\`."
  fi
fi

# Reverse direction: routines.yaml was deleted but snapshot still lists it.
while read -r rel _; do
  [ -z "${rel:-}" ] && continue
  case "$rel" in '#'*) continue;; esac
  [ -e "$ROOT/$rel" ] || bad "$rel is in .routines-applied but no longer on disk. Delete the trigger via Claude Code (\`RemoteTrigger update\` with enabled:false, or remove from routines.yaml), then \`make routines-mark-applied\`."
done < "$SNAP"

if [ $drift -eq 0 ]; then
  printf '  \033[32m✓\033[0m routines/ in sync with last apply\n'
fi
exit $drift
