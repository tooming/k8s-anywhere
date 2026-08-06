# Reconcile `docs/dependency-register.md` with ADR-0031/ADR-0032 + today's Loki bump

Fourth cycle of this run. Now/next's three 🟢 items remain gated on unconfirmed
maintainer-confirmation issues #631/#633 (re-checked this cycle, unchanged).
PLANNER/ARCHITECT fallback passes earlier this run (#1032) found nothing further
to groom or audit; #1033/#1035 covered this cycle's currency-sweep and
incident-log angles. This cycle's angle: `docs/dependency-register.md`'s own
"Scope note" cites an ADR count ("Of the 30 ADRs indexed... ADR-0001–ADR-0030")
that this same run's own first cycle (#1032, which authored ADR-0032) made stale —
the repo now has 32 ADRs, and two of the new ones (ADR-0031 TiDB Operator,
ADR-0032 TiDB) name real third-party products with no row in the register's table.

## What was found

Verified directly (`ls docs/decisions/adr-*.md | wc -l` and
`docs/decisions/README.md`'s own index): 32 ADRs exist, not 30. ADR-0031 and
ADR-0032 each decide on a single third-party product (TiDB Operator, TiDB itself)
— genuinely new tools, not covered by any existing row (checked directly: neither
"TiDB" nor "tidb-operator" appears anywhere in the table). Also, the Grafana row's
"Last reviewed" date (`2026-07-28`) was superseded by this run's own second cycle
(#1033), which added a new 2026-08-06 dated entry to ADR-0006's re-evaluation log
for the Loki security-fix bump.

## What changed

- `docs/dependency-register.md`'s Scope note: `30`→`32` ADRs, `28`→`30` remaining
  after superseded exclusions, `20`→`22` remaining after policy exclusions,
  `22`→`24` distinct tools — with a note on why TiDB Operator/TiDB get separate
  rows (same shape as the existing Istio/Kiali precedent under one shared ADR).
- Two new table rows: **TiDB Operator** (ADR-0031) and **TiDB** (ADR-0032), both
  `heavy-on-demand`, citing the real `make tidb-up`/`tidb-down` targets and the
  new ADRs' own dated entries.
- Grafana row's "Last reviewed" updated to cite the 2026-08-06 Loki bump (the ADR
  it points to — ADR-0006 — covers Grafana/Loki/Tempo together, and Loki's entry is
  now the most recent).
- "Keeping this in sync" section's snapshot date: `2026-08-04`→`2026-08-06`.

Behavior-preserving: pure re-indexing of content that already exists in
`docs/decisions/` (per this file's own stated purpose — "no new dependency-risk
judgment was made in producing this file," a rule this update honors, same as the
original). `make ci` stays green on the same set of checks (row-count assertion
still `>= 20`, now `25` including the header).

`docs/decisions/adr-0004-no-fabricated-content.md` compliance: every number and
date cited is verified directly against the real ADR count and content, not
assumed or carried forward from the original file's snapshot.

(chore/dependency-register-adr-count-tidb-sync)

## PR

<!-- filled in after PR creation -->
