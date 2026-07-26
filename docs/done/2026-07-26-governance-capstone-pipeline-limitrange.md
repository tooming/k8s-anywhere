# `capstone-pipeline` governance LimitRange — RFC #294 fan-out completion

(ROADMAP "Now / next" item, no prerequisites — picked up directly after the
parallel session's planner PR #751 added the gap to the backlog; reached via
`executor.prompt.md` STEP 3/4 after re-checking standing issues #631/#632/#633
were still unconfirmed and no other work was contended.)

A systematic cross-reference of every PSA-labeled namespace against
`gitops/platform/governance-appset.yaml`'s coverage list (the same technique
that previously found the dead `kiali-governance` cleanup and the
`tidb-admin-extras` doc gap) surfaced one remaining gap: `capstone-pipeline`
(the Kargo Project/Warehouse/Stage namespace, `gitops/kargo-project/namespace.yaml`)
is PSA `restricted` and not in either documented exclusion list (on-demand-heavy:
`tidb`/`tidb-admin`/`longhorn-system`/`istio-system`/`inkless`; ADR-0024:
`artifactory`), but had never gotten a standard-tier governance LimitRange leaf.

Verified directly (per ADR-0004) before implementing: `ls gitops/governance/`
showed no `capstone-pipeline` directory; `grep capstone-pipeline
gitops/platform/governance-appset.yaml` returned nothing; `tests/governance.bats`'s
`STANDARD_NS` list omitted it too — confirming this was a genuine, unclaimed gap,
not already in flight from the parallel session.

Changes, mirroring every other standard-tier leaf exactly:
- New `gitops/governance/capstone-pipeline/kustomization.yaml` (`resources:
  [../base/limitrange-standard.yaml]`, `namespace: capstone-pipeline`).
- New `capstone-pipeline-governance` entry in `governance-appset.yaml`'s list
  generator (`gitPath: gitops/governance/capstone-pipeline`, `destNamespace:
  capstone-pipeline`).
- `capstone-pipeline` added to `tests/governance.bats`'s `STANDARD_NS` — the
  existing generic assertions (`every standard-tier namespace has a governance
  leaf overlay`, `each standard-tier kustomization references the shared base
  limitrange`, `governance-appset lists every standard namespace`) cover it
  automatically, no new test needed.
- `docs/dependency-tree.md`'s wave-4 governance list updated to include
  `capstone-pipeline` in the always-on standard-tier namespace list.

This adds one new piece of always-on auto-synced cluster state (a
`capstone-pipeline` LimitRange, pre-created ahead of `make kargo-up`) — the
same pre-creation pattern already used for the `kargo` namespace itself via
`kargo-extras`, not a new pattern. Rollback is lossless: revert the appset
entry and ArgoCD prunes the LimitRange within its sync interval —
`capstone-pipeline` hosts no other workload today.

`make ci` green locally (bats/kustomize/kubeconform/terraform not installed in
this sandbox — same as every other cycle this run; full suite runs in GitHub
Actions).

## PR

(filled in once the PR is opened — see `auto/governance-capstone-pipeline`)
