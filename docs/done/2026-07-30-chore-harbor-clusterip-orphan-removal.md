# Remove orphaned Harbor NetworkPolicy manifest + add a mechanical guard against recurrence

`gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml` existed on disk but
was **not referenced anywhere in `gitops/harbor/networkpolicy/kustomization.yaml`** —
the only orphan across all 52 `kustomization.yaml` files in the repo. History confirms
this is a genuine bug, not a stray artifact: the file was dropped from the
kustomization's `resources:` list when the shared `zz-dns-clusterip-bridge.yaml`
template (`gitops/network/policies/`) replaced it as the unified ClusterIP-egress
bridge, but the file itself was never deleted. Worse, PR #716 (2026-07-24, "switch
Harbor cache to bundled redis-photon, not platform Valkey") still edited that dead
file's content as if it were live — kustomize builds ignore an unreferenced file
silently, so neither `make ci` nor a live cluster ever surfaced the drift. Even
`tests/harbor.bats` itself carried a contradiction: one test (line 209) asserted the
kustomization references the shared bridge template "not the per-namespace
`allow-harbor-clusterip-egress.yaml` copy" (correctly), while two other tests
(previously lines 217–230) still asserted that dead copy exists and has real
`CiliumNetworkPolicy` content — nothing had gone back to remove them once the file
became dead weight.

## Fix

1. Deleted `gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml` — fully
   superseded by `../../network/policies/zz-dns-clusterip-bridge.yaml`, already
   referenced in the same `kustomization.yaml`. No topology change: the live,
   applied NetworkPolicy set for the `harbor` namespace is identical before and
   after (the file was never part of any `kustomize build` output).
2. Replaced `tests/harbor.bats`'s two stale "dead file exists / has real content"
   tests with a single `"does not exist"` assertion, noting the file's
   `CiliumNetworkPolicy` content is already covered by `tests/networkpolicy.bats`'s
   `zz-dns-clusterip-bridge` assertions (it's the same shared template).
3. **Recurrence guard** (CLAUDE.md's bugfix-must-prevent-recurrence rule): new
   `scripts/kustomize-orphan-check.sh` — for every `kustomization.yaml` under
   `gitops/`, checks that every sibling `*.yaml`/`*.yml` file in its directory is
   referenced somewhere in it; flags any file that isn't (dropped from
   `resources:` but left on disk, or a new file never wired in). Wired into
   `make kustomize-orphan-check`, `make ci`, and `.github/workflows/ci.yml` (kept
   in parity per the `ci-parity-check` gate). A companion PostToolUse hook,
   `scripts/kustomize-orphan-sync-hook.sh`, nudges immediately when a file next to
   a `kustomization.yaml` is edited and turns out to be orphaned — wired into
   `.claude/settings.json`. New bats coverage: `tests/kustomize-orphan-check.bats`
   (the check script itself, with `tests/fixtures/kustomize-orphan-check/{in-sync,
   drift}` fixtures) and `tests/hook-scripts-kustomize-orphan.bats` (the hook,
   per the `hook-scripts-coverage.bats` frozen-monolith convention — new hook
   coverage goes in its own `tests/hook-scripts-<scope>.bats` file).

Running the new check against the real repo before this fix (and again after,
via `git stash`) confirmed exactly one orphan existed — this file — and zero
after the fix.

`make ci` passes: 2335 bats assertions, 0 failures (verified locally with
`bats` installed via `apt-get` and a fetched `mikefarah/yq` v4.53.3 binary, since
neither is present by default in this remote sandbox; `helm`/`kustomize`/
`kubeconform`/`terraform`/`shellcheck`/`yamllint` remain locally-skipped and
unavailable here, same as every other autonomous run). A `git stash`/`make ci`/
`git stash pop` comparison against a clean `main` checkout confirmed this diff
introduces zero new failures — the handful of pre-existing failures seen without
the `mikefarah/yq` binary on `PATH` (chart-pin / CRD-SSA / rollouts-plugin-list
checks, all yq-variant-gated) and two unrelated Kargo/Rollouts test failures are
identical before and after this change.

No topology change — no README/`docs/dependency-tree.md` update needed (this is a
dead-manifest removal + a new drift-check script/test/hook, not a live-cluster
change).

## PR

(filled in after PR creation)
