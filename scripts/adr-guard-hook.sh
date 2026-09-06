#!/usr/bin/env bash
# PostToolUse guard: ADRs named `adr-NNNN-<chosen>-not-<rejected>.md` encode a REJECTED
# technology (e.g. adr-0002-garage-not-minio -> "minio" is off-limits). If an edit to
# infra/code reintroduces a rejected term, surface a reminder so we never silently
# contradict an ADR. Self-maintaining: new "*-not-*" ADRs extend the guard automatically.
#
# Supersession-aware: an ADR can itself be superseded by a later one that *reverses*
# its verdict (e.g. ADR-0008 "envoy-gateway-not-traefik" was superseded by ADR-0040
# "traefik-not-envoy-gateway" — the exact chosen/rejected pair flipped). When that
# happens, the old ADR's rejected term is no longer actually rejected — it's now the
# *chosen* tech per the superseding ADR — so it must stop being flagged. The
# superseding ADR's own "-not-" filename already adds the new rejection (self-
# maintaining, per above), so nothing else needs to change when this fires.
#
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

# adr_pair <adr-file>: sets $chosen / $rejected from a `-not-` filename, e.g.
# adr-0008-envoy-gateway-not-traefik.md -> chosen=envoy-gateway rejected=traefik
adr_pair() {
  local rest
  rest="$(basename "$1" .md | sed -E 's/^adr-[0-9]+-//')"
  chosen="${rest%%-not-*}"
  rejected="${rest#*-not-}"
}

# reversed_by <adr-file>: true if this ADR's Status line says it was superseded by
# another ADR whose own chosen/rejected pair is the exact reverse of this one's — i.e.
# the "rejected" tech here is actually the *chosen* one there. Chain supersessions that
# don't flip the same pair (ADR-0011 artifactory-not-nexus -> ADR-0024 harbor-not-
# artifactory) are NOT a reversal: "nexus" is still rejected, only the comparison moved on.
reversed_by() {
  local adr="$1" status_line new_num new_adr new_chosen new_rejected
  status_line="$(grep -m1 -E '^\*\*Status\.' "$adr" 2>/dev/null || true)"
  [[ "$status_line" == *"Superseded by"* ]] || return 1
  new_num="$(printf '%s' "$status_line" | grep -oE 'ADR-[0-9]+' | head -1 | grep -oE '[0-9]+')"
  [ -n "$new_num" ] || return 1
  new_adr="$(printf '%s\n' "$ROOT"/docs/decisions/adr-"$new_num"-*-not-*.md 2>/dev/null | head -1)"
  [ -n "$new_adr" ] && [ -e "$new_adr" ] || return 1
  adr_pair "$adr"; local old_chosen="$chosen" old_rejected="$rejected"
  adr_pair "$new_adr"; new_chosen="$chosen" new_rejected="$rejected"
  [ "$old_rejected" = "$new_chosen" ] && [ "$old_chosen" = "$new_rejected" ]
}

hits=""
for adr in "$ROOT"/docs/decisions/adr-*-not-*.md; do
  [ -e "$adr" ] || continue
  reversed_by "$adr" && continue
  adr_pair "$adr"
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
