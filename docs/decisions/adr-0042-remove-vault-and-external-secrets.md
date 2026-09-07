# ADR-0042 — Remove Vault + External Secrets Operator entirely (supersedes ADR-0036, ADR-0037)

**Status.** Adopted. Removes HashiCorp Vault and External Secrets Operator as
workloads, with no replacement. Explicit maintainer direction, the same
"aggressive simplification" pattern as ADR-0041 — flagged against the two binding
ADRs it supersedes, per CLAUDE.md's ADR discipline, rather than implemented
silently.

---

## Context

[ADR-0037](adr-0037-vault-secrets-management.md) (HashiCorp Vault, the lab's
secrets backend) and [ADR-0036](adr-0036-external-secrets-vault-sync.md)
(External Secrets Operator, the sync mechanism that delivered Vault-held
credentials into native `Secret` objects) together decided this lab's entire
secrets-management pipeline: a real KV v2 store, reached via ESO's
Kubernetes-auth `ClusterSecretStore`, feeding every credential another
component needed (Garage RPC/S3 keys, Harbor admin/registry/S3 creds, Grafana
admin, Kargo admin, Velero S3, ACK AWS creds, the capstone app key).

Every one of those consumers is already gone. The 2026-09-06/2026-09-07
simplification round (commit 319d6b2, #1497) removed Garage, Harbor, Kargo,
Velero, ACK/moto/KRO, capstone, and the observability stack (Grafana) entirely,
no replacement — each of them was the reason a given `ExternalSecret` existed.
By the time this ADR was written, a direct repo check confirmed the fact
plainly: **zero** `kind: ExternalSecret` resources remained anywhere in
`gitops/` (the only file matching was itself dead — an orphaned leftover under
`gitops/argo-rollouts/`, unreferenced by any Application, cleaned up
separately). The `ClusterSecretStore` pointing at Vault had nothing left to
back. ESO and Vault were both still running, still consuming Colima VM
resources on every `make up`, in service of a secrets-sync path with no real
consumer on either end — proving nothing, the same shape the observability
stack's Argo Rollouts SLO gate was in after ADR-0041 removed Mimir (documented
there as "impacted, not superseded" since Argo Rollouts itself stayed; here
there is no remaining always-on component that still needs what Vault/ESO
provide, so both go, not just their downstream integration).

Per explicit maintainer direction this session ("remove vault from the
project"), and consistent with the capacity-driven, deliberate-narrowing
rationale ADR-0041 and the 2026-09-07 simplification round already
established (see CHARTER.md's "The 2026-09-07 simplification" section), this
ADR removes both.

---

## Decision

Remove, as ArgoCD-managed workloads, with no replacement:

- **HashiCorp Vault** (ADR-0037) — the KV v2 secrets backend, its
  `vault-unsealer` auto-re-unseal Deployment, `PersistentVolumeClaim`, and
  `IngressRoute`.
- **External Secrets Operator** (ADR-0036) — the sync operator, its
  `ClusterSecretStore` (`gitops/secrets/clustersecretstore.yaml`), and CRDs.

Every dependent piece is removed alongside them, not left as dead
configuration:

- `gitops/vault/` and `gitops/external-secrets/` (namespaces, NetworkPolicy
  overlays, the unsealer) — entire trees deleted.
- `gitops/secrets/` (the `ClusterSecretStore`) — deleted; nothing else lived
  in that directory.
- `gitops/platform/vault.yaml`, `vault-extras.yaml`, `external-secrets.yaml`,
  `external-secrets-config.yaml`, `external-secrets-extras.yaml` — the
  ArgoCD `Application` manifests themselves.
- `gitops/governance/vault/`, `gitops/governance/external-secrets/` — their
  governance LimitRange overlays.
- The `vault-governance`, `external-secrets-governance`,
  `vault-networkpolicy`, and `external-secrets-networkpolicy`
  `ApplicationSet` list-generator entries in `gitops/platform/
  governance-appset.yaml` and `gitops/platform/networkpolicy-appset.yaml`.
- `scripts/vault-bootstrap.sh` and the Makefile's `vault-bootstrap`/
  `vault-unseal` targets (`make up`'s bootstrap chain no longer calls it);
  `vault` dropped from `REQUIRED_TOOLS` and the `creds` target's Vault-token
  line.
- `dr-verify.sh`'s `p_vault`/`p_eso`/`eso_offenders` checks and their
  `T_VAULT`/`T_ESO` budget vars — nothing left to verify.
- Every dependent test file: `tests/networkpolicy-vault.bats`,
  `tests/securitycontext-vault.bats`, `tests/networkpolicy-external-secrets.bats`,
  `tests/external-secrets-chart-pin.bats`, plus the External Secrets block in
  the frozen `tests/securitycontext.bats` monolith and the `vault`/
  `external-secrets` entries in `tests/governance.bats`'s `STANDARD_NS` and
  `tests/lib/networkpolicy-paths.bash`'s shared path vars.

This lab's always-on stack is now exactly **4 namespaces**: `argocd`,
`cert-manager`, `lab-gateway` (Traefik, bundled with k3s), and `lab-demo`. No
credential currently flowing through the lab needs an external secrets store —
ArgoCD's admin password and Traefik/cert-manager's certificates are all
natively generated in-cluster (cert-manager's self-signed root CA chain,
ADR-0028), with no external secret material to sync.

## Historical record preserved

Neither ADR-0036 nor ADR-0037 is deleted — both are marked **Superseded by
ADR-0042** and kept in place, same as ADR-0006/ADR-0034 were for the
observability removal. Their own Re-evaluation logs (real chart/image-version
bump history, GHSA sweeps) remain the historical record of what actually ran
and when — this ADR does not relitigate or duplicate that content.

## Re-evaluation log

### 2026-09-07 — Adopted

Explicit maintainer direction this session ("remove vault from the project").
Verified directly (ADR-0004) before removal: `grep -rl "kind: ExternalSecret"
gitops/` found zero live consumers of the Vault-backed `ClusterSecretStore` —
the only match was an already-orphaned leftover file under
`gitops/argo-rollouts/` referencing neither a `kustomization.yaml` nor any
Application path. `make ci`'s drift/unit/lint gates verified green after the
removal (dependency-register, dependency-concentration, dependency-tree,
dependency-exit-runbooks, adr-followup, readme-check, lab-ui-check,
securitycontext-tests-check, networkpolicy-tests-check).
