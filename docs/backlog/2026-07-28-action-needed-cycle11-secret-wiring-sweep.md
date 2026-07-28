# [Action needed] Now/next still gated; Secret-wiring completeness sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped ten real, merged deliverables (PRs #789,
#790, #792–#799), including two live-cluster bugfixes (#796, #797).

This cycle tried a wiring-completeness cross-reference: parsed every `gitops/**/*.yaml`
manifest and collected (a) every Secret name actually produced (by an `ExternalSecret`'s
`.spec.target.name` or a plain `Secret`'s `metadata.name`) and (b) every `secretKeyRef`/
`secretRef` consumed by any container/env/volume across the whole tree (29 total
references), then checked each consumed name resolves to a real producer.

28 of 29 resolved cleanly. The one apparent gap —
`gitops/vault/unsealer.yaml` referencing Secret `vault-keys` in namespace `vault` with no
GitOps-managed producer — is a documented, intentional exception, not a bug: `vault-keys`
is created imperatively by `scripts/vault-bootstrap.sh` (`kubectl create secret generic
vault-keys ...`) as part of Vault's own Day-0 bootstrap seam (ADR-0001's boundary — Vault
cannot supply its own unseal key via ExternalSecrets before it's unsealed, the same
chicken-and-egg reasoning already documented for the off-cluster Garage tfstate backend,
ADR-0007). Confirmed the same secret is consumed identically by
`scripts/garage-bootstrap.sh` and `scripts/grafana-gitsync-bootstrap.sh`, all via the
same imperative-bootstrap pattern.

No actionable gap surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
