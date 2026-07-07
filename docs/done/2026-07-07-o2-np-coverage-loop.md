# O2 NP per-scope coverage loop bats

O2 NP per-scope coverage loop bats (CHARTER **Objective O2**, due **2026-09-30**; O2
recurrence guard — prevents a future namespace from gaining an NP overlay without a
corresponding per-scope bats file; mirrors the `zz-dns-clusterip-bridge` presence loop
added in `auto/gitops-clusterip-bridge`. **No prerequisites — executor may pick up
immediately.** Add a new `@test` to `tests/networkpolicy.bats` (NOT the frozen monolith
— `tests/networkpolicy.bats` is the shared NP file and accepts new tests): title `"every
NP overlay dir has a per-scope networkpolicy-<ns>.bats file"`; the body iterates all
`gitops/*/networkpolicy/kustomization.yaml` and
`gitops/apps/*/networkpolicy/kustomization.yaml` paths; for each path reads the
`namespace:` field from the kustomization (authoritative K8s namespace name); asserts
`tests/networkpolicy-<namespace>.bats` exists; fails with a clear message naming the
missing file. This bats loop is the O2 NP completeness gate: it fails `make ci` if a
future NP-fan-out PR skips the per-scope bats. Also renames
`tests/networkpolicy-longhorn.bats` → `tests/networkpolicy-longhorn-system.bats` to align
with the naming convention (file name matches actual K8s namespace `longhorn-system`, not
the directory name). Updates `docs/dependency-tree.md` with a one-line note. Closes
ROADMAP `auto/o2-np-coverage-loop`.

## PR

#343
