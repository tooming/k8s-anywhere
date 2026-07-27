# [Action needed] Now/next still gated; UPGRADE-DRAFTER lens also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles)

PR #758/#759, PR #762, PR #765, PR #766, PR #767 (see those PRs' bodies for
detail — CVE audits across the whole always-on stack plus the LGTMP stack,
all clean; a JANITOR-lens cleanup check also came up empty).

## This cycle's fresh angle (sixth cycle)

Tried the **UPGRADE-DRAFTER** lens directly — not "is there a CVE" but "is
there simply a newer stable version available" — on components not yet
mechanically re-checked this run. TRIAGER lens also checked (all three open
issues already fully labeled `domain:*`/`readiness:*`/`priority:*` — nothing
to triage) and DOC-DRIFT-AUTHOR lens (already confirmed green earlier this
run via `make readme-check`/`lab-ui-check`/`markdown-links-check`, re-run
again this cycle, still clean) — both genuine no-ops, not worth their own PR
per those routines' own no-op rules.

**Longhorn** (ADR-0013, on-demand): confirmed still correctly held at
`1.11.3`, one minor line behind `1.12.0` GA — this is a **deliberate,
already-recorded architect decision** (2026-07-18 entry: `1.12.x`'s V2/SPDK
Data Engine going GA is "a bigger behavioral surface change than this
routine currency bump warrants"), not an oversight upgrade-drafter should
mechanically override. Checked the ADR's own flip condition ("re-check when
the `1.11.x` line approaches end-of-support, or a specific CVE is filed") —
no 2026 CVE found against Longhorn this sweep, flip condition not met. No
bump; would need a fresh architect RFC to revisit the 1.12.x hold, not a
mechanical upgrade-drafter action.

No genuine upgrade-drafter-shaped bump found this cycle that doesn't either
duplicate an already-recorded architect decision or need its own RFC first.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
