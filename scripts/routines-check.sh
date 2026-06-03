#!/usr/bin/env bash
# Routines sync check: catch edits to routines/*.prompt.md (or routines.yaml)
# that haven't been "applied" to the live claude.ai triggers. The "apply" step
# is when Claude Code calls `RemoteTrigger update` with the file's content —
# see routines/README.md "Changing a routine". After applying, refresh the
# snapshot with `make routines-mark-applied`.
#
# Why this script: the claude.ai trigger backend cannot be reached from CI
# (no exposed token — see routines/README.md). So we can't fetch the live
# state from a shell. Instead we record, in-repo, the sha256 of each routine
# file as-of the last successful apply. CI then enforces "did anyone edit a
# routine file without re-applying?" by diffing current content vs snapshot.
#
# Exit 0 = in sync; 1 = drift (instructions printed).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAP="$ROOT/.routines-applied"
drift=0
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; drift=1; }

[ -d "$ROOT/routines" ] || exit 0

if [ ! -f "$SNAP" ]; then
  bad ".routines-applied does not exist. After applying current routines via Claude Code (\`RemoteTrigger update\` for each), run \`make routines-mark-applied\`."
  exit 1
fi

sha_of(){ shasum -a 256 "$1" | awk '{print $1}'; }

for f in "$ROOT"/routines/*.prompt.md "$ROOT"/routines.yaml; do
  [ -e "$f" ] || continue
  rel="${f#"$ROOT"/}"
  current="$(sha_of "$f")"
  stored="$(awk -v k="$rel" '$1==k {sub(/^sha256=/,"",$2); print $2}' "$SNAP")"
  if [ -z "$stored" ]; then
    bad "$rel is not in .routines-applied — new routine? Apply via Claude Code, then \`make routines-mark-applied\`."
  elif [ "$current" != "$stored" ]; then
    bad "$rel has been edited since last apply. Apply via Claude Code (\`RemoteTrigger update\` with the new content), then \`make routines-mark-applied\`."
  fi
done

# Reverse direction: a routine file was deleted but snapshot still lists it.
while read -r rel _; do
  [ -z "${rel:-}" ] && continue
  case "$rel" in '#'*) continue;; esac
  [ -e "$ROOT/$rel" ] || bad "$rel is in .routines-applied but no longer on disk. Delete the trigger via Claude Code (\`RemoteTrigger update\` with enabled:false, or remove from routines.yaml), then \`make routines-mark-applied\`."
done < "$SNAP"

if [ $drift -eq 0 ]; then
  printf '  \033[32m✓\033[0m routines/ in sync with last apply\n'
fi
exit $drift
