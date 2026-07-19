#!/usr/bin/env bash
# PostToolUse guard: ADRs named `adr-NNNN-<chosen>-not-<rejected>.md` encode a REJECTED
# technology (e.g. adr-0002-garage-not-minio -> "minio" is off-limits). If an edit to
# infra/code reintroduces a rejected term, surface a reminder so we never silently
# contradict an ADR. Self-maintaining: new "*-not-*" ADRs extend the guard automatically.
# Reads the Claude Code hook JSON on stdin; non-blocking (the tool already ran).
#   exit 0 = nothing to say  |  exit 2 = stderr is shown to Claude as a reminder
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/scripts/lib/hook-payload.sh"
fp="$(hook_file_path)"
[ -n "$fp" ] || exit 0

# Guard infra/code only. Never the ADRs/docs that legitimately discuss rejected tech.
case "$fp" in
  *docs/*) exit 0 ;;
  *infra/*|*gitops/*|*scripts/*|*Makefile|*.tf|*.hcl|*.yaml|*.yml) ;;
  *) exit 0 ;;
esac
[ -f "$fp" ] || exit 0

# Scan only the lines this edit *added* — pre-existing vendor usage in unchanged lines
# should not block unrelated edits.  For untracked (new) files, check everything.
if git -C "$ROOT" ls-files --error-unmatch "$fp" >/dev/null 2>&1; then
  added_content="$(git -C "$ROOT" diff HEAD -- "$fp" 2>/dev/null | sed -n '/^+[^+]/s/^+//p' || true)"
  [ -n "$added_content" ] || exit 0
else
  added_content="$(cat "$fp")"
fi

hits=""
for adr in "$ROOT"/docs/decisions/adr-*-not-*.md; do
  [ -e "$adr" ] || continue
  rejected="$(basename "$adr" .md | sed -E 's/.*-not-//')"
  [ -n "$rejected" ] || continue
  if printf '%s' "$added_content" | grep -qiw "$rejected"; then
    hits="$hits"$'\n'"  - '$rejected' (rejected by $(basename "$adr")) introduced in ${fp##*/}"
  fi
done

if [ -n "$hits" ]; then
  {
    echo "ADR guard: this file reintroduces a technology an ADR rejected:"
    printf '%s\n' "$hits"
    echo "Honor the ADR. If there's a real reason to revisit it, STOP and ask the user first."
  } >&2
  exit 2
fi
exit 0
