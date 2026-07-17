# ADR-0019 — Kyverno as the lab's admission policy engine (not OPA Gatekeeper)

**Status.** Adopted. Decision taken by the architect routine in this RFC. Always-on
component. CHARTER **Objective O1** (one of four Tier 1 next-wave components,
due 2026-12-31) and **Objective O4** (every image cosign-signed and admission-verified).

---

## Context

CHARTER lists Kyverno as the always-on admission policy engine for three roles:

1. **Validation** — backstop ADR-0017 (PSS-restricted) at admission time so a
   non-compliant pod added in the future is rejected, not just warned about by
   the namespace label.
2. **Mutation** — inject sane defaults (e.g. add `seccompProfile=RuntimeDefault`
   when a workload omits it).
3. **Image signature verification** — `verifyImages` policy that admits only
   images cosign-signed by the lab's CI key. This is the in-cluster half of
   Objective O4 (the other half is the cosign signing step in `.gitlab-ci.yml`).

Kubernetes ships only the in-tree PSA (Pod Security Admission) as a labelled
enforcement; arbitrary policy, mutation, and image verification require an
external admission engine. The two CNCF-graduated options are **Kyverno**
(graduated 2024-11) and **OPA Gatekeeper** (graduated 2022-09).

---

## Decision

Adopt **Kyverno** as the lab's always-on admission policy engine, using the
**official Helm chart** (`kyverno/kyverno` from `https://kyverno.github.io/kyverno/`).

### Chart + version

- **Chart:** `kyverno/kyverno` v3.3.x (latest 3.x stable at executor pickup
  time; pin in the Application).
- **Source:** `https://kyverno.github.io/kyverno/`
- **Namespace:** `kyverno` (new namespace; PSA label `baseline` at initial
  standup — Kyverno controllers run as non-root but the admission/cleanup
  controllers mount webhook TLS material that today requires `fsGroup` outside
  the `restricted` carve-out set; revisit when the chart documents `restricted`
  compatibility. **Update 2026-07-17:** that condition is now met — audit #482
  converted to [RFC #483](https://github.com/tooming/k8s-anywhere/issues/483);
  see [ADR-0017 §Re-evaluation log](adr-0017-pod-security-standards-restricted.md#re-evaluation-log)
  for the full trigger/decision record. Still `baseline` until that RFC's
  executor PR lands.).

### Footprint controls (12 GB budget)

Default Helm values target HA (3 replicas per controller, ~400-600 MB). Lab
override **per ADR-0005** (single-host, recreate-over-HA):

```yaml
admissionController:   { replicas: 1, resources: { limits: { memory: 256Mi } } }
backgroundController:  { replicas: 1, resources: { limits: { memory: 128Mi } } }
cleanupController:     { replicas: 1, resources: { limits: { memory: 64Mi  } } }
reportsController:     { replicas: 1, resources: { limits: { memory: 128Mi } } }
```

Total cap: ~600 MiB combined limits, ~200-300 MiB steady-state. Fits inside
the planned 500 MB Tier 1 next-wave envelope when combined with the other
three controllers (Argo Rollouts, Velero, Trivy Operator).

### Initial `ClusterPolicy` set

Land in `gitops/kyverno/policies/` (separate ArgoCD `Application`, sync-wave 5
so the engine is up first):

| Policy | Type | What it does |
|--------|------|--------------|
| `require-pod-security-restricted` | `validate` | Backstop ADR-0017: reject pods missing `runAsNonRoot`, `allowPrivilegeEscalation=false`, `capabilities.drop=[ALL]`, `seccompProfile=RuntimeDefault`. Skips namespaces labelled `pod-security.kubernetes.io/enforce=baseline` or `=privileged` (matches the ADR-0017 carve-out table). |
| `disallow-latest-tag` | `validate` | Reject any container `image:` ending in `:latest` or with no tag. |
| `add-default-seccomp` | `mutate` | Inject `seccompProfile.type=RuntimeDefault` when missing (defence-in-depth alongside the validation rule). |
| `verify-image-signatures` | `verifyImages` | Required for **Objective O4**. Admit only images cosign-signed by the lab's CI key (public key stored in a ConfigMap `cosign-public-key` in `kyverno` namespace, seeded by `scripts/cosign-bootstrap.sh`). Scope: registries in `artifactory.127.0.0.1.nip.io/**` to start; expand once O4 is end-to-end green. |
| `add-default-runasnonroot` | `mutate` | Inject pod-level `runAsNonRoot: true` when missing — closes the admission gap exposed by the Harbor migration (ADR-0024): the `goharbor` chart sets container-level but not pod-level `runAsNonRoot`, and `require-pod-security-restricted` validates the pod level. See `tests/kyverno-add-default-runasnonroot.bats`. |

All five policies in `enforce` mode (audit-only would defeat the purpose of an
admission engine). Each policy file ≤ 50 lines.

### Observability

Kyverno exposes Prometheus metrics on `:8000/metrics` (admission controller).
Add an Alloy `prometheus.scrape "kyverno"` job. Dashboard
`grafana/dashboards/lab-kyverno.json`: admission request rate, policy
violations by policy name (real `kyverno_policy_results_total` counter),
mutation rate, p95 admission latency, controller pod status.

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/kyverno/networkpolicy/` (ADR-0016 fan-out):
  baseline + ingress TCP 9443 from kube-apiserver (admission webhooks) and
  TCP 8000 from Alloy in `observability` (metrics scrape).
- PSA label `baseline` (carve-out — see Per-namespace profile update below).
  Revisit to `restricted` when chart documents it.

---

## Why Kyverno (not Gatekeeper)

- **Native Kubernetes resource syntax.** Kyverno policies are YAML CRs that
  read like Kubernetes manifests; Gatekeeper requires Rego. For a learning
  lab where the *policy itself* is the artifact a learner reads, Kyverno is
  the right pedagogical fit.
- **Built-in `verifyImages` for cosign.** Kyverno ships `verifyImages` as a
  first-class rule type with cosign / sigstore as a native back-end. Gatekeeper
  defers image verification to an external `gatekeeper-external-data-provider`,
  adding another moving part to the supply-chain story for Objective O4.
- **CNCF graduated.** Both are graduated, so neither carries project-risk;
  the differentiator is the developer experience above.
- **PSS-restricted backstop policy ships as a ready-to-use sample** in the
  Kyverno policies catalogue; Gatekeeper requires authoring it in Rego.

---

## Scope & exceptions

**In scope** — admission policy, mutation, and image verification for every
ArgoCD-deployed workload in the lab.

**Carve-outs in the initial policy set:**

- **PSS backstop policy** skips `kube-system`, `longhorn-system`,
  `istio-system`, `storage`, `tidb`, `tidb-admin`, `vault` (mirrors the
  ADR-0017 carve-out table). New carve-outs land as PR edits to the
  ClusterPolicy `exclude` block, not by disabling the policy.
- **`verifyImages` policy** initially scoped to images pulled from the
  in-cluster Artifactory only. Upstream chart images (Grafana, Prometheus,
  Vault, etc.) are NOT cosign-signed by the lab and would be rejected; they
  are excluded by registry match. Once a fan-out PR adds Sigstore public-key
  verification for upstream signatures (e.g. distroless), the exclusion
  shrinks.

**Out of scope (this RFC):**

- OPA / Rego co-existence — not adopting Gatekeeper alongside Kyverno.
- External-data-provider plug-ins (image-data lookups against external APIs).
- Policy-as-code testing harness (e.g. `kyverno-cli test`) — deferred to a
  follow-up RFC once the policy set grows past ~10 ClusterPolicies.

---

## Per-namespace profile update (ADR-0017 amendment)

ADR-0017's per-namespace profile table gains one row:

| Namespace | PSA profile | Reason |
|-----------|-------------|--------|
| `kyverno` | `baseline` | Controllers run as non-root but mount webhook TLS via `fsGroup`; chart does not yet document `restricted` compatibility. Re-evaluated 2026-07-17 (audit #482) — flip condition now met, actioned as [RFC #483](https://github.com/tooming/k8s-anywhere/issues/483); still `baseline` until that RFC's executor PR lands. |

The PSA label is set on the `Namespace` manifest the Kyverno Application creates.

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0019-kyverno-admission-engine.md` | This ADR |
| `gitops/platform/kyverno.yaml` | Auto-synced ArgoCD `Application` for the engine |
| `gitops/platform/kyverno-policies.yaml` | Auto-synced ArgoCD `Application` for the policy set (sync-wave 5) |
| `gitops/kyverno/policies/*.yaml` | The five ClusterPolicies (four initial + `add-default-runasnonroot`) |
| `gitops/kyverno/networkpolicy/kustomization.yaml` | Default-deny overlay |
| `gitops/platform/observability-alloy.yaml` | New `kyverno` scrape job |
| `grafana/dashboards/lab-kyverno.json` | Real-metric dashboard (Objective O5) |
| `scripts/cosign-bootstrap.sh` | Day-0 seam — generates cosign keypair, seeds public-key ConfigMap |
| `tests/kyverno.bats` | Clusterless tests: Application shape, four policies present, scrape job declared, dashboard exists |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Engine + policies land as ArgoCD `Application`s; no `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Single-replica controllers are a deliberate lab trade-off per ADR-0005; production uses HA defaults. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard sources real Kyverno `/metrics` counters only. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-replica controllers; recreate from manifest on failure. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `kyverno` namespace gets its own default-deny overlay during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Kyverno's `require-pod-security-restricted` policy backstops ADR-0017 at admission time. |
