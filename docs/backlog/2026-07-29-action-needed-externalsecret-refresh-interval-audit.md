# [Action needed] Now/next still gated; ExternalSecret refresh-interval consistency audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21
(**8+ days now** — flagged to the maintainer this cycle as the standing
blocker behind this run's entire chain of verification-only PRs).

## What this cycle already did

Merged [#843](https://github.com/tooming/k8s-anywhere/pull/843) (dashboard
UID + HTTPRoute hostname uniqueness audit).

## This cycle's fresh angle

Checked every `ExternalSecret`'s `refreshInterval` repo-wide for consistency
— a value that's too short would hammer Vault with unnecessary reads; too
long would delay credential rotation reaching a workload after a Vault-side
change. Found **18 ExternalSecrets, all using exactly `1h`** — perfectly
consistent, no outliers, no accidental default (Vault's own ESO chart
default is `1h` too, so this is deliberate consistency, not coincidence).
No gap.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633 — **now
flagged via a proactive notification this cycle**, since 8+ days of silence
on a standing gate is exactly the kind of thing worth surfacing rather than
quietly re-noting every cycle; (b) a new upstream CVE/release firing a
tracked ADR flip condition; (c) a new GitHub issue of any size (ungroomed
intake).

This note is this cycle's honest record — a genuinely distinct consistency
check (ExternalSecret refresh cadence). The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
