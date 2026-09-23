#!/usr/bin/env bash
# Portability drift check: no script or test may use an idiom that a stock macOS
# (BSD userland) rejects. `make ci` is run on the maintainer's Mac as well as on
# the Linux CI runners, and the GNU-only forms below broke it on the Mac without
# the Linux gate ever noticing (#1637): `sed -i` and `timeout` made 6 bats tests
# fail there, and `grep -P` + `realpath -m` made scripts/markdown-links-check.sh
# print "every internal markdown link resolves" while checking nothing — a false
# green, worse than a failure. Each rule below was verified to FAIL on a stock
# macOS (Darwin 25, `env -i` with only /usr/bin:/bin:/usr/sbin:/sbin, /bin/bash;
# 2026-09-23). Idioms macOS handles fine there (readlink -f, sed -r, xargs -r,
# md5sum/sha256sum, date +%N) are deliberately NOT flagged. Beware testing from an
# interactive shell that wraps grep/find with other tools: that reported
# `grep -P` and `find -printf` as working.
#
# The portable replacement for each hit:
#   grep -P            -> grep -E (or sed/awk)
#   sed -i 'expr' f    -> sed 'expr' f >tmp && mv tmp f      (sed -i.bak is portable too)
#   timeout N cmd      -> run_with_timeout N cmd             (scripts/lib/timeout.sh)
#   realpath -m/--…    -> plain `realpath`, or normalise in bash (markdown-links-check.sh)
#   date -d STR        -> `git log --format=%ct`-style epoch, or `date -j -f` on BSD
#   stat -c FMT        -> `stat -f` on BSD; or read via wc -c / git
#   find -printf       -> find … -exec printf …  /  -print0
#   head -n -N, tac    -> awk / sed
#   mktemp --suffix    -> mktemp -d, then name files inside it
#
# A line that must keep a flagged idiom on purpose (it runs inside a Linux
# container, or behind an explicit BSD fallback) carries a trailing
# `# portability-ok: <why>` comment — the reason is mandatory in review, the
# marker is what this check keys on. Comment-only lines are never flagged.
#
# Scope: scripts/**, tests/**/*.{bats,sh,bash} (not tests/fixtures/ — those are
# deliberate bad examples), .githooks/, and the Makefile. This file and
# tests/drift-portability-check.bats quote the idioms and are exempt.
#
# Fails LOUDLY if grep itself errors (status >1) — "no match" (1) is clean, but a
# check that cannot run must not report clean; that exact conflation is the bug
# class this file exists to stop.
#
# Static + offline. Run by `make portability-check`, `make ci`, and the CI drift job.
# Exit 0 = clean; 1 = a flagged idiom (or the check could not run).
set -uo pipefail

# ROOT defaults to the repo; tests point PORTABILITY_ROOT at a fixture tree.
ROOT="${PORTABILITY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd)" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
cd "$ROOT" || exit 1

# --- rules: parallel arrays (name / ERE / how to fix) --------------------------
# B = left word boundary for a command name: start of line, or anything that is
# not part of a word/path (so `run_with_timeout`, `gtimeout`, `x/realpath` never
# match). C = "arguments up to a pipe/sequence/comment", allowing the flag to
# come after other words (`grep -n -oP`, `date -u -d`).
B='(^|[^[:alnum:]_./-])'
C='([^|;&#]*[[:space:]])?'
RULE_NAME=(); RULE_RE=(); RULE_FIX=()
add_rule() { RULE_NAME+=("$1"); RULE_RE+=("$2"); RULE_FIX+=("$3"); }

add_rule 'grep -P' \
  "${B}e?grep[[:space:]]+${C}(-[[:alnum:]]*P[[:alnum:]]*|--perl-regexp)([[:space:]]|\$)" \
  "BSD grep has no -P; use grep -E (or sed/awk)"
add_rule 'sed -i without an attached suffix' \
  "${B}sed[[:space:]]+${C}(-[[:alnum:]]*i|--in-place)([[:space:]]|\$)" \
  "GNU 'sed -i expr' and BSD \"sed -i '' expr\" are incompatible; write to a temp file and mv, or use sed -i.bak"
add_rule 'bare timeout' \
  '(^|[[:space:];&|(])timeout[[:space:]]+(-[[:alnum:]-]+[[:space:]]+)*[0-9]' \
  "no timeout on stock macOS; source scripts/lib/timeout.sh and use run_with_timeout"
add_rule 'realpath with options' \
  "${B}realpath[[:space:]]+-" \
  "macOS realpath takes no -m/--relative-to/…; normalise in bash (see markdown-links-check.sh)"
add_rule 'date -d' \
  "${B}date[[:space:]]+${C}(-[[:alnum:]]*d|--date)([[:space:]]|\$)" \
  "BSD date has no -d; use an epoch (git log --format=%ct) or date -j -f"
add_rule 'stat -c' \
  "${B}stat[[:space:]]+${C}-[[:alnum:]]*c([[:space:]]|\$)" \
  "BSD stat uses -f; run it in a Linux container with a portability-ok marker, or use wc -c"
add_rule 'find -printf / -regextype' \
  "${B}find[[:space:]]+[^|;&#]*[[:space:]]-(printf|regextype)([[:space:]]|\$)" \
  "BSD find has neither; use -exec printf / -print0 / -E"
add_rule 'head -n -N' \
  "${B}head[[:space:]]+-n[[:space:]]*-[0-9]" \
  "BSD head rejects a negative count; use sed '\$d' / awk"
add_rule 'tac' \
  '(^|[[:space:];&|(])tac([[:space:]]|$)' \
  "no tac on macOS; use tail -r on BSD or awk"
add_rule 'mktemp --suffix' \
  "${B}mktemp[[:space:]]+${C}--suffix" \
  "BSD mktemp has no --suffix; mktemp -d, then name files inside it"

# --- files to scan --------------------------------------------------------------
files=()
while IFS= read -r -d '' f; do
  rel="${f#./}"
  case "$rel" in
    scripts/portability-check.sh|tests/drift-portability-check.bats) continue ;;
  esac
  files+=("$rel")
done < <(
  {
    [ -d scripts ]   && find scripts   -type f -name '*.sh' -print0
    [ -d tests ]     && find tests -path tests/fixtures -prune -o -type f \( -name '*.bats' -o -name '*.sh' -o -name '*.bash' \) -print0
    [ -d .githooks ] && find .githooks -type f -print0
    [ -f Makefile ]  && printf 'Makefile\0'
  } 2>/dev/null
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "no scripts/tests/hooks/Makefile — nothing to check"
  exit 0
fi

hits=0
for i in "${!RULE_NAME[@]}"; do
  # -H: always prefix the file name — grep omits it when handed a single file,
  # which would make the "file:line:" parsing below misread the line number.
  out="$(grep -HnIE -- "${RULE_RE[$i]}" "${files[@]}" 2>&1)"
  rc=$?
  if [ "$rc" -gt 1 ]; then
    bad "grep failed (exit $rc) while checking '${RULE_NAME[$i]}' — the check did not run: $(printf '%s' "$out" | head -1)"
    continue
  fi
  [ "$rc" -eq 0 ] || continue
  while IFS= read -r line; do
    body="${line#*:*:}"                       # drop "file:lineno:"
    case "$body" in
      *portability-ok*) continue ;;
    esac
    # comment-only line (optional indent, then #)
    trimmed="${body#"${body%%[![:space:]]*}"}"
    [ "${trimmed:0:1}" = "#" ] && continue
    bad "${line%%:*}:$(cut -d: -f2 <<<"$line"): ${RULE_NAME[$i]} — ${RULE_FIX[$i]}"
    hits=$((hits + 1))
  done <<<"$out"
done

if [ "$drift" -eq 0 ]; then
  printf '  %s✓%s no GNU-only idioms in scripts/tests/hooks/Makefile (%d files, %d rules)\n' "$G" "$Z" "${#files[@]}" "${#RULE_NAME[@]}"
fi
exit "$drift"
