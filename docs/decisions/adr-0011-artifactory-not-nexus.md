# ADR-0011 — Artifactory as the on-demand artifact registry (not Nexus)

**Status.** Adopted. Decision taken in RFC #58. Manifests pending (next ROADMAP item);
will live in `gitops/platform/artifactory.yaml` (non-auto-synced ArgoCD `Application`)
and brought up with `make artifactory-up`.

---

## Context

The lab's capstone pipeline (RFC #62) requires an in-lab artifact registry: GitLab CI
builds the demo-app container image and pushes it somewhere the cluster can pull from.
Three broad options exist:

| Option | Rationale |
|--------|-----------|
| **Docker Hub / external registry** | No new cluster component, but the lab's charter is "see how a cloud-native platform fits together" — deferring to an external service skips the registry learning objective entirely. |
| **Sonatype Nexus Repository OSS** | Feature-rich, supports Docker + Maven + npm; but the community Helm chart is maintained by a third party (`sonatype/nexus3` on Artifact Hub), adding chart-supply-chain uncertainty. JVM with default heap sizing (≥ 1 GB) and a large on-disk footprint. |
| **JFrog Artifactory OSS** ✅ | Docker-native OCI registry in the free OSS tier; a first-party chart (`jfrog/artifactory-oss` from `https://charts.jfrog.io`); the most widely deployed on-premises registry in the industry → highest learner transfer value. |

Both Nexus and Artifactory are JVM-based and heavy by the lab's standards. The deciding
factors for Artifactory are the **first-party chart** (no third-party supply-chain risk)
and the **industry prevalence** of JFrog as a registry reference implementation.

---

## Decision

Deploy **JFrog Artifactory OSS** as the lab's on-demand artifact registry, using the
**first-party Helm chart** (`jfrog/artifactory-oss` from `https://charts.jfrog.io`).

Artifactory is **on-demand, never auto-synced** (see *12 GB budget* below). The ArgoCD
`Application` lives in `gitops/platform/artifactory.yaml` with no `automated:` block;
users bring it up with `make artifactory-up` and tear it down with `make artifactory-down`.

---

## Why Artifactory over Nexus

| Criterion | Artifactory OSS | Nexus OSS |
|-----------|----------------|-----------|
| **Chart ownership** | First-party (`charts.jfrog.io`) | Third-party community chart on Artifact Hub |
| **Docker / OCI registry** | Yes, free OSS tier | Yes, free OSS tier |
| **Industry prevalence** | Most widely deployed on-premises registry | Common, particularly in Maven/Java shops |
| **Learning-path value** | High — learners encounter JFrog at virtually every enterprise | Moderate |
| **Footprint** | Heavy: JVM, ~1–2 GB heap at startup | Comparable JVM footprint |

Neither option changes the *type* of problem (both are JVM, both are heavy); Artifactory
wins on chart provenance and learner transfer value.

---

## 12 GB budget — the ADR-0001 / ADR-0005 trade-off

The always-on stack already occupies ~7 GB of the 12 GB Colima VM. Artifactory's JVM
allocates ~1–2 GB at startup (heap + off-heap). Running it alongside the always-on
stack leaves insufficient headroom for Istio ambient or Longhorn; it **must not** be
auto-synced.

Pattern (mirrors TiDB operator / cluster / demo):

- ArgoCD `Application` in `gitops/platform/artifactory.yaml` **with no `automated:` block**.
  ArgoCD discovers the Application but does not sync it until the user triggers it.
- `make artifactory-up` triggers the sync + waits for health.
- `make artifactory-down` deletes or suspends the Application to reclaim memory.
- A `bats` test (`tests/platform.bats` or similar) asserts the Application is **not**
  auto-synced (mirrors the `tidb-operator` assertion in `tests/data-layer.bats`).

This is consistent with **ADR-0001** (workloads via ArgoCD, never `helm install`) and
**ADR-0005** (recreate-from-code on a single host — if the PVC is lost, `make artifactory-up`
re-provisions it).

---

## Relationship to the capstone (RFC #62)

The capstone end-to-end pipeline chains:

```
GitLab CI  →  build image  →  push to Artifactory
                               ↓
                         ArgoCD image-updater  →  deploy capstone app
```

All capstone steps in the ROADMAP are **blocked on the Artifactory manifest item** landing
first (the next ROADMAP item after this ADR). Once Artifactory manifests ship:

1. GitLab CI job pushes to `artifactory.127.0.0.1.nip.io` (Envoy HTTPRoute).
2. ArgoCD (`gitops/apps/capstone/`) sources the pipeline-built image.
3. Envoy HTTPRoute and Grafana dashboard wired in subsequent steps.

Vault-stored registry credentials flow to GitLab CI via ESO — no plaintext creds in
`.gitlab-ci.yml` or CI variables.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Artifactory is deployed as an ArgoCD `Application` from the JFrog Helm chart. `helm install` is never run directly. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Single Artifactory instance; the lab accepts this SPOF (see ADR-0005). Production would run clustered Artifactory HA. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | On a single host, HA Artifactory is not viable; the PVC-backed single node is recoverable from code via `make artifactory-up`. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | The Artifactory UI and Docker registry endpoint are exposed via an Envoy `HTTPRoute` (`artifactory.127.0.0.1.nip.io`), like every other lab UI. |

---

## Files (once the manifest item lands)

| Path | Role |
|------|------|
| `gitops/platform/artifactory.yaml` | ArgoCD Application — non-auto-synced; chart `jfrog/artifactory-oss` from `https://charts.jfrog.io` |
| `gitops/artifactory/route.yaml` | Envoy `HTTPRoute` for the Artifactory UI / Docker registry |
| `Makefile` | `artifactory-up` and `artifactory-down` targets |
| `tests/platform.bats` | bats assertion: Artifactory Application has no `automated:` block |
