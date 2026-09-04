# Fix dependency-register.md Scope-note arithmetic drift + add a mechanical guard

(CHARTER **Core Values** §"Docs & dashboards don't drift"; JANITOR-fallback
bounded cleanup 2026-08-24, seventh cycle of this run, reached via
`executor.prompt.md` STEP 6b after cycle 6's fresh-angle sweep (GitHub Actions
pins, CI tool pins, ROADMAP filler section) came back clean and was recorded
honestly as `[Action needed]` (PR #1303). This cycle tried yet another angle:
`docs/dependency-register.md`'s own summary prose, rather than its per-row
content again. **No prerequisites — executor may pick up immediately.**)

## What was found

`docs/dependency-register.md`'s "Scope note" section states hand-maintained
summary arithmetic — "Of the 35 ADRs indexed... 32 distinct third-party-tool
rows" — that is derived prose, not mechanically computed. Verified directly
against reality: `docs/decisions/` actually has **36** `adr-*.md` files
(ADR-0036, External Secrets Operator, added 2026-08-19 — 5 days before this
check), and the table actually has **33** data rows, not 32. The Scope note's
arithmetic was never updated when ADR-0036 landed its own row.

The same stale "32" figure was independently repeated in two other files
(`docs/dependency-concentration.md`, `docs/dora-audit-readiness.md` — twice)
— all now corrected to 33. `dora-audit-readiness.md`'s companion "32 tools
across 24 ADRs" figure was also re-derived directly (a real count of distinct
ADR numbers cited in the register's ADR column across all 33 rows) to **27**,
not left inconsistent alongside the corrected row count.

## What changed

- `docs/dependency-register.md`: Scope note's ADR-total (35→36) and
  distinct-row-total (32→33) corrected, plus the intermediate "remaining"
  counts in its own arithmetic chain (33→34, 25→26). Added an explicit
  sentence naming ADR-0036/External Secrets Operator's 2026-08-19 row
  addition, mirroring how the existing text already narrates ADR-0035's.
- `docs/dependency-concentration.md`, `docs/dora-audit-readiness.md`: the
  three repeated "32 tools" citations corrected to 33 (and "24 ADRs"
  corrected to 27, independently re-derived and verified).
- **New mechanical guard**: extended `scripts/dependency-register-check.sh`
  with a second, independent check — verifies the Scope note's own stated
  ADR-total and row-total against a real `find docs/decisions/ -name
  'adr-*.md'` count and a real table-row count. Two new fixture pairs
  (`scope-note-in-sync/`, `scope-note-drift/`) + 2 new bats tests. Does
  **not** mechanically check the two downstream files (dependency-concentration.md,
  dora-audit-readiness.md) that repeat the same figure — noted as an honest
  remaining gap in the script's own header comment, not overclaimed.

## Verification

`bats tests/drift-adr-sync-checks.bats` — 31/31 pass (2 new). `make ci`
green. `scripts/dependency-register-check.sh` reports clean against the real
repo on both its checks.

## PR

https://github.com/tooming/k8s-anywhere/pull/1304
