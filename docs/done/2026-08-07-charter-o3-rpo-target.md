# Name O3's RPO target explicitly in CHARTER.md

(CHARTER **Objective O3**; planner gap-analysis 2026-08-07, reached via
`executor.prompt.md` STEP 6b after every standing "Now / next" item was found gated
(unchanged) on unconfirmed maintainer-confirmation issues #631/#633, with no ungroomed
intake issues and no un-RFC'd 🟡 items to promote instead — `docs/dora-audit-readiness.md`
Q3 ("What are the recovery targets (RTO/RPO) for critical functions?") already answers
"RPO ≤ 24 hours (Velero daily schedules, 168h retention) — true today but never labeled
'RPO' anywhere in the docs before this file" and names the fix directly: "Cheap fix: add
an explicit RPO line to O3 in CHARTER.md." **No prerequisites — executor may pick up
immediately.**) Verified directly (not assumed, ADR-0004): all six
`gitops/velero/schedules/*.yaml` Schedules (`data`, `tidb`, `capstone`, `vault`,
`observability`, `inkless`) run once daily (staggered 01:00–04:00,
`schedule: "<min> <hour> * * *"`) each with `ttl: 168h` (7-day retention) — the
worst-case gap between a change and its next backup is the ≤24h window this item
names, not a guessed number.

Added an explicit RPO line to CHARTER.md's O3 bullet, immediately after its existing
RTO sentence ("...under 10 minutes wall-clock on the maintainer's hardware."): states
RPO ≤ 24 hours, citing Velero's daily schedules across all six stateful namespaces and
their 168h/7-day retention (`gitops/velero/schedules/*.yaml`). Updated
`docs/dora-audit-readiness.md`'s Q3 "Gap" line to record that CHARTER now states the
RPO explicitly (closing the "never labeled 'RPO' anywhere" gap) — corrected the row
honestly rather than deleting it, matching this doc's existing pattern for gaps closed
elsewhere in the file. No manifest/code change — CHARTER.md plus one doc line only, so
no README/`docs/dependency-tree.md` drift is expected. `make ci` passes.

## PR

https://github.com/tooming/k8s-anywhere/pull/1060
