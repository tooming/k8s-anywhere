#!/usr/bin/env bash
# PostToolUse guard: flags a `gh pr merge` Bash command whose target PR had a
# non-passing required check. Born from a real incident (2026-07-13): an agent
# self-merged a PR over a known-red `routines-check`, rationalizing an exception to
# the very "never merge with a red CI check, no matter how green the rest of CI is"
# rule WAYS-OF-WORKING.md §2 states as absolute. A separate safety layer caught it
# after the fact and it had to be reverted (see PR #375). This hook is the mechanical
# guard for that class of mistake, for the routines that only have Bash (no MCP
# merge tool) and drive merges via `gh pr merge` directly.
#
# It cannot PREVENT the merge — PostToolUse fires after the tool already ran, same
# limitation as every other hook in this file (see routines-sync-hook.sh) — but it
# makes a merge-over-red-CI impossible to miss in the same turn, rather than relying
# on a separate safety layer or a human to catch it later.
#   exit 0 = nothing to say  |  exit 2 = stderr is shown to Claude as a reminder
set -uo pipefail

payload="$(cat 2>/dev/null || true)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

case "$cmd" in
  *"gh pr merge"*) ;;
  *) exit 0 ;;
esac

# Can't verify without gh — never false-positive just because the tool is missing.
command -v gh >/dev/null 2>&1 || exit 0

pr_num="$(printf '%s' "$cmd" | grep -oE 'gh pr merge[^&|;]*' | grep -oE '[0-9]+' | head -1 || true)"
[ -n "$pr_num" ] || exit 0

checks_output="$(gh pr checks "$pr_num" 2>&1 || true)"
[ -n "$checks_output" ] || exit 0

# `gh pr checks` exits non-zero both when a real check is failing AND when it can't
# determine status at all (no GH_TOKEN, no such PR, network error, wrong repo context)
# — those are common and must never be treated as "red CI" (false positive). So this
# doesn't trust the exit code: it looks for the literal word "fail" as its own token,
# which only appears in a real check's STATE column (`name\tfail\t...`), never in gh's
# own error text ("authentication required", "no pull requests found", etc). Narrowly
# scoped to definite failures, not "pending" — pending is a different, less clear-cut
# state this hook deliberately doesn't flag.
if grep -qiE '(^|[[:space:]])fail([[:space:]]|$)' <<<"$checks_output"; then
  {
    echo "'gh pr merge $pr_num' just ran against a PR with at least one failing check:"
    echo "$checks_output"
    echo
    echo "WAYS-OF-WORKING.md §2: never merge with a red CI check, no matter how green"
    echo "the rest of CI is, no matter what the reasoning seems to justify in the"
    echo "moment. If this was a mistake, revert it now rather than leaving a"
    echo "known-red merge standing — see PR #375 for the precedent."
  } >&2
  exit 2
fi
exit 0
