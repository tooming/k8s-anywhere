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
(Q16) named three upstream-org concentration groups, worst-first — this file covers
those three plus, as of 2026-09-02, the four highest-blast-radius of the single-tool
rows in [`docs/dependency-register.md`](dependency-register.md) (Cilium —
the CNI every pod's traffic depends on; Garage — the only stateful S3-compatible
store; Traefik — the sole ingress path for every UI in this lab; cert-manager —
TLS issuance, a silent failure mode if it stops), and, as of 2026-09-03, seven more
(Terraform/Terragrunt, RabbitMQ, Valkey, KEDA, Forgejo, kube-state-metrics,
node-exporter). That left this file's own coverage claim stale the moment the
register kept growing: as of 2026-09-06, a re-sweep against the register's current 32
rows found 13 single-tool rows with no runbook entry at all — Kyverno, Velero, Trivy
Operator, Kargo, Harbor, Oracle Cloud Infrastructure, k3s, moto, ACK S3 controller,
KRO, s3manager, Vault, and External Secrets Operator (three more names — Istio, Kiali,
Longhorn — were also flagged as missing before this sweep started, but by the time it
ran those tools, and their register rows, had already been removed from the lab
entirely per the note in the `github.com/argoproj` section above, so they need no
runbook of their own). Adding those 13 below closes out full coverage of every
single-tool row named in the register's criticality column, again. Said plainly
rather than silently narrowed (ADR-0004: an unscoped "covers dependencies" title would
itself overclaim completeness) even now that coverage is complete — a future new row
in the register (a new ADR naming a new tool) would still need its own runbook added
here, same as any new concentration group, and per the mechanical-guard gap named in
"Keeping this in sync" below, nothing currently catches that automatically.
(`github.com/grafana` and its two exporters were removed 2026-09-06, ADR-0041,
observability stack removed with no replacement — the same day this sweep ran, one
of the reasons it ran — and `github.com/pingcap` was removed the same day alongside
TiDB, ADR-0031/ADR-0032; both are covered by their own "no runbook needed" notes
below rather than counted among the 13.)

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

## `github.com/argoproj` — 2 tools (ArgoCD, Argo Rollouts)

Couples the GitOps control plane itself ([ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md),
`always-on-core`) to the progressive-delivery layer built on top of it
([ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md),
`always-on-next-wave`, CHARTER Objective O1). Lower blast radius than the Grafana-org
cluster (2 rows vs. 6), but ArgoCD is this lab's actual deployment mechanism — every
other exit runbook in this file assumes ArgoCD exists to execute the repoint.

**Mechanically:** ArgoCD is Terraform-bootstrapped (`infra/modules/argocd/`), not a
`gitops/` `Application` itself (ADR-0001's day-0 seam) — a real exit means swapping
the bootstrap module for a different GitOps controller's Terraform/Helm bootstrap,
then re-authoring every `gitops/**/*.yaml` `Application` manifest into the new
tool's own CRD shape (a real schema migration, not a repoint — different controllers
don't share one CRD API). Argo Rollouts is a normal auto-synced `Application`
(`gitops/platform/argo-rollouts.yaml`) with its own CRDs (`Rollout`,
`AnalysisTemplate`) consumed by `gitops/apps/capstone/rollout.yaml` — exiting it
means picking a different progressive-delivery controller and rewriting the
capstone `Rollout` object into that tool's canary/analysis shape.

**Fork-and-repoint, or a bigger migration?** Exiting ArgoCD itself is this lab's
single largest possible dependency exit — every `Application` manifest in the repo
is written in its CRD's vocabulary. Exiting Argo Rollouts alone is narrower: one
consumer (`capstone`), one CRD family to rewrite.

**Alternative evaluated?** No — ADR-0001 chose ArgoCD/GitOps as the deployment model
itself, not as a like-for-like tool pick among GitOps controllers, so no rejected
alternative is on record for ArgoCD specifically. Argo Rollouts likewise has no
recorded rejected alternative in ADR-0020. Same conclusion as the Grafana group: a
real exit starts with a new ADR, not an assumed replacement.

> `github.com/pingcap` (TiDB Operator, TiDB) previously had a runbook here — removed
> 2026-09-06 alongside TiDB itself, which was dropped from the lab entirely (no
> replacement; see [ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md)/
> [ADR-0032](decisions/adr-0032-tidb-version-policy.md)'s Status).

---

## Remaining single-tool rows (highest blast-radius four)

Unlike the three groups above, each of these is a single tool with no shared-org
sibling — so each entry below is one paragraph, not three, covering the same ground
(mechanically, fork-and-repoint-or-bigger, alternative evaluated) more tersely.

**Cilium** (CNI — [ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md)).
`gitops/platform/cilium.yaml` is Terraform-bootstrapped, not a `gitops/` `Application`
(ADR-0001's day-0 seam, like ArgoCD itself) — every pod's network path, and this
lab's entire default-deny `NetworkPolicy` posture (ADR-0016), depends on it. A real
exit is the single highest-blast-radius one in this file: swap the bootstrap CNI
install, then re-verify every existing `NetworkPolicy` manifest still expresses the
intended rules under the new CNI's policy engine (not guaranteed — policy dialects
differ). No alternative has been re-evaluated since ADR-0014 rejected Flannel +
Kubernetes' bundled NetworkPolicy controller at adoption time; a real exit starts
with a new ADR, same as every group above.

**Garage** (S3-compatible storage — [ADR-0002](decisions/adr-0002-garage-not-minio.md)/
[ADR-0007](decisions/adr-0007-off-cluster-garage-tfstate-backend.md)). The lab's only
stateful S3-compatible store — Velero backups, Mimir/Loki/Tempo chunks, and
Terraform state (off-cluster instance) all target it directly. `gitops/platform/
garage.yaml` is a normal auto-synced `Application`, but a real exit is a genuine
data migration (every bucket's real content), not a repoint — the S3 API surface is
portable, the data behind it is not. ADR-0002 rejected MinIO at adoption time; no
exit-direction alternative has been separately evaluated since.

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

**Forgejo** (self-hosted git source + CI runner —
[ADR-0035](decisions/adr-0035-forgejo-not-gitlab.md), supersedes
[ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md)). Runs at the host level
(Docker Compose), outside the cluster entirely — every ArgoCD `Application`'s
`repoURL` and the CI pipeline that signs the capstone image both depend on it
directly. This lab has *already executed* one exit in this exact slot
(GitLab→Forgejo, PR #1205, live 2026-08-17) — the most recent, most directly
applicable precedent in this file: a real exit means standing up the replacement,
re-pointing all ~121 `Application` `repoURL`s, re-registering deploy keys/webhooks,
and porting `.forgejo/workflows/*.yml` to the new tool's own CI syntax — a
same-day-achievable repoint for the git-hosting role itself, but the CI-workflow port
is a real rewrite, not a value swap (demonstrated by that migration's own real
findings, e.g. the `GITEA__server__SSH_LISTEN_PORT` bug). No rejected alternative is
recorded for Forgejo specifically beyond GitLab (ADR-0035's own comparison).

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

**Kyverno** (admission policy engine —
[ADR-0019](decisions/adr-0019-kyverno-admission-engine.md)). `gitops/platform/
kyverno.yaml` (the engine) and `gitops/kyverno/policies/*.yaml` (five
`ClusterPolicy` resources) are normal auto-synced `Application`s that gate
admission for every workload in the lab. A real exit means standing up a
replacement admission engine and rewriting all five policies (the PSS
backstop, `disallow-latest-tag`, two mutating defaults, and cosign
`verifyImages`) into the new tool's own policy language — Kyverno's YAML-CR
syntax and CEL/JMESPath idioms don't translate directly to, say, Gatekeeper's
Rego, so this is closer to a real rewrite than a repoint even though swapping
the `Application` itself is trivial. ADR-0019 explicitly compared Kyverno
against **OPA Gatekeeper** (the only other CNCF-graduated admission engine) at
adoption time and chose Kyverno for native Kubernetes-resource syntax and
built-in cosign support — Gatekeeper is a recorded, evaluated alternative, a
documented starting point most rows in this file don't have.

**Velero** (backup/restore — [ADR-0021](decisions/adr-0021-velero-backup-restore.md)).
`gitops/platform/velero.yaml` (controller + node-agent) and `gitops/platform/
velero-schedules.yaml` (six per-namespace `Schedule`s) are normal auto-synced
`Application`s; `make dr-restore` (CHARTER Objective O3) depends on them
directly. A real exit is closer to a data migration than a repoint — backups
already stored in Garage are in Velero's own Kopia-snapshot format, not
portable to a different backup tool without a full restore-then-rebackup
cycle, and `scripts/dr-restore.sh` would need rewriting against the
replacement's own restore CLI/CRD shape. ADR-0021 evaluated and rejected two
alternatives at adoption time — **Stash** (deprecated upstream) and **Kasten
K10** (commercial, fails ADR-0025's free/OSS-tier rule) — so a real exit
starts with a recorded rejected pair, though a third genuinely OSS
alternative may not exist today.

**Trivy Operator** (continuous vulnerability + SBOM scanning —
[ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md)). `gitops/
platform/trivy-operator.yaml` is a normal auto-synced `Application` scanning
every namespace under `gitops/`; the `lab-trivy.json` dashboard and any future
Kyverno-Trivy integration both assume its `VulnerabilityReport`/`SbomReport`/
`ConfigAuditReport` CRs exist. A real exit is close to fork-and-repoint for
the data itself — CVE/SBOM findings are regenerated continuously from image
content, not stored state, so a replacement scanner starts clean with no
migration — but every CR type the dashboard queries would need re-mapping to
the new tool's own CRD/metric shape. ADR-0022 named **Falco Sidekick +
Falcoctl** (runtime-focused, not image/SBOM-focused) and **Anchore
Grype-Operator** (chart judged too immature) as considered-but-not-adopted —
not a formal head-to-head rejection the way MinIO/Redis were, but not a
from-zero starting point either.

**Kargo** (GitOps promotion pipelines —
[ADR-0023](decisions/adr-0023-kargo-promotion-pipeline.md)). ON-DEMAND (`make
kargo-up`/`kargo-down`) — four `gitops/platform/kargo*.yaml` `Application`s
define the `capstone-pipeline` Warehouse/Stage pipeline. A real exit means
picking a different promotion-orchestration tool and rewriting the
`Warehouse`/`Stage`/`Freight` resources into its own CRDs — narrow blast
radius since it's on-demand and only the capstone `kustomization.yaml`
depends on Kargo's image-override mechanism. ADR-0023 named **Flux** and
**Argo Workflows** as compared alternatives, rejected for lacking Kargo's
artifact-source-agnostic Warehouse model and first-class promotion UI — a
recorded starting point for a real exit.

**Harbor** (on-demand artifact registry, supersedes Artifactory —
[ADR-0024](decisions/adr-0024-harbor-not-artifactory.md)). ON-DEMAND (`make
harbor-up`/`harbor-down`) — `gitops/platform/harbor.yaml` is a non-auto-synced
`Application`; the capstone CI pipeline pushes/pulls images against
`harbor.127.0.0.1.nip.io` directly. A real exit is a genuine data migration
(every stored image layer) plus re-pointing every CI push/pull target and
Kyverno's `verify-image-signatures` registry-match list — this lab has
**already executed this exact exit once** (ADR-0011→ADR-0024,
Artifactory→Harbor), the most directly relevant precedent in this file for
what a real registry exit looks like end-to-end, alongside the Forgejo/GitLab
precedent above. ADR-0024 explicitly compared and rejected **Sonatype Nexus**
and continuing on Artifactory — a documented two-way comparison, not a
from-scratch bake-off.

**Oracle Cloud Infrastructure** (cloud backend, opt-in —
[ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md)).
Not part of the localhost budget tiers at all — an alternate Terraform/
Terragrunt backend (`infra/live/oracle/{cluster,argocd,gitlab}/`, `infra/
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

**moto** (AWS API emulator —
[ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md)).
`gitops/platform/moto.yaml` sources this repo's own in-repo manifest
(`gitops/moto/`), not a Helm chart — a normal auto-synced `Application`, PSA
`restricted`, no persistence (`emptyDir` only). Exiting moto means replacing
it with a different free AWS-API emulator and repointing ACK's S3
controller's `endpoint_url`/`allow_unsafe_aws_endpoint_urls`/
`endpoint_use_path_style` config at it — no data migration (moto holds no
persistent state), but ACK's own `ReadOne` panic against moto's
`GetBucketEncryption` gap (documented in ADR-0038) may or may not reproduce
against a different emulator, so the exit isn't purely mechanical. ADR-0038's
own Context names **LocalStack** as the predecessor moto replaced — a real
prior exit exists as precedent, though it predates this ADR and was never
written up as a formal comparison at the time.

**ACK S3 controller** (AWS Controllers for Kubernetes, S3 service —
[ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md)).
`gitops/platform/ack-s3.yaml` (the official AWS-published `s3-chart`) is a
normal auto-synced `Application` in `ack-system`; KRO's `S3BucketClaim`
composes on top of its `Bucket` CRD. A real exit means picking a different
"cloud resources as Kubernetes CRDs" controller (**Crossplane** is the other
major entrant in this space) and rewriting KRO's `ResourceGraphDefinition` to
compose the new controller's CRD instead — a schema migration for every
consumer of the `Bucket` kind, narrow here since KRO is the only consumer. No
alternative to ACK has been evaluated in ADR-0038 — it was adopted as the
natural counterpart to moto's AWS-API emulation, not compared against
Crossplane or a similar tool.

**KRO** (Kube Resource Orchestrator —
[ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md)).
Currently **suspended** (manual-sync, replicas scaled to 0 since 2026-08-24,
per the ADR's own Suspension section) — `gitops/platform/kro.yaml` +
`gitops/kro-resources.yaml`'s `S3BucketClaim` `ResourceGraphDefinition` is
the platform-API layer composing ACK's `Bucket` CRD into a higher-level
claim. A real exit means picking a different resource-composition layer
(**Crossplane Compositions** is the closest analog) and rewriting the one
existing RGD into the new tool's own composition schema — low blast radius
today since KRO is already non-functional in the live cluster, so an exit
here is closer to "finish deciding whether to resurrect or replace it" than
an urgent cutover. No alternative has been evaluated — KRO was adopted for
its resource-graph model with no recorded comparison against Crossplane or a
similar tool.

**s3manager** (Garage browser UI —
[ADR-0039](decisions/adr-0039-s3manager-garage-browser-ui.md)). `gitops/
platform/s3manager.yaml` sources this repo's own in-repo manifest
(`gitops/storage/s3manager/`); it is a stateless, read-only UI over Garage's
S3 API with no data of its own. The lowest-blast-radius exit in this file —
losing it loses only a convenience view, since the CLI/`aws s3` path to the
same data is unaffected — and a real exit is pure fork-and-repoint: point a
different open-source S3-browser UI at the same `garage-s3` Secret
credentials and the existing NetworkPolicy/HTTPRoute pattern. No alternative
has been evaluated — ADR-0039 adopted `cloudlena/s3manager` as the first and
only S3-browser UI considered, chosen for its lightweight, stateless,
single-binary shape rather than compared against alternatives.

**Vault** (secrets backend —
[ADR-0037](decisions/adr-0037-vault-secrets-management.md)). `gitops/
platform/vault.yaml` is a normal auto-synced `Application`; every credential
ESO delivers to every other component (Garage, Harbor, Grafana, Kargo,
Velero, ACK, the capstone app) is actually held here, in Vault's KV v2 engine
on a 1Gi file-storage PVC — the lab's one real secrets-of-record store. A
real exit is a genuine data migration (every KV secret, re-created or
exported/imported) plus repointing ESO's `ClusterSecretStore` provider config
at the replacement backend — not a repoint, since Vault's KV v2 API shape is
Vault-specific. ADR-0037 doesn't record a rejected alternative (Vault was
this lab's first and only secrets-backend choice, adopted as infrastructure
glue before it had its own ADR) — no exit-direction alternative has ever been
evaluated, the same "starts with a new ADR" conclusion as most rows above.

**External Secrets Operator** (Vault-backed secret sync —
[ADR-0036](decisions/adr-0036-external-secrets-vault-sync.md)). `gitops/
platform/external-secrets.yaml` (engine) plus `gitops/secrets/*.yaml` (the
`ClusterSecretStore` and every component's `ExternalSecret`) are normal
auto-synced `Application`s — every native `Secret` object in the cluster
that isn't hand-created flows through this mechanism. A real exit means
picking a different secret-sync operator (or reverting to the **Vault Agent
Injector** / **Vault CSI provider**, both explicitly named as
never-evaluated alternatives in ADR-0036's own Scope & exceptions) and
rewriting every `ExternalSecret` resource into the new tool's own CRD shape
across every namespace that has one — broad blast radius (touches every
component with a credential) but mechanically uniform, one CRD shape
migrated repeatedly, closer to fork-and-repoint than a Cilium-style CNI exit.
Uniquely among rows in this file, ADR-0036 already names the *not-yet-
evaluated* alternatives explicitly ("no case has been made to reconsider
ESO") even though no comparison has actually been run.

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
