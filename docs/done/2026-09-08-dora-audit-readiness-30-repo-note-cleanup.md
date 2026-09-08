# Fix `docs/dora-audit-readiness.md` Q15's stale "~30-repo sweep" claim about `scripts/dependency-maintenance-check.sh`

Found live 2026-09-08 (planner gap analysis, same class this run already
fixed directly in the script itself —
[#1521](https://github.com/tooming/k8s-anywhere/pull/1521) — but missed
this second copy of the same stale claim describing the script from the
outside): Q15's "Answer" paragraph said "GitHub's request volume for a
`~30-repo` sweep makes it unsuitable as a hard, always-on gate" — the real
current count is 6 github-backed rows (`docs/dependency-register.md` is
down to 7 rows total, 2026-09-06/2026-09-07 simplification; only Oracle
Cloud Infrastructure lacks a `github.com` source).

Verified before editing:
- `grep -rn "30-repo" docs/*.md` confirmed this was the only remaining
  occurrence anywhere in `docs/`.
- `grep -rn "30-repo" tests/*.bats` confirmed no test asserts it.

## What was done

Reworded the parenthetical to avoid hardcoding a specific repo count again
(the same fix pattern already applied to the script's own header comment
in #1521) — "a multi-repo sweep — one network fetch per
`docs/dependency-register.md` row with a `github.com` upstream — is
unsuitable as a hard, always-on gate given GitHub's request volume" —
rather than swapping in "6", which would only recreate the same drift class
at the next simplification round.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green), confirming this
comment-only edit broke no mechanical assertion.

## PR

[#1523](https://github.com/tooming/k8s-anywhere/pull/1523) (autonomous
scheduled executor run, cycle 10: item picked directly from the
freshly-refilled "Now / next" lane after cycle 9's `plan/*` PR #1522).
