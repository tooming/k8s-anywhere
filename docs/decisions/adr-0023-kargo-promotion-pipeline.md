# ADR-0023 — Kargo for GitOps promotion pipelines (multi-stage, Warehouse-gated)

**Status.** Adopted. On-demand component (bring up with `make kargo-up`). Complements
Argo Rollouts (ADR-0020): Rollouts controls *how* a version lands in a stage (canary
steps, SLO gates); Kargo controls *which* version reaches each stage and *when* it is
cleared to move forward.

---

## Context

ADR-0020 added Argo Rollouts for SLO-gated canary delivery inside a single stage.
What it did not add is a multi-stage promotion layer:

- After the canary succeeds in `dev`, should the same image digest automatically flow
  to `prod`?  Who approves it?  Where is the audit trail?
- ArgoCD's auto-sync means every commit to `main` immediately changes every Application.
  There is no *gate* between environments.

The 2026 GitOps best-practice guidance from Akuity (Kargo's creator) identifies
**promotion orchestration** as the missing link between image build and production:
the Warehouse detects new artifact versions, Freight bundles them for promotion,
Stages define gates (automatic or manual), and the promotion pipeline connects them —
with full traceability in the Kargo UI.

---

## Decision

Adopt **Kargo** as the lab's promotion-orchestration layer.

### Chart + version

- **Helm repo:** `ghcr.io/akuity/kargo-charts` (OCI; the original
  `https://charts.kargo.io` HTTPS index was retired upstream — see
  `gitops/platform/kargo.yaml`'s header comment)
- **Chart:** `kargo` `1.11.3` (`appVersion: 1.11.3`; pin lives in
  `gitops/platform/kargo.yaml`'s `targetRevision` — Kargo ships app+chart together
  from one `Chart.yaml` per release tag, so chart version and appVersion are always
  identical; see [§Re-evaluation log](#re-evaluation-log) for the bump history —
  CVE-driven bumps get their own dated entry there and in `gitops/platform/kargo.yaml`'s
  header comment)
- **Namespace:** `kargo` (new; PSA `restricted` — Kargo pods run as uid 65532)

### Footprint controls (ON-DEMAND)

```
api:        replicas: 1   memory limit: 256Mi
controller: replicas: 1   memory limit: 128Mi
webhooks:   replicas: 1   memory limit:  64Mi
```

Total: ~250–450 MiB. **ON-DEMAND only** — do not enable auto-sync; incompatible
with always-on budget (ADR-0005).

### Pipeline for the capstone app

```
Warehouse (capstone-pipeline)
  └─ image: artifactory.127.0.0.1.nip.io/docker-local/hello  (digest-tracked)
        │
        ▼ Freight (new digest detected)
   Stage: dev  ──[auto-promote]──► argocd-update capstone Application
        │
        ▼ Freight (promoted through dev)
   Stage: prod ──[manual gate]────► argocd-update capstone Application
```

- **Warehouse** subscription: `artifactory.127.0.0.1.nip.io/docker-local/hello`
  using `Digest` tag-selection strategy — every new image digest (regardless of tag)
  is a new Freight entry.
- **Stage `dev`**: `requestedFreight.sources.direct: true` — auto-promoted as soon
  as Freight exists.  Promotion step: `argocd-update` triggers an ArgoCD hard-refresh
  of the `capstone` Application with the new kustomize image override.
- **Stage `prod`**: `requestedFreight.sources.stages: [dev]` — only Freight that has
  successfully transited `dev` is eligible.  Promotion is **manual** (user clicks
  "Promote" in the Kargo UI or uses `kargo promote`).

### Admin credentials

Kargo's admin account password hash is stored in Vault (`secret/kargo/admin`,
property `password-hash`) and rendered into `kargo-admin-credentials` Secret via
ESO. Seed the Vault path before running `make kargo-up`:

```bash
vault kv put secret/kargo/admin password-hash='<bcrypt-hash>'
```

Generate a bcrypt hash: `htpasswd -bnBC 14 "" <password> | tr -d ':\n'`

### UI access

HTTPRoute: `http://kargo.127.0.0.1.nip.io:8000` → `kargo-api` Service port 80.
TLS terminated at Envoy Gateway (ADR-0008); Kargo API runs plain HTTP inside
the cluster (`api.tls.selfSignedCert.generate: false`).

### Kargo Project namespace

The Kargo `Project` named `capstone-pipeline` creates and manages the
`capstone-pipeline` namespace (separate from the application's `capstone` namespace).
`Warehouse` and `Stage` resources live in `capstone-pipeline`; the `capstone`
application namespace is unchanged.

### NetworkPolicy + PSS

- **`kargo` namespace** — default-deny overlay at `gitops/kargo/networkpolicy/`
  (ADR-0016). Allows: ingress TCP 80 from `envoy-gateway-system` (Kargo UI);
  ingress TCP 9443 from kube-apiserver (admission webhooks);
  egress TCP 80 to `argocd` (argocd-update step);
  egress TCP 443 to `capstone` app registry (image digest discovery);
  egress to kube-apiserver via baseline. PSA label `restricted` — no carve-out
  needed (Kargo pods run uid 65532, non-root).
- **`capstone-pipeline` namespace** — default-deny overlay at
  `gitops/kargo-project/networkpolicy/` (ADR-0016), delivered by the standalone
  `gitops/platform/kargo-project-networkpolicy.yaml` Application (ON-DEMAND, wave 4,
  pairs with `kargo-project.yaml`). Allows: egress (no port restriction) to `kargo`
  (promotion-step pods report status back to the Kargo controller/API); egress TCP
  80 to `argocd` (the same `argocd-update` promotion step, called from the
  promotion-job pod running in `capstone-pipeline` rather than `kargo`). PSA label
  `restricted` on `gitops/kargo-project/namespace.yaml` — defense-in-depth even
  though no workloads currently run in `capstone-pipeline` outside promotion jobs
  (the namespace itself is created by the Kargo `Project` CRD; the explicit manifest
  lets ArgoCD SSA-patch the PSA labels onto it).

---

## Why Kargo (not Flux / Argo Workflows)

| Concern | Kargo |
|---------|-------|
| Artifact source agnosticism | Warehouse subscribes to images, Helm charts, or git commits — no single-source lock-in |
| ArgoCD-native | Kargo's `argocd-update` step talks to the existing ArgoCD API; no second GitOps engine |
| First-class UI | Kargo UI shows Freight lineage, stage health, and promotion history — the learning artifact |
| CNCF ecosystem fit | Akuity (Kargo's creator) also maintains Argo; ADR-0020's Rollouts + ADR-0023's Kargo cover the full CI→CD→progressive delivery chain |

---

## Scope & exceptions

**In scope** — the Kargo controller + API + webhooks; the `capstone-pipeline` Project
with one Warehouse (image-based) and two Stages (dev auto, prod manual); the Kargo UI
HTTPRoute; admin-credentials ExternalSecret.

**Out of scope (this ADR):**

- Git-commit subscriptions (the lab's capstone CI uses `:latest`; add once tagged
  images are in use).
- Kargo RBAC (`ProjectRole`) — single-user lab; kept out of scope, see
  [§Re-evaluation log](#re-evaluation-log) (audit #461, 2026-07-17).
- Kargo notifications (Slack/webhook on promotion failure) — kept out of scope, see
  [§Re-evaluation log](#re-evaluation-log) (audit #461, 2026-07-17).
- Promotion steps beyond `argocd-update` (git-clone → kustomize-set-image →
  git-commit → git-push) — deferred until the capstone pipeline uses versioned tags.

---

## Files this work touches

| Path | Role |
|------|------|
| `docs/decisions/adr-0023-kargo-promotion-pipeline.md` | This ADR |
| `gitops/platform/kargo-extras.yaml` | Namespace pre-creation (wave 0, ON-DEMAND) |
| `gitops/platform/kargo.yaml` | Kargo Helm Application (wave 1, ON-DEMAND) |
| `gitops/platform/kargo-networkpolicy.yaml` | NetworkPolicy Application (wave 4, ON-DEMAND) |
| `gitops/platform/kargo-project.yaml` | Kargo Project/Warehouse/Stage Application (wave 6, ON-DEMAND) |
| `gitops/kargo/namespace.yaml` | Namespace + PSA restricted labels |
| `gitops/kargo/route.yaml` | HTTPRoute `kargo.127.0.0.1.nip.io` |
| `gitops/kargo/networkpolicy/` | Default-deny + allow rules (`kargo` namespace) |
| `gitops/kargo-project/project.yaml` | Kargo Project, Warehouse, Stage resources |
| `gitops/kargo-project/namespace.yaml` | `capstone-pipeline` namespace + PSA restricted labels |
| `gitops/platform/kargo-project-networkpolicy.yaml` | NetworkPolicy Application for `capstone-pipeline` (wave 4, ON-DEMAND, pairs with `kargo-project.yaml`) |
| `gitops/kargo-project/networkpolicy/` | Default-deny + allow rules (`capstone-pipeline` namespace) |
| `gitops/apps/capstone/kustomization.yaml` | Enables kustomize mode (Kargo image override) |
| `gitops/secrets/kargo-admin-externalsecret.yaml` | ESO ExternalSecret for admin credentials |
| `tests/kargo.bats` | Clusterless structural tests |
| `tests/networkpolicy-capstone-pipeline.bats` | `capstone-pipeline` namespace NetworkPolicy overlay tests |

---

## Re-evaluation log

Audits of this ADR's own out-of-scope follow-ups (the architect routine's STEP 2)
record their outcome here when the decision is **kept**. An audit terminates in a
documented decision — not only when something changes — so a scope call that survives
review leaves a dated trail and an explicit *flip condition* instead of an open-ended
"follow-up" pointer that nothing ever resolves.

### 2026-07-17 — Kargo RBAC + promotion-failure notifications kept out of scope (audit [#461](https://github.com/tooming/k8s-anywhere/issues/461))

**Trigger.** A gap-analysis sweep found that the two items this ADR's
§"Scope & exceptions" lists as *"follow-up"* — `ProjectRole` RBAC and Slack/webhook
promotion-failure notifications — had never been captured in `ROADMAP.md`, `docs/done/`,
or a follow-up ADR, and (unlike ADR-0029's KEDA follow-ups) carried no concrete
implementation spec, so neither could be groomed straight to a 🟢 executor item.

**Decision: keep both out of scope.** Neither traces to a CHARTER Goal or Objective.
`ProjectRole` RBAC would exist for demonstration only — the lab has exactly one Kargo
identity (`gitops/secrets/kargo-admin-externalsecret.yaml`), so there is no second
principal to scope a Role against. Slack/webhook notifications would need a credential
or workspace outside GitOps control, breaking the default localhost path's
zero-external-dependency reproducibility (CHARTER Mission, ADR-0025) — and are
redundant with what already exists: the `kargo` Alloy scrape job
(`gitops/platform/observability-alloy.yaml`) feeds
`controller_runtime_reconcile_total{job="kargo",result=…}` into Mimir, and
`grafana/dashboards/lab-kargo.json` already plots it by result, so promotion failures
are already visible through the lab's own real-observability idiom (ADR-0004) without a
bolt-on external notifier.

**Flip conditions:**
- RBAC: revisit if the lab ever provisions a second Kargo identity (e.g. a CI service
  account promoting on an automated gate) or CHARTER adds a multi-tenant/authorization
  learning goal.
- Notifications: revisit if the lab adds a self-hosted, free/OSS in-cluster alerting
  sink (e.g. Prometheus Alertmanager reading the existing
  `controller_runtime_reconcile_total{job="kargo",result="error"}` series) — that is
  Alertmanager-shaped work, not a Slack/webhook integration, and would need its own gap
  writeup if/when Alertmanager becomes a lab component.

### 2026-07-25 — Chart bumped `1.10.9` → `1.11.0` (routine currency, upgrade-drafter sweep)

**Trigger.** A same-source enumeration pass (upgrade-drafter role, invoked as an
executor STEP 6b fallback after the "Now / next" lane came up fully gated on the
standing `[Action required]` issues #631/#632/#633) found `gitops/platform/kargo.yaml`'s
`1.10.9` pin one minor release behind the OCI registry's real newest stable tag.

**Verification (ADR-0004).** Confirmed `1.11.0` is a real, non-pre-release tag via the
OCI registry's own tag list (`ghcr.io/v2/akuity/kargo-charts/kargo/tags/list?n=1000`,
paginated — the default unpaginated response silently truncates to very old tags).
The OCI blob CDN itself is proxy-blocked in this sandbox, so schema compatibility was
verified against the equivalent real source instead: the chart's committed
`charts/kargo/values.yaml` at both git tags
(`raw.githubusercontent.com/akuity/kargo/{v1.10.9,v1.11.0}/charts/kargo/values.yaml`).
Every value path this Application sets (`global.securityContext`,
`api.{replicas,resources,tls.selfSignedCert,secret}`,
`controller.{replicas,resources}`, `webhooksServer.{replicas,resources}`) is present
unchanged at both tags; the diff is purely additive (new optional Dex BYO-OIDC config,
`revisionHistoryLimit`/`rollingUpdate` knobs, coarse `workloads`/`dataPlane` install
switches all defaulting to prior behavior) plus comment rewording. No CVE is cited
against `1.10.9` or fixed specifically by `1.11.0` — this is routine version currency,
not a security-driven bump (unlike the two dated bumps recorded in
`gitops/platform/kargo.yaml`'s own header comment).

**Decision: bump.** No blast radius either way — Kargo is ON-DEMAND (not auto-synced;
ADR-0005 budget), so this pin only takes effect on the next `make kargo-up`.

**Flip conditions:** revisit when the OCI registry's tag list shows a newer stable
release above `1.11.0`, or a security advisory is filed against `1.11.0` (check
`github.com/akuity/kargo/security/advisories` — GitHub API access for arbitrary repos
is proxy-blocked in this sandbox; check manually or via the maintainer).

### 2026-08-11 — Chart bumped `1.11.0` → `1.11.1` (routine currency, #1101)

**Trigger.** Routine version-currency sweep found `gitops/platform/kargo.yaml`'s
`1.11.0` pin one patch release behind the OCI registry's real newest stable tag.

**Verification (ADR-0004).** Confirmed directly against the real OCI registry
(`ghcr.io/akuity/kargo-charts/kargo`) via the registry's own tags/list and manifest
APIs — not assumed from the GitHub release page alone: tag `1.11.1` exists, manifest
annotation `org.opencontainers.image.created` is `2026-08-10T19:57:48Z` (real),
`org.opencontainers.image.version` is `1.11.1`. Kargo ships app+chart together from
one `Chart.yaml` per release tag, so this is a same-tag app+chart bump.

**Decision: bump.** Upstream changelog (v1.11.1, published 2026-08-10): nine
backported fixes — UI (ArgoCD link handling, YAML editor spacing, chart cloning),
controller (network connection management, git rename detection), server (REST API
error handling, HTTP request context propagation), response body leak prevention. No
CVE cited. Nothing in the changelog touches the Digest-strategy admission-webhook
behavior `tests/kargo.bats` already documents (#633) — that assertion is unaffected.
No blast radius either way — Kargo is ON-DEMAND (ADR-0005 budget), so this pin only
takes effect on the next `make kargo-up`.

**Flip conditions:** revisit when the OCI registry's tag list shows a newer stable
release above `1.11.1`, or a security advisory is filed against `1.11.1` (check
`github.com/akuity/kargo/security/advisories` manually or via the maintainer).

### 2026-08-18 — Chart bumped `1.11.1` → `1.11.2` (upgrade-drafter fallback, no CVE)

**Trigger.** Executor STEP 6b fallback chain, this run's second cycle: the
"Now / next" lane remained fully gated (unchanged from cycle 1) and
PLANNER/ARCHITECT fallback passes again found nothing. UPGRADE-DRAFTER's
sweep re-checked every observability/data/platform pin not yet re-verified
this run; Kargo's chart was one patch behind.

**Verification (ADR-0004).** Confirmed directly against the real published
package (`github.com/akuity/kargo/pkgs/container/kargo-charts%2Fkargo`,
since the OCI registry's own `tags/list` endpoint needs registry-auth this
sandbox can't complete): `1.11.2` is listed, published ~7 hours before this
check, real digest
`sha256:e5347cd11308d7260326cb98a30c5a272941c847b1ba4d3655589dca897430b1`.
Kargo ships app+chart together from one `Chart.yaml` per release tag, so
this is a same-tag app+chart bump, same as every prior entry here.

**Decision: bump.** Six backport commits into the `release-1.11` branch
(`github.com/akuity/kargo/compare/v1.11.1...v1.11.2`): an SSO post-login
redirect fix, a GitHub bypass-rule regression fix, a UI promotion-steps
wizard-registry fix, "fix: dropped origins when aborting queued
promotions", and "fix(health): Fixes pointless status write for argocd
health" (plus one no-op "remove accidentally committed file" chore). No CVE
cited; `github.com/akuity/kargo/security/advisories`' newest entry is still
the April 2026 OIDC open-redirect one, already closed at `1.10.2`+ per the
prior entries above — re-checked, nothing new. `values.yaml` schema
re-verified unchanged at both tags for every path this Application sets
(`global.securityContext`, `api.{replicas,resources,tls.selfSignedCert,secret}`,
`controller.resources`, `webhooksServer.{replicas,resources}`). No blast
radius either way — Kargo is ON-DEMAND (ADR-0005 budget), so this pin only
takes effect on the next `make kargo-up`.

**Honest note on relevance to #633.** The "dropped origins when aborting
queued promotions" and "pointless status write for argocd health" fixes
touch the same promotion/health-reporting machinery #633's own
investigation has been debugging for weeks. This remote clusterless
session cannot verify either fix actually changes #633's outcome — noting
the overlap honestly as a reason a live-cluster session picking up #633
next might want this pin already in place, not claiming it as a fix.

**Flip conditions:** revisit when the OCI registry's tag list shows a newer
stable release above `1.11.2`, or a security advisory is filed against
`1.11.2` (check `github.com/akuity/kargo/security/advisories` manually or
via the maintainer).

### 2026-09-01 — Chart bumped `1.11.2` → `1.11.3` (upgrade-drafter fallback, real authz-bypass fix)

**Trigger.** Executor STEP 6b fallback chain: the "Now / next" lane remained
fully gated this cycle (the two GitLab→Forgejo migration items and the
capstone-`Deployment`-removal item, all blocked on unconfirmed live-cluster
prerequisites), PLANNER found no ungroomed intake or un-RFC'd 🟡 item, so
the chain continued to UPGRADE-DRAFTER. A prior dependency-currency sweep
this run (Valkey, see ADR-0018) surfaced Kargo `1.11.3` as a real candidate
via its own commit log.

**Verification (ADR-0004).** Confirmed directly against the real packaged
chart's GitHub Packages page (`github.com/akuity/kargo/pkgs/container/
kargo-charts%2Fkargo`, since the OCI registry's own `tags/list` endpoint
needs registry-auth this sandbox can't complete — same fallback method as
the 2026-08-18 entry above): `1.11.3` is listed, published ~8 hours before
this check, real digest
`sha256:842baea04e91c798f566ed389230d960572bc829c3ce30eedb1e9ee8d29ee57f`.
Kargo ships app+chart together from one `Chart.yaml` per release tag, so
this is a same-tag app+chart bump, same as every prior entry here.

**Decision: bump.** Commit log (`github.com/akuity/kargo/compare/
v1.11.2...v1.11.3`) shows the headline fix is real and security-relevant,
not routine currency: `08a4d08` "fix(server): close cluster-scoped
authorization bypass in generic resource writes" plus `2aa5fd0` "fix: no
authz performed for resource refresh". Checked
`github.com/akuity/kargo/security/advisories` directly — no new advisory
has been filed for this fix yet (newest entry is still April 2026,
unchanged), so this predates formal GHSA/CVE disclosure; treated with the
same urgency as a CVE-mentioning release per this repo's own bump-priority
convention (CVE-mentioning > patch > minor) given the fix's own commit
message names an authorization bypass. Also includes two hardening
commits ("compile the Helm binary ourselves to reduce vulnerabilities",
"update dependencies to reduce vulnerabilities") and two unrelated UI
fixes. `values.yaml` schema re-verified at both tags
(`raw.githubusercontent.com/akuity/kargo/{v1.11.2,v1.11.3}/charts/kargo/
values.yaml`) for every path this Application sets: `global.securityContext`,
`api.{replicas,resources,tls.selfSignedCert,secret}`, `controller.resources`,
`webhooksServer.{replicas,resources}` — all present, unchanged structure.
Also confirmed `controller.replicas` (set in this Application's
`valuesObject` but absent from the chart's own schema at both tags) is a
pre-existing harmless no-op, not a regression introduced by this bump —
Helm silently ignores values keys with no matching template use. No blast
radius either way — Kargo is ON-DEMAND (ADR-0005 budget), so this pin only
takes effect on the next `make kargo-up`.

**Flip conditions:** revisit when the OCI registry's tag list shows a newer
stable release above `1.11.3`, or a security advisory is filed against
`1.11.3` (check `github.com/akuity/kargo/security/advisories` manually or
via the maintainer).

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Kargo lands as ArgoCD-synced manifests; `argocd-update` step calls back into ArgoCD — no second GitOps engine. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Single-replica components per ADR-0005; production runs HA. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-replica per component; ON-DEMAND to stay within budget. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Kargo UI routed via HTTPRoute `kargo.127.0.0.1.nip.io`. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `kargo` and `capstone-pipeline` namespaces get default-deny during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | PSA `restricted`; no carve-out needed. |
| [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md) | Kargo controls stage promotion; Rollouts controls canary progression inside a stage. They compose: Kargo promotes Freight to dev → Rollouts runs the canary → health check passes → Kargo eligible to promote to prod. |
