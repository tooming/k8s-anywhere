# Planner run 2026-07-06 — O2 coverage-guard items + stale clock-note fix

## Context

Executor run found the "Now / next" lane starved:
- Items 1–4 blocked on maintainer confirmation (O4 cosign CI, Harbor footprint gate).
- Items 5–7 (TiDB dashboard, O2 PSS bats, O2 NP bats) already covered by open PRs
  (#332, #335, #336).

No open intake issues; no incoming architect items in `docs/roadmap/incoming/`.

## What this run did

### Stale O2 clock note fixed
The preamble O2 clock note said "remaining always-on gaps are: PSS for `argocd`
and NP for `envoy-gateway-system`." Both are now `[x]` checked. Note updated to
reflect current state: those gaps are closed; the remaining O2 work is the two
coverage-loop guards added below.

### Three new 🟢 items added to "Now / next"

1. **`docs/00-architecture.md` — Harbor registry update**
   (`auto/architecture-doc-harbor-update`) — The architecture doc still cites
   Artifactory with an ADR-0011 reference; ADR-0024 (Harbor, 2026-06-30) supersedes
   it. Three targeted edits: update the Heavy/on-demand table row, the capstone
   pipeline section, and correct any ADR-0011 mentions to ADR-0024. Docs-only, 🟢.

2. **O2 NP per-scope coverage loop bats** (`auto/o2-np-coverage-loop`) — A new
   `@test` in `tests/networkpolicy.bats` that loops over every
   `gitops/*/networkpolicy/kustomization.yaml` and asserts a matching
   `tests/networkpolicy-<ns>.bats` exists. Prevents O2 regression when new namespaces
   are added. Mirrors the `zz-dns-clusterip-bridge` presence loop. 🟢.

3. **O2 PSS per-scope coverage loop bats** (`auto/o2-pss-coverage-loop`) — A new
   `@test` in `tests/drift-detectors.bats` that loops over all PSA-labelled
   `namespace.yaml` files in `gitops/` and asserts coverage exists in either the
   monolith or a per-scope file. The O2 PSS completeness gate. 🟢.

## What needs human action

- **O4 cosign CI confirmation**: `auto/cosign-enforce-flip` can only proceed once the
  maintainer confirms at least one CI run has pushed a `.sig` tag to Artifactory.
  Without this confirmation, O4 (every image signed + verified) is blocked.

- **Harbor footprint gate**: `auto/harbor-capstone-rewire` and
  `auto/harbor-artifactory-decommission` are blocked until the maintainer confirms
  on issue #297 that Harbor's on-demand footprint was measured on the live cluster
  and fits within the 12 GB budget.

- **CHARTER.md update**: `CHARTER.md` §"Target end-state" still says "Artifactory or
  Nexus" — ADR-0024 supersedes this. A human should update CHARTER.md to read
  "Harbor" since CHARTER.md is 🔴 (humans only per WAYS-OF-WORKING.md §2).
