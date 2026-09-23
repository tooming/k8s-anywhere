#!/usr/bin/env bash
# Markdown internal-link drift check: every relative [text](path) link in a
# tracked *.md file must resolve to a real file/dir. Docs get renamed and moved
# often in this repo (docs/done/, docs/backlog/, ADRs) with nothing catching a
# stale cross-reference left behind — this closes that gap. External links
# (http/https/mailto) and pure-anchor links (#section) are out of scope; a
# reachability check on external URLs is a different, network-dependent problem.
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
#
# Portable on purpose (BSD/macOS and GNU): no `grep -P`, no `realpath -m` /
# `--relative-to`. It used both, and on macOS `grep -P` errored inside a
# `< <(...)` process substitution whose status was never read, so the loop saw
# zero links and printed "every internal markdown link resolves" — a false green
# that hid every broken link (#1637). Extraction failure is now its own failure:
# "grep found no links" (status 1) is fine, "the extraction errored" is drift.
set -uo pipefail
# ROOT defaults to the repo; tests point MDLINKS_ROOT at a fixture tree.
# Resolved to an absolute path up front so a relative MDLINKS_ROOT is not
# interpreted relative to the *original* cwd after this script has cd'd into it.
ROOT="${MDLINKS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd)" || exit 1
cd "$ROOT" || exit 1

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

drift=0
broken=()

# normalize_path <dir> <link-path>: <dir>/<link-path> with "." and ".." segments
# collapsed, relative to ROOT (a link that climbs above ROOT keeps its leading
# ".."). Pure bash — replaces `realpath -m --relative-to="$ROOT"`, which macOS's
# realpath does not support. Symlinks are not resolved; the caller's `[ -e ]`
# follows them anyway.
normalize_path() {
  local IFS=/ part
  local -a parts out
  out=()
  read -ra parts <<<"$1/$2"
  for part in "${parts[@]}"; do
    case "$part" in
      ''|.) ;;
      ..)
        if [ "${#out[@]}" -gt 0 ] && [ "${out[${#out[@]}-1]}" != ".." ]; then
          unset "out[${#out[@]}-1]"
        else
          out+=("..")
        fi
        ;;
      *) out+=("$part") ;;
    esac
  done
  if [ "${#out[@]}" -eq 0 ]; then echo "."; else echo "${out[*]}"; fi
}

while IFS= read -r -d '' file; do
  reldir="$(dirname "$file")"
  # Strip fenced code blocks (```...```) and inline code spans (`...`) first —
  # otherwise a doc that *describes* markdown link syntax as a literal example
  # (e.g. this very script's own docs/done/ write-up) false-positives as a real
  # broken link.
  stripped="$(awk '/^```/{f=!f; next} !f' "$file" | sed -E 's/`[^`]*`//g')" || {
    broken+=("$file: could not strip code blocks/spans (awk|sed failed) — links NOT checked")
    drift=1
    continue
  }
  # grep exits 1 for "no match" (a file with no links — fine) and >1 for a real
  # error; only the latter is a failure.
  links="$(printf '%s\n' "$stripped" | grep -oE '\]\([^)]+\)')"
  rc=$?
  if [ "$rc" -gt 1 ]; then
    broken+=("$file: link extraction failed (grep exit $rc) — links NOT checked")
    drift=1
    continue
  fi
  [ -n "$links" ] || continue
  while IFS= read -r link; do
    link="${link#\](}"
    link="${link%)}"
    # Skip external / mail / pure-anchor links.
    case "$link" in
      http://*|https://*|mailto:*|'#'*|"") continue ;;
    esac
    # Strip a trailing #anchor, if any.
    path="${link%%#*}"
    [ -z "$path" ] && continue
    if [ "${path:0:1}" = "/" ]; then
      target="${path#/}"
    else
      target="$(normalize_path "$reldir" "$path")"
    fi
    if [ ! -e "$target" ]; then
      broken+=("$file: [$link] -> $target")
      drift=1
    fi
  done <<<"$links"
done < <(find . -name '*.md' -not -path './.git/*' -not -path './tests/fixtures/*' -print0)

if [ "$drift" -eq 1 ]; then
  printf '  %s✗%s broken internal markdown link(s) or unreadable file(s):\n' "$R" "$Z"
  printf '      %s\n' "${broken[@]}"
else
  printf '  %s✓%s every internal markdown link resolves\n' "$G" "$Z"
fi

exit "$drift"
