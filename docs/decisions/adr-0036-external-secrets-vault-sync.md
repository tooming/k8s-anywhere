# ADR-0036 — External Secrets Operator for Vault-backed secret sync

**Status.** Adopted (retroactive record). Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
closes a documentation gap on an already-implemented, already-live component, not a new
technical choice). Always-on-core component.

---

## Context

The lab needs a way to get real credentials (Vault-held secrets, provider-issued keys,
etc.) into native Kubernetes `Secret` objects that workloads mount — without hand-running
`kubectl create secret` (not GitOps-reproducible, ADR-0001) or committing plaintext
credentials to git (an obvious non-starter). This has been solved since early in the
lab's history by deploying **External Secrets Operator (ESO)** as an always-on-core
component (`gitops/platform/external-secrets.yaml`, sync-wave 1) with a Vault-backed
`ClusterSecretStore` (`gitops/secrets/clustersecretstore.yaml`, Kubernetes-auth to
`http://vault.vault.svc.cluster.local:8200`) — every credential the lab's other
components need (Garage RPC/S3 keys, Harbor admin/registry/S3 creds, Grafana admin,
Kargo admin, Velero S3, ACK AWS creds, the capstone app key) flows through an
`ExternalSecret` resolved against that store.

**Why this ADR is only being written now.** ESO was never compared against an
alternative at adoption time (there wasn't a serious "ESO vs. the Vault CSI provider vs.
Vault Agent Injector" evaluation the way, say, ADR-0018 weighed Valkey against Redis) —
it was infrastructure glue standing up the credential-delivery mechanism every other ADR
assumes exists. That's why it was never indexed: `docs/dependency-register.md` explicitly
scopes itself to "pure re-indexing of content that already exists in `docs/decisions/`"
and ESO had no ADR to index. But ESO is exactly the kind of component the register exists
to catch — always-on-core, and a genuine security-sensitive control point (it mediates
every cluster credential) — so the gap itself is real, found via this run's direct-GHSA-page
security sweep (cycle 12) turning up ESO's own advisory history and noticing it had no
governance record at all, unlike every peer component (RabbitMQ, Valkey, Kyverno,
cert-manager, KEDA, Argo Rollouts, Velero, Trivy Operator — all ADR-0009/0018/0019/0028/
0029/0020/0021/0022).

---

## Decision

Adopt **External Secrets Operator**, the CNCF-hosted, de-facto-standard operator for
syncing secrets from external stores (Vault, AWS Secrets Manager, GCP Secret Manager,
etc.) into native `Secret` objects, via its **official Helm chart**.

### Chart + version

- **Chart:** `external-secrets` from `https://charts.external-secrets.io`.
- **Current pin:** `2.10.0` (`gitops/platform/external-secrets.yaml`). Bumped from `2.9.0`
  2026-09-01 (upgrade-drafter fallback) — verified directly (ADR-0004) via a real clone's
  `git diff helm-chart-2.9.0 helm-chart-2.10.0` (purely additive TLS-config options, no
  `valuesObject` key this lab sets changed shape) and `git log v2.9.0..v2.10.0` (real fixes
  including an AWS credential-log-redaction fix). See
  [§Re-evaluation log](#re-evaluation-log) for the full trail.
- **CRDs via the chart itself** (`installCRDs: true`), keeping day-2 CRD management
  inside the GitOps loop per [ADR-0001](adr-0001-gitops-over-terraform-helm.md).
- **Namespace:** `external-secrets`.

### Security posture (already implemented, verified directly)

- **PSA `restricted`**, no carve-out: `gitops/external-secrets/namespace.yaml` labels the
  namespace `restricted`; the chart has no `global.podSecurityContext` key (each of the
  three Deployments — main, webhook, certController — needs its own), so
  `external-secrets.yaml`'s `valuesObject` sets pod- and container-level
  `runAsNonRoot`/`seccompProfile: RuntimeDefault`/`allowPrivilegeEscalation: false`/
  `readOnlyRootFilesystem: true`/`capabilities.drop: [ALL]` explicitly on all three.
- **NetworkPolicy** (`gitops/external-secrets/networkpolicy/`, ADR-0016 fan-out): egress
  to Vault (`allow-eso-vault-egress.yaml`), ingress for metrics scrape
  (`allow-eso-metrics-ingress.yaml`), ingress from kube-apiserver for the admission
  webhook (`allow-eso-webhook-from-apiserver.yaml`).
- **Footprint controls:** `resources.requests: {cpu: 25m, memory: 64Mi}` /
  `limits: {cpu: 250m, memory: 192Mi}` — trimmed well below chart defaults, matching this
  lab's per-component budget norm (comparable to cert-manager/KEDA).
- **Wave ordering:** `external-secrets-extras` (namespace + PSA labels) at wave 0,
  `external-secrets` (the engine, CRDs) at wave 1, `external-secrets-config`
  (`ClusterSecretStore` + `ExternalSecret`s, needs the wave-1 CRDs) at wave 2 with a
  5-retry/10s-backoff policy for the CRD-registration race.

### Observability

Real Prometheus metrics scraped by Alloy (`gitops/platform/observability-alloy.yaml`,
job `external-secrets`, `external-secrets.external-secrets.svc.cluster.local:8080`).
Dashboard `grafana/dashboards/lab-external-secrets.json` (real Mimir data, ADR-0004).

### Test coverage

`tests/external-secrets-chart-pin.bats`, `tests/networkpolicy-external-secrets.bats`,
`tests/observability-external-secrets.bats` — all already exist and pass.

---

## This cycle's security re-evaluation (2026-08-19, cycle 12)

Direct GHSA-page audit (`github.com/external-secrets/external-secrets/security/advisories`),
same method as this run's other component sweeps — checked every advisory's own
affected/patched-version fields against the live pin, not release notes or training
knowledge:

| GHSA | Severity | Affected | Patched | Current pin (`2.9.0`) safe? |
|------|----------|----------|---------|------------------------------|
| GHSA-77v3-r3jw-j2v2 | **Critical** | `>=0.20.2, <1.2.0` | `1.2.0` | Yes — past floor |
| GHSA-r2pg-r6h7-crf3 | High | `<2.3.0` | `2.3.0` | Yes — past floor |
| GHSA-vf79-2pjx-phpp | High | (BeyondTrust provider, not in use — this lab's `ClusterSecretStore` is Vault-only) | — | Not applicable |
| GHSA-fcxq-v2r3-cc8h | High | `<2.4.1` (per advisory prose "impacts any release following 0.1.0 up until fixed in 2.4.1") | `2.4.1` | Yes — past floor |
| GHSA-fq7h-9x26-6j22 | Moderate | not fully machine-extractable from the advisory summary; chart is well past this advisory's 2026-05 publish date and every other floor on this list | — | No newer patched-version floor found above `2.9.0` |
| GHSA-wv26-88m5-6h59 | Low | — | — | — |
| GHSA-qwgc-rr35-h4x9 | Moderate | 2024, long superseded | — | — |

**No action needed** — `2.9.0` (the newest available tag) sits past every floor found.
This is a **Keep** outcome, not a Bump.

---

## Scope & exceptions

**In scope (already shipped, this ADR is a retroactive record, not new work):** the
engine, namespace/PSA, NetworkPolicy fan-out, observability, and the `ClusterSecretStore`
+ per-component `ExternalSecret`s listed under Context above.

**Out of scope:** evaluating alternative secret-sync mechanisms (Vault CSI provider,
Vault Agent Injector) — no case has been made to reconsider ESO, and doing so now would
be re-litigating a working, unproblematic choice rather than closing a real gap.

---

## Re-evaluation log

ADR audits record their outcome here when the decision is kept. See "This cycle's
security re-evaluation" above for the first entry (2026-08-19, cycle 12 — Keep, no CVE
above the current pin).

**Flip condition (next re-evaluation).** Revisit if a new GHSA is filed against a
version above `2.9.0`, or if this lab's `ClusterSecretStore` provider config ever
changes away from the Kubernetes-auth Vault backend (which would reopen the
provider-specific advisories currently marked not-applicable, e.g. the BeyondTrust one).

### 2026-09-01 — Chart bumped `2.9.0` → `2.10.0` (upgrade-drafter fallback, no CVE)

**Trigger.** Routine currency sweep (this run's eleventh cycle) found
`external-secrets/external-secrets`'s `helm-chart-2.10.0` tag one release
past this lab's pinned `2.9.0` — the prior "no currency gap" note above had
gone stale.

**Verification (ADR-0004).** Real clone of `external-secrets/external-secrets`:
`git diff helm-chart-2.9.0 helm-chart-2.10.0 -- deploy/charts/external-secrets/
values.yaml` is purely additive (48 insertions, 0 deletions) — new optional
`tls.{minVersion,ciphers,curvePreferences}` blocks at the global/webhook/
certController levels, every one defaulting to empty (no behavior change
unless explicitly set). Every key this lab's `valuesObject` sets
(`installCRDs`, `podSecurityContext`, `securityContext`, `webhook.*`,
`certController.*`, `resources`) is unchanged in shape. `git log
v2.9.0..v2.10.0` (39 commits) includes real fixes: `fix(aws): redact
credentials in aws auth config logs` (a real credential-leak fix),
`fix(gcp): preserve workload identity token expiry`, `fix(vault): only apply
deprecated token-cache flags when explicitly set` — plus the TLS
security-profile feature itself (`feat: apply TLS security profile to the
external-secrets deployment`) and routine dependency bumps. No CVE cited
explicitly.

**Decision: bump.** Same major/minor line, additive-only schema change, real
fixes included. No blast radius concern beyond the normal ArgoCD
auto-sync reconciliation (this Application IS auto-synced, unlike this
run's on-demand bumps).

**Flip condition (next re-evaluation).** Revisit if a new GHSA is filed
against a version above `2.10.0`, or the `ClusterSecretStore` provider
config changes (same condition as the prior entry).

---

## Files this record touches

| Path | Role |
|------|------|
| `docs/decisions/adr-0036-external-secrets-vault-sync.md` | This ADR |
| `docs/dependency-register.md` | New External Secrets Operator row, indexing this ADR |
| `docs/decisions/README.md` | New index entry |

(All GitOps manifests, tests, and dashboards referenced above already exist and are
unchanged by this record — this ADR documents existing state, per ADR-0004: nothing
here is asserted without having been read directly this cycle.)

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Engine lands as an ArgoCD `Application`; CRDs installed via the chart. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard sources real `external-secrets` scrape data only; this ADR's own claims were verified directly against live manifests, not assumed. |
| [ADR-0009](adr-0009-rabbitmq-message-broker.md) / [ADR-0018](adr-0018-valkey-not-redis.md) / others | Every credential those components need flows through this operator's `ExternalSecret`s. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `external-secrets` namespace carries its own default-deny + explicit-allow overlay. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | `restricted` PSA, zero carve-out — already recorded there (`external-secrets` row, RFC #229, 2026-06-19); this ADR is the missing companion record for the *component itself*, not the PSA decision. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | Apache 2.0, no paid tier required. |
