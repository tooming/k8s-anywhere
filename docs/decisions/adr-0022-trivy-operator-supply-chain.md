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
config-audit findings by severity (real `trivy_resource_configaudits` gauge),
operator reconcile rate. SBOMs are CR-shaped, not metric-shaped — no
SbomReport-count panel exists yet, since no metric or `kube-state-metrics`
custom-resource-state config currently exposes that count (see
[§Re-evaluation log](#re-evaluation-log) 2026-08-12 — a prior version of this
dashboard queried a nonexistent metric for this; removed rather than left
permanently broken).

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

### 2026-08-07 — Chart currency bump `0.34.0` → `0.35.0` kept current

**Trigger.** Routine currency sweep (`gitops/`-wide `targetRevision` audit) found
`aquasecurity/helm-charts`' `gh-pages` index publishing `trivy-operator-0.35.0`
(2026-08-06T03:12:49Z) one release past this lab's pinned `0.34.0` — the
`aquasecurity/helm-charts` git repo's `main` branch no longer carries chart
source (chart-releaser publishes packaged `.tgz` assets + a `gh-pages` Helm
repo index instead), so verification here downloaded and diffed the two real
release tarballs directly rather than a git-tag diff.

**Findings, verified directly (not assumed, ADR-0004).** `diff -ru` between the
extracted `trivy-operator-0.34.0.tgz` and `trivy-operator-0.35.0.tgz` shows
exactly three kinds of change: `Chart.yaml`'s `version`/`appVersion` fields
(`0.34.0`→`0.35.0`, `appVersion` `0.32.0`→`0.33.0`), the `README.md` badges +
values-table doc for the same, and the bundled `trivy.image.tag` default
(`0.72.0`→`0.73.0`, in both `values.yaml` and the generated `README.md` row) —
plus the same version-label bump repeated across five `templates/specs/*.yaml`
compliance-scan CronJob manifests (`app.kubernetes.io/version` label only, not
behavior). No other `values.yaml` key changed shape — every key this lab's
`valuesObject` sets (`operator.*`, `trivy.resources`/`storageClassName`/
`storageSize`, `nodeCollector.*`) is present and unchanged.

A real clone's `git log v0.32.0..v0.33.0` (trivy-operator app repo) shows 4
commits: 2 routine dependency bumps (`golang.org/x/text` 0.38.0→0.39.0, the
`k8s.io/*` client group 0.36.2→0.36.3) and the `trivy` scanner version bump
itself — no operator-side feature/fix commit in this range. The bundled Trivy
scanner bump (`v0.72.0`→`v0.73.0`, `aquasecurity/trivy`) does carry two real
detection-accuracy fixes: `fix(vuln): don't skip packages covered by a
driver's own advisory feed` (#10980) and `fix(vex): reject non-local VEX
repository names` (#10987) — both correctness fixes to the scanner's own
vulnerability-detection path, the same "ships with a real fix" bar this
repo's other non-CVE currency bumps (e.g. Loki's ingester flush-race fix) use.

**Decision: Keep current — bump the pin.** Smallest-safe-delta, same-shape
`values.yaml`, no breaking change. Does not touch this ADR's compromise
finding above (`0.69.4` is still the only affected tag; `0.73.0` postdates it
by many releases) — noted here only because the pin this entry's own citation
references moved. **Flip condition (unchanged):** re-evaluate on the next
Trivy supply-chain advisory, or when a future chart bump changes a
`valuesObject` key shape.

### 2026-08-12 — `lab-trivy.json` metric-name drift fixed; SBOM panel removed as never-real (executor sweep)

**Trigger.** Executor STEP 6b JANITOR sweep (this run's 25th cycle) cross-checked
`grafana/dashboards/lab-trivy.json`'s PromQL queries against the real metric names
trivy-operator exposes at the pinned `appVersion` `0.33.0`, verified directly
against `docs/tutorials/integrations/metrics.md` and `pkg/metrics/collector_test.go`
at tag `v0.33.0` (raw source, not a rendered doc site — ADR-0004).

**Findings.** Two real bugs, both present since the dashboard's original authoring
(not a recent regression):
- The "ConfigAudit Checks by Severity" panel queried `trivy_config_audit_checks_total`
  — this metric name does not exist anywhere in trivy-operator. The real metric is
  `trivy_resource_configaudits` (confirmed with its `severity` label present,
  Title-Case values).
- The four CVE-count panels (Critical/High/Medium/Low) queried
  `trivy_image_vulnerabilities{severity="CRITICAL"}` etc. — uppercase. The real
  `severity` label values on this metric are Title Case (`Critical`, `High`,
  `Medium`, `Low`), confirmed against the metrics doc's own examples. Uppercase
  never matches, so these four panels also silently showed "No data" forever, not
  the legitimate "no scans yet" state their `noValue` text implied.
- The "SBOM Reports (total)" panel queried `trivy_sbom_reports_total` — this
  metric does not exist at all; trivy-operator's real metric surface at this
  version covers vulnerabilities/configaudits/rbacassessments/exposedsecrets/
  infraassessments/cluster-compliance only, nothing SBOM-shaped. This ADR's own
  "Observability" section (above) says "SBOMs are CR-shaped, not metric-shaped —
  a separate panel shows SbomReport count per namespace as a stat" — but no
  `kube-state-metrics` `CustomResourceState` config exposing that CR count was
  ever actually wired up (checked `gitops/platform/observability-ksm.yaml`
  directly — no such config exists), so the panel was structurally guaranteed to
  never show real data, not merely pending a first scan. Removed the panel rather
  than leave a permanently-broken query (ADR-0004: never present a query that can
  never reflect real state as if it were a legitimate "not yet" wait).

**Decision: fix the two real metric-name/label-casing bugs; remove the SBOM
panel.** Wiring up a real SbomReport-count metric (a `kube-state-metrics`
`CustomResourceState` config for the `SbomReport` CRD, or an equivalent) is a
separate, larger feature-add outside a bugfix's scope — flagged as a follow-up in
`docs/done/2026-08-12-dashboard-metric-drift-fix-cilium-harbor-trivy.md` rather
than silently dropped.

**Flip condition:** re-add an SBOM-count panel once a real metric backs it (either
trivy-operator ships one upstream, or a `kube-state-metrics` custom-resource-state
config is added for `SbomReport`).
