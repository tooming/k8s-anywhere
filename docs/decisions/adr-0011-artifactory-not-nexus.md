# ADR-0011 — Artifactory as the on-demand artifact registry (not Nexus)

**Status.** Adopted. Decision recorded from RFC #58. Manifests and `make` targets
land in the follow-on item; this ADR records the *why* before the *how*.

---

## Context

The capstone learning path (RFC #62) requires an **in-lab artifact registry** to close
the GitLab CI → in-cluster ArgoCD loop: a CI pipeline builds an image, pushes it to the
registry, and ArgoCD (or Argo Image Updater) deploys it. Without an in-lab registry the
loop has an external dependency that breaks the lab's offline-first, recreate-from-code
charter bar.

Two well-known, self-hostable OSS registries were on the table:

| Option | OCI / Docker registry | Other repo types | Notes |
|--------|----------------------|------------------|-------|
| **Sonatype Nexus Repository OSS** | Yes (Docker hosted + proxy) | Maven, npm, PyPI, raw, Helm | Mature, but the free OSS build is single-node only; the Helm chart (`sonatype/nexus-repository-manager`) is community-maintained and has had repeated breaking changes; footprint is ~2 GB JVM heap minimum. |
| **JFrog Artifactory OSS** ✅ | Yes (Docker local, remote, virtual) | Maven, npm, Helm, raw, generic | Single well-known OSS chart maintained by JFrog (`jfrog/artifactory-oss` from `https://charts.jfrog.io`); learning value matches real-world usage; footprint is heavy (~1–2 GB JVM) but manageable as an on-demand component. |

Both are JVM-based and heavy; neither is suitable for the always-on set.

---

## Decision

Use **JFrog Artifactory OSS** as the lab's on-demand artifact registry.

**Chart:** `artifactory-oss` from the JFrog Helm repository
(`https://charts.jfrog.io`), chart version pinned at deploy time.

**Not Nexus** because:
1. The JFrog chart is first-party and stable; the Nexus chart is community-maintained
   with a history of breaking updates and missing OCI support in the OSS tier.
2. Artifactory is the industry standard most learners encounter in production —
   higher transfer value from this lab.
3. Artifactory OSS handles Docker (OCI) natively in the free tier; Nexus OSS requires
   a separate hosted Docker repository configuration that has drifted across versions.
4. The JFrog chart ships sane defaults for a single-replica lab deployment, including a
   bundled Derby database so no external PostgreSQL dependency is needed for the OSS tier.

---

## Footprint and budget constraint

Artifactory OSS is a **heavy component** — the JVM allocates ~1–2 GB at startup and the
image is ~800 MB. Running it alongside the always-on stack (~7 GB for the full LGTMP
observability set + ArgoCD + Vault + GitLab) would push the 12 GB Colima VM to or beyond
its limit.

**Consequence: Artifactory is on-demand, never auto-synced.**

The follow-on manifest item (`gitops/platform/artifactory.yaml`) will be an ArgoCD
`Application` **without an `automated:` sync policy** — identical to the TiDB pattern
(`gitops/platform/tidb-operator.yaml`). It is brought up with `make artifactory-up` and
torn down with `make artifactory-down`.

This is the ADR-0001 + ADR-0005 combined trade-off:
- **ADR-0001**: workloads are ArgoCD Applications, never `helm install`; Artifactory is
  no exception.
- **ADR-0005**: on a single host, recoverability-over-HA is the correct posture; the
  on-demand pattern gives the user full control of when the heavy component runs.

---

## Relationship to the capstone (RFC #62)

The capstone end-to-end pipeline (RFC #62) is **blocked on Artifactory landing first**:

```
GitLab CI  →  build demo image  →  push to Artifactory  →  Argo Image Updater  →  ArgoCD deploy
```

Artifactory provides the Docker registry endpoint the CI job pushes to. The capstone
items in the ROADMAP are therefore sequenced: Artifactory manifests must merge before
any capstone CI step can be wired.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Artifactory is deployed as an ArgoCD `Application` from the JFrog Helm chart; never via `helm install`. The `Application` has no `automated:` block so ArgoCD manages it without auto-syncing. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Single-replica deployment accepted on a single host. Production usage would run Artifactory behind a PostgreSQL HA backend with HA-proxy — noted in the follow-on manifest's docs. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | On a single host, a second Artifactory replica provides no benefit; the on-demand bring-up / tear-down pattern (recreate-from-code) is the correct mitigation for a lab. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | The Artifactory UI is exposed via an Envoy `HTTPRoute` (`artifactory.127.0.0.1.nip.io`) — same pattern as every other lab UI. The Docker registry endpoint (`artifactory-registry.127.0.0.1.nip.io`) gets its own route for CI push/pull. |

---

## Files (to be created by the follow-on manifest item)

| Path | Role |
|------|------|
| `gitops/platform/artifactory.yaml` | ArgoCD `Application` — JFrog Helm chart, **no `automated:`** |
| `gitops/platform/artifactory/` | Helm values overlay (resource limits, derby DB, single replica) |
| `Makefile` targets `artifactory-up` / `artifactory-down` | Bring up / tear down without auto-sync |
| `tests/artifactory.bats` | Assert the Application has no `automated:` sync policy |
