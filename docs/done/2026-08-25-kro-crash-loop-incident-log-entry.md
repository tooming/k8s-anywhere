# docs: log the kro chronic crash-loop as a real incident (DORA Pillar 2)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — found while continuing to audit PR #1300's fallout (this same
run's prior two cycles: #1311 doc-drift, #1312 the `keda-governance`
dead-config removal). This run's "Now / next" lane remained fully gated
(unchanged: the two GitLab→Forgejo migration items and the capstone
`Deployment` removal, still gated on issue #633 — re-checked, no new
comment) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER
fallback passes found nothing new this cycle either. **No prerequisites —
executor may pick up immediately.**

## The gap

PR #1300's own commit message documented a real, previously-undocumented
incident: kro's controller had been chronically crash-looping (216+ restarts
over 13 days) with `failed to wait for ResourceGraphDefinition caches to
sync` — a downstream symptom of this host's apiserver being too slow to
satisfy kro's own informer-sync startup timeout, and each crash-restart's
fresh full-cache resync was itself contributing to the same apiserver/
datastore write pressure documented in `docs/incident-log.md`'s 2026-08-11
and 2026-08-17 P0 rows. This is exactly the kind of "what broke, in
production-shape terms, and why" record `docs/incident-log.md` exists to
capture (per its own header, closing DORA's Pillar 2 Q6/Q8 gap) — but it had
never been added there, only mentioned inline in a commit message and
ADR-0029's Re-evaluation log.

## The fix

Added a new row to `docs/incident-log.md`'s "Real incident history" table
following the file's own established shape exactly (Date / Severity /
Component(s) / Detection / Root cause / Fix / Time to resolve / Follow-up),
classified **P1** per the severity scheme's own mechanical definition ("a
single always-on component is down or degraded" — kro was always-on at the
time and was, in fact, down/crash-looping). Cross-references PR #1300 (the
fix — suspend + scale to 0) and the two prior P0 datastore-pressure rows
(the shared root-cause chain this incident's own restarts fed into). Added
a matching bats coverage test (`tests/incident-log.bats`) mirroring the
existing `#631`/`#633` backfill-coverage test's pattern, asserting the new
row's key facts (`kro`, `#1300`, the exact error string) are present —
a recurrence guard against this same gap (a real incident documented only
in a commit message, never in the incident log) recurring silently.

`make ci`: green (full local run including real `bats`, installed earlier
this run; the new test passes alongside the existing 9 in
`tests/incident-log.bats` and the full 2866+-test suite).

## PR

https://github.com/tooming/k8s-anywhere/pull/1313
