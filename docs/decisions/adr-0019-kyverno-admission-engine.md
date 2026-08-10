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
override **per ADR-0005** (single-host, recreate-over-HA), **except
`admissionController`, which runs 2 replicas — see the 2026-07-29
Re-evaluation log entry below for why**:

```yaml
admissionController:   { replicas: 2, resources: { limits: { memory: 256Mi } } }
backgroundController:  { replicas: 1, resources: { limits: { memory: 128Mi } } }
cleanupController:     { replicas: 1, resources: { limits: { memory: 64Mi  } } }
reportsController:     { replicas: 1, resources: { limits: { memory: 128Mi } } }
```

Total cap: ~832 MiB combined limits (512 MiB for `admissionController`'s two
replicas + 320 MiB for the other three single-replica controllers), ~300-400
MiB steady-state.

### Initial `ClusterPolicy` set

Land in `gitops/kyverno/policies/` (separate ArgoCD `Application`, sync-wave 5
so the engine is up first):

| Policy | Type | What it does |
|--------|------|--------------|
| `require-pod-security-restricted` | `validate` | Backstop ADR-0017: reject pods missing `runAsNonRoot`, `allowPrivilegeEscalation=false`, `capabilities.drop=[ALL]`, `seccompProfile=RuntimeDefault`. Skips namespaces labelled `pod-security.kubernetes.io/enforce=baseline` or `=privileged` (matches the ADR-0017 carve-out table). |
| `disallow-latest-tag` | `validate` | Reject any container `image:` ending in `:latest` or with no tag. **Carve-out (issue #498, 2026-07-18):** excludes the `capstone` namespace, whose manifests still hardcode a floating `:latest` placeholder pending Kargo wiring a real CI-pinned tag to capstone's image ref — without it, any Pod creation after the initial sync (crash/restart, Rollout scale event) is rejected and ArgoCD's `selfHeal` retries the same failing reconcile forever. Flip condition: remove the exclusion once `gitops/apps/capstone/{deployment,rollout}.yaml` reference a real, CI-pinned tag. **Carve-out (found 2026-07-28, structural sweep):** also excludes the `inkless` namespace — `ghcr.io/aiven/inkless:latest` has no stable named release to pin to (only rotating `edge-<commit>` builds); remove once Aiven ships a stable, pinnable release tag. **`argocd` carve-out REMOVED 2026-08-06** (issue #999, PR #1037) — its flip condition (a stable argo-cd release containing argoproj/argo-cd#26666, with the `latest` pin in `infra/modules/argocd/values.yaml` dropped for a real version tag) was met: the chart bumped to `10.2.3` (appVersion `v3.5.0`) and a live `terragrunt apply` picked up the pin. `gitops/kyverno/policies/disallow-latest-tag.yaml`'s `exclude` list is now `[capstone, inkless]` only — see this ADR's Re-evaluation log for the full writeup. |
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
  capstone's image refs are CI-pinned. Also excludes the `inkless` namespace
  (found 2026-07-28, structural sweep) — `ghcr.io/aiven/inkless:latest` has no
  stable named release to pin to (only rotating `edge-<commit>` builds);
  `make inkless-up` would otherwise fail admission on every attempt, not just
  on recreation. Remove once Aiven ships a stable, pinnable release tag. The
  `argocd` namespace carve-out (#632 investigation, 2026-07-24) was **removed
  2026-08-06** (issue #999, PR #1037) once its flip condition was met — see
  the Re-evaluation log below.

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

### 2026-07-27 — flip condition (b) above now satisfied; also closes two more CVEs (audit #760)

**Trigger.** Re-checking audit #502's own recorded flip condition (b) — "a
patched Kyverno release ships" — against this week's upstream findings.
Kyverno **1.18** (tagged, shipped 2026-05-05) is the release that carries the
CVE-2026-4789 fix (confirmed via `kyverno/kyverno` PR #15729 and the CNCF
1.18 announcement). Independently of this audit, `gitops/platform/kyverno.yaml`
was already bumped `3.3.9` → `3.8.2` (appVersion `v1.13.6` → `v1.18.2`) by
upgrade-drafter on 2026-07-19 as routine same-minor-unavailable hygiene, one
day after audit #502 closed — nobody connected that bump to this flip
condition at the time.

**Bonus finding, same sweep.** appVersion `v1.18.2` also independently fixes
two more Kyverno CVEs found while re-auditing this: **CVE-2026-22039**
(critical, CVSS 10.0, cross-namespace `apiCall` privilege escalation via
namespaced Policy — fixed in 1.16.3/1.15.3) and **CVE-2026-41068** (ConfigMap
context loader namespace-validation bypass, the "incomplete fix" follow-up to
22039 — fixed in 1.17.2). Both predate `v1.18.2`.

**Decision: keep — no bump needed, already satisfied.** The current pin
(chart `3.8.2`, appVersion `v1.18.2`) already sits past the fixed version for
all three CVEs (4789, 22039, 41068). No code change; this entry closes the
loop on #502's flip condition (b) for the record.

**Flip condition (next re-evaluation).** Unchanged: (a) this lab ever authors
a CEL-based `NamespacedValidatingPolicy`, or (b) a new CVE is filed against a
Kyverno version above `1.18.2`.

---

### 2026-07-29 — `admissionController` bumped to 2 replicas (fail-closed self-lockout)

**Trigger.** `resourceValidatingWebhookConfiguration` is fail-closed: with the
single `admissionController` replica this ADR originally specified, that one
pod restarting (routine under load — OOM, liveness kick, node hiccup) leaves
the webhook with zero endpoints, which blocks *every* delete/create
cluster-wide until it comes back — not just Kyverno-related resources. Hit
live 2026-07-29: this exact deadlock repeatedly stalled unrelated cluster
recovery work (couldn't even force-delete an unrelated stuck pod while the
sole admission-controller replica was mid-restart).

**Decision: keep the single-replica pattern for every other controller, but
carve out `admissionController` to 2 replicas** (confirmed with the user
2026-07-29). ADR-0005's argument (2 copies on one host add no real HA)
covers *host*-level failure; this is a different failure mode — a second
replica on the same node still answers the fail-closed webhook while the
first restarts, closing the gap. This is genuine resilience against a
correctness-blocking deadlock, not the SPOF theatre ADR-0005 warns against.
`gitops/platform/kyverno.yaml`'s `admissionController.replicas` is `2`; the
"Footprint controls" table above reflects the updated total.

**Flip condition (next re-evaluation).** Revisit if the fail-closed webhook
deadlock recurs even with 2 replicas (would suggest raising further, or a
different mitigation), or if upstream Kyverno adds a non-webhook admission
path that removes this failure mode entirely.

---

### 2026-08-06 — `disallow-latest-tag`'s `argocd` carve-out flip condition met, exclusion removed (issue #999, PR #1037)

**Trigger.** This ADR's `disallow-latest-tag` carve-out for the `argocd`
namespace (added #632 investigation, 2026-07-24) had an explicit flip
condition: "remove the exclusion once argo-cd ships a stable release
containing argoproj/argo-cd#26666 and the `latest` pin in `values.yaml` is
dropped for a real version tag." `auto/argocd-chart-10-2-3` bumped the
Terraform-bootstrapped chart to `10.2.3` (appVersion `v3.5.0`, which contains
#26666) and dropped `infra/modules/argocd/values.yaml`'s deliberate
`global.image.tag: latest` pin — but per ADR-0001, `infra/` is
Terraform-bootstrap-only and doesn't auto-apply, so the exclusion stayed live
until a real `terraform apply` picked up the change. Issue #999 tracked that
remaining live-cluster gate.

**Decision: flip condition met, exclusion removed.** A live-cluster session
ran `terragrunt apply` against `infra/live/local/argocd` 2026-08-06 (fixing a
separate, unrelated bug found along the way — a `provider "helm" { kubernetes
{ ... } }` block syntax break against the already-locked `hashicorp/helm`
v3.2.0 provider, which changed `kubernetes` from a block to an attribute).
Verified live (ADR-0004): every `argocd` Pod
(application-controller/applicationset-controller/redis/repo-server/server)
runs `quay.io/argoproj/argocd:v3.5.0`, confirmed via `kubectl get pods -n
argocd -o jsonpath='{.items[*].spec.containers[*].image}'`. PR #1037 removed
the `argocd` entry from `gitops/kyverno/policies/disallow-latest-tag.yaml`'s
`exclude.any[0].resources.namespaces` list (now `[capstone, inkless]` only)
and added a regression test (`tests/kyverno.bats`: "disallow-latest-tag no
longer excludes the argocd namespace (issue #999 resolved)") asserting
`argocd` stays absent.

**Flip condition (recurrence guard).** None needed going forward — this
carve-out is fully closed, not held pending a future condition. If a future
ArgoCD chart bump ever reintroduces a `latest`-tagged image pin, `tests/
kyverno.bats`'s new regression test would need updating alongside re-adding
the carve-out — that would be a fresh, deliberate decision, not a silent
regression, since the test actively asserts the exclusion's absence today.

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
