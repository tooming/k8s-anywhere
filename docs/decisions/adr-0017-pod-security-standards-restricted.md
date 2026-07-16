# ADR-0017 — Pod Security Standards `restricted` profile across all namespaces

**Status.** Adopted. Decision taken in RFC #83. Pilot namespace: `capstone`;
full fan-out to remaining namespaces follows per-namespace via the planner's
groomed items.

---

## Context

[RFC #83](https://github.com/tooming/k8s-lab/issues/83) calls for hardening
every pod's `securityContext` against the Kubernetes Pod Security Standards
(PSS) `restricted` profile. PodSecurityPolicy was removed in Kubernetes 1.25;
the in-tree successor is **Pod Security Admission (PSA)**, which enforces PSS
profiles via namespace labels.

The lab runs ~28 ArgoCD `Application`s across mixed direct manifests and Helm
charts. None currently set the required `securityContext` fields or carry PSA
namespace labels.

---

## Decision

Adopt PSS `restricted` as the target for every lab namespace, enforced at two
layers:

### Layer 1 — manifest fields (every Deployment / StatefulSet / DaemonSet)

**Pod-level `securityContext`:**

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001          # any non-zero UID; pick per-workload, default 10001
        runAsGroup: 10001
        fsGroup: 10001            # only when a writable volume is mounted
        seccompProfile:
          type: RuntimeDefault
```

**Container-level `securityContext`** (every container, including initContainers):

```yaml
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true    # exceptions noted in §Scope
  capabilities:
    drop: ["ALL"]
```

**Writable-filesystem workloads** use `emptyDir` mounts over write targets
(e.g. `/tmp`, `/var/cache`, `/var/log`) instead of relaxing
`readOnlyRootFilesystem`. For stateful workloads the existing PVC already
covers the data path; only ephemeral write targets need `emptyDir`.

**Helm-chart workloads** add `valuesObject.podSecurityContext` /
`valuesObject.containerSecurityContext` (or the chart-specific equivalent) in
the ArgoCD `Application`'s `spec.source.helm.valuesObject` so PSS-restricted
is enforced after the chart renders.

### Layer 2 — namespace labels (every namespace manifest)

```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

The manifest fields are what actually runs; the namespace label is the
in-cluster safety net that catches a future workload that forgets to set the
fields. Without the label, a non-compliant pod can be added and nothing
in-tree blocks it.

---

## Why PSS `restricted`

- **PSS `restricted` is the SIG-Auth-documented production baseline.** It
  bundles `runAsNonRoot`, `seccompProfile=RuntimeDefault`,
  `capabilities.drop=[ALL]`, `allowPrivilegeEscalation=false`, and the
  host-namespace prohibitions in one labelled enforcement.
- **`readOnlyRootFilesystem: true` is the highest-value hardening control.**
  It blocks the most common post-compromise step (drop a binary, modify a
  config). The `emptyDir`-over-write-targets pattern is the documented fix and
  preserves the security win without per-workload exceptions.
- **Two-layer enforcement is the defence-in-depth standard.** Manifest fields
  prevent the problem; namespace labels catch regressions. Both are required.
- **CNCF Cloud Native Security Whitepaper v2** independently names the same
  controls, confirming cross-vendor consensus.

---

## Per-namespace profile

Not every namespace can run under `restricted` — some system-level components
need elevated privileges. The table below records each carve-out permanently
so the executor never silently applies the wrong label.

| Namespace | PSA profile | Reason |
|-----------|-------------|--------|
| `capstone` | `restricted` | Pilot; workload is fully owned by us. |
| `argocd` | `restricted` | ArgoCD components run as UID 1000 (non-root), `readOnlyRootFilesystem: true`, no capabilities. Phase 2 (RFC #205) adds `global.podSecurityContext` + `global.containerSecurityContext` to `infra/modules/argocd/values.yaml` and flips `enforce: restricted`. |
| `observability` | `restricted` | LGTMP stack; containers are non-root-capable. |
| `storage` (Garage) | `baseline` | Upstream Garage image does not yet declare an explicit non-root user required by `restricted`. Re-evaluate per upstream release. |
| `data` | `restricted` | RabbitMQ + Redis both support non-root operation. |
| `tidb` / `tidb-admin` | `baseline` | TiDB operator pods need additional capabilities; `baseline` is HashiCorp/PingCAP's documented recommendation. |
| `moto` / `ack-system` | `restricted` | Stateless HTTP mock; non-root-capable. |
| `lab-gateway` | `restricted` | Envoy Gateway; runs as non-root. |
| `vault` | `baseline` | Vault needs `IPC_LOCK` to `mlock` its memory and prevent secret swap-to-disk. `restricted` forbids it; `baseline` is HashiCorp's recommended profile. Re-evaluated 2026-06-11 (audit #157) — **kept**; see [§Re-evaluation log](#re-evaluation-log). |
| `kyverno` | `baseline` | Kyverno admission controller mounts webhook TLS material via `fsGroup`; PSS `restricted` forbids it. Per ADR-0019 §"Per-namespace profile update". Re-evaluate when the upstream chart documents `restricted` compatibility. |
| `velero` | `restricted` | Controller runs non-root (UID 65534); node-agent DaemonSet uses a per-workload annotation to mount `/var/lib/kubelet/pods` for Kopia FS-backup (matches the node-exporter hostPath carve-out pattern in §"Per-workload field carve-outs"). Per ADR-0021 §"PSA profile" (implementation adopted `restricted`, overriding the initial `baseline` estimate). |
| `argo-rollouts` | `restricted` | Controller and dashboard both run as non-root (UID 65532), no host volumes, no privileged containers. Per ADR-0020 §"NetworkPolicy + PSS". |
| `trivy-system` | `baseline` | Trivy scan-job pods pull and unpack arbitrary OCI layer tarballs, exceeding `restricted`. Operator pod itself is restricted-compliant; chart applies one PSA profile to both. Per ADR-0022 §"PSA profile". Re-evaluate per chart upgrade. |
| `external-secrets` | `restricted` | ESO 2.x controller-manager, cert-controller, and webhook all run as UID 65534 (`nobody`), no host volumes, no special capabilities. Chart supports `global.podSecurityContext` / `global.containerSecurityContext` overrides. Per RFC #229 (architect decision 2026-06-19). |
| `kro` | `restricted` | KRO controller runs as UID 65534 (`nobody`), `readOnlyRootFilesystem: true`, no host volumes, no special capabilities. The chart `valuesObject` in `gitops/platform/kro.yaml` already carries the full hardened `podSecurityContext` + `containerSecurityContext` block — no additional workload patch needed. Per ROADMAP `auto/pss-kro-namespace`. |
| `kargo` | `restricted` | Kargo api/controller/webhooks-server all run as UID 65532 (non-root); no host volumes, no special capabilities. Per ROADMAP `auto/pss-kro-namespace` pattern. |
| `capstone-pipeline` | `restricted` | No workloads currently run in this namespace (Kargo itself runs in the `kargo` namespace; the Project CRD manages this namespace). `restricted` is a defense-in-depth floor ensuring any future pod admitted here is hardened by default. Per ROADMAP `auto/capstone-pipeline-psa`. |
| `envoy-gateway-system` | `baseline` | Two pod types share the namespace: the Gateway controller (non-root, `restricted`-compatible) and Envoy proxy data-plane pods (default UID 0 in `gateway-helm` v1.8.0). Flipping to `restricted` risks breaking north-south traffic. `baseline` blocks the most dangerous controls while permitting root UIDs. **Flip condition:** upstream chart explicitly supports non-root proxy pods via `EnvoyProxy.spec.provider.kubernetes.envoyDeployment.pod.securityContext` AND maintainer verifies north-south traffic unaffected after label flip. Per RFC #230 (architect decision 2026-06-19). |
| `lab-demo` | `baseline` | The upstream `jaegertracing/example-hotrod` image runs as root (no `USER` instruction in the Dockerfile). `baseline` blocks privileged containers and host-namespace use while permitting the root UID. **Flip condition:** when the image ships a non-root UID or is superseded by the capstone-built image. Per ROADMAP `auto/pss-np-lab-demo`. |
| `inkless` | `baseline` | The Aiven Inkless broker image (`ghcr.io/aiven/inkless:latest`) runs as root UID 0 — no `USER` directive in the base image. `baseline` blocks privileged containers and host-namespace use while permitting the root UID. **Flip condition:** when `ghcr.io/aiven/inkless` ships with an explicit non-root `USER` directive. Per RFC #257 (architect decision 2026-06-23). |
| `longhorn-system` | `privileged` | longhorn-manager and longhorn-csi-plugin require `SYS_ADMIN`, mount propagation, and host `/dev`. Block storage cannot work under `restricted`. Per ADR-0013 §"PSA profile". |
| `istio-system` | `privileged` | istio-cni runs as a DaemonSet that mutates host CNI config; ztunnel requires `NET_ADMIN`. Both fail under `restricted`. Per ADR-0012 §"PSA profile". (Kiali co-resides in this namespace; no separate `kiali` row needed. Per RFC #288.) |
| `artifactory` | `baseline` | JVM initContainers in `jfrog/artifactory-oss` run as root UID 0 for `chown`; main JVM process runs as UID 1030. `restricted` is not viable without upstream chart changes documenting restricted-compatible initContainers. **Flip condition:** when the upstream `jfrog/artifactory-oss` chart documents restricted-compatible initContainers. Per RFC #287 (architect decision 2026-06-27). |
| `node-exporter` | `privileged` | The `prometheus-node-exporter` DaemonSet mounts the host `/proc` and `/sys` via `hostPath` to read node metrics. `hostPath` volumes are forbidden by **both** `restricted` (Volume Types control) **and** `baseline` (verified against `baseline:latest`/`restricted:latest` on-cluster) — only `privileged` admits them. So it cannot run in the `restricted` `observability` namespace (it sat desired=2/ready=0, rejected at admission on the hostPath volumes), and `baseline` is not sufficient either. `privileged` is the tier `hostPath` requires — same class as `longhorn-system`/`istio-system` — not extra power: the workload stays hardened by its own securityContext (non-root UID 65534, `drop: [ALL]`, `readOnlyRootFilesystem`, seccomp `RuntimeDefault`, `hostPID`/`hostNetwork` false). Given its own namespace so the LGTMP `observability` stack stays `restricted`. **Flip condition:** none expected — host-metrics collection fundamentally requires `hostPath`. |
| `harbor` | `restricted` | Harbor is Go-based; core/registry/jobservice all run as non-root UID 10000; portal uses nginx with a non-root UID in the 1.16.x chart. No host volumes, no special capabilities. Per ADR-0024 / RFC #297 (architect decision 2026-06-30). |
| `cert-manager` | `restricted` | Controller, webhook, and cainjector all default to `runAsNonRoot: true` + `seccompProfile.type: RuntimeDefault` (pod) and `allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]` + `readOnlyRootFilesystem: true` (container) with no chart override — the full `restricted` profile out of the box, verified against the pinned chart's `values.yaml`. Per ADR-0028. |
| `kube-system` | unchanged | k3s-managed; out of scope. |

---

## Staged rollout

| Phase | Scope | Rationale |
|-------|-------|-----------|
| **Pilot** (this ADR) | `capstone` | Small namespace, single Deployment owned by us, dashboards already exist — clean blast radius. |
| **Fan-out** (planner-groomed items) | `argocd`, `observability`, `data`, `lab-gateway`, `moto`, `ack-system` (all `restricted`) | One namespace per executor run. |
| **Carve-out namespaces** | `storage`, `tidb`, `tidb-admin` (`baseline`); `vault` (`baseline`); `longhorn-system`, `istio-system` (`privileged`) | Label-only change (no workload securityContext fan-out). |

---

## Scope & exceptions

**In scope** — every Deployment / StatefulSet / DaemonSet under `gitops/**`
(~28 ArgoCD `Application`s, mix of direct manifests and Helm charts).

**Per-workload field carve-outs (still inside a `restricted` namespace):**

- `readOnlyRootFilesystem: false` for any chart that the executor verifies
  cannot be patched with an `emptyDir` overlay in the current pass — flag in
  the PR, file a follow-up. Default is `true`; this is an explicit exception,
  not the rule.

**Out of scope (this RFC):**

- Sigstore / cosign image signing and admission verification — separate concern.
- Kyverno / OPA Gatekeeper — PSA is the in-tree control; external policy
  engines only if a gap appears.

---

## Files this work touches (pilot)

| Path | Role |
|------|------|
| `docs/decisions/adr-0017-pod-security-standards-restricted.md` | This ADR |
| `gitops/apps/capstone/namespace.yaml` | Explicit `capstone` namespace manifest with four PSA `restricted` labels |
| `gitops/apps/capstone/deployment.yaml` | Pod- and container-level `securityContext` fields; `emptyDir` for write targets |
| `tests/securitycontext.bats` | Clusterless YAML structural tests: deployment sets `runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `readOnlyRootFilesystem: true`, `seccompProfile.type: RuntimeDefault`; namespace carries the four PSA labels |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a carve-out that survives a review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-06-11 — `vault` carve-out kept (audit [#157](https://github.com/tooming/k8s-lab/issues/157))

**Trigger.** `docs/industry/2026-W23-digest.md` → "Vault v2.0.2 — 2026-06-05":
the `cap_ipc_lock` capability is no longer granted to the `vault` binary at build
time, so a Vault configured with `disable_mlock = true` no longer needs
`IPC_LOCK` — which is the sole justification for the `vault: baseline` row above.

**Decision: keep `vault: baseline`.** The lab runs the Vault Helm chart `0.32.0`
on the 1.21.x line (`gitops/platform/vault.yaml`; the unsealer pins
`hashicorp/vault:1.21.2`). The release that drops `cap_ipc_lock` is named only in
the synthetic weekly digest — there is no pinnable chart/image to actually deploy,
so flipping the carve-out now would assert a security posture the running binary
does not have ([ADR-0004](adr-0004-no-fabricated-content.md)). Adding
`disable_mlock = true` to the *current* image in isolation would permit secret
swap-to-disk without the offsetting `restricted` tightening — a net regression —
so it is not done alone either.

**Flip condition (what reopens this).** A real, pinnable Vault chart/image whose
binary no longer holds `cap_ipc_lock` becomes deployable in the lab. The executor
PR is then: bump the Vault chart/image + set `disable_mlock = true`; flip
`gitops/vault/namespace.yaml` PSA labels `baseline → restricted` and add the
standard §Layer 1 `securityContext` (with `emptyDir` for any non-PVC write path);
update the `vault` row above. Until then the 🟢 PSS-labels carve-out fan-out keeps
`vault` at `baseline` so we never ship a carve-out we are about to remove.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Changes land as ArgoCD-synced manifest edits — no `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Defence-in-depth (two-layer enforcement) complements decoupled designs. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Security labels that are silently unenforced would be fabricated safety — this ADR pairs the manifest fields with namespace labels so enforcement is real. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-host lab still gets production-shaped security controls; the recreate-from-code property is unchanged. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | Companion security ADR (pod security controls vs host network controls). The two together express the production defence-in-depth baseline. |
