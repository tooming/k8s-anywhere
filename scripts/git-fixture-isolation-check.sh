#!/usr/bin/env bash
# git-fixture isolation drift check: any bats test that builds a throwaway git
# fixture (a `git init` / `git clone` into a temp dir) MUST unset the GIT_*
# environment variables in its setup(), NEVER rely on a clean environment.
#
# Why: git exports GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE (et al.) into every
# process it spawns while running a hook. `make ci` runs from the pre-push hook,
# so those vars leak into bats — and a fixture's `cd "$tmp" && git commit` then
# resolves to the REAL repo via the inherited GIT_DIR instead of the temp clone.
# The tests pass when `make ci` is run by hand (no GIT_* set) but fail the instant
# they run from the hook, silently blocking every local push. tests/prune-stale-
# branches.bats and tests/rebase-open-prs.bats hit exactly this. `unset GIT_DIR …`
# in setup() makes the fixture self-contained regardless of how CI was invoked.
# This flags any fixture-building bats file that forgets the unset, mechanically,
# mirroring the readme-check / yq-raw-check drift guards.
#
# Runs in CI (the 'drift' gates). Exit 0 = clean; 1 = drift.
set -uo pipefail
# ROOT defaults to the repo; tests point GITFIX_CHECK_ROOT at a fixture tree.
ROOT="${GITFIX_CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TESTS_DIR="$ROOT/tests"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

[ -d "$TESTS_DIR" ] || { echo "no tests/ dir — nothing to check"; exit 0; }

# Strip inline `#` comments first (so prose mentioning git/GIT_DIR doesn't trip the
# match), then classify each .bats file: does it BUILD a git fixture, and if so
# does it UNSET GIT_DIR? A fixture build is a real `git init`/`git clone` command —
# NOT a `grep` line that merely searches a file's content for that string (found
# live 2026-08-17: tests/forgejo-ci.bats's `grep -q 'git clone --no-checkout' "$WF"`
# asserts a *workflow YAML file* contains that shell command as text; it never runs
# git itself, so it needs no GIT_DIR isolation — the prior version of this check had
# no way to tell "runs git clone" apart from "greps for the string git clone" and
# flagged this as a false positive). Any line also containing `grep` is a content
# search, not a fixture build, and is excluded from the match.
for f in "$TESTS_DIR"/*.bats; do
  [ -e "$f" ] || continue
  stripped="$(sed 's/#.*//' "$f")"
  fixture_lines="$(printf '%s\n' "$stripped" | grep -E 'git[[:space:]]+(init|clone)([[:space:]]|$)' | grep -v 'grep')"
  [ -n "$fixture_lines" ] || continue
  if ! printf '%s\n' "$stripped" | grep -qE 'unset[[:space:]].*\bGIT_DIR\b'; then
    bad "$(basename "$f") builds a git fixture but never unsets GIT_DIR in setup()"
  fi
done

if [ "$drift" -ne 0 ]; then
  printf '      %s\n' "→ Why: git exports GIT_DIR/GIT_WORK_TREE into hooks; make ci runs from pre-push,"
  printf '      %s\n' "  so the leak redirects fixture commits into the real repo and the tests fail."
  printf '      %s\n' "→ Fix: add 'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR"
  printf '      %s\n' "  GIT_NAMESPACE' to setup(). See tests/prune-stale-branches.bats for the pattern."
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s git-fixture bats tests isolate GIT_* (survive a hook-invoked make ci)\n' "$G" "$Z"
exit "$drift"
