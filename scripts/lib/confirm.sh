# Shared "type-to-confirm" destructive-action gate — sourced, not executed.
# scripts/dr-chaos.sh, scripts/dr-destroy.sh, scripts/dr-test.sh, and
# scripts/dr-bluegreen-promote.sh each hand-rolled a byte-similar copy of this
# guard; consolidated here so a future format tweak only needs one edit,
# mirroring the budget-check.sh / colors.sh extraction precedent.
# Callers must source scripts/lib/colors.sh first if their message uses colors.

# confirm_or_abort <message> <confirm_word> [prompt_verb_phrase]
# DR_ASSUME_YES=1 bypasses entirely (non-interactive/scripted use, or a parent
# script — e.g. dr-test.sh — that already ran its own single prompt and wants
# its children to inherit the go-ahead). Otherwise: prints <message> verbatim
# (callers control their own trailing space/newline/coloring), then on a real
# TTY prompts "Type '<confirm_word>' <prompt_verb_phrase>: " and requires an
# exact match or exits 1 with "aborted."; with no TTY, refuses outright with
# "Refusing non-interactively without DR_ASSUME_YES=1." on stderr and exits 1.
confirm_or_abort() {
  local message="$1" word="$2" verb="${3:-to continue}"
  [ "${DR_ASSUME_YES:-0}" != "1" ] || return 0
  printf '%s' "$message"
  if [ -t 0 ]; then
    local ans
    read -r -p "Type '${word}' ${verb}: " ans
    [ "$ans" = "$word" ] || { echo "aborted."; exit 1; }
  else
    echo "Refusing non-interactively without DR_ASSUME_YES=1." >&2
    exit 1
  fi
}
