# Extend `make dr-restore` to cover `observability` and `inkless` (Objective O3 gap)

CHARTER **Objective O3** ("Stateful DR is exercised") was updated on 2026-07-29
to add `observability` and `inkless` to its stateful-namespace scope, after a
gap audit found both held real PVCs with no Velero Schedule (PR #874 added
`observability-daily`, PR #875 added `inkless-daily`, and both updated
ADR-0021's own "Scope & exceptions" section to declare all six namespaces —
`data`, `tidb`, `capstone`, `vault`, `observability`, `inkless` — in scope).
Neither of those PRs, however, touched the *restore* side: `scripts/dr-restore.sh`'s default
namespace list, the `make dr-restore` Makefile target's invocation, and
`tests/dr-restore.bats`'s coverage were all left hardcoded at the original
four namespaces (`data tidb capstone vault`) — a real, previously-undetected
drift between the backup schedules that now exist and the restore path
CHARTER O3 is actually measured by (`make dr-restore` under the 10-minute
budget), plus a stale code sample in ADR-0021 itself (§"`make dr-restore`
target") and in `docs/DR.md` that still showed the old four-namespace
invocation.

## What changed

- `scripts/dr-restore.sh` — default `NAMESPACES` array extended from
  `data tidb capstone vault` to `data tidb capstone vault observability
  inkless`; usage comment and default-list comment updated to match.
- `Makefile`'s `dr-restore` target — invocation extended to pass all six
  namespaces.
- `tests/dr-restore.bats` — added `observability` and `inkless` restore-line
  assertions (mirroring the four existing ones) and a new assertion that the
  `Makefile` `dr-restore` target's invocation line names all six namespaces,
  as a recurrence guard for this exact class of drift (backup-side scope
  updated without a matching restore-side update).
- `docs/decisions/adr-0021-velero-backup-restore.md` — updated the
  `make dr-restore` target code sample to the six-namespace invocation and
  noted when/why the list was extended.
- `docs/DR.md` — updated the namespace list, the Schedule table (added
  `observability`/`inkless` rows), and the "four namespaces" prose
  (restore-count references) to match the current six-namespace scope.

No cluster access was used or required — this is a clusterless, structural
fix (the namespace list is a plain bash array; `scripts/dr-restore.sh` is
excluded from `make ci`'s execution path by design since it needs a live
cluster, per ADR-0021, but its *structure* is covered by `tests/dr-restore.bats`,
which now asserts the six-namespace default). `make ci` passes.

## PR

https://github.com/tooming/k8s-anywhere/pull/883
