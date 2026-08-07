# ADR-0033 — GitLab (self-hosted) as the lab's git source of truth + CI runner

**Status.** Adopted (retroactive). Architect decision, RFC #NNN — ratifies a component
that has been running in this lab since its earliest bootstrap steps; this ADR gives it
the dedicated record every other real, always-on dependency already has. Not a
supersession — no prior ADR named GitLab as its subject.

---

## Context

`docs/dependency-register.md` audits every third-party dependency against the ADR that
decided it, and flagged a real, self-identified gap: **GitLab is referenced by name
across many ADRs (most centrally ADR-0001's GitOps framing — "Terraform/Terragrunt
*only* bootstraps; workloads land as ArgoCD `Application`s") but was never itself the
*subject* of one.** That's a distinct question from ADR-0001's: ADR-0001 decides
*imperative Helm/kubectl vs. GitOps reconciliation* — it does not decide *which git host
and CI system* the lab's `main` branch and pipelines actually live on. Folding GitLab
into ADR-0001 would conflate two independent axes and leave the dependency-register
table unable to cite a specific ADR for this row (its own construction rule: every row
cites the ADR that decided it).

GitLab is not a workload deployed via GitOps (ADR-0001 governs those) — it's
infrastructure substrate the whole GitOps loop depends on, deployed as a host-level
Docker Compose stack (`gitlab/docker-compose.yml`, `gitlab/gitlab-ce` + `nginx` TLS
terminator + `gitlab/gitlab-runner`, brought up via `make gitlab-up` before ArgoCD can
sync anything), the same architectural tier as the k3d cluster itself or the
[ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) Terraform-state backend —
which is exactly why it was never captured by a GitOps-workload ADR and needed its own.

**Real alternatives that exist for this role**, evaluated against what the lab already
needs (self-hosted, free, integrated CI runner, container registry client credentials
flow, Terraform provider for project/group automation):

| Option | Why not chosen |
|---|---|
| **GitHub (cloud, github.com)** | Free for public/private repos, but this lab's whole point is a self-contained, offline-capable, zero-external-dependency localhost path (ADR-0025/ADR-0026) — a cloud-hosted git remote is an external dependency the localhost backend explicitly avoids. GitHub Actions would also mean two different CI systems if the lab ever documents a GitHub-hosted mirror, doubling maintenance for no pedagogical gain. |
| **Gitea / Forgejo (self-hosted, lightweight)** | Genuinely lighter-weight (~100 MB vs. GitLab CE's ~2–3 GB steady-state) and a reasonable choice on resource grounds alone. Rejected because it has no first-party CI runner of comparable maturity to GitLab Runner + `.gitlab-ci.yml` — the lab would need a separate CI system (Drone, Woodpecker, or GitHub-Actions-compatible Forgejo Actions, itself newer and less battle-tested) bolted on, trading one heavier component for two lighter ones plus integration glue. GitLab's single Compose stack gives git hosting + CI + a Terraform provider (`infra/modules/gitlab-config`) for project/group/variable automation in one piece, which is the actual value this lab gets from it. |
| **A cloud CI system pointed at a local git remote** | Doesn't exist as a coherent option — CI systems that aren't self-hosted need a reachable webhook target, which a localhost-only git remote can't offer without a tunnel (itself an external dependency this lab avoids). |

**GitLab CE (self-hosted, "omnibus" image)** ✅ is the only option that gives the lab
git hosting, CI/CD, and registry-adjacent tooling as one self-contained, offline-capable
stack — the actual reason it was picked when the lab was first bootstrapped, made
explicit here for the first time.

---

## Decision

Continue running **self-hosted GitLab CE** (the `gitlab/gitlab-ce` omnibus Docker
image) as the lab's git source of truth and CI runner, deployed as a host-level Docker
Compose stack (`gitlab/docker-compose.yml`) — outside the Kubernetes cluster, in the
same bootstrap tier as the k3d cluster and the Terraform-state Garage instance
([ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md)) — not as an in-cluster
ArgoCD `Application` (ADR-0001 governs in-cluster workloads; GitLab is the substrate
those workloads' manifests are pulled from, so it structurally cannot be one of them).

### What's actually running (verified directly against `gitlab/docker-compose.yml`)

- **`gitlab` service** — image `gitlab/gitlab-ce:latest`, the omnibus package (Rails
  app + Gitaly + Puma + Sidekiq + PostgreSQL + Redis, all bundled in one container per
  upstream's standard all-in-one distribution model).
- **`nginx` service** — image `nginx:1.27-alpine`, TLS termination in front of GitLab
  (`scripts/gitlab-tls-bootstrap.sh` provisions the cert).
- **`gitlab-runner` service** — image `gitlab/gitlab-runner:latest`, registered against
  the GitLab instance (`lab-docker-runner`) so `.gitlab-ci.yml` pipelines (the capstone
  build → sign → push chain, ADR-0011/ADR-0024's CI flow) actually execute — see the
  finding in [#631's 2026-08-04 comment](https://github.com/tooming/k8s-anywhere/issues/631#issuecomment-5173106213):
  no runner existed for a long stretch of this lab's history, which silently meant no
  `.gitlab-ci.yml` pipeline had ever run at all until that gap was found and fixed
  (#1026).
- **Managed via Terraform** (`infra/modules/gitlab-config`, `infra/live/{local,oracle}/gitlab/`):
  the `gitlab` Terraform provider creates the `lab` group + `gitops` project and
  configures the ArgoCD repo-read credential — day-0 bootstrap only, per ADR-0001's own
  scope (Terraform/Terragrunt bootstraps; it does not manage GitLab's day-2 workload
  state, which lives in GitLab's own database).

### Real gap found while researching this ADR — GitLab is currently unpinned

Both `gitlab/gitlab-ce:latest` and `gitlab/gitlab-runner:latest` track `:latest`, not an
explicit version — the opposite of [ADR-0030](adr-0030-pin-k3s-version-explicitly.md)'s
"pin to an explicit version on every backend" precedent and every other always-on
component's convention in this lab (RabbitMQ, Valkey, Grafana, etc. all pin an exact
tag). This is a real, actionable gap, out of scope for this ADR itself (a version-pin
change is mechanical fan-out work, not an architecture decision) — tracked as a new 🟢
ROADMAP item this same run so the executor can pick it up directly, no further RFC
needed.

---

## Scope & exceptions

**In scope:** the choice of GitLab CE (self-hosted) as git host + CI runner, and its
placement outside the GitOps-managed cluster state (ADR-0001's boundary).

**Out of scope (explicit, tracked separately):**

- Pinning `gitlab-ce`/`gitlab-runner` to explicit versions (new 🟢 ROADMAP item, this
  run — see `docs/backlog/`).
- `docs/dependency-register.md` gaining a GitLab row citing this ADR (follow-up
  executor item — doc-only, not bundled into this architecture PR to keep it reviewable).
- Any change to GitLab's actual configuration, CI pipeline shape, or runner setup —
  this ADR ratifies the existing choice, it does not propose changes to how GitLab is
  used.

---

## Re-evaluation log

_(No entries yet — this is the ADR's first version. Future architect audits record
Keep/Supersede/Convert outcomes here, per the pattern established in every other ADR's
Re-evaluation log.)_

**Flip condition:** revisit if GitLab CE's licensing terms change in a way that
conflicts with [ADR-0025](adr-0025-free-oss-tiers-only.md) (free/OSS-tier requirement —
GitLab CE is MIT-licensed and free today), or if the lab's CI needs outgrow what a
single-instance omnibus deployment can support (e.g., genuine need for GitLab's paid
tiers' features), or if a lighter self-hosted git+CI combination reaches comparable
maturity to GitLab's bundled offering.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | GitLab hosts the `main` branch ArgoCD's `Application`s pull from — the git source of truth the GitOps loop reconciles against. Distinct axis: ADR-0001 decides *how workloads reach the cluster* (GitOps, not imperative); this ADR decides *which git host + CI system* the lab runs. |
| [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) | Same architectural tier — infrastructure substrate outside the Kubernetes cluster, provisioned once and treated as a bootstrap dependency rather than a GitOps-managed workload. |
| [ADR-0011](adr-0011-artifactory-not-nexus.md) / [ADR-0024](adr-0024-harbor-not-artifactory.md) | GitLab CI's `sign-image` job is the producer half of the capstone image-signing pipeline; the registry ADRs decide where the signed image lands. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | GitLab CE is MIT-licensed, no paid tier required — satisfies the free/OSS-tier bar. |
| [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) | Self-hosting GitLab (rather than depending on github.com) keeps the localhost backend's zero-external-dependency property intact. |
