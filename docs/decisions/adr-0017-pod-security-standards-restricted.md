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
| `vault` | `restricted` | Flipped from `baseline` 2026-07-17 (RFC #478): chart `v0.34.0`'s default Vault `v2.0.3` image no longer holds `cap_ipc_lock`; `disable_mlock = true` is set as the required counterpart. Full history: audit #157 (2026-06-11, kept) → audit #477 (2026-07-17, converted) → this flip. See [§Re-evaluation log](#re-evaluation-log). |
| `kyverno` | `restricted` | Flipped from `baseline` 2026-07-17 (RFC #483): chart `kyverno-chart-3.3.4`'s four controllers already default to the full restricted container securityContext, no override needed. Full history: audit #482 (2026-07-17, converted) → this flip. See [§Re-evaluation log](#re-evaluation-log). |
| `velero` | `restricted` | Controller runs non-root (UID 65534); node-agent DaemonSet uses a per-workload annotation to mount `/var/lib/kubelet/pods` for Kopia FS-backup (matches the node-exporter hostPath carve-out pattern in §"Per-workload field carve-outs"). Per ADR-0021 §"PSA profile" (implementation adopted `restricted`, overriding the initial `baseline` estimate). |
| `argo-rollouts` | `restricted` | Controller and dashboard both run as non-root (UID 65532), no host volumes, no privileged containers. Per ADR-0020 §"NetworkPolicy + PSS". |
| `trivy-system` | `baseline` | Trivy scan-job pods pull and unpack arbitrary OCI layer tarballs, exceeding `restricted`. Operator pod itself is restricted-compliant; chart applies one PSA profile to both. Per ADR-0022 §"PSA profile". Re-evaluate per chart upgrade. |
| `external-secrets` | `restricted` | ESO 2.x controller-manager, cert-controller, and webhook all run as UID 65534 (`nobody`), no host volumes, no special capabilities. Chart supports `global.podSecurityContext` / `global.containerSecurityContext` overrides. Per RFC #229 (architect decision 2026-06-19). |
| `kro` | `restricted` | KRO controller runs as UID 65534 (`nobody`), `readOnlyRootFilesystem: true`, no host volumes, no special capabilities. The chart `valuesObject` in `gitops/platform/kro.yaml` already carries the full hardened `podSecurityContext` + `containerSecurityContext` block — no additional workload patch needed. Per ROADMAP `auto/pss-kro-namespace`. |
| `kargo` | `restricted` | Kargo api/controller/webhooks-server all run as UID 65532 (non-root); no host volumes, no special capabilities. Per ROADMAP `auto/pss-kro-namespace` pattern. |
| `capstone-pipeline` | `restricted` | No workloads currently run in this namespace (Kargo itself runs in the `kargo` namespace; the Project CRD manages this namespace). `restricted` is a defense-in-depth floor ensuring any future pod admitted here is hardened by default. Per ROADMAP `auto/capstone-pipeline-psa`. |
| `envoy-gateway-system` | `baseline` | Two pod types share the namespace: the Gateway controller (non-root, `restricted`-compatible) and Envoy proxy data-plane pods (default UID 0 in `gateway-helm` v1.8.0). Flipping to `restricted` risks breaking north-south traffic. `baseline` blocks the most dangerous controls while permitting root UIDs. **Flip condition:** upstream chart explicitly supports non-root proxy pods via `EnvoyProxy.spec.provider.kubernetes.envoyDeployment.pod.securityContext` AND maintainer verifies north-south traffic unaffected after label flip. Per RFC #230 (architect decision 2026-06-19). |
| `lab-demo` | `baseline` | The upstream `jaegertracing/example-hotrod` image runs as root (no `USER` instruction in the Dockerfile). `baseline` blocks privileged containers and host-namespace use while permitting the root UID. **Flip condition:** when the image ships a non-root UID or is superseded by the capstone-built image. Per ROADMAP `auto/pss-np-lab-demo`. |
| `inkless` | `baseline` | The Aiven Inkless broker image (`ghcr.io/aiven/inkless:latest`) — see [§Re-evaluation log](#re-evaluation-log) 2026-07-18: the pinned upstream Dockerfile now ends `USER appuser` (non-root), but the profile stays `baseline` until the second half of the flip condition is also met. **Flip condition:** BOTH (a) `ghcr.io/aiven/inkless` ships an explicit non-root `USER` directive — met, see log — AND (b) the runtime is verified non-root on a live cluster — outstanding. Per RFC #257 (architect decision 2026-06-23), audit #494 (2026-07-18, kept). |
| `longhorn-system` | `privileged` | longhorn-manager and longhorn-csi-plugin require `SYS_ADMIN`, mount propagation, and host `/dev`. Block storage cannot work under `restricted`. Per ADR-0013 §"PSA profile". |
| `istio-system` | `privileged` | istio-cni runs as a DaemonSet that mutates host CNI config; ztunnel requires `NET_ADMIN`. Both fail under `restricted`. Per ADR-0012 §"PSA profile". (Kiali co-resides in this namespace; no separate `kiali` row needed. Per RFC #288.) |
| `artifactory` | `baseline` | JVM initContainers in `jfrog/artifactory-oss` run as root UID 0 for `chown`; main JVM process runs as UID 1030. `restricted` is not viable without upstream chart changes documenting restricted-compatible initContainers. **Flip condition:** when the upstream `jfrog/artifactory-oss` chart documents restricted-compatible initContainers. Per RFC #287 (architect decision 2026-06-27). |
| `node-exporter` | `privileged` | The `prometheus-node-exporter` DaemonSet mounts the host `/proc` and `/sys` via `hostPath` to read node metrics. `hostPath` volumes are forbidden by **both** `restricted` (Volume Types control) **and** `baseline` (verified against `baseline:latest`/`restricted:latest` on-cluster) — only `privileged` admits them. So it cannot run in the `restricted` `observability` namespace (it sat desired=2/ready=0, rejected at admission on the hostPath volumes), and `baseline` is not sufficient either. `privileged` is the tier `hostPath` requires — same class as `longhorn-system`/`istio-system` — not extra power: the workload stays hardened by its own securityContext (non-root UID 65534, `drop: [ALL]`, `readOnlyRootFilesystem`, seccomp `RuntimeDefault`, `hostPID`/`hostNetwork` false). Given its own namespace so the LGTMP `observability` stack stays `restricted`. **Flip condition:** none expected — host-metrics collection fundamentally requires `hostPath`. |
| `harbor` | `restricted` | Harbor is Go-based; core/registry/jobservice all run as non-root UID 10000; portal uses nginx with a non-root UID in the 1.16.x chart. No host volumes, no special capabilities. Per ADR-0024 / RFC #297 (architect decision 2026-06-30). |
| `cert-manager` | `restricted` | Controller, webhook, and cainjector all default to `runAsNonRoot: true` + `seccompProfile.type: RuntimeDefault` (pod) and `allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]` + `readOnlyRootFilesystem: true` (container) with no chart override — the full `restricted` profile out of the box, verified against the pinned chart's `values.yaml`. Per ADR-0028. |
| `keda` | `restricted` | Operator, metrics server, and admission webhooks all default to `runAsNonRoot: true` (pod) and `allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]` + `readOnlyRootFilesystem: true` + `seccompProfile.type: RuntimeDefault` (container) with no chart override — the full `restricted` profile out of the box, verified against the pinned chart's `values.yaml`. Per ADR-0029. |
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

### 2026-07-17 — `vault` carve-out re-audited, converted to RFC (audit [#477](https://github.com/tooming/k8s-anywhere/issues/477))

**Trigger.** Unlike the 2026-06-11 audit's trigger (a synthetic weekly digest
entry with no pinnable artifact), this trigger was verified directly against two
real upstream release pages: `hashicorp/vault` release
[`v2.0.2`](https://github.com/hashicorp/vault/releases/tag/v2.0.2) (2026-06-05)
— changelog states verbatim *"containers: Remove `cap_ipc_lock` capability on
`vault` at build time... Vault in containers will no longer be able to call
`mlock()`"* and recommends `disable_mlock = true` — and `hashicorp/vault-helm`
release `v0.34.0` (2026-07-02), a real currently-latest-stable chart whose
default server image ships that Vault version (`v0.33.0`, 2026-06-08, already
defaulted to `2.0.2`).

**Decision: Convert.** The 2026-06-11 flip condition above is now met by a real,
pinnable chart release, not a digest claim. Actioned as
[RFC #478](https://github.com/tooming/k8s-anywhere/issues/478), which carries the
concrete executor spec (chart bump `0.32.0 → 0.34.0`, `disable_mlock = true`,
PSA labels `baseline → restricted`, standard §Layer 1 `securityContext`, unsealer
image bump). The `vault` row above stays `baseline` until that RFC's executor PR
actually lands the change — this log entry records the decision, not the change
itself (ADR-0004: never assert a posture the running/committed manifests don't
yet have).

### 2026-07-17 — `vault` carve-out flipped to `restricted` (RFC #478 executor PR)

**Change landed.** `gitops/platform/vault.yaml`: chart `0.32.0 → 0.34.0`, `disable_mlock = true`
added to the standalone config, `server.statefulSet.securityContext.pod`/`.container`
set to the standard §Layer 1 block, an explicit `tmp` `emptyDir` added (mounted at
`/tmp`, alongside the chart's own unconditional `home` `emptyDir` at `/home/vault`)
for `readOnlyRootFilesystem: true`. `gitops/vault/namespace.yaml`: all four PSA
labels flipped `baseline → restricted`. `gitops/vault/unsealer.yaml`: image bumped
`hashicorp/vault:1.21.2 → hashicorp/vault:2.0.3`, and — since it also runs in this
now-`restricted` namespace — given its own pod/container `securityContext` plus
`home`/`tmp` `emptyDir` mounts (it had none before; the namespace was `baseline`
so it passed without one). The `vault` row above now reads `restricted`.

**Caveat (ADR-0004).** This environment is remote and clusterless — whether Vault
actually starts cleanly under `restricted` + `disable_mlock` + `readOnlyRootFilesystem`
is not verifiable here. `make ci` (structural/`kustomize`/bats) is green; runtime
verification is the maintainer's to confirm on the live cluster. If Vault fails to
start, the rollback is: revert this commit (chart pin, PSA labels, unsealer image
all revert together) — ArgoCD self-heals within its sync interval, no data loss
(the `dataStorage` PVC is untouched by any of these changes).

### 2026-07-17 — `kyverno` carve-out re-audited, converted to RFC (audit [#482](https://github.com/tooming/k8s-anywhere/issues/482))

**Trigger.** ADR-0019's original `baseline` justification — "controllers run as
non-root but mount webhook TLS via `fsGroup`" — was checked against the actual
pinned chart tag (`kyverno-chart-3.3.4`, not `main`). No hostPath volume and no
webhook-TLS-as-filesystem-volume was found in any of the four controllers'
Deployments (`admission-controller`, `background-controller`,
`cleanup-controller`, `reports-controller`) — TLS is read via the K8s API by
Secret name, not mounted. Kyverno's own official docs
(`kyverno.io/docs/installation/platform-notes/`) state the chart's default
securityContext "conforms to the upstream Pod Security Standards' restricted
profile" (the only documented incompatibility is OpenShift Security Context
Constraints, irrelevant to this plain-k3d/k3s lab). Independently confirmed
against `kyverno-chart-3.3.4`'s real `values.yaml`: all four controllers already
default to `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
`capabilities.drop: [ALL]`, `readOnlyRootFilesystem: true`,
`seccompProfile.type: RuntimeDefault` at the container level.

**Decision: Convert.** Unambiguous (official upstream docs + independently
verified pinned-tag chart source) and groundable now — no chart bump needed,
since `3.3.4` is already what this repo runs. Actioned as
[RFC #483](https://github.com/tooming/k8s-anywhere/issues/483). Given Kyverno's
higher blast radius (cluster-wide admission controller, unlike vault's
single-namespace secrets backend), the RFC requires the executor to
independently re-verify the chart's rendered securityContext before flipping
the namespace label — not simply trust this audit's citation — and to flag
(not force) the flip if any gap surfaces. The `kyverno` row above stays
`baseline` until that RFC's executor PR actually lands the change.

### 2026-07-17 — `kyverno` carve-out flipped to `restricted` (RFC #483 executor PR)

**Independent re-verification (per RFC #483's requirement).** Re-fetched the
pinned `kyverno-chart-3.3.4` tag's `values.yaml` fresh (not reusing the
architect cycle's read): all four controllers (`admissionController`,
`backgroundController`, `cleanupController`, `reportsController`) confirmed to
default `container.securityContext` to `runAsNonRoot: true`,
`allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`,
`readOnlyRootFilesystem: true`, `seccompProfile.type: RuntimeDefault`, and
`hostNetwork: false`; the `sigstoreVolume` default is `emptyDir: {}` (a
restricted-permitted volume type); no top-level `securityContext` override
exists. No hostPath or other restricted-incompatible volume/host-namespace
usage anywhere.

**Gap found and resolved — self-protection, not a manifest change.** This
repo's own `require-pod-security-restricted` ClusterPolicy backstop checks
`runAsNonRoot`/`seccompProfile` at the **pod** level (a deliberate choice per
that policy's own comment, stricter than plain K8s PSA which accepts either
level) — and the chart's `podSecurityContext` is empty for all four
controllers, container-level only. This looked like a real gap. Resolved by
checking Kyverno's own webhook self-protection: `config.excludeKyvernoNamespace`
defaults to `true` in the pinned chart, which excludes the `kyverno` namespace
from Kyverno's own generated webhooks and `resourceFilters` — so
`require-pod-security-restricted` (a Kyverno ClusterPolicy, enforced via
Kyverno's own webhook) never actually evaluates against pods in the `kyverno`
namespace itself, regardless of the pod-vs-container-level distinction. The
**built-in Kubernetes PSA** (the namespace-label mechanism actually being
flipped here) is a separate, independent admission path that accepts
container-level settings for `restricted` — already satisfied. No
`valuesObject` override was added (matches this repo's existing precedent for
`keda`/`cert-manager`: no carve-out when the chart already complies).

**Caveat (ADR-0004).** This environment is remote and clusterless — whether
Kyverno's admission webhook stays healthy under `restricted` on a live cluster
is not verifiable here; the self-protection exclusion is documented Kyverno
behavior (`config.excludeKyvernoNamespace`, verified against the pinned chart's
real `values.yaml`), not an assumption, but the maintainer should watch cluster
admission health closely after this syncs given Kyverno's blast radius.
Rollback: revert the namespace label commit — ArgoCD self-heals within its sync
interval; no other component changed.

### 2026-07-18 — `inkless` carve-out kept, evidence updated (audit [#494](https://github.com/tooming/k8s-anywhere/issues/494))

**Trigger.** RFC #257's original flip condition (stated in full in the RFC #257
issue body, but abbreviated in the `inkless` row above to only its first half):
"when `ghcr.io/aiven/inkless` ships with an explicit non-root `USER` directive
AND the runtime is verified non-root on a live cluster." Checked the real
upstream source (`github.com/aiven/inkless`, `docker/inkless/Dockerfile`) at the
latest release tag (`inkless-release-0.44`): the final build stage now ends
`USER appuser` (after `adduser -D --shell /bin/bash appuser` and `chown
appuser:appuser`/`chown appuser:root` on every directory the process writes —
`/usr/logs`, `/opt/kafka`, `/var/lib/kafka`, `/etc/kafka/secrets`, `/etc/kafka`).
`git log` on that file shows this has been true since commit `454eef1c53`,
dated 2026-04-01 — not a brand-new change, just not previously checked against
the real source rather than the digest-era assumption RFC #257 was written
against.

**Decision: keep `inkless: baseline`, condition partially met.** The Dockerfile
half of the two-part flip condition is now satisfied by a real, pinnable
upstream commit — but the second half ("verified non-root on a live cluster")
cannot be satisfied from this remote clusterless environment for an on-demand
heavy component this session cannot bring up. Flipping the namespace profile
on Dockerfile evidence alone, without confirming the actual running container
behaves correctly under the non-root UID (e.g., whether the entrypoint script
that runs before `USER appuser` takes effect still needs root for something
this Dockerfile read didn't surface), would assert a live posture this session
has not verified (ADR-0004). Also corrected the `inkless` row's flip-condition
text above, which had dropped RFC #257's live-verification requirement when
originally transcribed from the RFC into the table — restoring the full
two-part condition so a future audit doesn't repeat this partial reading.

**Flip condition (unchanged in substance, now stated in full in the row
above).** Both: (a) `ghcr.io/aiven/inkless` ships an explicit non-root `USER`
directive — **met**, see above; (b) the maintainer (or a future session with
live-cluster access) verifies the Inkless broker actually starts and operates
correctly running as that non-root user on a real cluster. When (b) is also
met, the executor PR is: flip `gitops/inkless/namespace.yaml`'s four PSA labels
`baseline → restricted`; add a `securityContext`/`podSecurityContext`
override to `gitops/inkless/inkless-statefulset.yaml` matching whichever key
the pinned Inkless/Kafka Helm chart (or plain manifest, if not chart-based)
actually reads — **verify against the actual manifest/chart source before
assuming a key name**, per the key-path-mismatch bugfix this same run already
found and fixed for four other components (kube-state-metrics, node-exporter,
grafana, alloy — see `docs/done/2026-07-18-fix-podsecuritycontext-key-mismatch.md`).

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Changes land as ArgoCD-synced manifest edits — no `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Defence-in-depth (two-layer enforcement) complements decoupled designs. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Security labels that are silently unenforced would be fabricated safety — this ADR pairs the manifest fields with namespace labels so enforcement is real. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-host lab still gets production-shaped security controls; the recreate-from-code property is unchanged. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | Companion security ADR (pod security controls vs host network controls). The two together express the production defence-in-depth baseline. |
