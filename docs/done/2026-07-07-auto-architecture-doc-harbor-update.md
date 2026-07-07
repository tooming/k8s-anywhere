# `docs/00-architecture.md` — Harbor registry update

**`docs/00-architecture.md` — Harbor registry update** (CHARTER **Core Values**
§"Docs & dashboards don't drift"; docs-only; **no prerequisites — executor may pick
up immediately**). The architecture doc was last fully rewritten in
`auto/architecture-doc-rewrite` (prior to ADR-0024). ADR-0024 (Harbor over
Artifactory, architect decision 2026-06-30) replaced ADR-0011, but the architecture
doc still cited Artifactory with an ADR-0011 reference and did not mention Harbor.
Three targeted edits (all three within `docs/00-architecture.md`):
(a) In the "Heavy / on-demand" table update the **Artifactory OSS** row to read
**Harbor** as the primary registry, citing ADR-0024; added a parenthetical noting
`gitops/platform/artifactory.yaml` remains pending the decommission item
(`auto/harbor-artifactory-decommission`) and the capstone re-wire
(`auto/harbor-capstone-rewire`).
(b) In the capstone pipeline section updated "push to Artifactory" text to reflect
that the target registry is Harbor (`make harbor-up`; `harbor.127.0.0.1.nip.io`)
per ADR-0024, noting the cutover is in progress.
(c) Corrected all remaining ADR-0011 mentions to ADR-0024.

## PR

#TBD
