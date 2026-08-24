# Extend dependency-register-check.sh to cover one ADR-0034 bold-entry shape

(CHARTER **Core Values** §"Docs & dashboards don't drift"; JANITOR-fallback
bounded cleanup 2026-08-24, fifth cycle of this run, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed
fully gated and this run's PLANNER/ARCHITECT/JANITOR fallback passes each
already produced their own real deliverable this run (PR #1297, #1298,
#1299, #1301) with nothing further to groom, decide, or bump. **No
prerequisites — executor may pick up immediately.**)

## What was found

`scripts/dependency-register-check.sh` (PR #1297, this run's first cycle)
shipped with an honestly-documented limitation: it only recognized the
`### YYYY-MM-DD` dated-heading Re-evaluation log convention, not ADR-0034's
`**YYYY-MM-DD**` bold-text entries — leaving 7 register rows (Mimir, Loki,
Tempo, Pyroscope, Alloy, kube-state-metrics, node-exporter) with zero
mechanical date-freshness coverage. Re-examined this cycle: 3 of those 7
(kube-state-metrics, Mimir, Pyroscope) DO have real, dated ADR-0034 entries
in a consistent, parseable shape (`**YYYY-MM-DD** — <Component> chart bumped
...` / `... image tag bumped ...`) — closing that slice was both real and
safely scoped.

The other 4 remain genuinely out of reach for now: Alloy/node-exporter have
no logged ADR-0034 entry at all (their currency sweeps happened but were
never written to the ADR's own Re-evaluation log — a real, separate gap this
script correctly can't paper over by inventing an entry), and Loki/Tempo's
actual currency history lives in ADR-0006 (cited only in the register's own
prose, never in the ADR column, by this file's own established design).

## The false-positive trap (why this needed care, not a blind regex)

A naive "take the newest bold-date entry anywhere in the ADR that mentions
the component's name" reading would have false-flagged Tempo: ADR-0034 has a
`**2026-08-18** — table-row correction (Tempo): ...` entry that names Tempo
but is a doc-formatting fix, not a new currency check (Tempo's real last
check is a 2026-08-13 entry in ADR-0006). Required the exact
`<Component> (chart|image tag) bumped` phrasing immediately after the date
before treating an entry as a real re-evaluation — verified against a
dedicated regression fixture reproducing that exact shape before trusting the
extension.

## What changed

- `scripts/dependency-register-check.sh`: added `latest_bold_component_date()`
  and wired it alongside the existing `latest_reeval_date()` — takes the
  newer of the two per cited ADR. Header comment rewritten to describe both
  shapes and their honest remaining gaps.
- Two new fixture pairs
  (`tests/fixtures/dependency-register-check/bold-entry-drift/`,
  `.../bold-entry-no-false-positive/`) + 2 new bats tests in
  `tests/drift-adr-sync-checks.bats` proving both the positive (catches a
  real bold-entry drift) and negative (doesn't false-flag the Tempo-shaped
  mention-without-a-bump) cases.
- `docs/dora-audit-readiness.md`'s Q14 Gap line updated to describe the
  narrower, now-accurate remaining limitation (3/7 covered, not 0/7) and to
  mention the PostToolUse hook (PR #1301) it hadn't yet reflected.

## Verification

`bats tests/drift-adr-sync-checks.bats` — all pass (29 tests, 2 new).
`make ci` green. `scripts/dependency-register-check.sh` still reports clean
against the real repo (no new drift surfaced — kube-state-metrics/Mimir/
Pyroscope's register dates already matched their real ADR-0034 history, this
just makes that fact mechanically enforced going forward).

## PR

chore/dependency-register-check-adr-0034-bold-entry
