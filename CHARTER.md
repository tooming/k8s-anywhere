# CHARTER — k8s-lab North Star

The durable statement of **what k8s-lab is becoming**. Slow-changing. The backlog in
[ROADMAP.md](ROADMAP.md) is *derived* from this: the weekly planner computes
`(this charter) − (actual repo state) → concrete items`. Change **this** file when the
*goals* change; change ROADMAP.md when the *next steps* change.

Layered top-down in the classical V/M/CV → Strategy → Goals → Objectives → Initiatives
order, most-stable at the top.

## Vision

The most complete production-shaped cloud-native platform a learner can run
**anywhere** — free on a single laptop, or on any conformant Kubernetes cloud
backend — **the lab that is the syllabus, not tied to one vendor**.

## Mission

A **cloud-agnostic GitOps platform** that wires the full cloud-native stack together
as portable infrastructure-as-code: the identical `gitops/` state deploys to a free
localhost cluster (the default, zero-external-dependency path — one 16 GB Mac) or to
any CNCF-conformant Kubernetes cloud backend, so the pieces are learned as one
coherent system that isn't tied to one host or one vendor — built as code end to end,
rebuildable with one command, with recovery that is *exercised*, not assumed.
(ADR-0026)

## Core Values (invariants every change must keep true)

- **Everything as code; GitOps deploys it.** Workloads are ArgoCD `Application`s;
  Terraform/Terragrunt *only* bootstraps. (ADR-0001)
- **Recreate-from-code.** `make up` rebuilds the whole lab; DR is verified, not assumed
  (`make dr-verify` / `dr-test` / blue-green). (ADR-0005)
- **Stateful DR is exercised.** Every stateful namespace (`data`, `tidb`, `capstone`,
  `vault`) has a Velero schedule and a `make dr-restore` path that recovers it from the
  latest backup — not just re-creates the workload from manifest.
- **Images are signed and verified.** Every image deployed into the cluster is signed
  by the lab's cosign key in CI and admitted by a Kyverno `verifyImages` policy; an
  unsigned image is rejected at admission.
- **Clusterless gates stay green.** `make ci` (lint + validate + test + drift checks) is
  the floor and runs on every push.
- **Cloud-agnostic by construction.** No component above the Terraform bootstrap seam
  encodes a backend-specific assumption; the same `gitops/` Applications deploy
  unchanged to localhost or to a cloud backend. (ADR-0026)
- **Fits the 16 GB reality — on the localhost backend.** The always-on stack lives in
  the 12 GB VM (~7 GB used); heavy components are on-demand, never auto-synced, and
  never two full stacks at once. This is the default, zero-cost path everyone starts
  with; it is not a ceiling on what a cloud backend can run.
- **Real observability only.** Dashboards and outputs reflect auto-discovered state —
  never fabricated, placeholder, or mocked data. (ADR-0004)
- **Decoupled / no needless SPOF**, and **Garage (not MinIO)** for S3. (ADR-0002, ADR-0003)
- **Docs & dashboards don't drift.** README, `docs/dependency-tree.md`, and the Grafana
  "Lab UIs" panel stay in sync (enforced by drift checks).

## Strategy (the bold choices — *how* we deliver the mission)

The 26 ADRs in [docs/decisions/](docs/decisions/) are the binding receipts. This section
states the meta-choices the ADRs encode, so the *why* sits above the *what*.

- **Cloud-agnostic over single-target.** The Terraform/Terragrunt bootstrap seam is a
  swappable backend module; localhost (k3d/Colima) is the default, free,
  zero-external-dependency backend everyone starts with, and any CNCF-conformant cloud
  Kubernetes service is a first-class, opt-in alternate — reached by swapping the
  backend module, never by forking the GitOps layer. Choosing a cloud backend is the
  operator's own infrastructure cost; it is not required by the default path, and
  every *software* dependency still must clear ADR-0025's free/OSS-tier bar
  regardless of backend. (ADR-0026, supersedes the prior "localhost over cloud"
  framing)
- **GitOps over imperative.** Terraform/Terragrunt bootstraps only; workloads land as
  ArgoCD `Application`s. No `helm install`, no `kubectl apply` to live state.
  (ADR-0001)
- **On-demand over always-on for heavy components.** The 12 GB VM holds a ~7 GB
  always-on core; heavy components (TiDB, Harbor, Istio, Longhorn, Inkless) come
  up by `make <name>-up`. Never two full stacks at once. (ADR-0003)
- **Recreate-from-code over pretend-HA.** A single host has SPOFs; we don't pretend
  otherwise. Recovery is via `make up` rebuilds + Velero restores, not multi-replica HA
  theatre. (ADR-0005)
- **Real over fabricated.** Dashboards, tests, and outputs reflect auto-discovered
  state. Stub data, mock metrics, and invented examples are forbidden. (ADR-0004)
- **Decisions written down, rejected options off-limits.** Every meaningful technical
  choice lands as an ADR; rejected options (MinIO per ADR-0002, sidecar mesh per
  ADR-0012, Flannel per ADR-0014, Redis per ADR-0018) cannot be reintroduced without a
  new ADR.

## Goals (qualitative — what a learner internalizes)

The directional outcomes a learner should walk away with — *what* success looks like,
without committing to *when* or *how much*. The lab should let a learner internalize,
hands-on: the **GitOps reconcile loop**; **IaC bootstrap vs. in-cluster GitOps**; the
**secrets flow** (Vault → External Secrets → workload); **north-south ingress** via the
Gateway API; the **observability pipeline** (metrics, logs, traces, profiles);
**S3-compatible storage**; **cloud control-plane patterns** (ACK/KRO against a mock);
**DR / blue-green** on a single host; **admission-time policy** (Kyverno: validation,
mutation, image verification); **progressive delivery** (canary releases gated by real
SLO metrics, not timers); **stateful backup & restore** (Velero against Garage —
restore is exercised, not assumed); **supply-chain security** end-to-end (cosign
signing in CI, Kyverno verifyImages on admit, continuous Trivy scanning + SBOMs); and
**cloud-agnostic infrastructure design** — why the GitOps layer never encodes a
backend, so the same platform runs free on a laptop or on a cloud Kubernetes service
without a fork. The sequenced path lives in [docs/00-architecture.md](docs/00-architecture.md).

## Objectives (measurable, time-bound)

The bars that turn goals into proof. Each is specific, measurable, and has a date — so
the planner can flag "missed objective" as a gap, not just absence-of-feature. Dates
are reviewed (and slipped, advanced, or retired) at each CHARTER edit.

- **O1 — Tier 1 next-wave deployed.** By **2026-12-31**, all four next-wave components
  (Kyverno, Argo Rollouts, Velero, Trivy Operator) are auto-synced ArgoCD
  `Application`s with their own ADR, real-metric Grafana dashboard, and bats coverage.
  *Measured by:* presence checks in `make ci` (one Application + one dashboard + one
  ADR per component).
- **O2 — Default-deny + PSS-restricted everywhere.** By **2026-09-30**, every namespace
  either enforces default-deny NetworkPolicy (ADR-0016) **and** PSS-restricted labels
  (ADR-0017), or has an ADR-cited carve-out in ADR-0017's per-namespace profile table.
  *Measured by:* `tests/networkpolicy.bats` + `tests/securitycontext.bats` cover every
  namespace in `gitops/`.
- **O3 — Stateful DR is exercised.** By **2026-12-31**, `make dr-restore` recovers
  every stateful namespace (`data`, `tidb`, `capstone`, `vault`) from its latest
  Velero backup in under 10 minutes wall-clock on the maintainer's hardware.
  *Measured by:* a bats target that times the restore and fails over budget.
- **O4 — Every image is signed and verified.** By **2026-12-31**, 100% of images
  deployed into the cluster are cosign-signed in CI and admitted by a Kyverno
  `verifyImages` `ClusterPolicy`; an unsigned image push to the capstone Application
  fails admission. *Measured by:* a CI step that pushes an unsigned image and asserts
  Kyverno rejection.
- **O5 — Every always-on component has a real-metric dashboard.** By **2026-09-30**,
  every Application in `gitops/bootstrap/root-app.yaml`'s auto-synced set has a
  matching `grafana/dashboards/lab-<name>.json` with at least one panel backed by a
  real (auto-discovered) data source — no stub dashboards. *Measured by:* a drift
  check wired into `make ci`.
- **O6 — Capstone end-to-end under 15 min.** By **2026-12-31**, a fresh `make up` to
  a Tempo-traced capstone request takes under 15 minutes on the maintainer's hardware,
  measured by a `make capstone-demo` target that wall-clocks the path.

## Target end-state (initiatives — the platform we're growing toward)

- **Always-on core** (built): k3d + ArgoCD + GitLab + Envoy Gateway + Vault + External
  Secrets + Garage + the full LGTMP observability stack + moto/ACK/KRO + a demo app
  (~28 ArgoCD Applications).
- **Always-on next wave** (built, ~500 MB total within budget): **Kyverno** (admission
  policy — validation, mutation, image verification); **Argo Rollouts** (SLO-driven
  canary delivery via Envoy traffic-splitting); **Velero** (cluster + PVC backup to
  Garage); **Trivy Operator** (continuous vulnerability + SBOM scanning). All four are
  auto-synced ArgoCD `Application`s with their own ADR, real-metric Grafana dashboard,
  and bats coverage (Objective O1, met ahead of its 2026-12-31 date).
- **Heavy / on-demand** (built, on-demand): a distributed database (TiDB), an artifact
  registry (Harbor), a service mesh + UI (Istio ambient + Kiali), and distributed
  storage (Longhorn) — each is a manual-sync ArgoCD `Application` with a `make
  <name>-up` / `<name>-down` target, brought up *one at a time* within the 12 GB
  budget. None run always-on; each is code-complete but not continuously deployed.
- **Capstone — the full inner loop**: GitLab CI builds *and signs* an image (cosign) →
  Kyverno verifies the signature on admit → ArgoCD deploys it → Argo Rollouts canaries it
  on real Mimir SLOs → Envoy routes it → Grafana shows its metrics & logs → Vault holds
  its secrets → Velero backs up its state.
- **Cloud backend** (built, partially verified against a real account): a second
  Terragrunt backend module (`infra/live/oracle/`) targeting Oracle Cloud's Always Free
  tier running self-managed k3s — `gitops/` requires no fork to run there. Localhost
  stays the default. The tfstate bootstrap, `terragrunt init` against the real S3 API,
  and the `cluster/` unit's VCN/subnet/security-list/internet-gateway layer all apply
  cleanly against a real OCI tenancy (2026-07-15); the k3s compute instance launch
  itself is still blocked by a transient Oracle Always Free capacity constraint
  (`500 Out of host capacity` across all ADs), not a bug in this repo — see
  [`infra/live/README.md`](infra/live/README.md)'s Status table for what's confirmed
  end-to-end versus still pending. (ADR-0026, ADR-0027)

## How this drives the ROADMAP

The weekly **planner** routine reads this charter + the actual repo and proposes concrete
ROADMAP items for the gaps (a target not yet built, a Core Value not upheld, a Goal not
yet covered, an Objective not on track for its date). The every-5h **executor** routine
implements one item per run. To steer the lab, change the goals here — the roadmap, and
then the work, follow.
