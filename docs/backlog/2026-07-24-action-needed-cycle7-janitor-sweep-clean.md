# [Action needed] Now/next still gated; janitor-lens sweep also clean

## What's blocked

The "Now / next" lane's remaining unchecked items are all gated on the standing
maintainer-confirmation issues #631/#632/#633 — re-verified this cycle (eleventh
cycle of this run, seventh dated cycle today): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

Escalated through `executor.prompt.md` STEP 6b's full fallback chain to the
**JANITOR** role (planner/architect/upgrade-drafter/doc-drift all re-checked this
run already and came up empty or already delivered):

1. **Duplication / shared-helper survey.** `scripts/lib/` already exists and is
   actively used (`budget-check.sh`, `colors.sh`, `hook-payload.sh`,
   `yq-variant.sh`) — the codebase already practices the DRY pattern a janitor
   pass would normally recommend introducing. Scanned all 23 `scripts/*-check.sh`
   drift detectors for un-abstracted repeated logic beyond what's already shared
   via `lib/` — none found; each script's core logic is genuinely distinct
   (different files/patterns being checked), not copy-pasted boilerplate.
2. **Doc-drift re-check for today's version bumps.** Grepped `docs/dependency-tree.md`
   and `README.md` for stale exact-version references to any component bumped this
   run (RabbitMQ `4.3.3`, Pyroscope `2.1.2`, Grafana chart `12.7.3`,
   kube-state-metrics `7.8.1`, Loki `3.7.3`) — zero hits; neither doc tracks exact
   chart/image versions for these components (by design — that's what
   `docs/decisions/`'s Re-evaluation logs and the ADR chart/image-pin sync checks
   are for), so no drift was introduced by any of today's 8 merged PRs.
3. **Dead/orphaned matter.** No new orphaned files, no stale relative links beyond
   what `make ci`'s `markdown-links-check` already gates. Nothing bounded and
   real enough to justify a `chore/*` cleanup PR today — per janitor's own STEP 3,
   "if nothing real qualifies... never manufacture churn."

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue of any size.

This note is this cycle's honest record — on top of the eight PRs already merged
earlier in this same run (#701, #702, #703, #706, #709, #710, #711) plus two prior
`[Action needed]` notes (#712, #713) — not a stopping point. The run continues to
the next cycle per `executor.prompt.md` STEP 8.
