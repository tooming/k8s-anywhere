# ADR-0024 — Harbor as the on-demand artifact registry (supersedes ADR-0011)

**Status.** Adopted (architect decision, RFC #297). **Supersedes
[ADR-0011](adr-0011-artifactory-not-nexus.md).** Manifests pending — to be groomed from
RFC #297 into executor items. The trimmed minimal-profile footprint **must be measured and
shown to fit the 12 GB budget on-demand before the migration is considered done** — that
measurement is the go/no-go acceptance gate (see *Minimal profile & the 12 GB gate*), not a
foregone conclusion. Per ADR-0004 this ADR records the **decision and direction only**;
nothing here asserts Harbor is deployed or running.

---

## Context

[ADR-0011](adr-0011-artifactory-not-nexus.md) chose **JFrog Artifactory OSS** over Sonatype
Nexus as the lab's on-demand OCI artifact registry, on two decisive grounds: a **first-party
Helm chart** (`jfrog/artifactory-oss`) and **industry prevalence**. It explicitly conceded
the downsides — Artifactory is *"heavy: JVM, ~1–2 GB heap at startup"* — and ruled it
**non-auto-synced**, because the JVM allocation would leave insufficient headroom on the
12 GB Colima VM for Istio ambient or Longhorn.

ADR-0011 only ever evaluated Artifactory against **Nexus**. **Harbor was never considered.**
Revisiting it now is therefore a genuinely new option, not a re-litigation of the rejected
Nexus choice. Since ADR-0011 was written the case shifted enough to act:

- **Harbor is the reference CNCF self-hosted registry.** It graduated in the CNCF in 2020
  and is the dominant self-hosted OCI registry in CNCF-shaped shops — the same "highest
  learner transfer value" argument ADR-0011 used for JFrog now points at Harbor for a
  CNCF-native platform.
- **The lab is CNCF-native everywhere else.** Cilium, Istio ambient, Kyverno, Argo, Velero,
  and Trivy Operator are all CNCF projects. Artifactory is the one single-vendor,
  JVM-based enterprise outlier carried mainly for transfer value.
- **The pain points ADR-0011 named are exactly what Harbor removes** — JVM weight, an OSS
  feature wall (replication and several repo types are gated behind paid Pro/Enterprise),
  and single-vendor governance.

| Option | Rationale |
|--------|-----------|
| **Stay on Artifactory OSS** | Already wired in, but keeps the JVM weight, the baseline-only PSS carve-out (RFC #287 — JVM init containers run as root UID 0), the OSS feature walls, and single-vendor governance. |
| **Sonatype Nexus** | Already rejected by ADR-0011 (third-party community chart). Not reopened here. |
| **Harbor (CNCF graduated)** ✅ | Go runtime (no JVM); first-party `goharbor/harbor` chart; Apache-2.0 with one free edition (no Pro feature walls); CNCF-graduated, vendor-neutral; OCI-native, cosign/notation aware. |

---

## Decision

Adopt **Harbor** as the lab's on-demand OCI artifact registry, deployed by ArgoCD (ADR-0001)
as a **non-auto-synced** `Application` from the **first-party `goharbor/harbor` Helm chart**,
run as a **minimal profile**, with registry storage backed by **Garage S3 (ADR-0002)**.
Retire the Artifactory manifests as part of grooming RFC #297.

Harbor keeps ADR-0011's two decisive wins — a **first-party chart** and **industry
prevalence** (Harbor is the dominant self-hosted CNCF registry) — while removing the JVM
weight, the OSS feature walls, and the single-vendor governance risk.

Harbor stays **on-demand by default** (mirrors ADR-0011's 12 GB budget reasoning): a
`gitops/platform/harbor.yaml` `Application` with **no `automated:` block**, brought up with
`make harbor-up` and town down with `make harbor-down`. It is promoted to always-on **only
if** the minimal profile measures light enough to stay resident — a decision deferred until
after measurement, never assumed.

---

## Why Harbor over Artifactory

| Criterion | Harbor | Artifactory OSS |
|---|---|---|
| **Runtime** | Go (multi-component, no JVM) | JVM, ~1–2 GB heap at startup |
| **Footprint** | Lighter; core+registry+jobservice tunable (verify, don't assume) | Heavy (ADR-0011's own words) |
| **Licensing** | Apache 2.0 — one free edition, no Pro feature walls | Free OSS tier vs. paid Pro/Enterprise (replication, repo types gated) |
| **Chart ownership** | First-party (`goharbor/harbor`) | First-party (`charts.jfrog.io`) — parity |
| **Governance** | CNCF **graduated**, vendor-neutral | Single-vendor (JFrog) |
| **OCI / Docker registry** | OCI-native, cosign/notation aware | Yes (OSS tier) |
| **Stack alignment** | CNCF-native, like Cilium/Istio/Kyverno/Argo | Enterprise-vendor outlier |
| **PSS profile** | Plausibly `restricted` (Go, non-root) → tightening vs. baseline | `baseline` only — JVM init containers run as root UID 0 (RFC #287) |

Replacing a JVM service with a Go one also lets the `harbor` namespace target **PSS
`restricted` (ADR-0017)** instead of the `baseline` carve-out RFC #287 conceded for
Artifactory's root-running init containers — advancing the hardening track rather than
carrying a permanent baseline exception.

---

## Minimal profile & the 12 GB gate

Harbor ships several components (core, registry, jobservice, portal, plus optional
trivy/notary/redis/db). The lab runs a **deliberately trimmed profile**:

- **Disable bundled Trivy** — the lab already scans cluster-wide via **Trivy Operator
  (ADR-0022)**; running two scan paths is redundant.
- **Disable Notary** — out of scope for the first cut (OCI pull/push only).
- **Point at existing platform services where practical** — a shared Postgres rather
  than bundling Harbor's own, where the chart allows it. **Redis is the exception**:
  reusing the platform **Valkey (ADR-0018)** was the original intent but doesn't
  render under ArgoCD (the chart's `existingSecret` path needs Helm `lookup()`, which
  is always nil outside a live `install`/`upgrade` — see [ADR-0018's 2026-07-21 log
  entry](adr-0018-valkey-not-redis.md#2026-07-21--harbors-own-cache-scoped-exception-bundled-redis-photon-not-valkey-632)).
  Harbor runs its own bundled `redis-photon` instead; this is scoped to Harbor's own
  cache and doesn't reopen ADR-0018.

**Whether this trimmed profile actually beats Artifactory's 1–2 GB on this VM is an
acceptance gate, not a foregone conclusion.** The measured footprint of the running minimal
Harbor is recorded in the `docs/done/` entry and must be confirmed to fit the 12 GB budget
on-demand before the migration is "done". If it does not, the migration is re-scoped or
halted — the decision to *adopt Harbor* stands, but the *go-live* is gated on the number.

---

## Relationship to the capstone (RFC #62)

The capstone end-to-end pipeline is unchanged in shape; only the registry host moves:

```
GitLab CI  →  build image  →  push to harbor.127.0.0.1.nip.io   (was artifactory.…)
                               ↓
                         ArgoCD image flow  →  deploy capstone app
```

GitLab CI pushes to `harbor.127.0.0.1.nip.io` instead of `artifactory.127.0.0.1.nip.io`;
the ArgoCD image flow is unchanged. Registry credentials still flow from Vault via ESO —
no plaintext creds in CI. Out of scope for the first cut: any non-registry Harbor feature
(signing enforcement, replication to remote registries).

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Harbor is an ArgoCD `Application` from the `goharbor/harbor` chart; no imperative `helm install`. |
| [ADR-0002](adr-0002-garage-not-minio.md) | Harbor registry storage targets Garage S3; egress stays TCP 3900 to `storage`. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single on-demand Harbor; recover-from-code via `make harbor-up`, like every other on-demand component. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Harbor UI + registry endpoint exposed via an Envoy `HTTPRoute` (`harbor.127.0.0.1.nip.io`). |
| [ADR-0011](adr-0011-artifactory-not-nexus.md) | **Superseded.** ADR-0011 chose Artifactory OSS; this ADR records the explicit switch to Harbor and the reasoning. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Target `restricted` for the `harbor` namespace if the chart renders non-root; the old `artifactory → baseline` row is removed. |
| [ADR-0018](adr-0018-valkey-not-redis.md) | Platform Valkey reuse doesn't render under ArgoCD (Helm `lookup()` is nil in `helm template`); Harbor runs its own bundled `redis-photon` instead as a scoped exception — see ADR-0018's 2026-07-21 log entry. |
| [ADR-0022](adr-0022-trivy-operator-supply-chain.md) | Bundled Harbor Trivy is **disabled** — scanning is already cluster-wide via Trivy Operator; one scan path, not two. |

---

## Files (once the manifest item lands — groomed from RFC #297)

| Path | Role |
|------|------|
| `gitops/platform/harbor.yaml` (+`harbor-extras.yaml`) | ArgoCD Application — non-auto-synced; chart `goharbor/harbor`, minimal profile (bundled Trivy/Notary disabled) |
| `gitops/harbor/route.yaml` | Envoy `HTTPRoute` for the Harbor UI / OCI registry (`harbor.127.0.0.1.nip.io`) |
| `Makefile` | `harbor-up` / `harbor-down` targets; `artifactory-up` / `artifactory-down` removed |
| `tests/platform.bats` | bats assertion: Harbor Application has no `automated:` block (on-demand) |

The Artifactory manifests (`gitops/platform/artifactory.yaml`, `artifactory-extras.yaml`,
`gitops/artifactory/route.yaml`), the `artifactory` Make targets, the `artifactory → baseline`
PSS row, and the `artifactory` NetworkPolicy/appset entries are decommissioned as part of the
same grooming, once Harbor lands and the footprint gate is met.
