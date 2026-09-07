# Dependency exit runbooks

Closes [`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q17's own named gap:
exit strategy per critical dependency is *implicit* (ADR-0001's GitOps-repointing
design — every workload is redeployable by changing one `Application` source) and
*demonstrated* once (the real, executed ADR-0011→ADR-0024 Artifactory→Harbor
migration), but until this file, no dependency had a **written** exit runbook in
advance of needing one. This file is that: pre-planned first-response steps, not a
new mitigation — the mitigation is already ADR-0001's design and the Artifactory→
Harbor precedent; this only writes the steps down before an exit is forced.

**Scope of this file.** [`docs/dependency-concentration.md`](dependency-concentration.md)
(Q16) named concentration groups, worst-first — this file covers those plus every
single-tool row in [`docs/dependency-register.md`](dependency-register.md). As of
2026-09-07, five single-tool rows have a real, live runbook below: Traefik,
cert-manager, Terraform/Terragrunt, Oracle Cloud Infrastructure, and k3s. Kyverno,
Velero, Trivy Operator, Kargo, Harbor, moto, ACK S3 controller, KRO, Cilium,
Garage, Forgejo, s3manager, Vault, and External Secrets Operator each had a real
runbook here once but are now moot — all fourteen components were removed entirely
2026-09-07, no replacement (alongside Argo Rollouts, `github.com/argoproj`'s other
former member — see that section above) — no exit runbook is needed for a
component that no longer exists, so each keeps a short "moot, removed" note below
rather than a full runbook, the same treatment already used for
`github.com/grafana`, RabbitMQ, Valkey, KEDA, and `github.com/pingcap`. A future
new row in the register (a new ADR naming a new tool) would still need its own
runbook added here, same as any new concentration group, and per the
mechanical-guard gap named in "Keeping this in sync" below, nothing currently
catches that automatically.

**How to read a runbook below.** Each names: what a real exit changes *mechanically*
in this repo's `gitops/`; whether a straight fork-and-repoint suffices or a
schema/data migration is also needed; and, honestly, whether any alternative has
actually been evaluated yet. A written runbook existing in advance doesn't make the
effort of a real exit smaller — it only means the first-response steps are already
identified, so a future session isn't starting from zero the way the Artifactory→
Harbor migration originally did.

---

## `github.com/grafana` — removed 2026-09-06 (ADR-0041), no runbook needed

This used to be the largest concentration in the register — the entire
observability pane (dashboards, metrics, logs, traces, continuous profiling, and
the unified collector feeding all of them), all one upstream org. There is no exit
runbook to write for it any more: the whole stack was removed outright with no
replacement (ADR-0041, supersedes ADR-0006/ADR-0034), so the concentration risk
this section used to plan an exit for is gone along with the dependency itself —
the most complete "exit" available. See
[`docs/dependency-concentration.md`](dependency-concentration.md)'s matching entry.

## `github.com/argoproj` — 1 tool (ArgoCD); no longer a concentration group

Used to couple the GitOps control plane itself
([ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md), `always-on-core`) to
the progressive-delivery layer built on top of it
([ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md)) — Argo
Rollouts was removed entirely 2026-09-07, no replacement (capstone, its only
consumer, is also gone), so argoproj now backs just ArgoCD, below the 2-row
concentration threshold ([docs/dependency-concentration.md](dependency-concentration.md)).
ArgoCD itself is still this lab's actual deployment mechanism — every other exit
runbook in this file assumes ArgoCD exists to execute the repoint — so its own
runbook stays:

**Mechanically:** ArgoCD is Terraform-bootstrapped (`infra/modules/argocd/`), not a
`gitops/` `Application` itself (ADR-0001's day-0 seam) — a real exit means swapping
the bootstrap module for a different GitOps controller's Terraform/Helm bootstrap,
then re-authoring every `gitops/**/*.yaml` `Application` manifest into the new
tool's own CRD shape (a real schema migration, not a repoint — different controllers
don't share one CRD API).

**Fork-and-repoint, or a bigger migration?** Exiting ArgoCD itself is this lab's
single largest possible dependency exit — every `Application` manifest in the repo
is written in its CRD's vocabulary.

**Alternative evaluated?** No — ADR-0001 chose ArgoCD/GitOps as the deployment model
itself, not as a like-for-like tool pick among GitOps controllers, so no rejected
alternative is on record for ArgoCD specifically. Same conclusion as the Grafana group: a
real exit starts with a new ADR, not an assumed replacement.

> `github.com/pingcap` (TiDB Operator, TiDB) previously had a runbook here — removed
> 2026-09-06 alongside TiDB itself, which was dropped from the lab entirely (no
> replacement; see [ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md)/
> [ADR-0032](decisions/adr-0032-tidb-version-policy.md)'s Status).

## `github.com/hashicorp` — 1 tool (Terraform); no longer a concentration group

Used to back 2 rows (Terraform + Terragrunt, gruntwork-io — a separate org —
and Vault); Vault (and External Secrets Operator, its only client) was removed
entirely 2026-09-07 (ADR-0042, supersedes ADR-0036/ADR-0037, no replacement —
explicit maintainer direction), so hashicorp now backs just Terraform, below
the 2-row concentration threshold
([docs/dependency-concentration.md](dependency-concentration.md)). Terraform's
own runbook stays below, same as ArgoCD's after the argoproj group thinned out
above.

---

## Remaining single-tool rows (highest blast-radius four)

Unlike the three groups above, each of these is a single tool with no shared-org
sibling — so each entry below is one paragraph, not three, covering the same ground
(mechanically, fork-and-repoint-or-bigger, alternative evaluated) more tersely.

**Cilium** and **Garage** ([ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md);
[ADR-0002](decisions/adr-0002-garage-not-minio.md)/
[ADR-0007](decisions/adr-0007-off-cluster-garage-tfstate-backend.md)) — moot,
component removed 2026-09-07, no replacement. Cilium's CNI/NetworkPolicy role is now
filled by k3s's bundled Flannel + kube-router (ADR-0016's "Cilium's removal"
section); Garage (both the in-cluster S3 store and the off-cluster tfstate backend)
has no replacement at all — no exit runbook is needed for a component that no
longer exists.

**Traefik** (ingress — [ADR-0040](decisions/adr-0040-traefik-not-envoy-gateway.md),
supersedes [ADR-0008](decisions/adr-0008-envoy-gateway-not-traefik.md)). Bundled
with k3s itself (no separate `Application` to point at — `infra/modules/k3d-cluster/`
just leaves it enabled) and fronts every `IngressRoute` in this lab — the front door
for every UI in README.md's Endpoints table. A real exit means picking a replacement
ingress controller and re-authoring every existing `IngressRoute`/`TLSStore`/
`TraefikService` into the new tool's shape (`IngressRoute` is a Traefik-proprietary
CRD, not a portable spec the way Gateway API's `HTTPRoute` was under the prior Envoy
Gateway choice — ADR-0040 names this trade-off explicitly — so this exit is closer
to a full fork-and-repoint than Cilium's CNI-level exit). ADR-0040 itself supersedes
ADR-0008's choice of Envoy Gateway; no further exit-direction alternative has been
separately evaluated since.

**cert-manager** (TLS lifecycle — [ADR-0028](decisions/adr-0028-cert-manager-tls-lifecycle.md)).
`gitops/platform/cert-manager.yaml` + `cert-manager-root-ca.yaml` issue every
in-cluster TLS certificate; unlike the other three, its failure mode is silent
(existing certs keep working until they expire) rather than an immediate outage — a
real exit is closer to fork-and-repoint (`Certificate`/`Issuer` are cert-manager's
own CRDs, so a replacement means re-authoring those resources into the new tool's
CRD shape, not a data migration). ADR-0028 doesn't record a rejected alternative
(cert-manager was this lab's first and only TLS-lifecycle choice) — no exit-direction
alternative has ever been evaluated.

## Remaining single-tool rows (the other seven)

The four highest-blast-radius single-tool rows above were covered first, worst-first,
per this file's original scope. This section covers the remaining seven single-tool
rows in [`docs/dependency-register.md`](dependency-register.md) — closing the rest of
[Q17](dora-audit-readiness.md)'s named gap. Same terse, one-paragraph-per-tool shape.

**Terraform / Terragrunt** (day-0 bootstrap seam —
[ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md)). Two different upstream
orgs (`hashicorp`, `gruntwork-io`) sharing one register row. Neither is a `gitops/`
`Application` — both run only once, at cluster bootstrap, before ArgoCD exists to
reconcile anything (the same day-0 seam Cilium and ArgoCD itself occupy). A real exit
means rewriting `infra/modules/**/*.tf` and every `infra/live/**/*.hcl` against a
different IaC tool's own syntax and state model — every backend module, every
Terragrunt `inputs` block. Lowest ongoing blast radius of any row in this file (it
only runs at bootstrap, never touches steady-state reconciliation) but the highest
one-time rewrite cost, since literally every `.tf`/`.hcl` file in the repo would need
re-authoring, not just one Application's source. No alternative has been evaluated —
ADR-0001's decision was GitOps-over-imperative, not a bake-off among IaC tools for the
bootstrap seam itself.

**RabbitMQ, Valkey, and KEDA** each had a runbook here (message broker/ADR-0009, cache
supersedes Redis/ADR-0018, event-driven autoscaling/ADR-0029 respectively) until all
three were removed from the lab entirely 2026-09-06, with no replacement — see each
ADR's own Status. No exit runbook is needed for a component that no longer exists.

**Forgejo** ([ADR-0035](decisions/adr-0035-forgejo-not-gitlab.md), supersedes
[ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md)) — moot, component
removed 2026-09-07, no replacement. No self-hosted git source runs any more;
ArgoCD clones directly from this repo's public GitHub remote. No exit runbook is
needed for a component that no longer exists.

(kube-state-metrics and node-exporter, the two remaining ADR-0034 exporters this
section used to cover individually, were removed 2026-09-06 alongside the rest of
the observability stack, ADR-0041 — same "no runbook needed, the dependency itself
is gone" resolution as the `github.com/grafana` group above.)

---

## Remaining single-tool rows (the final thirteen)

The eleven single-tool rows above were covered first, worst-first and then by
recency. This section covers the 13 single-tool rows found missing by the
2026-09-06 re-sweep named in the Scope note — closing out the rest of
[Q17](dora-audit-readiness.md)'s named gap again. Same terse,
one-paragraph-per-tool shape as the two sections above.

**Kyverno** ([ADR-0019](decisions/adr-0019-kyverno-admission-engine.md)),
**Velero** ([ADR-0021](decisions/adr-0021-velero-backup-restore.md)),
**Trivy Operator** ([ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md)),
and **Kargo** ([ADR-0023](decisions/adr-0023-kargo-promotion-pipeline.md)) — moot,
all four removed 2026-09-07, no replacement. capstone, Kyverno's/Kargo's/Argo
Rollouts' shared consumer, is also gone. No exit runbook is needed for a component
that no longer exists.

**Harbor** (on-demand artifact registry, supersedes Artifactory —
[ADR-0024](decisions/adr-0024-harbor-not-artifactory.md)) — moot, component removed
2026-09-07, no replacement. No exit runbook is needed for a component that no
longer exists.

**Oracle Cloud Infrastructure** (cloud backend, opt-in —
[ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md)).
Not part of the localhost budget tiers at all — an alternate Terraform/
Terragrunt backend (`infra/live/oracle/{cluster,argocd}/`, `infra/
modules/oracle-k3s-cluster/`) provisioning a k3s VM plus an off-host Garage
tfstate instance, both on Oracle's Always Free tier. A real exit means
picking a different permanently-free cloud and rewriting the entire
`oracle-k3s-cluster` module and its two-instance bootstrap sequence from
scratch — not a repoint, since ADR-0026's cloud-agnostic contract only
guarantees the *output shape* (`cluster_name`/`kube_context`/`api_endpoint`),
not portable Terraform. ADR-0027's own comparison table found **Azure AKS**
and **GKE Autopilot** both fail ADR-0025's zero-spend bar on compute cost,
leaving Oracle the only option that cleared it at adoption time — a real exit
to a different provider starts from that same table, re-run against current
pricing.

**k3s** (cluster engine —
[ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md)
backend choice / [ADR-0030](decisions/adr-0030-pin-k3s-version-explicitly.md)
version pin). Runs underneath both backends — `infra/modules/k3d-cluster/`
(localhost) and `infra/modules/oracle-k3s-cluster/` (Oracle, bare k3s via
cloud-init) — the single most privileged layer in the stack and the day-0
seam every `gitops/` `Application` assumes exists before ArgoCD can reconcile
anything. A real exit means swapping the cluster distribution itself (k0s,
kubeadm, a managed control plane) and rewriting both Terraform modules' install
mechanism from scratch — the highest-blast-radius exit possible short of
exiting Kubernetes entirely, since literally everything in `gitops/` runs on
top of it. No alternative Kubernetes distribution has ever been evaluated
against k3s — ADR-0027's comparison was "k3s vs. a managed control plane"
(rejected on cost, not distribution features) and ADR-0030 only pins k3s's
own version — a real distribution-level exit starts with a new ADR, same as
every group above.

**moto, ACK S3 controller, and KRO** (all three —
[ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md)) — moot, all
three removed 2026-09-07, no replacement. ACK and moto were dropped by explicit
maintainer request; KRO went with them as an orphaned dependent (its only
`ResourceGraphDefinition` claimed an ACK `Bucket`). No exit runbook is needed for
a component that no longer exists.

**s3manager** ([ADR-0039](decisions/adr-0039-s3manager-garage-browser-ui.md)) —
moot, component removed 2026-09-07, no replacement. It was Garage's browser UI
with no purpose independent of Garage, which was removed the same day (no
replacement); s3manager was orphaned by that removal and dropped alongside it.
No exit runbook is needed for a component that no longer exists.

**Vault and External Secrets Operator** (secrets backend + sync operator —
[ADR-0037](decisions/adr-0037-vault-secrets-management.md)/
[ADR-0036](decisions/adr-0036-external-secrets-vault-sync.md); formerly the
`github.com/hashicorp` concentration group's other member, with Terraform, see
above) — moot, both removed 2026-09-07 (ADR-0042, supersedes ADR-0036/
ADR-0037, no replacement — explicit maintainer direction). ESO had zero live
`ExternalSecret` consumers left in the repo by the time it was cut — every
component that had ever needed a Vault-held credential (Garage, Harbor, Kargo,
Velero, ACK, capstone) was already gone. No exit runbook is needed for a
component that no longer exists.

---

## Keeping this in sync

This file is a downstream consumer of two others: [`docs/dependency-
concentration.md`](dependency-concentration.md)'s named concentration groups
(a new group appearing there should get a runbook section here) and
[`docs/dependency-register.md`](dependency-register.md)'s criticality column (a new
row there — a new ADR naming a new tool — should get a runbook section here too, same
as a new concentration group).

**Both halves are now mechanically guarded.** As of 2026-09-02/03,
`scripts/dependency-exit-runbooks-sync-check.sh` (`make
dependency-exit-runbooks-sync-check`, wired into `make ci`'s `drift` job) failed the
build if any `github.com/ORG` group named in `dependency-concentration.md` had no
matching `## \`github.com/ORG\`` section here — a new concentration group could no
longer silently go un-runbooked. **The register single-tool-row half was not**, and
that gap bit for real, not hypothetically: the 2026-09-03 entry above made a
"coverage is complete" claim for 11 rows, and 13 more rows were added to the register
in the three days since without a matching runbook entry, undetected until a manual
re-sweep on 2026-09-06 (this same session, adding the 13 entries above). Per this
repo's own bugfix-must-prevent-recurrence rule, that re-sweep also **extended the
same script** to add a second phase: every `Tool` name in `dependency-register.md`'s
table must now appear somewhere in this file (its own `**Name**` heading, or listed
by name inside a concentration-group section header) or `make
dependency-exit-runbooks-sync-check` fails, the same way phase 1 already did for
concentration groups. The `PostToolUse` hook
(`scripts/dependency-exit-runbooks-sync-hook.sh`) was extended to watch
`docs/dependency-register.md` edits too, not just this file's and
`dependency-concentration.md`'s, since a new un-runbooked row is added by editing
the register, not this file. A future new register row can no longer silently go
un-runbooked the way the 13-row gap did.
