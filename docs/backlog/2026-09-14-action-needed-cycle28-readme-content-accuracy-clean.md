# [Action needed] Cycle 28 — README.md content-accuracy read, clean

## This run so far

Twenty-six PRs shipped this run (#1588–#1614), four of them real
substantive fixes in this cycle's immediate predecessors: a DORA Pillar 3
content fix (#1605), an ArgoCD chart bump (#1606), a k3s v1.37.0
deliberate-hold decision (#1607), a stale-investigation closeout (#1613),
and a stale cert-manager version citation in `docs/dependency-tree.md`
with a new mechanical guard (#1614). See prior `docs/backlog/2026-09-14-*.md`
files for every other cycle's detail.

## This cycle

Read `README.md` in full (133 lines) for content accuracy, applying the
same lens that found real staleness in `docs/dependency-tree.md` two
cycles ago — checked every table (stack layers, endpoints, DR commands,
quality gates, layout), every cross-reference link, and every claim
against current repo state. All four `dr-chaos-*` targets listed match
`docs/DR.md` exactly; the "large simplification" summary matches
CHARTER.md's own accounting; no version numbers are cited in this file at
all (unlike `docs/dependency-tree.md`/`docs/decisions/context.md`), so
there's no citation-drift surface here to guard. No staleness found.

## Assessment

Twenty-eight consecutive cycles this run have worked the fallback chain.
The content-accuracy-read angle has now covered every major prose doc in
the repo (`docs/00-architecture.md`, `docs/dependency-concentration.md`,
`docs/dependency-exit-runbooks.md`, `docs/dora-resilience-mapping.md`,
`docs/DR.md`, `docs/dora-audit-readiness.md`, `docs/dependency-tree.md`,
and now `README.md`) — two of eight turned up real, fixed staleness; the
rest confirmed clean.

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- A new release/GHSA against any pinned source.
- k3s `v1.37.1+` shipping (ADR-0030's own flip condition, PR #1607).
- Oracle's Always Free capacity actually freeing up.
- A later cycle in this same run, once meaningfully more time has passed
  — the content-accuracy-read angle is now well-covered; a later cycle
  should pick a genuinely different surface (e.g. re-run the pin-currency
  sweep once enough time has passed for something new to have shipped
  upstream).

This is cycle 28's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
