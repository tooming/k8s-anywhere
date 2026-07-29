# Decommission Artifactory manifests

(RFC #297 / ADR-0024 — architect decision 2026-06-30; **maintainer-confirmation
prerequisite: pick up ONLY after `auto/harbor-capstone-rewire` merges AND the
maintainer has confirmed the Harbor footprint gate on #297; skip if not
verifiable this run**). Remove `gitops/platform/artifactory.yaml`,
`gitops/platform/artifactory-extras.yaml`, the entire `gitops/artifactory/`
tree (namespace, route, networkpolicy), the `make artifactory-up`/`artifactory-down`
targets, the `artifactory-networkpolicy` entry in
`gitops/platform/networkpolicy-appset.yaml`, the `artifactory` row in ADR-0017's
profile table, the `artifactory` LimitRange entry in the governance appset /
`gitops/governance/`, the artifactory nodes/edges in `docs/dependency-tree.md`,
the now-superseded `gitops/secrets/artifactory-registry-externalsecret.yaml`,
and the artifactory rows in README. Add a recurrence guard — extend
`tests/harbor.bats` (or a dedicated `tests/no-artifactory.bats`) asserting no
`artifactory` ArgoCD Application / route / make-target / appset entry remains
(a `grep -r artifactory gitops/ Makefile` guard allowing only historical
`docs/done/` + ADR-0011/0024 mentions). `make ci` must pass. `docs/done/` entry
required. **Closes #297** — the migration's final slice; close the issue once
this lands and the footprint gate is on record. (auto/harbor-artifactory-decommission)

## What shipped

Both gate conditions were verified before picking this up: `auto/harbor-capstone-rewire`
merged as PR #885, and the Harbor footprint gate was confirmed on issue #632
(the standing tracking issue for the same ADR-0024 go/no-go gate #297's own
acceptance criteria name) — Harbor's minimal profile measures ~73m CPU /
~595Mi memory standalone, ~6.6GB/12GB cluster-wide.

Removed entirely:
- `gitops/platform/artifactory.yaml`, `gitops/platform/artifactory-extras.yaml`
- `gitops/artifactory/` (namespace, route, networkpolicy tree — 5 files)
- `gitops/secrets/artifactory-registry-externalsecret.yaml`
- The legacy-registry entry in `gitops/platform/networkpolicy-appset.yaml`
- `make artifactory-up` / `make artifactory-down` Makefile targets
- The legacy-registry row in ADR-0017's per-namespace PSA profile table (a
  dated closing entry was added to its Re-evaluation log documenting why the
  row was removed rather than kept)
- The legacy-registry rows/prose in README.md (stack table, URL table, "16 GB
  reality" section) and `docs/dependency-tree.md` (mermaid subgraph + edge,
  two appset-table rows, one edge-table row, two prose bullets)
- `secret/artifactory/registry` Vault seeding in `scripts/vault-bootstrap.sh`
  (orphaned once its ExternalSecret was gone)
- Three now-obsolete `tests/*.bats` files/blocks (`tests/networkpolicy-artifactory.bats`,
  `tests/securitycontext-artifactory.bats`, plus the legacy-registry-specific
  `@test`s in `tests/capstone.bats` and `tests/platform.bats`)

Fixed in passing (stale references to the pre-Harbor-cutover state that
`auto/harbor-capstone-rewire` missed, discovered by re-running `make ci`
locally with the correct toolchain installed):
- Two stale comments (`gitops/platform/kargo-networkpolicy.yaml`,
  `gitops/platform/capstone.yaml`) and one Dockerfile comment
  (`gitops/apps/demo/Dockerfile`) still said "Artifactory" — updated to Harbor.
- `scripts/lab-health-check.sh`'s `ONDEMAND_NS` list still carried the legacy
  registry namespace alongside a comment explicitly staged for this exact
  removal ("appended on its own line ... so the outgoing on-demand registry
  entry, which stays until its manifests are decommissioned, is left
  untouched") — merged Harbor into the base list and dropped the legacy entry.
- `grafana/dashboards/stack-health.json`'s "Lab UIs" panel still listed the
  legacy registry's URL row (`make lab-ui-check` caught this as a stale-row
  drift once the HTTPRoute was gone) — removed.
- `grafana/dashboards/lab-capstone.json`'s markdown panel still described the
  pipeline pushing to "the in-lab Artifactory registry" with the old
  `docker-local/hello` path and `artifactory-registry` secret name — updated
  to Harbor's `library/hello` path and `harbor-registry` secret name
  (ADR-0004: a dashboard's own prose must reflect what's actually running).
- `scripts/readme-check.sh` gained a narrow exception: a **Superseded by**
  ADR's historical decision text (ADR-0011 explicitly says its original
  reasoning is "kept below for the historical record") is allowed to keep
  `make artifactory-*` mentions describing what was true when written, rather
  than being flagged as live-doc drift. This is a real, intentional gap in the
  original check (it never encountered a superseded ADR whose named `make`
  targets were later actually removed) — mechanically necessary once the
  targets it documents no longer exist, otherwise no superseded ADR could ever
  again cite its own historical bootstrap machinery without permanently
  failing `make readme-check`.

New `tests/no-artifactory.bats` — six assertions: no legacy-registry mention
survives under `gitops/` (any file) or in the `Makefile`; the `gitops/artifactory/`
tree, its two platform Applications, and its ExternalSecret are all gone; the
networkpolicy appset no longer lists it. Scoped deliberately to `gitops/` +
`Makefile` only (not `docs/decisions/` or `docs/done/`), matching this item's
own guard spec — those two locations are permanent, intentional historical
record (ADR-0011/0024, and this very file), not drift.

**Toolchain note:** this session's sandbox shipped the Python/jq-based `yq`,
not mikefarah's Go `yq` several existing bats tests require (`tag`,
`eval-all`, etc.) — installing the correct binary surfaced and let this run
fix two real, pre-existing gaps above (the stale dashboard prose and the
`lab-health-check.sh` `ONDEMAND_NS` cleanup) that a partial local run with the
wrong `yq` would have silently missed. Full local verification: `shellcheck -S
warning scripts/*.sh` clean; `yamllint` clean (same pre-existing unrelated
`infra/modules/oracle-k3s-cluster/cloud-init.yaml` warning as every other
recent run); `kustomize build` clean across every `networkpolicy`/`governance`
overlay (no `gitops/artifactory/networkpolicy` left to build); `kubeconform`
schema validation clean (144 valid, 0 invalid, 0 errors); full bats suite
**2315/2315 green** (2344 minus the two deleted test files' worth of tests,
plus this item's six new ones, net of the removed per-item `@test`s).
`helm`-dependent drift checks (`helm-chart-pin-check.sh`, `argocd-crd-ssa-check.sh`)
gracefully skip locally (no `helm` binary) and run for real in GitHub Actions CI.

Closes #297.

## PR

(filled in once opened)
