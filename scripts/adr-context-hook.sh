#!/usr/bin/env bash
# SessionStart hook: surface the architecture decisions (docs/decisions/ ADRs) into
# context at the start of every session, so technical/tooling choices are never made
# in ignorance of them. stdout is added to the session context.
# Honor the ADRs; if a change would contradict one, STOP and ask first (see CLAUDE.md).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/docs/decisions"
[ -d "$DIR" ] || exit 0

echo "Architecture decisions on record (docs/decisions/) — these are BINDING. If a"
echo "change would contradict one, flag it and ask BEFORE implementing (see CLAUDE.md):"
for f in "$DIR"/adr-*.md; do
  [ -e "$f" ] || continue
  title="$(grep -m1 '^# ' "$f" | sed 's/^# *//')"
  decision="$(grep -m1 -i '\*\*Decision\.\*\*' "$f" | sed -E 's/\*\*//g')"
  echo "- ${title}"
  [ -n "$decision" ] && echo "    ${decision}"
done
exit 0
