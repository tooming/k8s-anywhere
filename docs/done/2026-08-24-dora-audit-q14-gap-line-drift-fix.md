# Fix stale Q14 "Gap" line in docs/dora-audit-readiness.md

(CHARTER **Core Values** §"Docs & dashboards don't drift"; JANITOR-fallback
bounded cleanup 2026-08-24, third cycle of this run, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed
fully gated and PLANNER/ARCHITECT fallback passes this same run each produced
their own real deliverable (`chore/dependency-register-drift-fix-and-guard`,
PR #1297; `arch/industry-digest-2026-w35`, PR #1298) with nothing further to
groom or decide. **No prerequisites — executor may pick up immediately.**)

## What was found

`docs/dora-audit-readiness.md`'s Q14 ("Is there a register of ICT third-party
dependencies?") answer text was accurate, but its own **Gap** line had gone
stale within this same run: it still said "the register has no mechanical
drift guard yet — it's a manual snapshot that can go stale" — a claim this
run's own first cycle made untrue by shipping
`scripts/dependency-register-check.sh` (PR #1297, wired into `make ci`).
Caught during a fresh-angle sweep of this doc's other "Gap:" lines for
staleness relative to this run's own recent changes (JANITOR STEP 3 priority
#3, "stale doc reference").

## What changed

Rewrote Q14's Gap line to describe the guard that now exists (what it checks,
where it's wired) and its two honest, still-real limits — stated plainly
rather than glossed over (ADR-0004): it doesn't yet parse ADR-0034's
`**YYYY-MM-DD**` bold-entry Re-evaluation-log convention (7 rows citing
ADR-0034 alone aren't mechanically checked), and it can't invent a review
date for an ADR that has no Re-evaluation log at all (a gap in the ADR, not
something the register or its guard can paper over).

Checked the file's other "Gap:" lines for similar staleness relative to this
run's changes — none found; only Q14 referenced something this run's own
earlier cycle had just changed.

## Verification

`bash scripts/markdown-links-check.sh` and `bash scripts/adr-followup-check.sh`
both pass. `make ci` green. Single-file, prose-only diff.

## PR

https://github.com/tooming/k8s-anywhere/pull/1299
