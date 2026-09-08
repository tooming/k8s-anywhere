# Add the "truly start over" clean-slate warning `docs/incident-log.md`'s 2026-09-06 k3s-datastore-persistence entry already recommended but never landed

Found live 2026-09-08 (planner gap analysis, different lens: a scan of
`docs/incident-log.md`'s own "Follow-up" column for a recommendation
flagged-but-not-yet-actioned, rather than the removed-component-rationale
class this run's other items addressed): `docs/DR.md`'s "What is NOT
preserved on a rebuild" section didn't warn that a bare `colima delete`
does NOT wipe Colima's container-runtime data (including the k3s embedded
datastore), so a session reaching for it expecting a genuine clean slate
silently keeps hours/days of stale state instead.

The 2026-09-06 P0 incident row's Follow-up column read: "**Recommend**:
`docs/DR.md`'s rebuild guidance ... reached for a bare `colima delete`
expecting a true clean slate and didn't get one. Worth a follow-up doc
note in DR.md's 'Full rebuild' section spelling out that `colima delete
--data` (not bare `colima delete`) is what 'truly start over' actually
requires — flagged here rather than done, since this session is focused on
#633 itself." Verified this was never actioned: `grep -n "colima delete"
docs/DR.md` returned zero hits before this fix. Confirmed the `Makefile`
has no `colima-delete` target at all — this is purely a live-session manual
command, so this was a docs-only gap, no Makefile/script change needed.

## What was done

Added a paragraph to `docs/DR.md`'s "What is NOT preserved on a rebuild"
section explaining:
- `make down`/`colima stop` is the normal stop/start cycle — Colima's
  container-runtime data is correctly kept, matching `make down`'s own doc
  comment ("Data on PVCs/volumes is kept").
- `colima delete` alone tears down only the Lima VM itself and
  **deliberately preserves** that same container-runtime data across VM
  recreation — a `make up` afterward silently resumes from the old state.
- Cited the incident-log row directly (the 90MB `state.db` immediately
  after a supposedly-fresh bootstrap, hours old, that turned out to be the
  actual root cause).
- **To genuinely start over**: `colima delete --data` (or `colima delete -f
  --data` to skip the confirmation prompt), not a bare `colima delete`.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green), confirming no mechanical
assertion regressed (none existed against DR.md's prose shape here, per
the ROADMAP item's own scope note).

## PR

[#1526](https://github.com/tooming/k8s-anywhere/pull/1526) (autonomous
scheduled executor run, cycle 13: item picked directly from the
freshly-refilled "Now / next" lane after cycle 12's `plan/*` PR #1525).
