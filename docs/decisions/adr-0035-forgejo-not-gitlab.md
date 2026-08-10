# ADR-0035 — Forgejo (self-hosted) as the lab's git source of truth + CI runner (supersedes ADR-0033)

**Status.** Adopted. **Supersedes [ADR-0033](adr-0033-gitlab-git-source-and-ci.md).**
Architect decision. Migration execution tracked as new ROADMAP items (this same run) —
this ADR lands the decision; the cutover itself is mechanical fan-out work across
several follow-up PRs (compose stack, Terraform module, CI pipeline port, script/Makefile
rename, GitLab decommission), mirroring how [ADR-0024](adr-0024-harbor-not-artifactory.md)
(Harbor superseding Artifactory) was executed in stages.

---

## Context

ADR-0033 evaluated Gitea/Forgejo against GitLab CE and rejected it for one specific,
named reason: *"it has no first-party CI runner of comparable maturity to GitLab
Runner + `.gitlab-ci.yml` — the lab would need a separate CI system... bolted on."*
That gap is the entire basis for ADR-0033's decision — everything else in its
comparison table favored the lighter option. Re-checking that one gap, and the actual
resource cost GitLab imposes on this host, is what this ADR does.

### What's changed since ADR-0033

**Forgejo Actions has matured past the "newer and less battle-tested" characterization
ADR-0033 gave it.** As of this review (2026-08-11): it's reported production-ready by
the self-hosting community, targets a large subset of GitHub Actions workflow syntax
(`.forgejo/workflows/*.yml`, falling back to `.github/workflows/*.yml`), and most
GitHub Marketplace actions work with only minor adjustment. Real deployments (e.g.
Codeberg's own hosted Actions) are running it at production scale, not just in
hobbyist setups.

**GitLab CI genuinely still has features Forgejo Actions doesn't match** — DAG
pipelines, parent-child pipelines, multi-project pipelines. This is a real, honestly-
acknowledged gap. It doesn't bite here: this lab's entire CI surface is one linear job
— build → cosign sign → push to Harbor (ADR-0011/ADR-0024) — with no fan-out, no
cross-project triggering, and no plans to add any. The feature gap is real; it isn't
relevant to what this lab's pipeline actually does.

**Terraform provider: an honest downgrade, not a blocker.** The current
`infra/modules/gitlab-config` uses `gitlabhq/gitlab` — GitLab's own, first-party
provider. Forgejo has no first-party provider; the two community options
(`svalabs/terraform-provider-forgejo`, `adyxax/terraform-provider-forgejo`, both on the
public Terraform Registry) cover the resources this lab actually uses (organization,
repository, branch protection, deploy tokens/keys). This is a real reduction in
provider pedigree, flagged here rather than glossed over — but it's not a functional
gap against this lab's Terraform usage, which is day-0 bootstrap only (ADR-0001) and
doesn't exercise anything exotic.

### What's verified, not assumed (ADR-0004)

Two claims worth checking before writing this ADR, checked live rather than asserted:

- **Is GitLab actually paying an emulation tax on this arm64 host, the way Harbor
  was (GOMAXPROCS fix, PR #1102)?** No — checked and ruled out.
  `docker manifest inspect gitlab/gitlab-ce:latest` and `gitlab/gitlab-runner:latest`
  both list genuine `arm64` platform manifests alongside `amd64`, and the running
  `gitlab` container is healthy with no analogous Go-runtime panics in its logs. GitLab
  is not under QEMU emulation here — this ADR does **not** rest on that argument, and
  it would have been wrong to claim it does.

- **What does GitLab actually cost this host, in practice, right now?**
  `docker stats --no-stream gitlab` (2026-08-11): **3.744 GiB / 32% of the 11.65 GiB
  Colima VM**, for the `gitlab` container alone (not counting `gitlab-runner` or the
  `gitlab-tls` nginx sidecar). That's a real, measured number on the same host that
  spent this entire investigation chasing resource-pressure-driven crashloops in
  Harbor, ArgoCD's repo-server (PR #1103), Kyverno, and Envoy Gateway (PR #1063) — a
  single component holding a third of total host memory at idle is a structural risk
  on a box already this tight, independent of whether GitLab itself is currently
  crashlooping (it isn't).

Options considered (updated from ADR-0033's table):

| Option | Why not chosen |
|---|---|
| **Keep GitLab CE** | Still functional, still free/OSS (ADR-0025), not under emulation. But: 3.7 GiB / 32% of host memory measured live for one container, on a host that has spent this session fighting resource-pressure crashloops elsewhere; the CI-maturity gap that justified paying that cost in ADR-0033 has narrowed. |
| **GitHub (cloud)** | Same reasoning ADR-0033 already gave — external dependency the localhost-first design (ADR-0025/ADR-0026) explicitly avoids. Unchanged. |
| **Forgejo + Forgejo Actions** ✅ | ~100–300 MB steady-state vs. GitLab's 3.7 GiB; Actions has matured to production-ready with broad GitHub Actions workflow compatibility, enough for this lab's one-job linear pipeline; community (not first-party) Terraform provider covers the resources this lab needs; loses GitLab's advanced pipeline-orchestration features this lab doesn't use. |
| **Gitea (Forgejo's upstream)** | Forgejo is the community-governed fork of Gitea and is what ADR-0033 itself named as the more actively-developed option going into 2026; no reason to pick the base project over the fork this lab already had in mind. |

---

## Decision

Migrate the lab's git source of truth + CI runner from self-hosted **GitLab CE** to
self-hosted **Forgejo + Forgejo Actions**, keeping the same architectural placement
ADR-0033 established: a host-level Docker Compose stack outside the Kubernetes cluster,
in the same bootstrap tier as the k3d cluster and the Terraform-state Garage instance
([ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md)) — not an in-cluster ArgoCD
`Application` (ADR-0001 governs in-cluster workloads; the git host is the substrate
those workloads are pulled from, so it structurally cannot be one of them).

### Target shape (mirrors what ADR-0033 documented for GitLab)

- **`forgejo` service** — `codeberg.org/forgejo/forgejo` (verified multi-arch: amd64,
  arm64, arm/v6 — runs natively on this host, no emulation).
- **`forgejo-runner` service** — `code.forgejo.org/forgejo/runner`, registered against
  the Forgejo instance so `.forgejo/workflows/*.yml` pipelines (the same build → sign →
  push chain, ADR-0011/ADR-0024) actually execute. ADR-0033's own history is the
  cautionary precedent here: GitLab ran with **no runner at all** for a long stretch
  before that gap was found (#631, #1026) — the runner's presence and registration must
  be verified live, not assumed, the moment this migration lands, exactly the same way.
- **`nginx` TLS terminator** — unchanged in role from ADR-0033's `gitlab-tls` service.
- **Terraform-managed** (new `infra/modules/forgejo-config`,
  `infra/live/{local,oracle}/forgejo/`) using `svalabs/terraform-provider-forgejo` (or
  `adyxax/terraform-provider-forgejo` — pick whichever's resource coverage is the better
  match once the module is actually written) to create the org + repo and configure the
  ArgoCD repo-read credential — day-0 bootstrap only, per ADR-0001's scope.

### Migration execution (tracked as ROADMAP items, not done in this ADR)

This ADR authorizes and directs the migration; it does not itself contain it — the
change touches too many files to review as one PR (compose stack, TLS bootstrap script,
Terraform module, CI pipeline syntax port, every `gitlab-*` script and Makefile target,
ArgoCD's repo source, dependency-register, README/CHARTER/WAYS-OF-WORKING references).
Concrete steps, added to ROADMAP.md this same run:

1. Stand up `forgejo/docker-compose.yml` alongside the still-running GitLab stack
   (additive, zero risk to the current CI path) — `forgejo` + `forgejo-runner` + reused
   `nginx` TLS pattern, plus `up`/`down` Makefile targets mirroring the existing
   `gitlab-up`/`gitlab-down` pair (not yet added — tracked as a ROADMAP item, see below).
2. `infra/modules/forgejo-config` Terraform module (org/repo/branch-protection/deploy
   token) + `infra/live/{local,oracle}/forgejo/` — parallels `gitlab-config`.
3. Port `.gitlab-ci.yml`'s build → cosign sign → push job to
   `.forgejo/workflows/build-sign-push.yml`; verify a real pipeline run pushes a signed
   image to Harbor (the same live-verification bar ADR-0033/#631 held GitLab to).
4. Re-point ArgoCD's `Application`/repo-credential Secret at the Forgejo remote; verify
   a real sync.
5. Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh` (bootstrap, TLS bootstrap,
   push, force-push, rebase-prs' GitLab leg) and the matching `Makefile` targets;
   update `tests/gitlab-compose.bats`, `tests/gitlab-push.bats` → `forgejo-*` bats
   files with equivalent coverage (mechanical-guard parity, not a coverage regression).
6. Decommission the GitLab stack (`gitlab/docker-compose.yml`, `gitlab-config` module)
   once the above are verified live and stable for a real work cycle — matching how
   Artifactory's decommission (`docs/done/2026-07-29-harbor-artifactory-decommission.md`)
   followed, rather than preceded, Harbor's proven-live cutover.
7. `docs/dependency-register.md`'s GitLab row → a Forgejo row citing this ADR (done as
   part of this ADR's own PR, see below — the row itself is a one-line, low-risk edit
   unlike the rest of the migration).

---

## Scope & exceptions

**In scope:** the choice of Forgejo + Forgejo Actions (self-hosted) as git host + CI
runner, superseding GitLab CE, and confirmation of its placement outside the
GitOps-managed cluster state (unchanged from ADR-0033).

**Out of scope (explicit, tracked as ROADMAP items per the execution list above):** the
actual compose stack, Terraform module, CI pipeline port, script/Makefile renames, and
GitLab decommission. This ADR does not leave GitLab non-functional — it keeps running,
unmodified, until the migration steps above are verified live; there is no point at
which the lab is left without a working git source or CI path.

---

## Re-evaluation log

_(First version of this ADR — no entries yet.)_

**Flip condition:** revisit if Forgejo Actions' feature gap against GitLab CI (DAG /
multi-project pipelines) becomes something this lab's pipeline actually needs, or if a
first-party Forgejo Terraform provider ships and the community ones prove unreliable in
practice, or if GitLab CE's resource footprint stops mattering (e.g. the host gets
meaningfully more memory headroom than the current 11.65 GiB Colima VM).

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0033](adr-0033-gitlab-git-source-and-ci.md) | Superseded by this ADR — same role (git source + CI runner), same architectural placement, different tool. |
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Forgejo hosts the `main` branch ArgoCD's `Application`s pull from — the git source of truth the GitOps loop reconciles against. Unchanged relationship from ADR-0033. |
| [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) | Same architectural tier — infrastructure substrate outside the Kubernetes cluster, bootstrap dependency rather than a GitOps-managed workload. |
| [ADR-0011](adr-0011-artifactory-not-nexus.md) / [ADR-0024](adr-0024-harbor-not-artifactory.md) | Forgejo Actions' `sign-image` job is the producer half of the capstone image-signing pipeline; the registry ADRs decide where the signed image lands. Unchanged from ADR-0033's relationship. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | Forgejo is MIT-licensed, no paid tier — satisfies the free/OSS-tier bar, same as GitLab CE did. |
| [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) | Self-hosting Forgejo (rather than depending on github.com) keeps the localhost backend's zero-external-dependency property intact — unchanged reasoning from ADR-0033. |
