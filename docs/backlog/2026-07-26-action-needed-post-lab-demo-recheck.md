# [Action needed] Now/next still gated; standing issues still unconfirmed

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, `updated_at` unchanged since
2026-07-21T05:34 UTC. No new open issues, no open PRs from either session.

## This cycle

This run has landed real, substantive work via a systematic sweep of ADR
flip conditions that are checkable without live-cluster access: PR #752
(capstone-pipeline governance gap, a genuine unclaimed ROADMAP item), PR #753
(ADR-0017 `artifactory` PSS flip re-check — not met, evidence gap narrowed),
PR #755 (ADR-0017 `lab-demo` PSS flip re-check — not met, conclusively).

This cycle checked three more flip conditions before falling back to this
note (ADR-0009 RabbitMQ 4.3.x community-support window, ADR-0013 Longhorn
1.11.x line, ADR-0023 Kargo OCI registry tag currency) — all three were
already re-verified within the last 1-8 days (2026-07-24, 2026-07-23,
2026-07-25 respectively), so re-checking again today would just repeat the
same lookup with no realistic chance of new information. This angle has hit
diminishing returns for today; not manufacturing a fourth check just to
produce activity.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record — not a stopping point. The run
continues to watch for a standing-issue confirmation or a genuinely new
signal in subsequent cycles per `executor.prompt.md` STEP 8.
