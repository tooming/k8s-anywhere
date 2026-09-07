# Fix a broken ROADMAP.md line-number citation in docs/dora-audit-readiness.md's Q5

JANITOR-fallback cleanup (executor STEP 6b), a sixth distinct finding this
run's current gated-lane streak, continuing the same-file sweep that already
found Q17 (#1490) and Q14 (#1491).

## What was found

Q5 ("Is the risk framework reviewed on a defined cadence?")'s Evidence line
cited `[ROADMAP.md:2615](../ROADMAP.md)` — a fragile absolute line-number
pointer. Checked directly: ROADMAP.md currently has only **2420 lines**
total, so line 2615 doesn't exist any more (this run's own legacy-item-trim
batches shrank the file well past it). Worse: checked via `git show` against
`a6a4252` (the commit that introduced this citation) what line 2615
contained *at the time it was written* — an unrelated paragraph about a
Harbor Grafana dashboard panel, nothing to do with "review cadence." The
citation was never accurate, not just stale from later edits.

## What was fixed

Replaced the broken line-number pointer with a citation to
`routines/architect.prompt.md` STEP 2 — the actual source of the
`## Re-evaluation log` pattern this Q&A's Answer text describes (verified:
that STEP literally instructs appending a dated `## Re-evaluation log`
section to the ADR when an audit resolves "Keep"), and noted honestly in the
citation itself that the prior reference was broken from the start, not
merely outdated.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose
correction, no code/manifest/test touched. The "2420 lines, line 2615
doesn't exist" claim and the "line 2615 was already unrelated content at
authorship time" claim were both verified directly (`wc -l ROADMAP.md`;
`git show a6a4252:ROADMAP.md | sed -n '2610,2620p'`) in this session.

## PR

(backfilled after PR creation)
