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
- **Namespace:** `kyverno` (PSA label `baseline` at initial standup 2026-06-XX,
  flipped to `restricted` 2026-07-17 per [RFC #483](https://github.com/tooming/k8s-anywhere/issues/483) —
  the chart's four controllers already default to the full restricted container
  securityContext; see [ADR-0017 §Re-evaluation log](adr-0017-pod-security-standards-restricted.md#re-evaluation-log)
  for the full trigger/decision record, including the webhook self-protection
  finding that resolved the pod-vs-container-level question this note
  originally raised).

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
| `disallow-latest-tag` | `validate` | Reject any container `image:` ending in `:latest` or with no tag. **Carve-out (issue #498, 2026-07-18):** excludes the `capstone` namespace, whose manifests still hardcode a floating `:latest` placeholder pending Kargo wiring a real CI-pinned tag to capstone's image ref — without it, any Pod creation after the initial sync (crash/restart, Rollout scale event) is rejected and ArgoCD's `selfHeal` retries the same failing reconcile forever. Flip condition: remove the exclusion once `gitops/apps/capstone/{deployment,rollout}.yaml` reference a real, CI-pinned tag. |
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
- **`disallow-latest-tag` policy** excludes the `capstone` namespace (issue
  #498, 2026-07-18) — its manifests still hardcode a floating `:latest`
  placeholder pending Kargo wiring a real CI-pinned tag. Remove once
  capstone's image refs are CI-pinned.

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
| `kyverno` | `restricted` | Flipped 2026-07-17 (RFC #483): chart `kyverno-chart-3.3.4`'s four controllers already default to the full restricted container securityContext. Bumped to `kyverno-chart-3.3.9` 2026-07-18 (upgrade-drafter) — re-verified, no regression. See [ADR-0017 §Re-evaluation log](adr-0017-pod-security-standards-restricted.md#re-evaluation-log) for the self-protection finding that resolved the pod-vs-container-level question this row previously raised, and its 2026-07-18 entry for the bump re-verification. |

The PSA label is set on the `Namespace` manifest the Kyverno Application creates.

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-18 — CVE-2026-4789 (CEL `http.Get`/`http.Post` SSRF) kept (audit #502)

**Trigger.** [CVE-2026-4789](https://github.com/advisories/GHSA-qqrv-2hch-83q4)
(critical SSRF, disclosed 2026-07): Kyverno's CEL-based `http.Get()`/`http.Post()`
library functions, available to `NamespacedValidatingPolicy` CEL expressions,
enforce no URL restrictions — a namespace-scoped user authoring such a policy
could make the cluster-privileged admission-controller pod issue arbitrary HTTP
requests. Affects Kyverno 1.16.0+.

**Decision: keep chart pin `3.3.4`.** This lab's entire policy set
(`gitops/kyverno/policies/`) uses only the classic `kind: ClusterPolicy` CRD —
`require-pod-security-restricted`, `disallow-latest-tag`, `add-default-seccomp`,
`verify-image-signatures`, `add-default-runasnonroot` — none of which are the
newer CEL-based `NamespacedValidatingPolicy` kind, and none reference
`http.Get`/`http.Post` (verified: `grep -rn "http.Get\|http.Post\|NamespacedValidatingPolicy" gitops/kyverno/` returns zero matches). The vulnerable code
path is never reached by this lab's actual deployed policies, regardless of
chart version. Additionally, as of this audit no patched Kyverno release has
shipped yet (the fix landed on `kyverno/kyverno`'s `main` branch via PR #15789
but no tagged release cuts it) — there is nothing groundable to bump to even
if this were applicable (ADR-0004).

**Flip condition.** Revisit if either (a) this lab ever authors a CEL-based
`NamespacedValidatingPolicy` — at that point, audit it against
`http.Get`/`http.Post` usage and require `--httpBlocklist`/`--httpAllowlist`
scoping before merging, or (b) a patched Kyverno release ships and the
executor wants the defense-in-depth chart bump anyway as routine hygiene
(upgrade-drafter's normal patch-bump lane, not an architect decision at that
point).

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
