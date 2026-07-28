# [Action needed] Now/next still gated; routine file-reference sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped twenty-two real, merged deliverables (PRs
#789, #790, #792–#812), including three real bugfixes (#796, #797, #808).

First checked whether the README-mentioned-`make`-target cross-reference this cycle
intended to run is already covered — it is: `scripts/readme-check.sh` (already part of
`make ci`) mechanically asserts every `make <target>` the README mentions exists in the
Makefile, so that specific check would have duplicated existing coverage.

Instead checked a related, previously-untried cross-reference: every
`routines/<name>.prompt.md` file path cited in `executor.prompt.md`'s STEP 6b fallback
chain (planner, architect, upgrade-drafter, doc-drift-author, triager, janitor — 6
files) against the actual files present under `routines/`. All 6 resolve to real files;
the remaining 4 files under `routines/` (`operator.prompt.md`, `verifier.prompt.md`,
`learning-post-writer.prompt.md`, `executor.prompt.md` itself) are correctly *not*
referenced in the chain, matching `docs/WAYS-OF-WORKING.md`'s own registry description
of which roles are fallback-chain members versus local on-demand/other roles.

No actionable gap surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
