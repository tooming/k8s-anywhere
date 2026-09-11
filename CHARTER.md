# CHARTER — k8s-lab North Star

The durable statement of **what k8s-lab is becoming**. Slow-changing. The backlog in
[ROADMAP.md](ROADMAP.md) is *derived* from this: the planner role computes
`(this charter) − (actual repo state) → concrete items`. Change **this** file when the
*goals* change; change ROADMAP.md when the *next steps* change.

Layered top-down in the classical V/M/CV → Strategy → Goals → Objectives → Initiatives
order, most-stable at the top.

**A large, deliberate simplification landed 2026-09-06/2026-09-07** (see "The
2026-09-07 simplification" near the bottom of this file for the full pivot and why).
This charter has been rewritten to describe the lab's actual current, intentionally
small shape — not a temporary gap to rebuild back up to the platform's prior, much
larger scope.

## Vision

The most complete production-shaped cloud-native platform a learner can run
**anywhere** — free on a single laptop, or on any conformant Kubernetes cloud
backend — **the lab that is the syllabus, not tied to one vendor**.

## Mission

A **cloud-agnostic GitOps platform** that wires a small, coherent cloud-native stack
together as portable infrastructure-as-code: the identical `gitops/` state deploys to
a free localhost cluster (the default, zero-external-dependency path — one 16 GB Mac)
or to any CNCF-conformant Kubernetes cloud backend, so the pieces are learned as one
coherent system that isn't tied to one host or one vendor — built as code end to end,
rebuildable with one command, with recovery that is *exercised*, not assumed.
(ADR-0026)

## Core Values (invariants every change must keep true)

- **Everything as code; GitOps deploys it.** Workloads are ArgoCD `Application`s;
  Terraform/Terragrunt *only* bootstraps. (ADR-0001)
- **Recreate-from-code.** `make up` rebuilds the whole lab; DR is verified, not
  assumed (`make dr-verify` / `dr-test`). There is no stateful backup/restore
  mechanism in this lab any more (Velero was removed entirely 2026-09-07, no
  replacement) — full-cluster-recreate-from-git is the only recovery path, and an
  honest one for a lab with no stateful application data left to protect. (ADR-0005)
- **Clusterless gates stay green.** `make ci` (lint + validate + test + drift checks) is
  the floor and runs on every push.
- **Cloud-agnostic by construction.** No component above the Terraform bootstrap seam
  encodes a backend-specific assumption; the same `gitops/` Applications deploy
  unchanged to localhost or to a cloud backend. (ADR-0026)
- **Fits the 12 GB reality — on the localhost backend.** The always-on stack (4
  namespaces) uses a small fraction of the 12 GB Colima VM. There are no on-demand
  heavy components any more (Harbor and Kargo, the only two this lab ever ran, were
  both removed entirely, no replacement) — everything that exists is always-on.
- **Real state only.** Outputs reflect auto-discovered state — never fabricated,
  placeholder, or mocked data. (ADR-0004)
- **Decoupled / no needless SPOF.** (ADR-0003)
- **Docs don't drift.** README and `docs/dependency-tree.md` stay in sync with the
  actual repo (enforced by drift checks).

## Strategy (the bold choices — *how* we deliver the mission)

The ADRs in [docs/decisions/](docs/decisions/) are the binding receipts. This section
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
- **Aggressive simplification over breadth-for-its-own-sake.** As of 2026-09-07, the
  lab favors a small, well-understood always-on core over demonstrating every
  cloud-native pattern at once — see "The 2026-09-07 simplification" below.
- **Recreate-from-code over pretend-HA.** A single host has SPOFs; we don't pretend
  otherwise. Recovery is via `make up` rebuilds, not multi-replica HA theatre or a
  backup mechanism this lab no longer runs. (ADR-0005)
- **Real over fabricated.** Tests and outputs reflect auto-discovered state. Stub
  data, mock metrics, and invented examples are forbidden. (ADR-0004)
- **Decisions written down, rejected options off-limits.** Every meaningful technical
  choice lands as an ADR; rejected options (MinIO per ADR-0002, sidecar mesh per
  ADR-0012, Flannel + kube-router per ADR-0014's original decision — since revisited,
  see the ADR's own Status) cannot be reintroduced without a new ADR.

## Goals (qualitative — what a learner internalizes)

The directional outcomes a learner should walk away with — *what* success looks like,
without committing to *when* or *how much*. The lab should let a learner internalize,
hands-on: the **GitOps reconcile loop**; **IaC bootstrap vs. in-cluster GitOps**;
**north-south ingress** via Traefik's native `IngressRoute` CRDs; **automated TLS
certificate lifecycle**
(cert-manager issuing and rotating certs from a self-signed root CA at the ingress
edge — not a one-off hand-issued Secret); **operational-resilience discipline**
(DORA's risk-management/incident/testing/third-party-risk pillars mapped onto
concrete GitOps practice — ADRs, dependency pinning, an honest accounting of what DR
capability actually remains — explicitly as an educational lens, never a regulatory
compliance claim this lab cannot honestly make); and **cloud-agnostic infrastructure
design** — why the GitOps layer never encodes a backend, so the same platform runs
free on a laptop or on a cloud Kubernetes service without a fork. The sequenced path
lives in [docs/00-architecture.md](docs/00-architecture.md).

Cloud control-plane patterns (ACK/KRO against a mock), admission-time policy engines,
progressive delivery, stateful backup & restore, continuous vulnerability scanning,
and a real secrets-management backend + sync flow (Vault → External Secrets Operator
→ workload) were all goals this lab used to teach — see "The 2026-09-07
simplification" below for why that scope was cut, and each removed component's own
ADR Status for what it demonstrated while it was live.

## Objectives (measurable, time-bound)

The bars that turn goals into proof. Each is specific, measurable, and has a date — so
the planner can flag "missed objective" as a gap, not just absence-of-feature. Dates
are reviewed (and slipped, advanced, or retired) at each CHARTER edit.

- **O1 — Retired 2026-09-07.** Was "Tier 1 next-wave deployed" — all four
  components it measured (Kyverno, Argo Rollouts, Velero, Trivy Operator) were
  removed from the lab entirely, no replacement, the same day (alongside Harbor,
  Kargo, ACK, moto, KRO, Cilium, Garage, Forgejo, GitLab, the DR front door, and
  capstone). There is no next-wave tier left to hold a bar against. The number is
  retired rather than reused, matching how O5 was retired 2026-09-06 (same pattern).
- **O2 — Default-deny + PSS-restricted everywhere.** By **2026-09-30**, every namespace
  either enforces default-deny NetworkPolicy (ADR-0016) **and** PSS-restricted labels
  (ADR-0017), or has an ADR-cited carve-out in ADR-0017's per-namespace profile table.
  Enforcement moved from Cilium to k3s's bundled Flannel + kube-router 2026-09-07
  (ADR-0014's Status) — the bar itself (every namespace covered) is unchanged.
  *Measured by:* `tests/networkpolicy-*.bats` + `tests/securitycontext-*.bats` (one file
  per namespace, plus the shared-baseline `tests/networkpolicy.bats` and the frozen
  `tests/securitycontext.bats`) cover every namespace in `gitops/`.
- **O3 — Retired 2026-09-07.** Was "Stateful DR is exercised" — Velero, the
  mechanism this objective measured, was removed entirely, no replacement, the
  same day as its S3 backend (Garage). This lab has no stateful application data
  left to hold an RTO/RPO bar against (see [docs/DR.md](docs/DR.md) and
  [ADR-0021](docs/decisions/adr-0021-velero-backup-restore.md)'s Status for the
  honest current DR picture: full-cluster-recreate-from-git only). Retired rather
  than reused, same pattern as O1/O5.
- **O4 — Retired 2026-09-07.** Was "Every image is signed and verified" — Kyverno
  (the admission engine that enforced `verifyImages`) was removed entirely, no
  replacement, the same day. There is no admission-time policy engine left to hold
  this bar against. Retired rather than reused, same pattern as O1/O3/O5.
- **O5 — Retired 2026-09-06 (ADR-0041).** Was "every always-on component has a
  real-metric dashboard" — removed outright, not renumbered, when the observability
  stack it measured (Grafana + the LGTM(P) backends) was removed with no
  replacement; there is no dashboard layer left to hold a bar against. The number
  is retired rather than reused, matching how a superseded ADR keeps its number.
- **O6 — Retired 2026-09-07.** Was "Capstone end-to-end under 15 min" — capstone
  itself (the demo app this objective timed), along with Argo Rollouts and Kargo
  which fed its pipeline, was removed entirely, no replacement, the same day. The
  lab's remaining demo workload (`lab-demo`, a single static hello-world
  Deployment) has no equivalent multi-step pipeline to time. Retired rather than
  reused, same pattern as O1/O3/O4/O5.
- **O7 — Deployment pipeline health is measured.** By **2026-10-31**, `make
  dora-metrics` computes and `docs/dora-metrics.md` reports all four DORA (DevOps
  Research and Assessment) metrics — deployment frequency, lead time for changes,
  change failure rate, time to restore service — from real git/CI history for the
  trailing 90 days, each re-grounded in this repo's clusterless, self-merging GitOps
  model (RFC #580) rather than assumed unmeasurable; a metric with insufficient
  evidence renders as "insufficient data", never a fabricated number (ADR-0004).
  *Measured by:* a `make ci` presence check that `scripts/dora-metrics.sh` exists,
  is executable, and the `dora-metrics` Makefile target is wired.

## Target end-state (initiatives — the platform we're growing toward)

- **Always-on core** (built, 4 namespaces, all always-on — nothing on-demand): k3d
  (bundled Flannel CNI + kube-router NetworkPolicy) + ArgoCD (syncing directly from
  this repo's public GitHub remote) + Traefik + cert-manager + a demo app
  (`lab-demo`). This is the entire lab as of 2026-09-07 — see "The 2026-09-07
  simplification" below for what used to sit alongside it and why it's gone.
- **Cloud backend** (built, partially verified against a real account): a second
  Terragrunt backend module (`infra/live/oracle/`) targeting Oracle Cloud's Always Free
  tier running self-managed k3s — `gitops/` requires no fork to run there. Localhost
  stays the default. The tfstate bootstrap, `terragrunt init` against the real S3 API,
  and the `cluster/` unit's VCN/subnet/security-list/internet-gateway layer all apply
  cleanly against a real OCI tenancy (2026-07-15); the k3s compute instance launch
  itself is still blocked by a transient Oracle Always Free capacity constraint
  (`500 Out of host capacity` across all ADs), not a bug in this repo — see
  [`infra/live/README.md`](infra/live/README.md)'s Status table for what's confirmed
  end-to-end versus still pending. (ADR-0026, ADR-0027) Note: the localhost backend's
  own equivalent tfstate store (an off-cluster Garage instance) was removed and
  migrated to a local Terraform backend the same day (ADR-0007's Status). This
  module's own tfstate backend design — a separate, still-live off-cluster Garage
  instance on its own Oracle Always Free AMD Micro instance — was audited against
  that same question and **kept unchanged** (ADR-0007's Re-evaluation log,
  2026-09-07): it serves a durable, cross-session state need the local backend's
  local-file replacement doesn't have, and never shared the local host's capacity
  constraint that motivated removing the local backend's Garage in the first place.
- **TLS certificate lifecycle**: cert-manager issues and auto-renews certs from a
  self-signed root CA (works identically on localhost and the Oracle backend, unlike
  public ACME). Every north-south route is reachable over both HTTP and Traefik's
  HTTPS listener — a wildcard `*.127.0.0.1.nip.io` Certificate backs it, additive
  alongside the original HTTP-only path, never a breaking cutover. (ADR-0028)

### The 2026-09-07 simplification — what changed, and why

This lab used to run a much larger stack: an admission-policy engine (Kyverno), a
progressive-delivery controller (Argo Rollouts), a backup/restore system (Velero), a
continuous vulnerability scanner (Trivy Operator), a GitOps promotion pipeline
(Kargo), an OCI artifact registry (Harbor), a cloud-control-plane demo pattern
(moto/ACK/KRO), a dedicated eBPF CNI (Cilium), an in-cluster S3 store (Garage), a
self-hosted git source (first GitLab, then Forgejo), a DR front door with a
zero-downtime blue/green drill, a real secrets backend + sync operator (Vault +
External Secrets Operator), and an end-to-end demo pipeline (capstone) tying several
of the above together. By explicit maintainer decision, **all of it was removed
entirely, no replacement**, across a short, deliberate series of changes
2026-09-06/2026-09-07 — see each component's own ADR Status for the specific
reasoning (several cite this single-host lab's real, live-observed capacity
constraints — see `docs/incident-log.md`'s 2026-09-06 entries — as a contributing
factor, alongside the maintainer's explicit preference for a smaller, more legible
lab over demonstrating every pattern at once). Vault and External Secrets Operator
were the last of this round: by the time they were cut, ESO had zero live
`ExternalSecret` consumers left in the repo — every component that had ever needed a
Vault-held credential (Garage, Harbor, Kargo, Velero, ACK, capstone) was already gone
— so the secrets-sync path they still ran was proving nothing with a real consumer
behind it (ADR-0042, supersedes ADR-0036/ADR-0037).

What's left is a small, coherent core that still teaches the fundamentals this
project cares most about — the GitOps reconcile loop, IaC-bootstraps-then-GitOps-runs,
ingress, and TLS lifecycle — without the operational weight of the larger stack. This
is not a temporary regression to rebuild back up from; it is the maintainer's
deliberate current shape for this project. A future CHARTER edit may reintroduce
scope deliberately, the same way any other goal change happens here — but nothing in
this file should be read as an implicit promise to do so.

## How this drives the ROADMAP

The **executor** routine (several times a day — see `routines/routines.yaml` for the
current cadence) reads this charter + the actual repo and implements ROADMAP
items back-to-back for as long as each run continues (one PR per item, but a run is no
longer capped at one item — see `executor.prompt.md` STEP 8). When its own lane is
empty it falls back through the **planner** role, which reads this charter against the
actual repo and proposes concrete ROADMAP items for the gaps (a target not yet built, a
Core Value not upheld, a Goal not yet covered, an Objective not on track for its date).
To steer the lab, change the goals here — the roadmap, and then the work, follow.
