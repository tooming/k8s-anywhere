# ADR-0038 — moto + ACK (S3) + KRO for the cloud-control-plane demo pattern

**Status.** Adopted (retroactive record). All three components are already live in
`gitops/` — this ADR closes a documentation gap, not a new technical choice. No
binding ADR is contradicted or superseded; self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2, same precedent as
[ADR-0036](adr-0036-external-secrets-vault-sync.md) (External Secrets Operator) and
[ADR-0037](adr-0037-vault-secrets-management.md) (Vault): a real, already-implemented,
already-live mechanism that predated having any ADR of its own. KRO is currently
**suspended** in the live cluster (manual sync only, replicas scaled to 0 — see
§Suspension below); moto and ACK-S3 are always-on.

---

## Context

CHARTER's "Target end-state" names "moto/ACK/KRO" as part of the always-on core
(`README.md`, `docs/decisions/context.md`, ROADMAP.md all reference the trio by
name), and all three have real ArgoCD `Application`s, PSA `restricted` namespaces,
default-deny NetworkPolicy, a Grafana dashboard
(`grafana/dashboards/lab-cloud-control-plane.json`), and dedicated bats coverage
(`tests/ack-s3.bats`, `tests/securitycontext-kro.bats`,
`tests/securitycontext-moto-ack-labgateway.bats`,
`tests/networkpolicy-{ack-system,kro,moto}.bats`) — yet, unlike every other
always-on component, none of the 37 ADRs prior to this one names them as its
subject. Their real version-bump history instead lived only as inline YAML
comments in `gitops/platform/ack-s3.yaml` (the same shape ADR-0037 found and
migrated for Vault) — a genuine documentation gap, not a new decision to make.

**Why this trio exists.** The lab's "platform engineering" teaching goal needs a
concrete, safe way to demonstrate "cloud infrastructure provisioned via a
Kubernetes-native API" without touching a real cloud account or paying real
money (ADR-0025's free/OSS-tier rule):

- **moto** — a Python/FastAPI, token-free AWS API emulator (replaces LocalStack).
  Gives ACK a real HTTP endpoint that speaks the actual AWS S3 API without any
  AWS account or cost.
- **ACK (AWS Controllers for Kubernetes), S3 service controller** — manages "AWS"
  S3 buckets as a native Kubernetes CRD (`kind: Bucket`), pointed at moto instead
  of real AWS via `endpoint_url` + `allow_unsafe_aws_endpoint_urls` +
  `endpoint_use_path_style` (moto is plain HTTP and needs path-style bucket
  addressing — virtual-host style has no DNS here).
- **KRO (Kube Resource Orchestrator)** — the platform-API layer on top: a
  `ResourceGraphDefinition` (`S3BucketClaim`) composes one high-level claim into
  an ACK `Bucket` + a catalog `ConfigMap`, the "one claim provisions cloud + k8s
  resources together" pattern a platform team would actually build.

---

## Decision

Adopt all three as the lab's cloud-control-plane demo stack.

### moto

- **Image:** `motoserver/moto:5.2.2` (bumped to `5.2.3` in this same cycle — see
  §Re-evaluation log).
- **Deployment shape:** plain in-repo manifest (`gitops/moto/`), not a Helm
  chart — the ArgoCD `Application` (`gitops/platform/moto.yaml`) sources this
  repo's own `gitops/moto` path directly (`targetRevision: main`).
- **Namespace:** `moto`, PSA `restricted` (uid 65534/`nobody`, no root or Linux
  capabilities needed — full `restricted` profile achievable with zero
  carve-out).
- **Ephemeral:** no persistence (`emptyDir` for `/tmp` only) — fine for ACK
  demos; a restart just means real S3 state is gone, matching a real AWS
  account only in shape, not in continuity.

### ACK S3 controller

- **Chart:** `s3-chart` `1.11.0` (`public.ecr.aws/aws-controllers-k8s`, the
  official AWS-published chart registry).
- **Namespace:** `ack-system`, `installScope: cluster`, PSA `restricted` (uid
  65534, full profile, no carve-out).
- **Credentials:** dummy creds from Vault via ESO (`ack-aws-creds` Secret, INI
  format, `secret/aws/moto` — see [ADR-0036](adr-0036-external-secrets-vault-sync.md)).
- **Known limitation (upstream, documented like Beyla's own known-limitation
  precedent):** ACK's S3 `ReadOne` panics (nil deref, `hook.go:460`) because
  moto's `GetBucketEncryption` returns a `...NotFoundError` instead of a
  default-SSE config (real S3 always returns one; moto's `latest` tag doesn't
  either) — ACK doesn't nil-check it. The `Bucket` CR still gets created
  successfully in moto, but `ACK.ResourceSynced` stays `False` and the
  controller reconcile-panic-loops (with backoff). Not fixable via config —
  would need patching ACK or moto upstream. **ArgoCD reports the Application
  Healthy regardless** (no health check exists for the ACK `Bucket` kind), so
  the `Bucket`'s own `ResourceSynced` condition — not ArgoCD's green — is the
  real truth for this component (ADR-0004: don't trust the wrong signal).

### KRO

- **Chart:** `kro` `0.9.3` (`ghcr.io/kro-run/kro`, OCI registry ref).
- **Namespace:** `kro`, `rbac.mode: unrestricted` (default — KRO needs this to
  manage arbitrary resource kinds its RGDs reference, including ACK `Bucket`s),
  PSA `restricted` at the pod level (uid 65534, full profile).
- **Upstream project moved orgs** (verified live during this ADR's authorship,
  2026-09-03): the project's GitHub repo now resolves at `kubernetes-sigs/kro`
  (a Kubernetes SIG Cloud Provider subproject) — `github.com/kro-run/kro`
  transparently redirects there. This lab's chart pull path
  (`ghcr.io/kro-run/kro`) is a container registry reference, a separate system
  from the GitHub org the source lives under, and continues to resolve
  normally — noted here as a real fact worth tracking, not an action item;
  revisit if the OCI path itself ever stops resolving.

---

## Suspension (2026-08-24, cluster-load reduction)

KRO's controller was chronically crash-looping (216+ restarts over 13 days) —
"failed to wait for ResourceGraphDefinition caches to sync," a downstream
symptom of this host's apiserver being too slow to satisfy KRO's own
informer-sync startup timeout, not an independent bug in KRO itself. Each
crash-restart triggered a fresh full-cache resync (a burst of List/Watch calls
against the shared k3s datastore), making a chronically-crashing KRO also a
contributor to the same apiserver/datastore write pressure it was a victim of.
**Decision: suspend, not remove.** KRO is CHARTER-mentioned demo infrastructure
(cloud control-plane patterns), not ADR-mandated core infra, so it's the right
thing to trim first under this host's 12 GB budget. Turned off via
`syncPolicy` (the `automated` block removed, not a Helm values field — this
chart's OCI ref isn't independently pullable from a clusterless session to
verify a values-field name against its real schema, and this repo has been
burned before by a values key that silently no-ops because it doesn't match
the chart's actual schema; see `harbor.yaml`'s `extraEnvVarsSecret` /
`pyroscope.yaml`'s dead securityContext-key comments for that history). Live
replicas scaled to 0 directly. **Re-enable by restoring the `automated` block
in `gitops/platform/kro.yaml` once the cluster has real headroom again** — a
live-cluster/interactive-session action, not executor-buildable.

---

## Observability

`grafana/dashboards/lab-cloud-control-plane.json` (ADR-0004: real, auto-discovered
data, no stubs): per-component pod status/memory/CPU/restarts (KSM + cAdvisor)
and ArgoCD sync state for all three (`moto`, `ack-system`, `kro` namespaces),
plus an about-text panel noting the ACK `ReadOne` panic limitation above and
that a controller pod count is the more reliable KRO health signal than
ArgoCD's own green.

## NetworkPolicy + PSS

- `gitops/moto/networkpolicy/`: allow ingress from `ack-system` (ACK reaching
  the S3 endpoint) and from the shared gateway namespace (demo UI access).
- `gitops/ack/networkpolicy/`: allow egress to `moto` (the emulated AWS
  endpoint).
- `gitops/kro/networkpolicy/`: allow egress to `ack-system` (KRO reconciling
  ACK `Bucket`s the RGD composes).
- All three namespaces carry PSA `restricted` labels (see per-component
  sections above) — no carve-out needed anywhere in this trio, all three run
  as uid 65534 with the full profile.

## Test coverage

`tests/ack-s3.bats`, `tests/securitycontext-kro.bats`,
`tests/securitycontext-moto-ack-labgateway.bats`,
`tests/networkpolicy-ack-system.bats`, `tests/networkpolicy-kro.bats`,
`tests/networkpolicy-moto.bats` — Application shape, chart/image pins, PSA
labels + pod/container securityContext, and NetworkPolicy rules, all
clusterless-verifiable.

---

## Files

| Path | Role |
|------|------|
| `docs/decisions/adr-0038-ack-kro-moto-cloud-control-plane.md` | This ADR |
| `gitops/platform/moto.yaml` | Auto-synced ArgoCD `Application` (in-repo manifest source) |
| `gitops/moto/*.yaml` | moto Deployment, Service, HTTPRoute, namespace, NetworkPolicy |
| `gitops/platform/ack-s3.yaml` | Auto-synced ArgoCD `Application` (AWS-published chart) |
| `gitops/ack-resources.yaml` | ACK RBAC/CRD scaffolding |
| `gitops/ack/networkpolicy/` | ACK's default-deny overlay |
| `gitops/platform/kro.yaml` | ArgoCD `Application`, manual-sync only while suspended |
| `gitops/platform/kro-extras.yaml` | KRO namespace/PSA scaffolding (stays auto-synced) |
| `gitops/kro-resources.yaml` | The `S3BucketClaim` ResourceGraphDefinition |
| `gitops/kro/networkpolicy/` | KRO's default-deny overlay |
| `grafana/dashboards/lab-cloud-control-plane.json` | Real-metric dashboard |
| `docs/decisions/context.md` | Component summary + the ACK `ReadOne` known-limitation note |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | All three land as ArgoCD `Application`s; moto sources this repo's own manifests directly. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard reads real KSM/cAdvisor/ArgoCD data; the ACK `ReadOne` limitation is documented rather than papered over, and ArgoCD's own "Healthy" is explicitly named as not the real signal for this component. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | All three namespaces get default-deny during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | All three land at full `restricted` with zero carve-out (uid 65534 throughout). |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | moto replaces any real AWS account entirely — zero cost, zero token. |
| [ADR-0036](adr-0036-external-secrets-vault-sync.md) | ACK's dummy AWS credentials flow through Vault → ESO, same mechanism as every other secret in the lab. |

---

## Re-evaluation log

### 2026-08-17 — ACK S3 chart bumped `1.9.0` → `1.10.0` (upstream-currency gap-analysis)

**Migrated from `gitops/platform/ack-s3.yaml`'s own inline comment** (this ADR
didn't exist yet). Executor.prompt.md STEP 6b/rule #9 filler after every
Now/next item was re-confirmed gated on #631/#633. Verified directly (not
assumed, ADR-0004): the upstream repo's `Chart.yaml` at tag `v1.10.0` shows
`version`/`appVersion` `1.10.0` (one minor release ahead of the prior `1.9.0`
pin, not a major bump); the tag's only functional change is "feat: add ABAC
field to Bucket" (#241) plus a routine ACK runtime/code-generator bump
(`v0.62.0` → `v0.62.1`, #244) — no change to any key this Application's
`valuesObject` sets (`aws.*`, `installScope`, `podSecurityContext.*`,
`securityContext.*`, `resources.*`).

### 2026-09-01 — ACK S3 chart bumped `1.10.0` → `1.11.0` (upgrade-drafter fallback)

**Migrated from `gitops/platform/ack-s3.yaml`'s own inline comment.** Verified
directly (ADR-0004) via a real clone of `aws-controllers-k8s/s3-controller`:
`git diff v1.10.0 v1.11.0 -- helm/Chart.yaml helm/values.yaml` shows the
version/appVersion/image.tag bump plus exactly one new key,
`featureGates.IgnoreFieldDrift: false` (a new opt-in feature, default off) —
this Application's `valuesObject` sets no `featureGates` override at all, so
it's a complete no-op here. Upstream's own release notes name the real
feature: "Support tags at CreateBucket time from `Spec.Tagging`" plus an ACK
runtime bump to `v0.63.0`.

### 2026-09-03 — ADR authored (retroactive record); moto bumped `5.2.2` → `5.2.3`; full currency + GHSA check across all three

**Trigger.** This run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) found moto/ACK/KRO — despite being real, live, already-hardened
always-on components with their own dashboard and bats coverage — had no
governing ADR and no `docs/dependency-register.md` row at all, unlike every
other component in the lab. Same shape as the ADR-0036/ADR-0037 gaps closed
earlier this run.

**Checked directly against live sources (ADR-0004), all three components:**

- **moto:** Docker Hub's tags API confirms `5.2.3` is real (`last_updated:
  2026-08-22T18:51:38Z`) and is the newest patch (`5.2.4` returns 404). No
  published GHSA advisories exist for `getmoto/moto` at all. Bumped
  `gitops/moto/deployment.yaml`'s image tag `5.2.2` → `5.2.3` — a routine
  patch, no CVE, no `valuesObject`-equivalent keys to diff (plain manifest, not
  a chart).
- **ACK S3 controller:** `raw.githubusercontent.com/aws-controllers-k8s/
  s3-controller/v1.11.1/helm/Chart.yaml` returns 404 — `1.11.0` (bumped above,
  2026-09-01) is still the newest tag. No published GHSA advisories exist for
  `aws-controllers-k8s/s3-controller`.
- **KRO:** confirmed via the real GitHub releases list that `v0.9.3` (released
  27 Jul) is still the newest tag — no `v0.9.4` exists (a `v0.9.4` fetch at the
  chart's `Chart.yaml` path 404s, consistent with no such tag existing at all,
  not a path-naming mismatch — verified by also 404ing on the known-current
  `v0.9.3` tag at the same path, meaning this chart's `Chart.yaml` simply isn't
  under a flat repo-root path; the GitHub releases list itself is the reliable
  signal here). No published GHSA advisories exist for `kubernetes-sigs/kro`
  (the project's current org — see §KRO above for the org-move finding).

**Decision: keep ACK S3 at `1.11.0` and KRO at `0.9.3` (both already current);
bump moto to `5.2.3`.** No CVE-driven urgency anywhere in the trio.

No `gitops/` change for ACK-S3 or KRO (already current — see PR history
above). `docs/dependency-register.md` gains a row each for moto, ACK S3
controller, and KRO in this same cycle.

**Flip condition (next re-evaluation).** Re-check moto/ACK-S3/KRO currency and
GHSA status on the next full-sweep pass; re-check whether KRO's suspension can
lift once a live-cluster session confirms the apiserver/datastore write
pressure that caused the 2026-08-24 crash-loop has real headroom again.
