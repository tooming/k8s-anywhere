# Fix post-2026-09-06-removal-wave stale content in docs/platform-products.md and docs/dependency-concentration.md

JANITOR-fallback cleanup (executor STEP 6b), third distinct finding this
cycle after PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER all
came up empty on this cycle's earlier passes (which already produced #1486
and #1487). A different lens this time: cross-checking every doc/script
mention of TiDB/Istio+Kiali/Longhorn/RabbitMQ/Valkey/KEDA against
`docs/00-architecture.md`, `CHARTER.md`, and `docs/dependency-tree.md` (all
three already correctly document the 2026-09-06 removal wave) to find any
doc the cleanup missed.

## What was found

`docs/platform-products.md` and `docs/dependency-concentration.md` were both
missed by the 2026-09-06 removal-wave cleanup and every subsequent sweep this
run — unlike `docs/00-architecture.md`, `CHARTER.md`, and
`docs/dependency-tree.md`, which all correctly frame TiDB/Istio ambient mesh +
Kiali/Longhorn as "built and demonstrated, then removed 2026-09-06, no
replacement."

**`docs/platform-products.md`** presented all three removed components as
currently-built, working products:
- The Tier-5 "Heavy add-ons" Mermaid diagram node and its table row both
  listed `TiDB, Harbor, Istio mesh, Longhorn` as "all four ... built", with
  no mention that Kargo (the platform's actual second heavy component,
  already correctly listed in `00-architecture.md`'s own "On-demand (heavy)"
  section) exists at all.
- The Product catalog's "Service mesh (east-west)" row described
  `make istio-up` as a working 🟡 on-demand product.
- The Product catalog's "Relational database" (`make tidb-up`) and "Block
  storage / PVs" (`make longhorn-up`) rows described both as working.
- The team-org table's Data & storage row listed `Garage, (Longhorn/TiDB/
  Harbor)`.
- Two "16 GB reality" capacity mentions were stale — `00-architecture.md`
  (the authoritative source) states the real budget is a **12 GB** Colima VM.

**`docs/dependency-concentration.md`**'s "Every other row is a distinct org"
paragraph still listed RabbitMQ, Valkey, KEDA, kube-state-metrics, and
node-exporter — all five removed from `docs/dependency-register.md` entirely
(RabbitMQ/Valkey/KEDA: ADR-0009/ADR-0018/ADR-0029, 2026-08-25/2026-09-06;
kube-state-metrics/node-exporter: ADR-0041, 2026-09-06) — while separately
omitting six rows added since the paragraph was last touched (External
Secrets Operator, Vault, moto, ACK S3 controller, KRO, s3manager). The file's
own "26 of 29 total rows" count was stale too — the register now has 21 rows,
18 GitHub-hosted.

The existing `dependency-concentration-sync-check.sh` mechanical guard did
**not** catch this: it only validates the count for orgs backing 2+ rows
(e.g. confirming `github.com/argoproj` correctly says "2 tools"), not the
free-text "every other row is a distinct org" enumeration of single-row orgs
or the file's own summary counts — a real, pre-existing gap in that guard's
coverage, noted here rather than silently left uncovered (this cleanup does
not attempt to close that gap mechanically; the free-text enumeration is
prose, not a structured count a script can easily validate without becoming
its own maintenance burden — flagging honestly per CLAUDE.md rather than
claiming a guard this PR doesn't add).

A companion, much smaller instance of the same drift class: a bats test
title in `tests/dependency-exit-runbooks-sync-check.bats` still said "all 32
register rows" (stale — the register has 21 now); the test body itself
doesn't assert a row count, so this was cosmetic, but fixed for accuracy
while already in this exact area.

## What was fixed

- `docs/platform-products.md`: Tier-5 diagram + table now say `Harbor,
  Kargo` (matching `00-architecture.md`'s own heavy-component list) with a
  historical note on the three removed components; the Service
  mesh/Relational database/Block storage product rows converted to
  parenthetical "was built, then removed 2026-09-06" notes, mirroring the
  file's own existing Observability-retirement pattern (section E); the
  team-org table's Data & storage and Connectivity rows corrected; both "16
  GB" mentions corrected to "12 GB".
- `docs/dependency-concentration.md`: the row-count summary corrected to
  "18 GitHub-hosted ... of 21 total"; the single-org enumeration paragraph
  rewritten to list the register's actual current 16 single-row GitHub orgs
  (adding the 6 missing rows), with an explicit note on which five tools
  were removed and why.
- `tests/dependency-exit-runbooks-sync-check.bats`: test title's stale "32"
  corrected to "21".

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — every count in this PR
(21 total register rows, 18 GitHub-hosted, 16 single-org rows) was verified
by directly counting `docs/dependency-register.md`'s real table rows and
their "Upstream source" column values in this session, not assumed or
carried over from the stale text being corrected.

## PR

https://github.com/tooming/k8s-anywhere/pull/1489 (chore/platform-products-post-removal-wave-drift-fix)
