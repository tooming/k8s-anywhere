# Fix stale 4-namespace Velero backup list in README.md / docs/00-architecture.md

PRs #874/#875 (2026-07-29) extended Velero's stateful-namespace scope from four
(`data`, `tidb`, `capstone`, `vault`) to six, adding `observability` and `inkless`
Schedules (CHARTER Objective O3's own scope was extended the same day after a gap
audit found both namespaces held real PVCs with no backup Schedule). The follow-up
fix (`docs/done/2026-07-29-dr-restore-observability-inkless.md`) updated
`scripts/dr-restore.sh`, the `Makefile`'s `dr-restore` target, `tests/dr-restore.bats`,
`docs/decisions/adr-0021-velero-backup-restore.md`, and `docs/DR.md` to the six-
namespace scope — but missed two other docs that also enumerate this list:
`docs/00-architecture.md` (two occurrences: the Velero tools-table row, and the
"Stateful backup & restore" Goals-sequence bullet) and `README.md`'s stack table
"Backup & restore" row. All three still said "data, tidb, capstone, and vault" only.

Ground truth confirmed directly: `gitops/velero/schedules/` has six Schedule
manifests (`data-daily.yaml`, `tidb-daily.yaml`, `capstone-daily.yaml`,
`vault-daily.yaml`, `observability-daily.yaml`, `inkless-daily.yaml`), matching
`docs/DR.md`'s and ADR-0021's already-correct six-namespace phrasing.

## Fix

Updated all three stale lines to name `observability` and `inkless` alongside the
original four, mirroring the phrasing `docs/DR.md`/ADR-0021 already use. No topology
change — the Schedules themselves already existed; this is pure doc reconciliation
(mirrors the doc-drift-author role's mechanical-reconciliation-only mandate:
`README.md` and `docs/00-architecture.md` are both in its allowed-file set).

`make ci` passes (2345 assertions, 0 failures — `readme-check`/`markdown-links-check`
both confirmed clean).

## PR

(filled in after PR creation)
