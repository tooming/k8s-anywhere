# Janitor note — 2026-08-10 (stale "needs RFC" language in a resolved item)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, seventh cycle this
run (after `auto/external-secrets-chart-2-9-0`, `auto/pyroscope-chart-2-2-1`,
`plan/alerting-rfc-gap`, `arch/alerting-rfc-week33`, `plan/groom-alerting-rfc`, and
`auto/grafana-alerting-rules` — six merged PRs today). The three standing Now/next
items remain gated on unconfirmed maintainer-confirmation issues #631/#633/#1034 —
re-checked directly this cycle, unchanged since 2026-08-07.

**Fallback chain walked this cycle:** PLANNER — intake still exactly the three
standing `[Action required]` issues, nothing to groom; no un-RFC'd 🟡 items exist
(the alerting item was fully built and merged this run). ARCHITECT — no open
`adr-audit` issues, and this run's own extensive currency sweep (two cycles) plus
the W33 digest fetch pass already covered every ADR'd component this week; nothing
fresh to audit. UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR — `make ci`'s drift checks are all
green; no doc/dependency-tree/lab-ui drift found. Landing on JANITOR.

**What was found:** while re-reading ROADMAP.md's "Cross-cutting hardening" section
this run (to groom the alerting RFC in an earlier cycle), noticed the already-`[x]`-
resolved "Author retroactive ADR(s) for GitLab and the LGTMP observability-stack
internals" item (RFC #1073, resolved 2026-08-07) still carried its *original*,
now-stale body text from when it was an open 🟡 question: "**Needs an architect RFC
before the executor may build it — do NOT build around this open question**" and
"No branch yet — 🟡, architect RFC required first." Both sentences are false as of
the item's own header, which already says `[x] ~~🟡~~ ... Resolved 2026-08-07`. Only
the header + a short parenthetical got updated when the item was checked off
(2026-08-07, per its own note); the body underneath was never revisited.

This is a real, if minor, ADR-0004-adjacent accuracy bug: a resolved item's body
telling a future reader (human or agent) "don't build around this, it's still an
open question" is actively misleading, not just untidy. Fixed by rewording both
sentences to past tense, pointing at RFC #1073 as the resolution, without deleting
the surrounding historical detail (the gap description, the RFC's scope questions,
and the acceptance criteria all still have genuine record value — this repo's
convention throughout ROADMAP.md's "Done"-shaped items keeps that detail rather than
trimming resolved items down to a one-liner).

**No mechanical guard added** — this is a one-off staleness in prose, not a
recurring bug class with a detectable pattern (unlike, say, a version-pin drift,
which has an obvious "does the doc's number match the live pin" check). Grepping
ROADMAP.md for other `[x]`/struck-through items with similarly stale "Needs an
architect RFC"/"No branch yet" language found none — this appears to be an isolated
instance from this specific item's edit history, not a widespread pattern worth a
`scripts/*-check.sh` guard.

**Why this run stops at JANITOR rather than falling through to `[Action needed]`:**
a real, bounded, `make ci`-green cleanup was found and fixed — per STEP 6b, "a real
`chore/*` cleanup PR beats an idle issue."
