# ADR-0029 — KEDA for event-driven autoscaling

**Status.** Adopted. Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
is new ground, not a supersession). On-demand component (converted from always-on
2026-08-25 — see Re-evaluation log). New CHARTER Goal ("event-driven autoscaling") — no
existing Objective covers it; ROADMAP items below carry the buildable scope.

---

## Context

Every workload in the lab today scales exactly one way: not at all, or by hand. There is
no Horizontal Pod Autoscaler, no queue-depth-driven scaling, nothing that demonstrates
the "scale on a real signal, not a timer" pattern a production-shaped platform is
expected to teach — even though the lab already runs the two ingredients that make that
pattern *real* rather than synthetic: RabbitMQ (ADR-0009, a message broker with an actual
queue an autoscaler can watch) and Prometheus-compatible metrics via Mimir (any
Mimir-backed metric is a valid KEDA scaler trigger). This is a genuine gap against the
CHARTER Vision ("the most complete production-shaped cloud-native platform") and sits
naturally alongside the existing "progressive delivery" Goal (Argo Rollouts, ADR-0020,
already teaches *how* a new version rolls out under real SLOs) — autoscaling teaches the
adjacent, equally fundamental question of *how many* replicas run at all.

**Why not the stock HorizontalPodAutoscaler:** the stock HPA only scales on CPU/memory
(or hand-wired custom-metrics-API adapters) — it cannot watch a RabbitMQ queue depth or
an arbitrary Mimir/PromQL expression out of the box. **KEDA** (Kubernetes Event-Driven
Autoscaling, CNCF graduated 2023-09) is the de-facto standard that closes that gap: it
ships 60+ built-in scalers (RabbitMQ, Prometheus, Kafka, cron, and more) and drives the
*same* underlying HPA object, so it augments rather than replaces core Kubernetes
autoscaling — no rejected-technology conflict with anything already adopted.

---

## Decision

Adopt **KEDA** as the lab's event-driven autoscaling controller, using the
**official Helm chart**. (Originally always-on; converted to on-demand 2026-08-25 —
see Re-evaluation log.)

### Chart + version

- **Chart:** `keda` v2.18.0 (chart version tracks app version 1:1, same convention as
  cert-manager — confirmed via the upstream `kedacore/charts` repo's `release/v2.18`
  branch, `Chart.yaml`: `version: 2.18.0`, `appVersion: 2.18.0`).
- **Source:** `https://kedacore.github.io/charts` (the project's published Helm repo;
  index is proxy-blocked in an executor's sandbox — same class of limitation as
  `charts.jetstack.io`/`kyverno.github.io` — but the chart's own git repo, published via
  per-release branches rather than tags for recent versions, is reachable via
  `git clone --branch release/v2.18 --sparse`, the same workaround this ROADMAP already
  documents for other proxy-blocked chart indexes).
- **Namespace:** `keda`.
- **CRDs via the chart itself** (`crds.install: true` — the chart's own default,
  confirmed in `values.yaml`), keeping day-2 CRD management inside the GitOps loop per
  [ADR-0001](adr-0001-gitops-over-terraform-helm.md).

### PSA profile — `restricted`, no carve-out needed

Verified directly against the pinned chart's `values.yaml`: all three components
(operator, metrics server, admission webhooks) default to pod-level
`runAsNonRoot: true` and container-level `capabilities.drop: [ALL]` +
`allowPrivilegeEscalation: false` + `readOnlyRootFilesystem: true` +
`seccompProfile.type: RuntimeDefault` — the full `restricted` PSS profile, no chart
override needed. Second always-on component after cert-manager (ADR-0028) to land at
`restricted` with zero carve-out.

### Footprint controls (12 GB budget)

Chart default per component: `limits: {cpu: 1, memory: 1000Mi}`,
`requests: {cpu: 100m, memory: 100Mi}` — the limits are a generous ceiling unsuited to
this lab's per-component budget norm (matches neither cert-manager's nor Kyverno's
trimmed-limits convention). Override to:

```yaml
resources:
  operator:      { limits: { memory: 128Mi }, requests: { memory: 100Mi, cpu: 100m } }
  metricServer:  { limits: { memory: 128Mi }, requests: { memory: 100Mi, cpu: 100m } }
  webhooks:      { limits: { memory: 64Mi },  requests: { memory: 50Mi,  cpu: 50m  } }
```

Total cap: ~320 MiB combined limits — comparable to cert-manager's ~256 MiB, well within
budget alongside the rest of the always-on stack.

### Admission webhook port

Chart default admission webhook port is **9443** (confirmed in `values.yaml`:
`webhooks.port: ""` with the field comment "Default is 9443") — the NetworkPolicy allow
rule for kube-apiserver ingress uses this port, following the same `ipBlock` pattern as
every other webhook-bearing component in this lab.

### Observability

All three components expose real Prometheus metrics on `:8080/metrics` (confirmed via
`prometheus.operator.port` / `prometheus.metricsServer.port` in `values.yaml`, both
default `8080`; each runs in its own pod so there is no port conflict). Verified the
actual metric names against the pinned tag's Go source
(`pkg/metricscollector/prommetrics.go`, `DefaultPromMetricsNamespace = "keda"`) rather
than guessing from the docs:

- `keda_scaler_active` — whether a given scaler is currently active (1) or not (0).
- `keda_scaled_object_paused` — whether a `ScaledObject` is paused.
- `keda_scaler_metrics_value` — the current value each scaler reports, per trigger.
- `keda_scaler_detail_errors_total` / `keda_scaled_object_errors_total` — error counters.
- `keda_build_info` — version/build metadata gauge.

Add an Alloy `prometheus.scrape "keda"` job. Dashboard `grafana/dashboards/lab-keda.json`:
operator/metricServer/webhooks pod status (KSM), ArgoCD sync state, scaler active count
(`keda_scaler_active`), ScaledObject error rate (`keda_scaled_object_errors_total`) — all
real Mimir data (ADR-0004); panels show "No data" naturally until a `ScaledObject`
actually exists (the follow-up item below).

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/keda/networkpolicy/` (ADR-0016 fan-out): baseline +
  ingress TCP 9443 from kube-apiserver (admission webhook callback) + ingress TCP 8080
  from `observability` (metrics scrape — all three components expose on this port).
- PSA labels `restricted` on the `Namespace` (see above — no carve-out needed).

---

## Scope & exceptions

**In scope (this ADR, split across ROADMAP items per rule #9's ≤400-line guidance):**

- The KEDA engine itself (auto-synced `Application`, namespace, NetworkPolicy overlay,
  Alloy scrape, dashboard) using the chart's own `certificates.autoGenerated: true`
  default for webhook TLS (self-signed, chart-managed) — fully additive, no existing
  workload is touched, buildable and clusterless-verifiable in one item.

**Out of scope at this ADR's original adoption (both shipped since — see the "Files"
table below, tagged "shipped"):**

- **Wiring the admission webhook's TLS to cert-manager** instead of the chart's
  built-in self-signed cert generation. The chart supports this natively
  (`certificates.certManager.enabled: true` with `issuer.generate: false` +
  `issuer.name: k8s-lab-ca` + `issuer.kind: ClusterIssuer` — confirmed in
  `values.yaml`'s `certificates.certManager` block), which would give cert-manager
  (ADR-0028) a second real consumer beyond the Gateway's HTTPS listener. Deferred
  because it depends on the `k8s-lab-ca` `ClusterIssuer` (cert-manager-root-ca, wave 5)
  and is a genuinely separate concern from standing the engine up — same "engine now,
  integration later" split this ROADMAP already used for cert-manager itself.
  **Real wave-ordering constraint found while scoping this** (verified against the
  chart's own template logic, `templates/manager/deployment.yaml` +
  `templates/manager/minimal-rbac.yaml`): the cert volume's `optional` flag is
  `{{ and .Values.certificates.autoGenerated (not .Values.certificates.certManager.enabled) }}`
  — enabling `certManager` flips that volume from optional to **required**. The `keda`
  Application (currently wave 1, same wave as `cert-manager` itself) would then need
  its own `Certificate` (created by KEDA's chart, referencing `k8s-lab-ca`) to actually
  issue *before* the operator/webhook pods can start — but `k8s-lab-ca` doesn't exist
  until `cert-manager-root-ca` (wave 5) reconciles. Leaving `keda` at wave 1 while
  making this change would be a **real circular deadlock**, not just a cold-start
  delay: ArgoCD's sync-wave gating holds wave 4/5 until wave 1's `keda` Application
  reports Healthy, and `keda` can't become Healthy without wave 5 having already run.
  The fix is straightforward — move `keda`/`keda-extras`/`keda-networkpolicy` to sync
  *after* wave 5 (wave 6, alongside `lab-gateway-certificate`, which depends on the
  same `ClusterIssuer` for the same reason) — but it's a real re-plumbing of this
  ADR's own wave placement, not a one-line `valuesObject` change, so it's captured
  here explicitly rather than left for the follow-up PR to rediscover.
- **A real `ScaledObject` demo** — e.g. scaling `data-demo` (or a dedicated demo
  workload) on the `data` namespace's RabbitMQ queue depth via KEDA's `rabbitmq`
  scaler. This is the actual pedagogical payoff (event-driven autoscaling *demonstrated*,
  not just installed) but requires its own RabbitMQ-credential wiring
  (`TriggerAuthentication` reading the existing `rabbitmq-creds` ExternalSecret) and
  NetworkPolicy egress from `keda` to `data`'s RabbitMQ management API — a distinct,
  separately-sized item.
- **Scaling any *existing* always-on component.** This ADR does not retrofit
  autoscaling onto Kyverno, Trivy Operator, or any other current workload — every
  always-on component stays single-replica per ADR-0005's recreate-over-HA trade-off
  until a specific case is made otherwise.

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-27 — CVE-2025-68476 not applicable + already patched (audit #764)

**Trigger.** Routine CVE sweep found **CVE-2025-68476** — arbitrary file read
via `TriggerAuthentication`'s `spec.hashiCorpVault.credential.serviceAccount`
path when configured for HashiCorp Vault auth (incorrect/insufficient path
validation on the mounted Service Account Token path, letting an attacker who
can create/edit a `TriggerAuthentication` exfiltrate arbitrary node-filesystem
files). Affects all versions `< 2.17.3` and `2.18.0`–`<2.18.3`, fixed in
`2.17.3`/`2.18.3`.

**Decision: keep chart pin `2.20.1` — not applicable, and already patched
anyway.** Two independent reasons: (1) `gitops/platform/keda.yaml` pins
`2.20.1`, already past both fixed floors; (2) this lab's only
`TriggerAuthentication` (`gitops/data/demo/keda-scaling/triggerauthentication.yaml`)
uses `spec.secretTargetRef`, not `spec.hashiCorpVault` — grepped the full
`gitops/` tree for `hashiCorpVault`, zero matches outside this ADR's own prose.
The vulnerable code path is never reached by this lab's actual deployed
config, regardless of chart version.

**Flip condition (next re-evaluation).** Revisit if (a) this lab's
`TriggerAuthentication` is ever changed to use `spec.hashiCorpVault`, or (b) a
new CVE is filed against a KEDA version above `2.20.1`.

### 2026-08-03 — chart bump `2.20.1` → `2.20.2`, currency only (not a re-audit)

**Trigger.** Upgrade-drafter routine sweep (real upstream check, not training
knowledge): `github.com/kedacore/charts` tags `v2.20.2` (confirmed via `git
diff v2.20.1 v2.20.2` on a real clone of the chart repo). Chart version and
appVersion track 1:1 for KEDA (`2.20.1` → `2.20.2` on both). `values.yaml`
diff is purely additive — three new optional `http.maxIdleConns`/
`maxIdleConnsPerHost`/`idleConnTimeout` keys with defaults, no key removed or
renamed. No CVE against `2.20.2` — this bump doesn't answer the 2026-07-27
audit's flip condition above, it is routine chart currency.

**Decision: Bump (not a Keep/Supersede/Convert audit outcome).** Chart
bumped to `2.20.2`. **Flip condition for the next CVE-style audit:**
unchanged in kind from the 2026-07-27 entry above, now against the `2.20.2`
floor — revisit if this lab's `TriggerAuthentication` is ever changed to use
`spec.hashiCorpVault`, or a new CVE is filed against a KEDA version above
`2.20.2`.

### 2026-08-25 — Convert always-on → on-demand (cluster-load reduction)

**Trigger.** Live-cluster session investigating issue #633 found this
laptop's Colima VM (12 GB budget, 6 cores) chronically overloaded — load
average routinely 10-35 with the on-demand Harbor/Kargo units both already
down, driven by 18+ always-on namespaces plus whatever on-demand unit(s)
happened to be up. The maintainer directed a general trim of anything not
strictly needed continuously.

**Decision: Convert (Always-on → On-demand).** KEDA is reactive/event-driven
by its very design — it scales workloads in response to a RabbitMQ queue
depth or a Mimir/PromQL signal crossing a threshold. Nothing in this lab
generates sustained load on those signal sources outside an active
autoscaling demo, so there is no always-on workload for KEDA to be watching
between demonstrations — unlike, say, Cilium (CNI, every packet) or
cert-manager (continuous cert-expiry monitoring), whose whole value is being
up all the time. `gitops/platform/keda.yaml` and `keda-extras.yaml` both
lost their `syncPolicy.automated` block (manual sync only); `make keda-up` /
`make keda-down` added to the Makefile, mirroring Longhorn/Kargo/Inkless's
existing on-demand pattern. Not registered in
`scripts/ondemand-budget-check.sh`'s `UNIT_APPS`/`UNIT_NS` maps — that guard
protects the "one heavy unit at a time" budget for genuinely large units
(Harbor, Kargo, Longhorn, Inkless, TiDB, Istio), and KEDA's ~320 MiB
footprint doesn't compete for that budget; it's safe to run alongside any
other on-demand unit.

**Flip condition (next re-evaluation).** Revisit if the lab grows a workload
whose autoscaling behavior needs to be *continuously* observable (e.g., a
Grafana dashboard panel demonstrating live scale events as a permanent
fixture rather than an on-demand walkthrough), or if this host's resource
budget grows enough that the always-on footprint stops mattering.

**Follow-up (same day) — `keda-governance` was a dead-config gap this
conversion left behind.** `gitops/platform/governance-appset.yaml` still
carried a `keda-governance` list entry (RFC #293/#294's per-namespace
LimitRange fan-out) targeting `destNamespace: keda` with `CreateNamespace:
true`. Since `keda-extras` — the Application that used to create that
namespace — went on-demand in this same conversion, that entry would have
had ArgoCD recreate an otherwise-empty `keda` namespace (just a LimitRange,
no workload) on every reconciliation, working against this decision's own
"fully on-demand, zero footprint" intent. Removed the entry (and the
`gitops/governance/keda/` leaf directory) — same dead-config shape the
`kiali-governance` removal already established (`istio-system` excluded as
an on-demand-heavy namespace too variable for static defaults). Re-add if
`keda`'s namespace becomes always-on again.

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0029-keda-event-driven-autoscaling.md` | This ADR |
| `gitops/platform/keda.yaml` | Auto-synced ArgoCD `Application` for the engine |
| `gitops/platform/keda-extras.yaml` | Namespace pre-creation (PSA `restricted`, wave 0) |
| `gitops/keda/namespace.yaml` | PSA `restricted` labels |
| `gitops/keda/networkpolicy/` | Default-deny overlay |
| `gitops/platform/keda-networkpolicy.yaml` | NetworkPolicy overlay Application (wave 4) |
| `gitops/platform/observability-alloy.yaml` | New `keda` scrape job |
| `grafana/dashboards/lab-keda.json` | Real-metric dashboard (Objective O5 pattern) |
| `tests/keda.bats` | Clusterless tests: Application shape, chart pin, PSA labels, NetworkPolicy, scrape job, dashboard |
| `gitops/platform/keda.yaml` (`certificates.certManager`) | cert-manager webhook TLS wiring, referencing `k8s-lab-ca` (shipped; see `tests/keda.bats`) |
| `gitops/data/demo/keda-scaling/` | `ScaledObject` + `TriggerAuthentication` demo scaling `rabbitmq-load` (shipped; see `tests/keda-scaledobject.bats`) |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Engine lands as an ArgoCD `Application`; CRDs installed via the chart, not `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) / [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-replica controller, modest memory caps — lab trade-off, not a production default. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard sources real `keda_scaler_*`/`keda_scaled_object_*` counters only; scaler-activity panels show "No data" until a `ScaledObject` exists. |
| [ADR-0009](adr-0009-rabbitmq-message-broker.md) | The follow-up `ScaledObject` demo scales on this RabbitMQ's real queue depth. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `keda` namespace gets its own default-deny overlay during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Second always-on component (after cert-manager) to land at `restricted` with zero carve-out — add a `keda: restricted` row. |
| [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md) | Sibling "how many replicas" concern alongside Rollouts' "which version" concern — both drive real-metric-gated behavior, neither on a timer. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | Apache 2.0, CNCF graduated, no paid tier required. |
| [ADR-0028](adr-0028-cert-manager-tls-lifecycle.md) | The follow-up webhook-TLS item gives cert-manager's `k8s-lab-ca` issuer a second real consumer. |
