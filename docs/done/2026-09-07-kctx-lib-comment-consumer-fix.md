# Fix stale consumer list in scripts/lib/kctx.sh's header comment

## PR

[#1509](https://github.com/tooming/k8s-anywhere/pull/1509)

## What

Continuing the same JANITOR-fallback coverage sweep as #1506/#1507
(ROADMAP rule #9, "Now / next" genuinely empty): `scripts/lib/kctx.sh`'s
header comment listed `scripts/cosign-bootstrap.sh` and
`scripts/garage-bootstrap.sh` as current consumers of its shared
KCTX-aware `kubectl()` wrapper. Both files were deleted in PR #1497 (the
2026-09-07 aggressive-simplification change that removed Garage and the
container-signing pipeline entirely, alongside everything else that PR
dropped) — confirmed via `git log --diff-filter=D` that both were deleted
in that exact commit, and via `grep -rl "lib/kctx.sh" scripts/*.sh` that
only 4 scripts (`dr-verify.sh`, `lab-health-check.sh`,
`ondemand-budget-check.sh`, `vault-bootstrap.sh`) actually source it today.

## Fix

Rewrote the comment to list only the real current consumers, moving the two
removed ones into the same parenthetical the comment already used for a
third historical consumer (`scripts/grafana-gitsync-bootstrap.sh`, removed
2026-09-06 alongside Grafana's native Git Sync).

## Verification

- `make ci`: fully green, zero `not ok` lines.
- `grep -rl "lib/kctx.sh" scripts/*.sh` confirms the corrected 4-script list
  is exhaustive.

## ADR compliance

No ADR contradicted — comment-only accuracy fix, no behavior change.

## Behavior preserved

Comment-only change; `kctx.sh`'s actual `kubectl()` wrapper logic is
untouched.
