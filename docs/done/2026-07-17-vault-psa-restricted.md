# `vault` PSA `baseline` → `restricted` flip

CHARTER **Objective O2** hardening, RFC #478 — architect decision 2026-07-17, converting
audit #477; supersedes the 2026-06-11 audit #157 "keep" — see ADR-0017 §"Re-evaluation
log" for both entries. The flip condition #157 was waiting on is now met: a real,
pinnable `hashicorp/vault-helm` chart release (`v0.34.0`, 2026-07-02) ships a Vault
server (`v2.0.3`) that no longer holds `cap_ipc_lock` at build time (verified against
`hashicorp/vault` release `v2.0.2`'s changelog, 2026-06-05). Bumped
`gitops/platform/vault.yaml` chart `0.32.0` → `0.34.0`; added `disable_mlock = true` to
the standalone config; flipped `gitops/vault/namespace.yaml`'s four PSA labels
`baseline` → `restricted`; added the standard ADR-0017 §Layer 1 `securityContext`
(verified exact chart value keys — `server.statefulSet.securityContext.pod`/`.container`
— against the pinned `0.34.0` chart's real `values.yaml`) with an explicit `tmp`
`emptyDir` for `readOnlyRootFilesystem: true` (the chart's own `home` `emptyDir` at
`/home/vault` already covers that path unconditionally); bumped
`gitops/vault/unsealer.yaml`'s image `hashicorp/vault:1.21.2` → `hashicorp/vault:2.0.3`
and — since it also runs in this now-`restricted` namespace and previously had no
`securityContext` at all — gave it its own pod/container `securityContext` plus
`home`/`tmp` `emptyDir` mounts; updated the ADR-0017 `vault` row to `restricted`.
Extended security-context coverage: removed the now-stale "vault namespace.yaml
enforces PSS baseline" test from the frozen `tests/securitycontext.bats` monolith and
added `tests/securitycontext-vault.bats` (18 assertions: namespace PSA labels, chart
version + `disable_mlock`, Layer-1 securityContext fields, `tmp`/`home` emptyDir mounts,
unsealer image + securityContext). `make ci` passes.

**Caveat (ADR-0004).** This environment is remote and clusterless — whether Vault
actually starts cleanly under `restricted` + `disable_mlock` + `readOnlyRootFilesystem`
is not verifiable here. Structural/`kustomize`/bats validation is green; runtime
verification is the maintainer's to confirm on the live cluster. Rollback: revert the
commit (chart pin, PSA labels, unsealer image all revert together) — ArgoCD self-heals
within its sync interval, no data loss (the `dataStorage` PVC is untouched).

## PR

https://github.com/tooming/k8s-anywhere/pull/481
