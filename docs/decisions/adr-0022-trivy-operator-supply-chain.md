# ADR-0022 — Trivy Operator for continuous vulnerability + SBOM scanning

**Status.** Adopted. Decision taken by the architect routine in this RFC. Always-on
component. CHARTER **Objective O1** (one of four Tier 1 next-wave components,
due 2026-12-31) and covers CHARTER goal *supply-chain security end-to-end
(Trivy continuous scanning + SBOMs)*.

---

## Context

CHARTER Goals name *supply-chain security end-to-end (cosign signing in CI,
Kyverno verifyImages on admit, continuous Trivy scanning + SBOMs)* as the
target end-state. ADR-0019 (Kyverno) covers the admission-side of that triad;
this ADR covers the *in-cluster, continuous* side: every running workload has
a fresh CVE report and SBOM, regenerated as new vulnerabilities are
disclosed, without ad-hoc CLI runs.

Trivy is the dominant OSS scanner (Aqua Security project, CNCF incubating).
The container-image scanning CLI (`trivy image`) is widely used in CI, but
this ADR is about the **operator** — the in-cluster controller that watches
workloads, schedules scan jobs, and emits CRs.

---

## Decision

Adopt **Trivy Operator** as the lab's always-on continuous vulnerability +
SBOM scanner, using the **official Helm chart**
(`aqua/trivy-operator` from `https://aquasecurity.github.io/helm-charts/`).

### Chart + version

- **Chart:** `aqua/trivy-operator` v0.30.x (latest stable at executor pickup
  time; pin in the Application). Trivy CLI version v0.68.x.
- **Source:** `https://aquasecurity.github.io/helm-charts/`
- **Namespace:** `trivy-system` (new namespace; PSA label `baseline` —
  scan-job pods pull and unpack arbitrary OCI artifacts which needs broader
  filesystem access than `restricted` allows; controller itself is
  `restricted`-compatible but the chart applies one profile to both).

### Footprint controls (12 GB budget)

```yaml
operator:
  resources: { limits: { memory: 256Mi } }
trivy:
  resources: { requests: { memory: 128Mi }, limits: { memory: 512Mi } }
  storageClassName: ""           # use default; ephemeral on local-path
  storageSize: "5Gi"             # vuln-DB cache PVC
nodeCollector:
  enabled: true                  # for k8s-node CVE reports
  resources: { limits: { memory: 64Mi } }
```

Steady-state: ~300-450 MiB (operator + cached vuln-DB). Scan jobs are
ephemeral — the operator schedules them, they run for ~30-90s, exit.

### CRs the operator emits

The operator watches every Deployment/StatefulSet/DaemonSet/CronJob and emits
one CR per container per workload:

| CR | What it captures |
|----|-----------------|
| `VulnerabilityReport` | Per-container CVE list with severity, package, fix version (real `trivy` output) |
| `ConfigAuditReport` | Pod-spec compliance against built-in checks (e.g. `runAsNonRoot`, `readOnlyRootFilesystem`) — complements ADR-0017 with continuous audit |
| `ExposedSecretReport` | Detected hard-coded secrets in container images |
| `SbomReport` | CycloneDX SBOM per container — enables CHARTER goal *Trivy SBOMs* |
| `ClusterComplianceReport` | NSA / CIS / PCI cluster-wide compliance roll-up |
| `InfraAssessmentReport` | k8s-node config audit (kubelet, audit logs, file perms) |

Enable in the chart with:

```yaml
operator:
  vulnerabilityScannerEnabled: true
  configAuditScannerEnabled: true
  rbacAssessmentScannerEnabled: true
  exposedSecretScannerEnabled: true
  sbomGeneration: true              # SbomReports — CHARTER goal
  clusterComplianceEnabled: true
```

### Scope: which namespaces are scanned

The operator scans every namespace by default. Carve-out to keep the
cache+CR count manageable on a single node:

```yaml
operator:
  excludeNamespaces: kube-system,kube-public,kube-node-lease
  targetNamespaces: ""            # empty = all but excludes above
```

`kube-system` is excluded because k3s-managed workloads aren't under lab
control (ADR-0017 also leaves `kube-system` unchanged). Lab namespaces under
`gitops/` are all in-scope.

### Observability

Trivy Operator exposes Prometheus metrics on `:8080/metrics`. Add Alloy
`prometheus.scrape "trivy-operator"`. Dashboard
`grafana/dashboards/lab-trivy.json`: CVE-by-severity counts per namespace
(real `trivy_image_vulnerabilities` gauge), top-10 vulnerable workloads,
config-audit pass/fail per workload, scan-job duration p95, operator
reconcile rate. SBOMs are CR-shaped, not metric-shaped — a separate panel
shows SbomReport count per namespace as a stat.

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/trivy-system/networkpolicy/` (ADR-0016).
  Allows: ingress TCP 8080 from `observability` (metrics scrape); egress
  TCP 443 to a configurable vuln-DB mirror — by default, the chart pulls
  from `ghcr.io/aquasecurity/trivy-db` (cluster egress, see CONSTRAINTS).
  Egress to kube-apiserver via baseline.
- PSA label `baseline` (per chart constraint above).

### Vuln-DB mirror (lab-realistic constraint)

The default Trivy vuln-DB lives at `ghcr.io/aquasecurity/trivy-db` (~80 MiB,
refreshed every 6h). On a localhost lab this still works (cluster has
outbound HTTPS) but it's the only continuous egress dependency added by
this ADR — record it explicitly so a future "fully offline lab" RFC knows
where the bytes go.

---

## Why Trivy Operator (not alternatives)

- **De-facto in-cluster CNCF scanner.** Trivy is the most widely-deployed
  Kubernetes CVE scanner; the operator is the upstream-supported
  controller. Falco Sidekick + Falcoctl is an alternative but is focused on
  runtime threat detection, not image-scanning + SBOMs.
- **First-class SBOM generation.** Trivy emits CycloneDX-format SBOMs as
  `SbomReport` CRs out of the box — directly serves the CHARTER goal.
  Grype-Operator (Anchore) doesn't ship as a chart of equivalent maturity.
- **One scanner end-to-end.** The same Trivy version that runs in the
  capstone CI build (`.gitlab-ci.yml`) for pre-flight scanning runs
  in-cluster; vuln-DB and findings are consistent.
- **CNCF incubating; Aqua Security is the maintainer** — long-term
  project-risk is low.

---

## Scope & exceptions

**In scope** — continuous CVE scanning, config-audit, exposed-secret
detection, SBOM generation, cluster-compliance reports for every lab
namespace under `gitops/`.

**Out of scope (this RFC):**

- Wiring Trivy findings into Kyverno admission decisions (e.g. "reject any
  image with a HIGH CVE"). Possible once both engines are live but is a
  separate policy decision — file a follow-up RFC once the noise level is
  understood.
- Pushing SBOMs to an external registry / SLSA attestation flow.
- Runtime threat detection (eBPF-based syscall monitoring) — that is the
  Falco / Tetragon space, separate RFC if needed.
- Manual scan triggers — operator schedules on its own cadence; no `make
  trivy-scan` target.

---

## Per-namespace profile update (ADR-0017 amendment)

ADR-0017's per-namespace profile table gains one row:

| Namespace | PSA profile | Reason |
|-----------|-------------|--------|
| `trivy-system` | `baseline` | Scan-job pods pull and unpack arbitrary OCI artifacts; chart applies one profile to operator + scan jobs. Re-evaluate per chart upgrade. |

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0022-trivy-operator-supply-chain.md` | This ADR |
| `gitops/platform/trivy-operator.yaml` | Auto-synced ArgoCD `Application` |
| `gitops/trivy-system/networkpolicy/kustomization.yaml` | Default-deny overlay |
| `gitops/platform/observability-alloy.yaml` | New `trivy-operator` scrape job |
| `grafana/dashboards/lab-trivy.json` | Real-metric dashboard (Objective O5) |
| `tests/trivy-operator.bats` | Clusterless tests: Application shape, scanner toggles set, scrape job present, dashboard exists |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Operator lands as an ArgoCD `Application`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Decoupled: operator + scan jobs + vuln-DB cache PVC are separate. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard reads real `trivy_*` metrics + counts live CRs. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single operator replica; recreate from manifest. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `trivy-system` namespace gets default-deny during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Adds `trivy-system: baseline` to the per-namespace profile table. ConfigAuditReports continuously audit pod-spec compliance with ADR-0017 — a useful drift signal. |
| [ADR-0019](adr-0019-kyverno-admission-engine.md) | Companion supply-chain ADR (Kyverno = admission-side, Trivy = continuous-scan side). Possible future RFC merges the two via a Kyverno policy that consults `VulnerabilityReport` severity. |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-28 — March 2026 Trivy supply-chain compromise (CVE-2026-33634) kept, not exposed (audit #773)

**Trigger.** A threat actor published a malicious `trivy` binary `v0.69.4`
release and force-pushed compromised tags to `aquasecurity/trivy-action` and
`aquasecurity/setup-trivy` in March 2026.

**Decision: Keep.** Not affected on either exposure path: the pinned chart
(`gitops/platform/trivy-operator.yaml`'s `targetRevision: 0.34.0`, operator
`appVersion: 0.32.0`) has no `trivy.image.tag` override, so the embedded
scanner defaults to the chart's own pinned tag (`0.72.0`, verified against the
chart's real `values.yaml`) — a later, unaffected release; and this repo's
`.gitlab-ci.yml` has zero references to `trivy-action`/`setup-trivy`, so the
CI pipeline was never exposed to the compromised GitHub Actions. **Flip
condition:** a `trivy.image.tag` override is ever added pointing at `v0.69.4`
specifically, or `trivy-action`/`setup-trivy` is ever adopted in CI without
pinning to a post-incident safe tag (`>=0.35.0` for `trivy-action`, the
recreated `0.2.6` for `setup-trivy`).
