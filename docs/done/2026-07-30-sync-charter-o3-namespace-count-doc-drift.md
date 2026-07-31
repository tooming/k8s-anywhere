# Fix stale 4-namespace stateful-DR claims in CHARTER.md + docs/dora-audit-readiness.md

CHARTER Objective O3's scope was extended from four stateful namespaces to six
(adding `observability` and `inkless`) on 2026-07-29 after a gap audit found both
held real PVCs with no Velero Schedule (see `docs/done/2026-07-29-dr-restore-
observability-inkless.md`). CHARTER.md's own **Objective O3** section was updated
correctly at the time — but its **Core Values** section (three sections earlier in
the same file) was not: it still said "Every stateful namespace (`data`, `tidb`,
`capstone`, `vault`) has a Velero schedule..." — an internal inconsistency within
CHARTER.md itself, not just a doc lagging behind code.

`docs/dora-audit-readiness.md` (Q2, ICT-critical-asset mapping) separately cited
"CHARTER Objective O3 names the four stateful namespaces (`data`, `tidb`, `capstone`,
`vault`) as critical" — quoting O3's OWN scope inaccurately, since O3 itself has said
six namespaces since 2026-07-29.

Ground truth (already verified in two prior fixes this run, PRs #929/#930):
`gitops/velero/schedules/` has six Schedule manifests; `scripts/dr-restore.sh`,
`tests/dr-restore.bats`, `docs/decisions/adr-0021-velero-backup-restore.md`, and
`docs/DR.md` all correctly say six.

## Fix

- `CHARTER.md`'s Core Values "Stateful DR is exercised" bullet now lists all six
  namespaces, matching its own Objective O3 section three sections later.
- `docs/dora-audit-readiness.md`'s Q2 answer now says "six" and names
  `observability`/`inkless` alongside the original four.

No topology/decision change — pure doc reconciliation. Third fix in this run's
"cross-check a recent multi-file change against every doc that describes it" sweep
(after the Velero namespace-list fix in README.md/docs/00-architecture.md, PR #929,
and the Kyverno replica-count fix in ADR-0019/docs/dependency-tree.md, PR #930).

`make ci` passes (2345 assertions, 0 failures).

## PR

https://github.com/tooming/k8s-anywhere/pull/932
