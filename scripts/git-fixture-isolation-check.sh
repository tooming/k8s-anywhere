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
bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

[ -d "$TESTS_DIR" ] || { echo "no tests/ dir — nothing to check"; exit 0; }

# Strip inline `#` comments first (so prose mentioning git/GIT_DIR doesn't trip the
# match), then classify each .bats file: does it BUILD a git fixture, and if so
# does it UNSET GIT_DIR? A fixture build is a real `git init`/`git clone` command.
for f in "$TESTS_DIR"/*.bats; do
  [ -e "$f" ] || continue
  stripped="$(sed 's/#.*//' "$f")"
  printf '%s\n' "$stripped" | grep -qE 'git[[:space:]]+(init|clone)([[:space:]]|$)' || continue
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
