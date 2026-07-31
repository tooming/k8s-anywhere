# Fix docs/DR.md's bootstrap order table — 4 of 15 real `make up` steps missing

`docs/DR.md`'s "The order (what `make up` does, and why)" table claimed to document
the complete, ordered list of what `make up` does, but only listed 11 steps. The real
`up:` target in `Makefile` (lines 235-250) runs 15 sub-targets in this order:

```
colima-up → tfstate-up → cluster-up → cilium-up → coredns-host-alias → argocd →
gitlab-up → gitlab-configure → root-app → vault-bootstrap → gitlab-tls-bootstrap →
garage-bootstrap → cosign-bootstrap → frontdoor → grafana-gitsync-bootstrap
```

Four real, non-trivial steps were missing from the table entirely:

- `tfstate-up` (Makefile:285) — starts/bootstraps the off-cluster Garage holding
  Terraform state (ADR-0007); runs before `cluster-up`, but the table's old step 2
  went straight to the k3d cluster.
- `coredns-host-alias` (Makefile:324) — patches CoreDNS so `host.k3d.internal`
  resolves (k3d 5.x on Colima omits this); runs between `cilium-up` and `argocd`, but
  the table jumped straight from Cilium to ArgoCD.
- `cosign-bootstrap` (Makefile:430) — generates the cosign keypair + seeds the
  `cosign-public-key` ConfigMap in `kyverno` (ADR-0019); runs between
  `garage-bootstrap` and `frontdoor`.
- `frontdoor` (Makefile:507) — brings up the stable `:8000` front door; runs right
  before `grafana-gitsync-bootstrap`.

All four backing scripts (`scripts/tfstate-bootstrap.sh`, `scripts/coredns-host-alias.sh`,
`scripts/cosign-bootstrap.sh`, `scripts/frontdoor-ensure.sh`) were verified to exist and
do real work — not aliases or no-ops folded into an existing row.

## Fix

Added the 4 missing rows in their correct real-execution position, renumbering the
table from 1-11 to 1-15. Fixed the one stale in-doc step-number cross-reference just
below the table ("Once 7–8 are done" → "Once 9–10 are done", since App-of-apps and
Vault bootstrap shifted from steps 7/8 to 9/10).

New recurrence guard in `tests/bootstrap-seams.bats`: rather than one hardcoded
assertion per step (which is exactly the pattern that let this drift happen — new
steps get added to `up:` without a matching hardcoded test), the new test
generically re-derives every `$(MAKE) <target>` call from the `up:` recipe and
asserts each target name is present in `docs/DR.md`. A future step added to `up:`
without a DR.md row now fails CI automatically.

**Blast radius on a live cluster:** none — documentation and test-only.

`make ci` passes.

## PR

https://github.com/tooming/k8s-anywhere/pull/951
