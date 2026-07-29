# [Action needed] Now/next still gated; Makefile/script reference integrity audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#851](https://github.com/tooming/k8s-anywhere/pull/851)
(dependency-tree.md count cross-check).

## This cycle's fresh angle

Two dead-code/dangling-reference checks, distinct from the earlier
Makefile-target-symmetry sweep (which checked up/down pairing, not script
existence) and the earlier script-test-coverage check (which only checked
`tests/`, not `Makefile`/CI):

1. **Every `scripts/*.sh` path referenced in `Makefile` actually exists on
   disk** — swept all 100 `.PHONY` targets' script references; zero
   missing.
2. **Every script under `scripts/` is referenced from at least one of
   `Makefile`, `.github/workflows/ci.yml`, or `tests/`** — zero orphaned
   scripts found (this is a broader net than the test-coverage-only check
   run earlier this run, which already found no gap; this confirms the
   same conclusion from the Makefile/CI angle too).

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — two genuinely distinct
dangling-reference checks, both clean. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
