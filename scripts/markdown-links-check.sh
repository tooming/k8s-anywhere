#!/usr/bin/env bash
# Markdown internal-link drift check: every relative [text](path) link in a
# tracked *.md file must resolve to a real file/dir. Docs get renamed and moved
# often in this repo (docs/done/, docs/backlog/, ADRs) with nothing catching a
# stale cross-reference left behind — this closes that gap. External links
# (http/https/mailto) and pure-anchor links (#section) are out of scope; a
# reachability check on external URLs is a different, network-dependent problem.
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point MDLINKS_ROOT at a fixture tree.
# Resolved to an absolute path up front: a relative MDLINKS_ROOT would otherwise
# be interpreted relative to the *original* cwd by `realpath --relative-to`
# below, even after this script has already cd'd into it.
ROOT="${MDLINKS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd)" || exit 1
cd "$ROOT" || exit 1

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Z=$'\033[0m'; else G=; R=; Z=; fi

drift=0
broken=()

while IFS= read -r -d '' file; do
  reldir="$(dirname "$file")"
  while IFS= read -r link; do
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
      target="$(realpath -m --relative-to="$ROOT" "$reldir/$path" 2>/dev/null)"
    fi
    if [ ! -e "$target" ]; then
      broken+=("$file: [$link] -> $target")
      drift=1
    fi
  done < <(
    # Strip fenced code blocks (```...```) and inline code spans (`...`) first —
    # otherwise a doc that *describes* markdown link syntax as a literal example
    # (e.g. this very script's own docs/done/ write-up) false-positives as a real
    # broken link.
    awk '/^```/{f=!f; next} !f' "$file" | sed -E 's/`[^`]*`//g' | grep -oP '\]\(\K[^)]+'
  )
done < <(find . -name '*.md' -not -path './.git/*' -not -path './tests/fixtures/*' -print0)

if [ "$drift" -eq 1 ]; then
  printf '  %s✗%s broken internal markdown link(s):\n' "$R" "$Z"
  printf '      %s\n' "${broken[@]}"
else
  printf '  %s✓%s every internal markdown link resolves\n' "$G" "$Z"
fi

exit "$drift"
