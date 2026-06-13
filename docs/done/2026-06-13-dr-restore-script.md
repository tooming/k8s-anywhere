# 2026-06-13 — make dr-restore + scripts/dr-restore.sh

**ROADMAP item:** `make dr-restore + scripts/dr-restore.sh — Objective O3 enabler`
**Branch:** `auto/dr-restore-script`
**PR:** (see PR opened by this run)

## What was delivered

- `scripts/dr-restore.sh` — iterates `velero restore create --from-schedule <ns>-daily --wait`
  for `data`, `tidb`, `capstone`, `vault`; times each restore; prints a summary table;
  fails with exit 1 if total wall-clock exceeds 600 s or any restore phase is not `Completed`.
- `Makefile` — new `dr-restore` target wiring the script (approved by RFC #155 acceptance
  criteria; architect's binding decision makes this 🟢 per WAYS-OF-WORKING.md §2).
- `tests/dr-restore.bats` — clusterless structural tests: script exists + executable, all four
  namespace restore lines present, `--from-schedule` + `--wait` flags declared, 600 s budget
  check implemented, Makefile target wired.
- `docs/DR.md` — new `## Velero backup restore (make dr-restore)` section documenting the
  target, the Schedule table, behaviour, and Velero prerequisite.

## Why

CHARTER Objective O3 requires `make dr-restore` to recover every stateful namespace from
its latest Velero backup in < 10 min. This PR ships the runner script and the Makefile
target that the maintainer invokes locally (the executor never calls `velero` itself —
clusterless rule). ADR-0021 §"dr-restore runner" is the binding spec.
