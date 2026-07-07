# Fix: governance kustomize paths pointed at the wrong base

## What was wrong

PR #319 consolidated 17 identical per-namespace `limitrange.yaml` files into a single
shared `gitops/governance/base/limitrange-standard.yaml`. The intent was clear from the
commit message, and `tests/governance.bats` was updated to validate that file.

However, the fix commit in that PR added the base file at `gitops/base/limitrange-standard.yaml`
instead of `gitops/governance/base/`, and wired all 18 kustomization overlays with the path
`../../base/limitrange-standard.yaml`. From `gitops/governance/<ns>/`, that two-level `../../`
lands in `gitops/` — not `gitops/governance/` — so kustomize was building from
`gitops/base/limitrange-standard.yaml` while the governance-local
`gitops/governance/base/limitrange-standard.yaml` sat orphaned.

Effect: bats tests were validating the orphaned file, not the actually-deployed one. The two
files had identical YAML data (diverging only in comments), so no observable mismatch in the
cluster, but the structural inconsistency is a maintenance footgun.

## Fix

Changed the path in all 18 standard-tier governance kustomizations from
`../../base/limitrange-standard.yaml` to `../base/limitrange-standard.yaml`. This now resolves
to `gitops/governance/base/limitrange-standard.yaml` — the file the bats tests already check,
matching the PR #319 intent. Removed the spurious `gitops/base/` directory and its sole file.

No YAML content changes; kustomize output is identical.
