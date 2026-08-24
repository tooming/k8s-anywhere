# dependency-register.md k3s drift fix + a mechanical recurrence guard

(CHARTER **Core Values** §"Docs & dashboards don't drift"; JANITOR-fallback bounded
cleanup 2026-08-24, reached via `executor.prompt.md` STEP 6b after the "Now / next"
lane was found fully gated — all three unchecked items need live-cluster
verification or a maintainer confirmation this remote clusterless session cannot
provide (issue #633 still open, unconfirmed) — and a PLANNER-fallback gap-analysis
pass found no ungroomed issues, no `docs/roadmap/incoming/` files, and no un-RFC'd
🟡 items anywhere in ROADMAP.md. **No prerequisites — executor may pick up
immediately.**)

## What was found

`docs/dependency-register.md`'s k3s row cited only [ADR-0027](../decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md)
(the Oracle-backend-choice ADR, which has no Re-evaluation log) and reported "not
dated in ADR" — but k3s's actual version-currency governance lives in
[ADR-0030](../decisions/adr-0030-pin-k3s-version-explicitly.md), which has a real,
current Re-evaluation log (audits on 2026-07-28, 2026-08-05, and most recently
2026-08-20). The register's own "Keeping this in sync" section already named this
exact failure mode as a known risk ("nothing currently fails `make ci`" if a row's
date drifts from its ADR's own log) — and it had already recurred once before this
run (three rows fixed 2026-08-12, `docs/done/2026-08-12-dependency-register-log-drift-fix.md`).

Writing a small cross-reference script to check every row (not just k3s) turned up
two more real, independently-verified instances of the same bug:
- **Envoy Gateway**: register said `2026-08-07`; ADR-0008's own log has a newer
  `2026-08-18` entry (`v1.9.0` re-checked and deliberately kept at `v1.8.3` — real
  breaking changes, can't be verified from a clusterless session on this sync-wave-0
  ingress control plane).
- **Kyverno**: register said `2026-08-06`; ADR-0019's own log has a newer
  `2026-08-18` entry (the `disallow-latest-tag` `inkless` carve-out's flip condition
  was met and the exclusion removed, PR #1217).

Two other candidate flags (Loki, Tempo) were investigated and confirmed as **false
positives** from a naive whole-row scan picking up ADR-0006's Grafana-specific
newest entry (ADR-0006 is shared across Grafana/Loki/Tempo) — the check was
narrowed to scan only the ADR column, not the whole row, which eliminates that
class of false positive while still catching the three real findings above.

## What changed

- `docs/dependency-register.md`: fixed the k3s, Envoy Gateway, and Kyverno rows'
  "Last reviewed" cells to the real, verified dates and summaries; k3s's ADR column
  now cites both ADR-0027 and ADR-0030 (previously ADR-0030 was deliberately
  excluded from any row per the file's own Scope note — now cited directly in the
  k3s row it governs, with the Scope note's own prose updated to match).
- **New mechanical guard**: `scripts/dependency-register-check.sh` — cross-references
  every register row's "Last reviewed" date against the newest `### YYYY-MM-DD`
  Re-evaluation-log entry of every ADR cited in that row's ADR column. Self-maintaining
  (no hardcoded tool list). Documented, honest limitation: only recognizes the
  `### YYYY-MM-DD` heading convention (used by ADR-0006/0008/0019/0030 and most
  others), not ADR-0034's `**YYYY-MM-DD**` bold-entry convention — so Mimir/Loki/
  Tempo/Pyroscope/Alloy/KSM/node-exporter rows citing ADR-0034 alone are silently
  skipped, not silently passed (ADR-0004: not overclaiming coverage this script
  doesn't have).
- Wired into `make dependency-register-check` and `make ci` (Makefile), and into
  `.github/workflows/ci.yml`'s `drift` job (kept in parity, per CLAUDE.md).
- New `tests/fixtures/dependency-register-check/{in-sync,drift,shared-adr-no-false-positive,no-reeval-log}/`
  fixtures + coverage in `tests/drift-adr-sync-checks.bats` (5 new tests, including
  a dedicated regression test for the Loki/Tempo-shaped false-positive this script
  had to be narrowed to avoid).
- `tests/dependency-register.bats`: one new assertion pinning the k3s row's
  ADR-0030 citation specifically (content-correctness, complementary to the new
  script's date-freshness check).

## Verification

`make ci` green (bats, drift-detectors coverage, the new
`dependency-register-check` gate, and the pre-existing gates all pass). This is a
docs + tests + CI-script-only diff — no `gitops/`, `infra/`, or ADR *decision*
content changed, only two ADRs' already-recorded Re-evaluation log dates getting
correctly reflected in a downstream summary doc. Zero live-cluster blast radius.

## PR

chore/dependency-register-drift-fix-and-guard
