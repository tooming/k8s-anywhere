#!/usr/bin/env bash
# bats/shellcheck duplication guard — a bats test must never invoke `shellcheck`
# directly on a single script.
#
# THE GAP (found live 2026-09-07, three PRs in a row this session): `make lint`
# (scripts/lint.sh, wired into `make ci`) already shellchecks every file under
# `scripts/*.sh` — including any newly-added script — with the repo's one
# established pattern: optional locally (skipped with a note when `shellcheck`
# isn't installed), but a hard failure in CI (`CI=true`), so the gate can never
# silently no-op on a real CI run. tests/forgejo-repo-secret.bats instead added
# its own one-off `run shellcheck --severity=warning "$SCRIPT"` assertion —
# fully redundant with the coverage `make lint` already provides for that exact
# file, AND missing the skip-when-uninstalled guard, so it hard-fails `make ci`
# in any sandbox without `shellcheck` on PATH (this one included) instead of
# skipping like every other tool-dependent check in this repo does.
#
# THE STRUCTURAL FIX (removes the footgun, not just detects it): forbid a bats
# test from invoking `shellcheck` directly at all. Shellchecking a script is
# `scripts/lint.sh`'s job — a bats file has no business re-implementing it
# per-script, worse and without the skip guard.
#
# Mirrors the readme-check / roadmap-check / git-fixture-isolation-check drift
# guards: scripts/<thing>-check.sh + `make <thing>-check` in `make ci` + bats
# coverage in its own tests/drift-<scope>.bats file (per
# tests/drift-detectors.bats's own "new coverage goes in its own file" rule).
#
# Exit 0 = clean; 1 = a bats file invokes shellcheck directly.
#
# Test seam: BATS_SHELLCHECK_DUP_ROOT overrides the repo root (fixtures).
set -uo pipefail
ROOT="${BATS_SHELLCHECK_DUP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TESTS_DIR="$ROOT/tests"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0

[ -d "$TESTS_DIR" ] || { echo "no tests/ dir — nothing to check"; exit 0; }

for f in "$TESTS_DIR"/*.bats; do
  [ -e "$f" ] || continue
  # Strip inline `#` comments first so prose mentioning shellcheck doesn't trip
  # the match (mirrors git-fixture-isolation-check.sh's own approach).
  stripped="$(sed 's/#.*//' "$f")"
  if printf '%s\n' "$stripped" | grep -qE '(^|[^A-Za-z0-9_])run[[:space:]]+shellcheck([[:space:]]|$)'; then
    bad "$(basename "$f") invokes shellcheck directly — that's make lint's job"
  fi
done

if [ "$drift" -ne 0 ]; then
  printf '      %s\n' "→ Why: scripts/lint.sh already shellchecks every scripts/*.sh file (skipped"
  printf '      %s\n' "  locally when uninstalled, hard-required in CI) — a bats test re-running it"
  printf '      %s\n' "  per-script duplicates that coverage without the same skip guard, so it"
  printf '      %s\n' "  hard-fails make ci in any sandbox without shellcheck on PATH."
  printf '      %s\n' "→ Fix: remove the bats assertion; scripts/lint.sh already covers the file."
fi

[ "$drift" -eq 0 ] && printf '  %s✓%s no bats test invokes shellcheck directly (make lint already covers scripts/*.sh)\n' "$G" "$Z"
exit "$drift"
