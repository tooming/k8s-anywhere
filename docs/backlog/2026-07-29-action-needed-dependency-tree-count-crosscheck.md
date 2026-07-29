# [Action needed] Now/next still gated; dependency-tree.md cross-check against the new Application count clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#850](https://github.com/tooming/k8s-anywhere/pull/850) (memory-budget
figure consistency check).

## This cycle's fresh angle

Follow-up to the two-cycles-ago CHARTER/dora-audit-readiness Application-count
fix (#846/#849): checked whether `docs/dependency-tree.md` — the canonical,
wave-by-wave Application map — makes any *summary total* claim that would
now conflict with the corrected ~33/~58/~63 figures. It doesn't: the file is
structured entirely as a per-wave breakdown (no single "~N Applications
total" sentence anywhere), so there was nothing to update there. Also
independently cross-confirmed one detail from that recount while reading:
`docs/dependency-tree.md` states `tidb-admin-extras` has "no `automated:`
sync block — syncs alongside `make tidb-operator-up`," matching (from a
completely different source than the `yq` field check used two cycles ago)
the finding that it's genuinely on-demand, not part of the auto-synced set.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — closing the loop on the recent
Application-count fix by confirming no other doc needed the same
correction, with an independent cross-check of one of that fix's own
findings. The run continues to the next cycle per `executor.prompt.md`
STEP 8; this is not a stopping point.
