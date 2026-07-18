# Convert vault securityContext recurrence guards to path-aware yqs() assertions

Janitor fallback (executor routine, STEP 6b — ROADMAP `Now / next` fully
gated again this cycle; no un-RFC'd 🟡 items, no un-absorbed architect RFCs
in `docs/roadmap/incoming/`, no open issues for the triager, and the
upgrade-drafter fallback already delivered its one PR for this pass through
the chain earlier in this run — PR #540).

## What was found

A repo-wide sweep of `tests/securitycontext-*.bats` (prompted by this
session's KRO/Pyroscope work, PRs #537/#540) found that nearly
every per-component file still asserts container/pod `securityContext`
fields with a bare `grep -q 'fieldName: value'` — no anchor to the field's
actual YAML path. A bare grep can't distinguish a value correctly nested
under the right key from the same value string sitting anywhere else in the
file (including under a wrong or misspelled key) — exactly the gap class
that let the KRO `containerSecurityContext`-vs-`securityContext` mismatch
(and four earlier instances: KSM, node-exporter, Pyroscope, Grafana) ship
silently green for as long as it did.

`tests/securitycontext-vault.bats` was the largest single-component instance
of this gap (10 bare-grep assertions across both the vault Application's
Helm `valuesObject` and the hand-written `vault-unsealer` Deployment) and was
picked as this cycle's bounded target — the full sweep across all ~19
affected files is too large for one PR (WAYS-OF-WORKING.md §3's ~400-line
cap) and is left for future janitor cycles.

## What changed (behavior-preserving)

Converted 10 assertions in `tests/securitycontext-vault.bats` from bare
`grep -q` to path-aware `yqs()` reads, verified against the real nesting in
each source file:
- `gitops/platform/vault.yaml` (Helm chart): `.spec.source.helm.valuesObject.server.statefulSet.securityContext.pod.*` (pod-level) and `.container.*` (container-level) — matches the vault-helm chart's actual `server.statefulSet.securityContext.{pod,container}` schema.
- `gitops/vault/unsealer.yaml` (plain Deployment): `.spec.template.spec.securityContext.*` (pod-level) and `.spec.template.spec.containers[0].securityContext.*` (container-level).

All 10 new assertions verified passing locally against the actual pinned
manifests (via the real yq queries, cross-checked with `yq` directly before
running through `bats`). Test names and count are unchanged (21 tests total,
same as before) — this is a strengthening of existing assertions, not new
coverage or a behavior change to any manifest.

## Validation

`bats tests/securitycontext-vault.bats` — 21/21 pass locally. `make ci` —
same known pre-existing local bats failures as every prior cycle this
session (sandbox bats/yq toolchain mismatch, unrelated to this change).
GitHub Actions is the authoritative gate for this PR.

## PR

https://github.com/tooming/k8s-anywhere/pull/541
