# [Action needed] Now/next still gated; docs/done PR/issue reference spot-check also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (eighth cycle of 2026-07-26): all three still open, zero comments.

## This cycle's fresh angle

`docs/done/` holds 244 permanent Done records citing 163 unique `#NNNN`
PR/issue references. Verifying every one is out of scope for a single bounded
cycle, so spot-checked a spread sample (every 20th unique number across the
full range): `#101, #230, #306, #374, #435, #493, #544, #616, #718`.

Two (`#230`, `#544`) initially 404'd against the PR-lookup endpoint — briefly
looked like a broken reference. Checked before reporting (per ADR-0004):
both are real, closed/completed **RFC issues** (not PRs) — `#230` is the
`envoy-gateway-system` PSS-hardening RFC, `#544` is the Grafana chart-source
migration-off-deprecated-repo RFC. The other seven resolved directly as real,
merged PRs. All nine references in the sample are legitimate and accurate;
no broken or dangling cross-reference found in this spot-check.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of any
size.

This note is this cycle's honest record — this run's eighth cycle today. The
readily-available distinct verification angles for a clusterless session are
now substantially exhausted after CVE research (×5 across PRs #729–#733),
CHARTER + GitHub Actions currency (#732), janitor-lens duplication (#734),
appset/governance completeness (#735), and this Done-record spot-check —
every one confirming the repo's state is genuinely sound rather than turning
up new buildable work. Saying so plainly here rather than manufacturing a
progressively more strained ninth angle. Not a stopping point per STEP 8 —
the run continues to watch for a standing-issue confirmation or a genuinely
new signal (a fresh CVE disclosure, a new GitHub issue) in subsequent cycles.
