# De-duplicate `dependency-register-check.sh`'s row-parsing logic into the shared lib

`scripts/lib/dependency-register.sh` (extracted 2026-09-02, its own header comment
says "before, not after, a third copy could appear") stops
`dependency-maintenance-check.sh` and `dependency-concentration-sync-check.sh` from
each hand-rolling the same `docs/dependency-register.md` row-walking logic. But
`scripts/dependency-register-check.sh` — which predates that extraction — still had
its own independent, hand-rolled copy of exactly that same row-walking pattern
(parse the pipe-delimited table, skip the header, trim fields), just extracting a
different column set (the ADR and Last-reviewed columns, not the Upstream-source
column `depreg_rows()` returns). Exactly the "two near-identical copies of a parser"
class CLAUDE.md's de-duplication principle exists to catch, and exactly the gap
`tests/dependency-register-lib.bats`'s own "sources this shared lib" test was
supposed to guard against but didn't check this third script.

## What changed

- `scripts/lib/dependency-register.sh`: added `depreg_full_rows()`, a sibling to
  the existing `depreg_rows()` — prints `<tool>\t<adr_column>\t<reviewed_column>`
  per real table row (matching `dependency-register-check.sh`'s original
  `^\| [A-Za-z0-9]` row-start test and header-skip convention, mirroring
  `depreg_rows()`'s own `t != "Tool"` guard).
- `scripts/dependency-register-check.sh`: sources the lib; replaced its inlined
  `grep | while ... awk` row-walker with a `while IFS=$'\t' read -r ... done < <(depreg_full_rows "$REGISTER")` loop.
- `tests/dependency-register-lib.bats`: added a `depreg_full_rows()` unit test and
  extended the "sources this shared lib" test to also cover
  `dependency-register-check.sh`.

## Verification (behavior-preserving, not just structurally similar)

Since `bats` isn't installed in this clusterless session, ran the refactored script
directly against all 8 existing fixture scenarios in
`tests/fixtures/dependency-register-check/` (`in-sync`, `drift`,
`shared-adr-no-false-positive`, `no-reeval-log`, `bold-entry-drift`,
`bold-entry-no-false-positive`, `scope-note-in-sync`, `scope-note-drift`) — every
one produced the exact same exit code (0 for in-sync/no-false-positive cases, 1 for
drift cases) as before the refactor, and the real `docs/dependency-register.md`
still passes cleanly. `make ci` green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1389
