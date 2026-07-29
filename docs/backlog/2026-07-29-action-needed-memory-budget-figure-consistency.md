# [Action needed] Now/next still gated; memory-budget figure consistency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#849](https://github.com/tooming/k8s-anywhere/pull/849) (CHARTER's
Always-on core ArgoCD Application count re-counted, ~28 → ~33, closing issue
#846 — a real fix, not just another clean-audit note).

## This cycle's fresh angle

Following on directly from the prior cycle's successful numeric-accuracy
fix, this cycle checked for a similarly-verifiable numeric inconsistency:
both "12 GB" and "16 GB" appear across CHARTER.md/README.md/ROADMAP.md/
`docs/*.md` (`grep -oE "1[26] GB"` — 12+ mentions of each). At a glance this
looked like it could be the same kind of stale-figure drift the ArgoCD
count fix just resolved.

Read the surrounding context for each: they are **two different, correctly
distinguished concepts, not a conflict** — "16 GB" is the host machine's
total RAM ("the default, zero-external-dependency path — one 16 GB Mac");
"12 GB" is the VM's own allocated budget *within* that host (leaving ~4 GB
headroom for the host OS/Colima overhead). CHARTER.md's own Core Value
title ("Fits the 16 GB reality — on the localhost backend") and body text
("The always-on stack lives in the 12 GB VM (~7 GB used)") make this
distinction explicit and consistent everywhere it's used. No fix needed.

Also considered, but did **not** attempt to verify: the "~500 MB total"
(Always-on next wave) and "~480 MB" (Istio ambient mesh) footprint claims.
Unlike the ArgoCD Application count (a mechanically countable fact from
files in this repo), these are runtime memory-usage figures that would
require actually running the components on a live cluster to measure —
exactly the kind of claim this repo's own Harbor-footprint gate (#632)
insists must come from a real measurement, not a declared-request sum
(which would understate real usage and risk asserting a misleading
number). Left unverified rather than guessed at (ADR-0004).

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633 (which
would also let the actual Kyverno/Rollouts/Velero/Trivy and Istio footprints
finally be measured for real, resolving the "~500 MB"/"~480 MB" question
alongside them); (b) a new upstream CVE/release firing a tracked ADR flip
condition; (c) a new GitHub issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct numeric
check that, this time, correctly confirmed consistency rather than finding
another real drift, and explicitly declined to fabricate a memory-footprint
verification this session cannot actually perform. The run continues to the
next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
