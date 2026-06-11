# ROADMAP

The backlog for **k8s-lab**, derived from [CHARTER.md](CHARTER.md) (the north-star this
is projected from) and worked by two decoupled routines: a weekly **planner** that
proposes items here (plan-only PRs) and an every-6h **executor** that implements one item
per run. CHARTER = the goals; this file = the next steps.

The always-on stack is already built (Envoy, Vault, External Secrets, Garage,
the full LGTMP observability stack, moto/ACK/KRO, the RabbitMQ + Valkey data layer,
the demo app — ~28 ArgoCD apps). What's left is the heavy *on-demand* components,
the end-to-end capstone, and cross-cutting hardening.

---

## How the executor uses this file

The **executor** routine (every 6h) reads this file each run. It has **only this repo** —
no access to anyone's local notes — so every rule it must follow lives here, in
`docs/decisions/` (the ADRs), or in [docs/WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md)
(agent governance & review). The rules below are binding.

1. **One item per run.** Take the single topmost unchecked `[ ]` item under
   *Backlog* (prefer the *Now / next* list). Keep the change to one reviewable PR.
2. **You are remote and clusterless.** There is **no** Kubernetes cluster, no
   Colima, no live GitLab reachable from where you run. Never run `make up`,
   `make dr-*`, `kubectl`, `argocd`, `vault`, or anything needing a cluster.
   **Your definition of done is `make ci` passing** — lint + validate + test +
   readme-check + lab-ui-check. Never weaken, skip, or stub a gate to go green.
3. **The ADRs in `docs/decisions/` are binding:**
   - **ADR-0001** GitOps over Terraform/Helm — deploy workloads as ArgoCD
     `Application`s. Terraform/Terragrunt *only* bootstraps; never `helm install`
     or apply workloads imperatively.
   - **ADR-0002** Garage, not MinIO, for S3-compatible storage.
   - **ADR-0003** Prefer decoupled / no-SPOF designs where reasonable.
   - **ADR-0004** No fabricated content — dashboards and outputs must reflect
     real, auto-discovered state. Never placeholder, mock, or invented data.
   - **ADR-0005** On a single host, recreate-from-code over true HA.
4. **Respect the 12 GB budget — heavy components must NOT be auto-synced.** The
   always-on stack already fills ~7 GB of the 12 GB VM. Add each heavy/on-demand
   component as code that the user brings up *manually*:
   - manifests under `gitops/<area>/…`;
   - an ArgoCD `Application` that is **not** registered for automated sync in
     `gitops/bootstrap/root-app.yaml` — either leave it out of the app-of-apps, or
     give it a `syncPolicy` **without** `automated:` so it only syncs on manual
     trigger;
   - a `make <name>-up` / `make <name>-down` target;
   - docs + `bats` tests + README/dashboard wiring as applicable.
   Never add a heavy component to the always-on auto-synced set.
5. **Keep docs and dashboards in sync.** If you add a user-facing UI, wire it into
   the Grafana "Lab UIs" panel (there's a drift check) and update the README /
   `docs/dependency-tree.md` so `make readme-check` and `make lab-ui-check` stay
   green.
6. **Every scheduled run's work lands as a PR — never push to `main`, never self-merge.**
   One branch per run (`auto/<short-slug>`). Title it clearly; the body should say what +
   why and note it's an autonomous run. CI runs on the PR; the user reviews and merges. A
   run never commits straight to a branch without opening a PR, and never silently does
   nothing (see rule #9).
7. **Check it off in the same PR.** Mark the item `[x]`, move it to *Done*, and
   reference the PR number.
8. **If the top item can't be done cleanly in one run, take the next feasible
   item** instead of committing something that fails `make ci`. If you genuinely
   can't make any gate-passing progress this run, do **not** open a half-baked PR —
   **prompt the maintainer** (rule #9's channel) instead, then stop.
9. **Never invent new backlog items — and never go silent.** You only implement items
   already listed below; the weekly planner refills the backlog (see next section). But
   when there's no actionable item — the *Now / next* lane is empty, or everything left is
   🟡/🔴 blocked on a human — do **not** just stop. **Prompt the maintainer** so the
   idle/blocked state is visible: open a single GitHub issue titled `executor idle — needs
   work` (or, if one is already open, add a comment to it — search first, never spam a new
   one each run) that @-mentions the maintainer and lists what's blocked and which
   decision/RFC/ADR is owed to unblock it. One issue, refreshed each idle run. That is the
   only acceptable "no PR" outcome — fabricated make-work is still forbidden.
10. **Stay in your autonomy tier** (see [docs/WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md)).
    You operate at **🟢 Green only** — docs, tests, non-auto-synced manifests, dashboards
    from real metrics. If the next item actually needs **🟡 Yellow** work (a new
    dependency, a CI/gate/Makefile change, anything security-adjacent) or **🔴 Red** work
    (secrets, any cluster/repo-settings change), do NOT do it: open a GitHub issue stating
    what a human must decide, and move to the next feasible Green item.

---

## Where new items come from — the planner

The executor never invents work — it only implements items already listed below. New
items come from a separate **weekly planner** routine (also runnable on-demand) that:

- reads [CHARTER.md](CHARTER.md) (the north-star) + the repo state + this file + open PRs
  + **open GitHub issues** (the intake queue), then produces items two ways:
  - **gap analysis** — a charter target not yet built, a Core Value not upheld, a Goal
    not yet covered, or an Objective not on track for its date, becomes a proposed item;
  - **intake grooming** — each open issue is a user work request of any size; the planner
    sizes it and splits it into one or more concrete, single-PR-sized items;
- opens a **plan-only PR** on a `plan/<slug>` branch that edits **only this file** —
  adding items and re-prioritizing *Now / next*. It never writes feature code and never
  edits CHARTER.md (if the *goals* look stale, it says so in the PR body for a human);
- closes the loop on each groomed issue (comments the resulting items, labels it
  `groomed`, closes it);
- de-dupes against existing items and open PRs; it won't open a churn PR when there's
  nothing to propose — but it **never ends a run silent**: with no ROADMAP changes it
  instead files (or refreshes) a single GitHub issue surfacing the highest-value
  gap/decision for a human. **Every planner run yields a plan PR or a GitHub issue.**

### How you add work

- **Already a clean ~1-PR task?** Add it straight to *Now / next* below — the executor
  builds it next run; no planner needed.
- **A goal or direction?** Put it in [CHARTER.md](CHARTER.md) — the planner derives items.
- **Ungroomed work of unknown size?** Open a **GitHub issue** describing it (any level of
  detail). The planner grooms it into the right number of items — don't pre-size it,
  that's the planner's job. The executor never reads issues, so nothing half-baked gets
  built. To groom it *now* instead of waiting for the weekly run, trigger the planner
  on-demand (routines page → Run, or ask Claude). Label an issue `wontfix` or `question`
  to make the planner skip it.

You review and merge plan PRs, same as implementation PRs.

---

## Backlog

> **Autonomy tiers** (per [docs/WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md) §2) are
> tagged inline on every item: **🟢 Green** the executor may build now; **🟡 Yellow**
> needs an architect RFC *first* — the executor still must not build it unprompted, but
> the architect's RFC is binding (no human-approval step) and the planner grooms it into
> 🟢 items on its next run; **🔴 Red** humans only. *Now / next* holds only 🟢 items.

### Now / next
> Pick the topmost unchecked item. If it can't be done cleanly this run, fall
> through to the next.
>
> **Planner note (2026-06-11 — Tier 1 next-wave fan-out + O2 tail).** The
> 2026-06-08 O2 fan-out wave has fully landed (capstone/data/vault/observability
> NetworkPolicies + PSS for capstone/data/observability + PSS labels for
> vault/storage/tidb/tidb-admin + storage/argocd/moto/ack/lab-gateway NPs —
> all in *Done*). Two architect waves landed this week: (a) all four Tier 1
> next-wave ADRs are merged — ADR-0019 (Kyverno), ADR-0020 (Argo Rollouts),
> ADR-0021 (Velero), ADR-0022 (Trivy Operator); and (b) RFC issues #153–#156
> carry the binding implementation specs. Per WAYS-OF-WORKING.md §2, the
> architect's decision *is* the approval — the planner grooms each RFC's
> *Acceptance criteria* into 🟢 single-PR executor items here, no human-RFC
> step needed.
>
> Backlog order: **CHARTER Objective O1** (Tier 1 next-wave deployed by
> 2026-12-31) is the highest-priority outstanding objective. Within O1, items
> are ordered by what they unblock — Kyverno first (gates O4, signed-images),
> then Velero (gates O3, exercised DR), then Argo Rollouts (progressive
> delivery), then Trivy Operator (continuous CVE/SBOM). Each RFC is split into
> the sub-PRs its own *Acceptance criteria* section recommends ("split
> controller-PR + …" notes from the architect are honored). The remaining O2
> tail (PSS-restricted for `moto`/`ack-system`/`lab-gateway`, NP for
> `tidb`/`tidb-admin`) trails the Tier 1 wave so the executor always has 🟢
> work; the cloud-control-plane dashboard (O5) is promoted from cross-cutting.
>
> **O2 clock note.** O2 is dated **2026-09-30** — ~3.5 months out. After the
> two O2 tail items below merge, the remaining always-on gaps are: PSS for
> `argocd` (🟡 — touches `infra/modules/argocd/values.yaml`, needs architect
> RFC; see *Cross-cutting*); NP for `envoy-gateway-system` (🟡 — Envoy
> data-plane egress fan-out matches every backend Service, needs architect
> RFC). Both are surfaced as 🟡 entries in *Cross-cutting*.
>
> **WIP / size discipline reminder.** Per WAYS-OF-WORKING.md §3, target ≤ 400
> changed lines per PR. Items below that risk crossing the cap carry a
> "split if oversized" executor note matching the RFC's own split guidance.

- [ ] 🟢 **Kyverno engine + observability** (CHARTER **Objective O1**,
  RFC #153 — see
  [ADR-0019](docs/decisions/adr-0019-kyverno-admission-engine.md) for
  the binding chart values, scrape target, and namespace profile).
  Add `gitops/platform/kyverno.yaml` (auto-synced ArgoCD
  `Application`, chart `kyverno/kyverno` v3.3.x from
  `https://kyverno.github.io/kyverno/`, namespace `kyverno`; pin a
  specific 3.3.x patch at executor pickup). Apply the per-ADR
  `valuesObject` lab footprint overrides: 1 replica per controller +
  memory limits per ADR-0019 §"Footprint controls" (admission 256Mi,
  background 128Mi, cleanup 64Mi, reports 128Mi). Add
  `gitops/kyverno/namespace.yaml` with PSA labels at `baseline` +
  `enforce-version: latest` per ADR-0019 (carve-out is `baseline`,
  not `restricted` — webhook TLS material needs `fsGroup`).
  Default-deny NetworkPolicy overlay at
  `gitops/kyverno/networkpolicy/kustomization.yaml` referencing the
  shared baseline templates + ingress TCP 9443 from the
  kube-apiserver (webhook callback — use the existing apiserver
  `ipBlock` pattern from `allow-dns-and-apiserver.yaml`) + ingress
  TCP 8000 from `observability` (metrics scrape) + egress to
  kube-apiserver for admission review fan-out. New auto-synced
  `Application` `gitops/platform/kyverno-networkpolicy.yaml`
  (sync-wave 4, `LoadRestrictionsNone`). New `kyverno` scrape job
  in `gitops/platform/observability-alloy.yaml` targeting
  `kyverno-svc.kyverno.svc.cluster.local:8000` per ADR-0019
  §"Scrape target". New `grafana/dashboards/lab-kyverno.json`
  ("Lab — Kyverno (Admission Policy)") modelled on `lab-vault.json`
  stat-row: pod running per controller
  (admission/background/cleanup/reports from KSM), memory +
  restarts (cAdvisor), ArgoCD sync state, policy results rate from
  real `kyverno_policy_results_total` by `policy_validation_mode` +
  `policy_background_mode`, admission review latency p95 from
  `kyverno_admission_review_duration_seconds_bucket`,
  policy-execution errors from
  `kyverno_policy_execution_duration_seconds_count` filtered by
  `result!="pass"`. Wire dashboard into the Grafana "Lab UIs" panel
  (no HTTPRoute — Kyverno has no UI; document in the PR body).
  Update `docs/dependency-tree.md` with a KYVERNO subgraph + Alloy
  scrape edge. New `tests/kyverno.bats`: Application shape, chart
  source + version pin, namespace PSA labels, NetworkPolicy overlay
  structure, scrape job target, dashboard file + three required
  panels. **Executor note:** if the PR crosses ~400 lines per
  WAYS-OF-WORKING.md §3, ship the chart Application + namespace +
  NetworkPolicy in PR 1; file the dashboard + Alloy scrape + bats
  as the next planner item. The `kyverno: baseline` row addition
  to ADR-0017's per-namespace profile table is a separate small
  docs item (see "ADR-0017 amendment" below) — do NOT include it
  here. The *initial ClusterPolicy set* (validate + mutate +
  verifyImages) lands as the next item. (auto/kyverno-engine)

- [ ] 🟢 **Kyverno initial ClusterPolicies (validate + mutate +
  verifyImages)** (CHARTER **Objective O1** + gates **Objective O4**,
  RFC #153 — ADR-0019 §"Initial ClusterPolicy set" for binding
  policy text). Wait for the Kyverno engine PR above to merge before
  this one (CRDs need to exist for the policies to validate against
  in `make ci`). Add four `ClusterPolicy` manifests under
  `gitops/kyverno/policies/` (each ≤ 50 lines per ADR-0019):
  `require-pod-security-restricted.yaml` (validate `enforce`-mode;
  matches all pods; skips namespaces labelled
  `pod-security.kubernetes.io/enforce=baseline` or `=privileged`;
  backstops ADR-0017);
  `disallow-latest-tag.yaml` (validate; rejects `image: *:latest`
  or no-tag);
  `add-default-seccomp.yaml` (mutate; injects
  `seccompProfile.type=RuntimeDefault` when omitted);
  `verify-image-signatures.yaml` (verifyImages; cosign matching the
  `cosign-public-key` ConfigMap seeded by the cosign-bootstrap
  script; scoped to `artifactory.127.0.0.1.nip.io/**` per ADR-0019
  §"verifyImages scope" so upstream chart images are *not*
  rejected). Add `gitops/platform/kyverno-policies.yaml` (auto-synced
  `Application`, sync-wave 5 — after the engine, before policies
  need to take effect; matches RFC #153 acceptance criteria).
  Extend `tests/kyverno.bats` (or new `tests/kyverno-policies.bats`)
  asserting all four policy files exist, the verifyImages policy
  references the artifactory registry pattern, the PSS backstop has
  the documented skip labels, the seccomp mutation has the correct
  `mutate.patchStrategicMerge` shape. **Executor note:** the
  `verifyImages` policy will *not* admit any image until the cosign
  signing step in `.gitlab-ci.yml` is wired (separate planner item
  once the cosign-bootstrap script lands). To keep the lab
  functional in the interim, gate the
  `verify-image-signatures.yaml` policy as `failurePolicy: Ignore`
  *and* set `validationFailureAction: Audit`; flip to `Enforce` in
  a future planner item once the CI signing flow lands. Document
  this stance in the PR body. (auto/kyverno-policies)

- [ ] 🟢 **cosign-bootstrap.sh day-0 seam (key generation +
  ConfigMap)** (CHARTER **Objective O4** enabler, RFC #153 —
  script-only PR per ADR-0019 §"Cosign keypair management"). New
  `scripts/cosign-bootstrap.sh` that: (a) generates a cosign
  keypair under `infra/secrets/cosign/` (gitignored — the path is
  the standard local-only secret seam used by the existing
  `vault-bootstrap.sh` and `garage-bootstrap.sh`); (b) seeds the
  cosign public key into a Kubernetes `ConfigMap` named
  `cosign-public-key` in namespace `kyverno` (`kubectl create
  configmap`; idempotent with `--dry-run=client -o yaml | kubectl
  apply -f -` so re-running matches the existing seam patterns).
  Per RFC #153 acceptance criteria: this script lands in this PR
  but is NOT yet wired into `make up` — that's a separate planner
  item once the script is reviewed. Add
  `tests/cosign-bootstrap.bats` (clusterless structural tests:
  script exists, is executable, declares the expected `cosign
  generate-key-pair` invocation, the ConfigMap name + namespace
  match the verifyImages policy's `keyRef`, the
  `--dry-run | apply` idempotency pattern is used). No Makefile
  target is added yet (Makefile changes are 🟡 — defer to the
  "wire cosign-bootstrap into make up" follow-up the next planner
  cycle files once this lands). (auto/cosign-bootstrap-script)

- [ ] 🟢 **Velero controller + Garage S3 backend** (CHARTER
  **Objective O1** + gates **Objective O3**, RFC #155 — see
  [ADR-0021](docs/decisions/adr-0021-velero-backup-restore.md) for
  the binding chart values, Garage backend shape, and
  ExternalSecret). Add `gitops/platform/velero.yaml` (auto-synced
  `Application`, chart `vmware-tanzu/velero` v8.4.x from
  `https://vmware-tanzu.github.io/helm-charts`, namespace
  `velero`; pin a specific 8.4.x patch at executor pickup). Apply
  the per-ADR `valuesObject`: `backupStorageLocation` provider
  `aws`, `s3ForcePathStyle=true`,
  `s3Url=http://garage.storage.svc.cluster.local:3900`, bucket
  `velero`, `defaultVolumesToFsBackup: true`,
  `uploaderType: kopia` (NOT restic — restic is deprecated in
  Velero 1.14 per ADR-0021). Add `gitops/velero/namespace.yaml`
  with PSA labels at `restricted` (controller + node-agent both
  run non-root; node-agent DaemonSet gets a per-workload
  `hostPath` carve-out matching the node-exporter pattern — see
  ADR-0017 §"Per-workload field carve-outs"). Update
  `scripts/garage-bootstrap.sh` to (a) create the `velero-key`
  Garage access key, (b) grant on the `velero` bucket, (c)
  create the `velero` bucket, (d) store the rendered creds at
  Vault path `secret/velero/s3` (mirrors the existing
  `inkless/s3` flow). Add
  `gitops/secrets/velero-s3-externalsecret.yaml` (ESO
  ExternalSecret rendering the `cloud-credentials` Secret the
  chart consumes — see ADR-0021 §"ExternalSecret shape" for the
  AWS-style INI body). Update `scripts/vault-bootstrap.sh`
  ensuring the `secret/velero/s3` path exists (mirrors inkless).
  Default-deny NetworkPolicy overlay at
  `gitops/velero/networkpolicy/kustomization.yaml` (ingress 8085
  from `observability` for metrics; egress 3900 to `storage` for
  Garage S3; egress to backed-up-namespace pod IPs for Kopia PV
  reads — Kopia egress allow uses `podSelector: {}` across
  namespaces `data`/`tidb`/`capstone`/`vault` matching the
  Schedule set in the next item). New auto-synced `Application`
  `gitops/platform/velero-networkpolicy.yaml` (sync-wave 4,
  `LoadRestrictionsNone`). New `velero` Alloy scrape job in
  `gitops/platform/observability-alloy.yaml`
  (`velero.velero.svc.cluster.local:8085`). New
  `grafana/dashboards/lab-velero.json` ("Lab — Velero (Backup &
  Restore)") with stat-row (controller running, node-agent
  running, ArgoCD sync) +
  `velero_backup_last_successful_timestamp` per Schedule +
  `velero_backup_partial_failure_total` + restore success rate.
  Wire dashboard into the Grafana "Lab UIs" panel. Update
  `docs/dependency-tree.md` (VELERO subgraph + Garage S3 edge).
  New `tests/velero.bats`: Application shape, chart source +
  version pin, Garage backend URL + path-style + bucket,
  ExternalSecret references `velero/s3`, namespace PSA labels,
  NetworkPolicy overlay structure, scrape job target, dashboard
  file + required panels, the `garage-bootstrap.sh` and
  `vault-bootstrap.sh` updates are present. **Executor note:**
  if the PR crosses ~400 lines per WAYS-OF-WORKING.md §3, ship
  the chart Application + namespace + bootstrap script updates +
  ExternalSecret in PR 1; file the dashboard + NetworkPolicy +
  Alloy scrape as the next planner item. The `velero: restricted`
  row addition to ADR-0017 is a separate small docs item (see
  "ADR-0017 amendment" below). The four `Schedule` CRs land in
  the next item; the `make dr-restore` Make target lands in the
  item after that. (auto/velero-controller)

- [ ] 🟢 **Velero Schedules — four stateful namespaces** (CHARTER
  **Objective O1** + gates **Objective O3**, RFC #155 — see
  ADR-0021 §"Schedule set" for binding cron + TTL). Wait for the
  Velero controller PR above to merge first (CRDs need to exist
  for Schedule manifests to validate in `make ci`). Add four
  `Schedule` CRs under `gitops/velero/schedules/`:
  `data-daily.yaml` (`schedule: "0 2 * * *"`, `ttl: 168h`,
  `includedNamespaces: [data]`, `defaultVolumesToFsBackup: true`);
  `tidb-daily.yaml` (`schedule: "30 2 * * *"`, TTL 168h,
  namespace `tidb`); `capstone-daily.yaml`
  (`schedule: "0 3 * * *"`, TTL 168h, namespace `capstone`);
  `vault-daily.yaml` (`schedule: "30 3 * * *"`, TTL 168h,
  namespace `vault`). Add `gitops/platform/velero-schedules.yaml`
  (auto-synced `Application`, sync-wave 5 — after the velero
  controller establishes CRDs). Extend `tests/velero.bats` with
  four-schedule assertions (each manifest exists, has the
  documented cron + TTL + namespace,
  `defaultVolumesToFsBackup: true` present on each).
  (auto/velero-schedules)

- [ ] 🟢 **make dr-restore + scripts/dr-restore.sh — Objective O3
  enabler** (CHARTER **Objective O3**, due **2026-12-31**: the
  explicit `< 10 min` wall-clock bar for restoring every stateful
  namespace from its latest Velero backup. RFC #155 acceptance
  criteria.). Wait for the Velero Schedules PR above to merge
  first. Add `scripts/dr-restore.sh` per ADR-0021 §"dr-restore
  runner": iterates `velero restore create --from-schedule
  <ns>-daily --wait` for `data`/`tidb`/`capstone`/`vault`, times
  each restore, prints a table, fails with exit code 1 if the
  total wall-clock exceeds 600s (Objective O3 budget) or any
  restore reports `phase != Completed`. Add `dr-restore` target
  to `Makefile` (clusterless `make` invocations are 🟢; the
  script's `velero` CLI call is run by the maintainer locally —
  not by the executor). Add `tests/dr-restore.bats` (clusterless
  structural tests: script exists + is executable, the four
  namespace restore lines are present, the 600s budget check is
  implemented, the Makefile target is wired). Update
  `docs/DR.md` with a section documenting the new `make
  dr-restore` target and its budget. **Executor note:** this PR
  adds a `Makefile` target — per WAYS-OF-WORKING.md §2 that is
  normally 🟡, but the architect's RFC #155 acceptance criteria
  explicitly names this Makefile target as part of the binding
  decision, so the planner grooms it as 🟢 (the architect's RFC
  is the approval). (auto/dr-restore-script)

- [ ] 🟢 **Argo Rollouts controller** (CHARTER **Objective O1**,
  RFC #154 — see
  [ADR-0020](docs/decisions/adr-0020-argo-rollouts-progressive-delivery.md)
  for the binding chart values, plug-in install, and
  traffic-router config). Add
  `gitops/platform/argo-rollouts.yaml` (auto-synced
  `Application`, chart `argo/argo-rollouts` v2.40.x from
  `https://argoproj.github.io/argo-helm`, namespace
  `argo-rollouts`; pin a specific 2.40.x patch at executor
  pickup). Apply the per-ADR `valuesObject`: 1 controller replica
  + 1 dashboard replica;
  `controller.trafficRouterPlugins` array carrying the
  `argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi` v0.5.0
  plug-in per ADR-0020 §"Traffic-router plug-in". Add
  `gitops/argo-rollouts/namespace.yaml` with PSA labels at
  `restricted`. Add `gitops/argo-rollouts/route.yaml` (Envoy
  `HTTPRoute` `rollouts.127.0.0.1.nip.io` → rollouts-dashboard
  Service on TCP 3100, namespace `argo-rollouts`). Add
  `gitops/platform/argo-rollouts-extras.yaml` (auto-synced
  `Application` for the route). Default-deny NetworkPolicy overlay
  at `gitops/argo-rollouts/networkpolicy/kustomization.yaml`
  (ingress 8090 from `observability` for metrics; ingress 3100
  from `envoy-gateway-system` for the HTTPRoute; egress 8080 to
  `observability` for Mimir analysis queries; egress to the k8s
  apiserver via the shared baseline). New auto-synced
  `Application` `gitops/platform/argo-rollouts-networkpolicy.yaml`
  (sync-wave 4, `LoadRestrictionsNone`). New `argo-rollouts`
  scrape job in `gitops/platform/observability-alloy.yaml`
  (`argo-rollouts-metrics.argo-rollouts.svc.cluster.local:8090`).
  New `grafana/dashboards/lab-argo-rollouts.json` ("Lab — Argo
  Rollouts (Progressive Delivery)") with stat-row (controller
  running, dashboard running, ArgoCD sync) + reconcile rate +
  Rollout phase distribution + analysis run outcomes. Wire
  dashboard into the Grafana "Lab UIs" panel + add the new
  HTTPRoute tile (`make lab-ui-check` must stay green). Update
  `docs/dependency-tree.md` (ARGO-ROLLOUTS subgraph + Mimir query
  edge + Envoy HTTPRoute edge). New `tests/argo-rollouts.bats`:
  Application shape, chart source + version pin, plug-in install
  block, namespace PSA labels, HTTPRoute wired, NetworkPolicy
  overlay structure, scrape job target, dashboard file +
  required panels. **Executor note:** if the PR crosses ~400
  lines per WAYS-OF-WORKING.md §3, ship the chart Application +
  namespace + HTTPRoute + NetworkPolicy in PR 1; file the
  dashboard + Alloy scrape as the next planner item. The
  capstone Rollout overlay + success-rate AnalysisTemplate land
  in the next item. The `argo-rollouts: restricted` row addition
  to ADR-0017 is a separate small docs item (see "ADR-0017
  amendment" below). (auto/argo-rollouts-controller)

- [ ] 🟢 **Capstone Rollout overlay + success-rate
  AnalysisTemplate** (CHARTER **Objective O1** + the capstone
  "Argo Rollouts canaries on real Mimir SLOs → Envoy routes it"
  vision, RFC #154). Wait for the Argo Rollouts controller PR
  above to merge first. Add
  `gitops/argo-rollouts/analysistemplates/success-rate.yaml`
  (`AnalysisTemplate` `success-rate` using the `prometheus`
  provider, address
  `http://mimir-query-frontend.observability.svc.cluster.local:8080/prometheus`,
  header `X-Scope-OrgID: lab`, query
  `sum(rate(envoy_cluster_upstream_rq{response_code!~"5.."}[1m]))
  / sum(rate(envoy_cluster_upstream_rq[1m]))` — exact PromQL is
  in ADR-0020 §"AnalysisTemplate"; success condition `>= 0.95`).
  Add `gitops/apps/capstone/rollout.yaml` (`Rollout` resource —
  SEPARATE file from `deployment.yaml` per RFC #154; the
  existing Deployment stays for now as the "no-canary"
  reference, executor may delete it in a follow-up planner item
  once the Rollout proves out). Rollout
  `spec.strategy.canary.steps`: `setWeight: 10` →
  `pause: {duration: 60s}` → `analysis: success-rate` →
  `setWeight: 50` → `pause: {duration: 60s}` →
  `analysis: success-rate` → (auto-complete to 100% via no
  terminal step). `spec.strategy.canary.trafficRouting.plugins`
  references the `argoproj-labs/gatewayAPI` plug-in pointing at
  the existing capstone HTTPRoute. Extend
  `tests/argo-rollouts.bats` (or add
  `tests/capstone-rollout.bats`): Rollout file exists, the four
  steps are in the documented order, AnalysisTemplate references
  Mimir at the documented URL with the `X-Scope-OrgID` header,
  the success-rate query matches the documented shape, the
  plug-in reference is correct. **Executor note:** the Rollout
  will not produce traffic-split data until a `kubectl argo
  rollouts set image` is run against the capstone Rollout (the
  maintainer does this locally to demo). That's intentional —
  the PR ships the shape, not a live demo. Document this in the
  PR body. (auto/capstone-rollout)

- [ ] 🟢 **Trivy Operator continuous scanning + SBOMs** (CHARTER
  **Objective O1** + CHARTER goal *supply-chain security
  end-to-end*, RFC #156 — see
  [ADR-0022](docs/decisions/adr-0022-trivy-operator-supply-chain.md)
  for the binding chart values, scanner toggles, and namespace
  profile). Add `gitops/platform/trivy-operator.yaml`
  (auto-synced `Application`, chart `aqua/trivy-operator`
  v0.30.x from `https://aquasecurity.github.io/helm-charts/`,
  namespace `trivy-system`; pin a specific 0.30.x patch at
  executor pickup). Apply the per-ADR `valuesObject`: all
  scanners enabled per RFC #156 *Decision* (`vulnerability`,
  `configAudit`, `rbacAssessment`, `exposedSecret`,
  `sbomGeneration`, `clusterCompliance`, `infraAssessment`);
  `excludeNamespaces` list per the RFC
  (`kube-system,kube-public,kube-node-lease`); 5Gi vuln-DB cache
  PVC on `local-path`. Add `gitops/trivy-system/namespace.yaml`
  with PSA labels at `baseline` (the controller alone is
  `restricted`-compatible but the chart applies one profile to
  both; scan-job pods unpack arbitrary OCI artifacts which
  exceeds `restricted`). Default-deny NetworkPolicy overlay at
  `gitops/trivy-system/networkpolicy/kustomization.yaml`
  (ingress 8080 from `observability`; egress 443 to the vuln-DB
  mirror `ghcr.io` — use the existing `ipBlock 0.0.0.0/0` egress
  pattern with port 443 since the mirror's IP is not stable).
  New auto-synced `Application`
  `gitops/platform/trivy-system-networkpolicy.yaml` (sync-wave 4,
  `LoadRestrictionsNone`). New `trivy-operator` scrape job in
  `gitops/platform/observability-alloy.yaml`
  (`trivy-operator.trivy-system.svc.cluster.local:8080`). New
  `grafana/dashboards/lab-trivy.json` ("Lab — Trivy Operator
  (Supply Chain)") with stat-row (operator running, ArgoCD
  sync) + CVE-by-severity stat panels (Critical / High / Medium
  / Low from `trivy_image_vulnerabilities{severity=…}`) +
  top-10 vulnerable workloads table + configAudit pass/fail pie
  + scan-job p95 duration timeseries + a stat panel counting
  `SbomReport` CRs per namespace (CHARTER SBOM goal). Wire
  dashboard into the Grafana "Lab UIs" panel. Update
  `docs/dependency-tree.md` (TRIVY subgraph + vuln-DB egress +
  scan target edges). New `tests/trivy-operator.bats`:
  Application shape, chart source + version pin, scanner toggles
  match the RFC, `excludeNamespaces` matches the RFC, namespace
  PSA labels, NetworkPolicy overlay structure, scrape job
  target, dashboard file + required panels. **Executor note:**
  if the PR crosses ~400 lines per WAYS-OF-WORKING.md §3, ship
  the chart Application + namespace + NetworkPolicy in PR 1;
  file the dashboard + Alloy scrape + bats as the next planner
  item. The `trivy-system: baseline` row addition to ADR-0017
  is in the combined "ADR-0017 amendment" docs item below.
  (auto/trivy-operator)

- [ ] 🟢 **ADR-0017 amendment — four Tier 1 next-wave namespace
  rows** (CHARTER **Objective O2** record-keeping; docs-only).
  Small docs PR adding four rows to the ADR-0017
  §"Per-namespace profile" table for the namespaces introduced
  by the Tier 1 next-wave items above: `kyverno` → `baseline`
  (webhook TLS `fsGroup` per ADR-0019 §"Per-namespace profile
  update"); `velero` → `restricted` (controller + node-agent
  both non-root per ADR-0021); `argo-rollouts` → `restricted`
  (per ADR-0020); `trivy-system` → `baseline` (scan-job pods
  unpack arbitrary OCI artifacts per ADR-0022). Cite each row's
  source ADR in the "Reason (today)" column. Add one bats
  assertion to `tests/securitycontext.bats` per namespace
  verifying the namespace manifest's labels match the ADR-0017
  row. **Executor note:** this item can be done as soon as the
  corresponding namespace manifests land — if a namespace
  manifest isn't merged yet, skip that row and file a follow-up
  planner item. (auto/adr-0017-next-wave-rows)

- [ ] 🟢 **Lab — Cloud control-plane (moto / ACK / KRO)
  dashboard** (CHARTER **Objective O5**, due **2026-09-30**:
  every always-on component has a real-metric Grafana dashboard.
  Promoted from *Cross-cutting* — this is the only always-on
  piece with no dashboard, see `grafana/dashboards/` against the
  always-on Application list). New
  `grafana/dashboards/lab-cloud-control-plane.json` modelled on
  the `lab-vault.json` stat-row pattern, three subsections —
  **moto** (pod running / memory / CPU / restarts from
  KSM+cAdvisor, ArgoCD sync state for the `moto` Application;
  namespace `moto`); **ACK S3** (same five metrics for the
  `ack-s3` Application's controller Deployment in namespace
  `ack-system`, plus a Loki logs panel filtered to the ACK
  controller pod showing reconciles against `kind=Bucket`);
  **KRO** (same five metrics for the KRO controller in namespace
  `ack-system`, plus a stat panel counting `kubectl get
  resourcegraphdefinitions` instances and a logs panel for the
  KRO controller pod showing RGD reconciles). About-text panel
  cites the `ack-demo-bucket` + `app-data` instance as the live
  demo objects to watch reconcile. All data from real
  KSM/cAdvisor/ArgoCD/Loki sources already scraped by Alloy —
  no new scrape jobs needed (ADR-0004). Wire the dashboard into
  the Grafana "Lab UIs" stack-health panel row list. Add
  `tests/observability.bats` assertions (file exists, three
  subsection headings present, no Prometheus query references
  metrics not currently scraped). Update
  `docs/dependency-tree.md` with a brief note that the
  cloud-control-plane stack now has a dashboard. *(Note for
  executor: if ACK or KRO controller pods expose
  controller-runtime metrics on a `:8080/metrics`-style port, do
  NOT add a scrape job in this PR — file that as a follow-up
  planner item; this PR stays clusterless-verifiable.)*
  (auto/cloud-control-plane-dashboard)

- [ ] 🟢 **PSS-restricted fan-out — `moto` + `ack-system`
  namespaces + `lab-gateway` labels** (CHARTER **Objective O2**,
  due **2026-09-30**; ADR-0017 §"Staged rollout" continuation —
  closes the always-on `restricted`-eligible fan-out except
  argocd which is 🟡). Three changes bundled because each is
  small individually and they share the moto+ack control-plane
  pair: (a) `moto` — add `gitops/moto/namespace.yaml` with the
  four PSA labels at `restricted` per ADR-0017 §"Per-namespace
  profile"; patch the moto chart's `valuesObject` in
  `gitops/platform/moto.yaml` with pod-level (`runAsNonRoot:
  true`, `runAsUser`/`runAsGroup`/`fsGroup` non-zero,
  `seccompProfile.type: RuntimeDefault`) + container-level
  (`allowPrivilegeEscalation: false`,
  `readOnlyRootFilesystem: true` with an `emptyDir` for moto's
  writable paths, `capabilities.drop: [ALL]`);
  (b) `ack-system` — add `gitops/ack/namespace.yaml` with the
  same four PSA labels at `restricted`; patch the `ack-s3` and
  `kro` chart `valuesObject`s in `gitops/platform/ack-s3.yaml`
  and `gitops/platform/kro.yaml` with the same securityContext
  shape (ACK + KRO controllers are stock controller-runtime,
  non-root-capable);
  (c) `lab-gateway` — the namespace today holds no pods (Envoy
  proxy pods live in `envoy-gateway-system`) so this is
  label-only: add `gitops/network/namespace.yaml` with the four
  PSA labels at `restricted` per ADR-0017's fan-out table. New
  `tests/securitycontext-moto-ack-labgateway.bats` (or extend
  the existing `tests/securitycontext.bats`): three namespace
  PSA-label assertions + securityContext field assertions for
  the moto Deployment + the ack-s3 / kro controller Deployments.
  **Executor note:** if the PR crosses ~400 lines per
  WAYS-OF-WORKING.md §3, ship `moto` + `lab-gateway` first and
  file `ack-system` as a follow-up. (auto/pss-moto-ack-labgateway)

- [ ] 🟢 **NetworkPolicy fan-out — `tidb` + `tidb-admin`
  namespaces** (CHARTER **Objective O2**, due **2026-09-30**;
  ADR-0016 §4 fan-out completion — these are on-demand
  namespaces so the policy only takes effect after
  `make tidb-up`, but the manifest needs to exist so a future
  on-demand bring-up gets the default-deny floor automatically).
  Two overlays:
  (a) `gitops/tidb/networkpolicy/kustomization.yaml` — baseline
  (`default-deny-all` + `allow-dns-and-apiserver`) +
  per-workload allows for the TiDB cluster topology:
  intra-namespace TCP 2379/2380 (PD client/peer), TCP
  20160/20180 (TiKV server/status), TCP 4000/10080 (TiDB
  server/status); egress TCP 10250 to nodes for kubelet (TiKV
  topology probe); egress to `tidb-admin` namespace for
  operator reconciliation; ingress from `tidb-admin` for the
  same; ingress TCP 4000 from `tidb` namespace (for the
  `tidb-demo` workload reading the database); ingress TCP
  10080 from `observability` for the existing Alloy scrape job.
  (b) `gitops/tidb-admin/networkpolicy/kustomization.yaml` —
  baseline only; egress to `tidb` namespace for operator
  reconciliation; egress to kube-apiserver via the baseline
  template. Two new ArgoCD `Application`s
  `gitops/platform/tidb-networkpolicy.yaml` and
  `gitops/platform/tidb-admin-networkpolicy.yaml`. **Sync
  policy is `automated: { prune: true, selfHeal: true }`** —
  these are on-demand namespaces, but the *NetworkPolicy
  manifests themselves are cheap (no pods)* so they can
  auto-sync alongside the namespace creation; this means the
  policies are *already in place* when the on-demand `make
  tidb-up` brings the pods up, not racing it. *(This is the
  same shape as the `lab-gateway-networkpolicy` Application
  that landed in the prior wave — see *Done*.)* Extend
  `tests/networkpolicy.bats` with tidb + tidb-admin overlay
  assertions. Update `docs/dependency-tree.md`. **Executor
  note:** if the PR crosses ~400 lines per WAYS-OF-WORKING.md
  §3, ship `tidb-admin` (small) first and file `tidb` as a
  follow-up. (auto/networkpolicy-tidb-fanout)

### Heavy on-demand components (README "Planned" row)
> **All three heavy components have human RFCs (#58 Artifactory, #59 Istio
> ambient, #60 Longhorn) and have been groomed into 🟢 ADR + manifest pairs in
> *Now / next* above.** Any future heavy/on-demand component goes through the
> same grooming flow: human files an RFC issue → planner splits into ADR +
> non-auto-synced manifest + `make` target + docs + bats items → executor builds.
> Heavy components MUST stay out of `gitops/bootstrap/root-app.yaml`'s
> auto-synced set (rule #4).

### Capstone — "tie it together" (learning-path step 5)
> RFC #62's end-to-end pipeline is **complete** — all five steps (GitLab CI
> build → ArgoCD deploy → Envoy HTTPRoute → Grafana tile → Vault `ExternalSecret`)
> shipped via the `auto/capstone-step-{1..5}` PRs and live in *Done* below. The
> capstone NetworkPolicy fan-out item in *Now / next* completes the
> defence-in-depth layer for the pipeline-deployed pod.

### Cross-cutting hardening & quality (always-safe filler)
> Use these when nothing above can be done cleanly in a single run. Mixed tiers —
> the 🟡 items still need an architect RFC before the executor builds them. The
> 🟢 cloud-control-plane dashboard item that previously lived here has been
> promoted to *Now / next* above (CHARTER **O5** carrier).

- [ ] 🟡 **PSS-restricted hardening — `argocd` namespace** (CHARTER
  **Objective O2**, due **2026-09-30**; ADR-0017 §"Staged rollout"
  remainder — the namespace is bootstrap-created by Terraform in
  `infra/modules/argocd/`, so flipping the namespace PSA labels and
  the per-workload `podSecurityContext` requires editing
  `infra/modules/argocd/values.yaml` (Helm-chart values for the argocd
  release) — that's an `infra/` bootstrap change, which
  WAYS-OF-WORKING.md §2 classifies as 🟡. **Awaiting an architect RFC**
  for: (a) whether to flip the namespace PSA enforcement label
  directly in `infra/modules/argocd/values.yaml` (Helm chart-supplied
  PSA labels) or in a separate ArgoCD-Application-managed Namespace
  manifest that re-labels the existing Terraform namespace (which is
  what the prior argocd-NetworkPolicy item does); (b) which ArgoCD
  controllers need carve-outs (the application-controller
  `runAsNonRoot: true` with a non-zero UID is well-documented; the
  repo-server's git working dir is the only known
  `readOnlyRootFilesystem: true` blocker); (c) the rollout sequence
  (apply the namespace label first as `warn`/`audit` only, observe,
  then flip `enforce`). Executor must not pick this up unprompted.
  The planner will split into 🟢 items the run after the RFC issue
  lands.

- [ ] 🟡 **NetworkPolicy fan-out — `envoy-gateway-system` namespace**
  (CHARTER **Objective O2**, due **2026-09-30**; ADR-0016 §4 fan-out
  remainder — flagged by the prior `lab-gateway-networkpolicy` Done
  item: Envoy proxy pods live in `envoy-gateway-system` and that
  namespace's NetworkPolicy is a larger item once the architect RFCs
  the proxy/data-plane egress requirements — it's effectively the
  cluster's ingress gateway, so its egress fan-out matches every
  backend Service. **Awaiting an architect RFC** for: (a) whether to
  enumerate egress allows per backend Service (high-maintenance — adds
  a fan-out for every new HTTPRoute) or use a coarse-grained
  `namespaceSelector` allow per namespace that hosts a backend (looser
  but matches the ADR-0008 shared-gateway pattern); (b) ingress allows
  for the listener ports the Gateway exposes (TCP 8000 + 8443 on host
  `127.0.0.1.nip.io`); (c) ingress allow on TCP 19000 + 19001 from
  `observability` for the existing Alloy scrape jobs (already in
  `gitops/platform/observability-alloy.yaml`); (d) the
  envoy-gateway-system controller's egress to the kube-apiserver for
  Gateway API reconciliation. Executor must not pick this up
  unprompted. The planner will split into 🟢 items the run after the
  RFC issue lands.

- [ ] 🟡 **ADR-0017 audit — vault PSA-restricted after Vault v2.0.2
  upgrade** (issue #157, `adr-audit` label). The architect routine
  surfaced that Vault v2.0.2 drops `cap_ipc_lock` from its container
  image, meaning the existing `vault: baseline` carve-out in
  ADR-0017's per-namespace profile table can be retired *if* the lab
  bumps Vault to v2.0.2+ **and** sets `disable_mlock = true` in the
  Vault config. The audit issue's "Recommendation" is *Revisit* — not
  a binding decision — so the next architect cycle owns the call
  (either edit ADR-0017 in place or supersede it). Executor must not
  pick this up unprompted. The planner will split into 🟢 items the
  run after the follow-up RFC issue lands. The dependent work is:
  (a) image bump of the vault Application to v2.0.2+;
  (b) `disable_mlock = true` in the vault config;
  (c) `gitops/vault/namespace.yaml` PSA labels flip baseline →
  restricted; (d) PSS-restricted `securityContext` on the vault
  Deployment + `emptyDir` for writable paths outside its PVC;
  (e) ADR-0017 row update.

_Future 🟡 entries land here when the architect routine files a new RFC
issue but the planner hasn't yet split it. The four 2026-W23 RFCs
(Kyverno → #153 / ADR-0019; Argo Rollouts → #154 / ADR-0020; Velero →
#155 / ADR-0021; Trivy Operator → #156 / ADR-0022) have been groomed
into 🟢 single-PR items in *Now / next* above (this planner run,
2026-06-11). All four ADRs (0019-0022) are merged on `main`, so the
executor builds top-down without waiting for further architect input.
The two prior 🟡 entries (NetworkPolicy default-deny, securityContext
hardening) remain groomed into the 🟢 fan-out items in *Now / next*
(ADR-0016 and ADR-0017 are adopted). The ADR-0010 Redis→Valkey swap
(issue #94) landed as ADR-0018 in PR #106 and is in *Done*._

---

## Done
<!-- Autonomous runs: move completed items here with their PR number. -->
- [x] **PSS-restricted fan-out — `observability` namespace** (ADR-0017 §Staged rollout; LGTMP stack) — Added `gitops/observability/mimir/namespace.yaml` (explicit Namespace manifest with four PSA `restricted` labels; synced by the wave-1 mimir Application). Full ADR-0017 §Layer 1 fields on direct-manifest deployments: Mimir, Loki, Tempo each receive pod-level `runAsNonRoot: true`, `runAsUser/runAsGroup/fsGroup: 10001`, `seccompProfile.type: RuntimeDefault`; container-level `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`; `/tmp` `emptyDir` added to each. Helm-chart Applications receive matching `podSecurityContext` + `containerSecurityContext` in their `valuesObject`: KSM (UID 65534, `readOnlyRootFilesystem: true`), node-exporter (UID 65534, `readOnlyRootFilesystem: true`, `hostPID/hostNetwork/hostRootFsMount` disabled for PSS restricted compliance), Alloy (UID 473, `readOnlyRootFilesystem: false` carve-out — WAL write-path), Grafana (UID 472, `readOnlyRootFilesystem: false` carve-out — plugin state; init container `ca-bundle` gets full PSS fields including `readOnlyRootFilesystem: true`), Pyroscope (UID 10001, `readOnlyRootFilesystem: false` carve-out — profiling data). 42 new bats tests in `tests/securitycontext-observability.bats`. `docs/dependency-tree.md` updated.
- [x] **NetworkPolicy fan-out — `lab-gateway` namespace** (ADR-0016 §4 fan-out; the Gateway listener namespace) — Added Kustomize overlay at `gitops/network/networkpolicy/` (kustomization.yaml; no per-workload allow rules — namespace holds only the Gateway CR, no pods). Baseline templates only: `default-deny-all` floor + `allow-dns-and-apiserver`. Future-proofs the namespace so any pod added later inherits the deny floor without a follow-up PR. New auto-synced ArgoCD `Application` `gitops/platform/lab-gateway-networkpolicy.yaml` (wave 4, `--load-restrictor LoadRestrictionsNone`). 11 new bats tests in `tests/networkpolicy.bats` (kustomization structure, namespace label, template references, no extra rules, ArgoCD Application shape). `docs/dependency-tree.md` updated with lab-gateway NetworkPolicy note; wave-4 table row updated. (auto/networkpolicy-lab-gateway-fanout)
- [x] **NetworkPolicy fan-out — `moto` + `ack-system` namespaces** (ADR-0016 §4 fan-out; completes the mock-cloud-control-plane pair) — Added Kustomize overlay at `gitops/moto/networkpolicy/` (kustomization.yaml + two per-workload allow rules). `allow-moto-from-ack.yaml` permits ingress from all pods in `ack-system` on TCP 5000 (ACK S3 controller calls moto's AWS-compatible HTTP API at `moto.moto.svc:5000` for Bucket CR reconciliation). `allow-moto-from-gateway.yaml` permits ingress from Envoy proxy pods (`app.kubernetes.io/component: proxy`) in `envoy-gateway-system` on TCP 5000 (for the `moto.127.0.0.1.nip.io` HTTPRoute). Added Kustomize overlay at `gitops/ack/networkpolicy/` (kustomization.yaml + one egress rule). `allow-ack-egress-moto.yaml` permits egress from all pods in `ack-system` to the `moto` namespace on TCP 5000 (the `endpoint_url` configured in the `ack-s3` Application valuesObject). Two new auto-synced ArgoCD `Application`s `gitops/platform/moto-networkpolicy.yaml` and `gitops/platform/ack-networkpolicy.yaml` (both sync-wave 4, `--load-restrictor LoadRestrictionsNone`). 25 new bats tests in `tests/networkpolicy.bats` (kustomization structure, per-workload allow rules, port and namespace selectors, ArgoCD Application shape). `docs/dependency-tree.md` updated with moto and ack-system NetworkPolicy notes; wave-4 table row updated.
- [x] **NetworkPolicy fan-out — `argocd` namespace** (ADR-0016 §4 fan-out; ArgoCD is the GitOps reconcile plane — highest blast-radius non-secrets namespace) — Added Kustomize overlay at `gitops/argocd/networkpolicy/` (kustomization.yaml + four per-workload rules). `allow-argocd-server-from-gateway.yaml` permits ingress from Envoy proxy pods (`app.kubernetes.io/component: proxy`) in `envoy-gateway-system` on TCP 8080 (for the `argocd.127.0.0.1.nip.io` HTTPRoute). `allow-argocd-from-alloy.yaml` permits ingress from Alloy pods (`app.kubernetes.io/name: alloy`) in `observability` on metrics ports 8080/8082/8083/8084 (matching the four `*-metrics` scrape targets already configured in `observability-alloy.yaml`). `allow-argocd-intra-namespace.yaml` is a broad intra-namespace allow-all covering controller ↔ repo-server (gRPC 8081), controller/server ↔ argocd-cache (6379), appset ↔ server (7000). `allow-argocd-repo-server-egress-gitlab.yaml` permits egress from `argocd-repo-server` pods to port 8929 via `ipBlock 0.0.0.0/0` (GitLab on the Docker host via `host.k3d.internal`, same pragmatic CIDR pattern as Alloy kubelet scraping). New auto-synced ArgoCD `Application` `gitops/platform/argocd-networkpolicy.yaml` (wave 4, `--load-restrictor LoadRestrictionsNone`). 21 new bats tests in `tests/networkpolicy.bats`. `docs/dependency-tree.md` updated with argocd NetworkPolicy note and wave-4 table row. (auto/networkpolicy-argocd-fanout)
- [x] **NetworkPolicy fan-out — `storage` namespace (Garage)** (ADR-0016 §4 fan-out; protects the S3 backplane for the LGTMP observability stack and Inkless) — Added Kustomize overlay at `gitops/storage/networkpolicy/` (kustomization.yaml + two per-workload allow rules). `allow-garage-s3-from-observability.yaml` permits ingress from any pod in the `observability` namespace on TCP 3900 (S3 API writes from Mimir/Loki/Tempo/Pyroscope) and TCP 3903 (Alloy admin metrics scrape). `allow-garage-s3-from-inkless.yaml` permits ingress from Inkless broker pods (`app: inkless`) in the `inkless` namespace on TCP 3900 (diskless Kafka log-segment S3 writes). The observability egress rule already mirrors TCP 3900+3903 with a broad `podSelector: {}` — both sides of the allow are consistent. No egress allows needed — Garage does not initiate outbound connections. New auto-synced ArgoCD `Application` `gitops/platform/storage-networkpolicy.yaml` (wave 4, `--load-restrictor LoadRestrictionsNone`). 17 new bats tests in `tests/networkpolicy.bats` (kustomization structure, per-workload allow rules, port and namespace selectors, ArgoCD Application shape). `docs/dependency-tree.md` updated with a storage NetworkPolicy note; wave-4 table row updated to include all five NetworkPolicy Applications.
- [x] **PSS labels — non-restricted carve-out namespaces** (ADR-0017 §Per-namespace profile; label-only) — Created `gitops/vault/namespace.yaml` (baseline — vault mlock requires IPC_LOCK), `gitops/storage/garage/namespace.yaml` (baseline — Garage upstream image non-root not declared), updated `gitops/tidb/namespace.yaml` (baseline — TiDB Operator caps), created `gitops/tidb-admin/namespace.yaml` (baseline — same). Each manifest sets `pod-security.kubernetes.io/{enforce,warn,audit}: baseline` + `enforce-version: latest`. Wired into existing ArgoCD Application source paths: vault-extras (gitops/vault), garage (gitops/storage/garage), tidb-cluster (gitops/tidb); new on-demand Application `gitops/platform/tidb-admin-extras.yaml` for tidb-admin (no automated sync — TiDB is on-demand). 4 new assertions in `tests/securitycontext.bats`. (auto/pss-carve-out-namespaces)
- [x] **NetworkPolicy fan-out — `observability` namespace** (ADR-0016 §4 fan-out) — Added Kustomize overlay at `gitops/observability/networkpolicy/` with seven policies: `allow-intra-namespace.yaml` (all-to-all within observability; covers Alloy → Mimir/Loki/Pyroscope writes, Grafana → backends, KSM + LGTMP self-scrapes); `allow-grafana-ingress-from-gateway.yaml` (ingress TCP 3000 from Envoy proxy pods in `envoy-gateway-system`); `allow-tempo-ingress-otlp.yaml` (ingress TCP 4318 OTLP HTTP from `capstone` and `lab-demo` trace producers); `allow-alloy-egress-external.yaml` (Alloy egress to argocd TCP 8080/8082/8083/8084, data TCP 15692/9121, envoy-gateway-system TCP 19000/19001, inkless TCP 9308, and cluster nodes TCP 10250 via cidr); `allow-egress-storage.yaml` (all pods egress to storage namespace TCP 3900 Garage S3 backend + TCP 3903 Garage metrics). New auto-synced ArgoCD `Application` `gitops/platform/observability-networkpolicy.yaml` (wave 4, `--load-restrictor LoadRestrictionsNone`). 19 new bats tests in `tests/networkpolicy.bats`. `docs/dependency-tree.md` updated. (auto/networkpolicy-observability-fanout)
- [x] **NetworkPolicy fan-out — `vault` namespace** (ADR-0016 §4 fan-out; protects the secrets plane) — Added Kustomize overlay at `gitops/vault/networkpolicy/` (kustomization.yaml + two per-workload allow rules). `allow-vault-from-eso.yaml` permits ingress on TCP 8200 from ESO controller pods (`app.kubernetes.io/name: external-secrets`) in the `external-secrets` namespace (k8s auth + KV secret reads — critical for all ExternalSecrets cluster-wide). `allow-vault-from-gateway.yaml` permits ingress on TCP 8200 from Envoy proxy pods (`app.kubernetes.io/component: proxy`) in `envoy-gateway-system` (vault.127.0.0.1.nip.io HTTPRoute). The allow-dns-and-apiserver baseline already covers Vault's k8s-auth API calls. New auto-synced ArgoCD `Application` `gitops/platform/vault-networkpolicy.yaml` (wave 4, `--load-restrictor LoadRestrictionsNone`). 15 new bats tests in `tests/networkpolicy.bats` (kustomization structure, per-workload allow rules, port 8200 on both rules, namespace selectors, ArgoCD Application shape). `docs/dependency-tree.md` updated with a vault NetworkPolicy note. (auto/networkpolicy-vault-fanout)
- [x] **PSS-restricted fan-out — `data` namespace** (ADR-0017 §Staged rollout) — Added `gitops/data/rabbitmq/namespace.yaml` (explicit `Namespace` manifest with four PSA `restricted` labels, synced by the wave-3 rabbitmq Application). Added pod-level and container-level PSS-restricted `securityContext` to both StatefulSets (`rabbitmq:3.13-management` UID 999, `valkey/valkey:8.0-alpine` UID 999 + `redis_exporter` sidecar) and both demo Deployments (`rabbitmq-load`, `valkey-load`): pod-level `runAsNonRoot: true`, `runAsUser/runAsGroup: 999`, `fsGroup: 999` (StatefulSets), `seccompProfile.type: RuntimeDefault`; container-level `allowPrivilegeEscalation: false`, `privileged: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`; `emptyDir` `/tmp` mounts for all five workloads. 25 new bats tests in `tests/securitycontext-data.bats` (5 namespace PSA label checks + 5 securityContext fields × 4 workloads). ADR-0017 carve-out table already records `data` as `restricted`-eligible. (auto/pss-data-fan-out)
- [x] **NetworkPolicy fan-out — `capstone` namespace** (ADR-0016 §4 fan-out) — Added Kustomize overlay at `gitops/apps/capstone/networkpolicy/` (kustomization.yaml + two per-workload allow rules) pulling the shared `default-deny.yaml` and `allow-dns-and-apiserver.yaml` baseline templates. `allow-capstone-ingress-from-gateway.yaml` permits ingress on TCP 8080 from Envoy proxy pods (`app.kubernetes.io/component=proxy`) in `envoy-gateway-system`. `allow-capstone-egress-tempo.yaml` permits egress on TCP 4318 (OTLP HTTP) to Tempo pods (`app=tempo`) in `observability`. New auto-synced ArgoCD `Application` `gitops/platform/capstone-networkpolicy.yaml` (wave 4, `--load-restrictor LoadRestrictionsNone`). 17 new bats tests in `tests/networkpolicy.bats` (kustomization structure, per-workload allow rules, port and namespace selectors, ArgoCD Application shape). `docs/dependency-tree.md` updated with a capstone NetworkPolicy note. Closes the capstone defence-in-depth layer alongside the existing PSS pilot. (auto/networkpolicy-capstone-fanout)
- [x] **Lab — Inkless Kafka dashboard: real broker/consumer metrics** — Extended `grafana/dashboards/lab-inkless.json` with five `kafka_exporter`-sourced queries: `kafka_brokers{job="inkless"}` (broker up count), `kafka_topic_partitions` (topic count), `kafka_topic_partition_under_replicated_partition` (replication health), `kafka_topic_partition_current_offset` (throughput, rate-based), and `kafka_consumergroup_lag` (top-20 by lag). New Alloy scrape job `prometheus.scrape "inkless"` in `gitops/platform/observability-alloy.yaml` targets the kafka-exporter sidecar at `inkless.inkless.svc.cluster.local:9308`. `tests/inkless.bats` asserts the broker (`kafka_brokers`) and consumer-lag (`kafka_consumergroup_lag`) queries are present and that the kafka-exporter sidecar is declared on the StatefulSet. ADR-0004: all data from real metrics. (copilot/get-metrics-from-inkless, PR #101)
- [x] **ADR-0018 — Valkey as the lab's cache / key-value store (supersedes ADR-0010)** — Industry-news-writer's first digest (`docs/industry/2026-W23-digest.md`) confirmed the supersede call: Valkey on BSD-3 under Linux Foundation governance is now the cloud-provider default (AWS ElastiCache for Valkey GA Oct 2024; GCP Memorystore added Valkey support). ADR-0018 written; manifests swapped at `gitops/platform/valkey.yaml` + `gitops/data/valkey/` (single-node StatefulSet with `redis_exporter` sidecar, Service on 6379/9121, ExternalSecret). Vault path `secret/valkey/default` seeded; `gitops/data/demo/valkey-load.yaml` generates continuous real SET/GET/INCR traffic; `grafana/dashboards/lab-valkey.json` renamed (queries unchanged — `redis_exporter` metric names are identical against Valkey). The pilot NetworkPolicy overlay's `allow-valkey-ingress.yaml` (TCP 6379, 9121) already references the new workload. Closes issue #94. (copilot/gt-94-update-documentation, PR #106; exporter-memory follow-up fix/valkey-exporter-memory, PR #109)
- [x] **securityContext hardening — `capstone` pilot** (ADR-0017, RFC #83) — Added `gitops/apps/capstone/namespace.yaml` (explicit `Namespace` manifest with four PSA `restricted` labels: `enforce`, `enforce-version: latest`, `warn`, `audit`). Updated `gitops/apps/capstone/deployment.yaml` with full PSS-restricted securityContext: pod-level (`runAsNonRoot: true`, `runAsUser/runAsGroup/fsGroup: 10001`, `seccompProfile.type: RuntimeDefault`) and container-level (`allowPrivilegeEscalation: false`, `privileged: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`); added `emptyDir` volume + `/tmp` volumeMount for the writable ephemeral path required by `readOnlyRootFilesystem: true`. 11 clusterless bats tests in `tests/securitycontext.bats` (namespace PSA label checks, deployment runAsNonRoot, seccompProfile, allowPrivilegeEscalation, readOnlyRootFilesystem, capabilities.drop, no-privileged). ADR-0017 (pod security standards restricted) already adopted. (copilot/reviewer-idle-no-agent-prs)
- [x] **NetworkPolicy baseline — `data` namespace pilot** (ADR-0016, RFC #82) — Added `gitops/platform/data-networkpolicy.yaml` (auto-synced ArgoCD `Application`, wave 4, Kustomize overlay with `--load-restrictor LoadRestrictionsNone` to resolve cross-directory template references). The overlay applies five NetworkPolicy objects to the `data` namespace: `default-deny-all` (Ingress + Egress floor), `allow-dns-and-apiserver` (kube-dns UDP/TCP 53 + k3s apiserver 10.43.0.1/32:6443), `allow-rabbitmq-ingress` (AMQP 5672, management 15672, Prometheus 15692), `allow-valkey-ingress` (Valkey 6379, redis_exporter 9121), `allow-data-demo-egress` (rabbitmq-load + valkey-load outbound to their targets). Shared baseline templates remain in `gitops/network/policies/` for reuse by future namespace overlays. 25 clusterless bats tests in `tests/networkpolicy.bats` (file existence, policyTypes shape, podSelectors, ports, kustomization references). `docs/dependency-tree.md` already updated with the network-policy note. Also updated `.routines-applied` to resolve a pre-existing CI failure caused by a prior commit that added/edited routine files without running `make routines-mark-applied` — maintainer should apply the three changed routines (architect, executor, industry-news-writer) via RemoteTrigger after merging. (auto/networkpolicy-data-pilot)
- [x] **Cilium on-demand manifest + infra flip** (ADR-0014 follow-on) — Added `gitops/platform/cilium.yaml` (non-auto-synced ArgoCD `Application`, chart `cilium/cilium` v1.16.6 from `https://helm.cilium.io`, namespace `kube-system`; `kubeProxyReplacement: true`; Hubble disabled for budget); set `disable_default_cni = true` in `infra/live/local/cluster/terragrunt.hcl` (Flannel + bundled NetworkPolicy controller disabled — ADR-0014 atomic requirement); `make cilium-up` (`helm upgrade --install`, day-0 bootstrap seam — run before `make argocd` on fresh clusters) / `make cilium-down` targets; `docs/DR.md` bootstrap order note (cluster-up → cilium-up → argocd → rest of stack); 10 bats tests in `tests/cilium.bats` (file exists, no automated: block, kube-system namespace, helm.cilium.io source, kubeProxyReplacement true, Hubble disabled, disable_default_cni true, both make targets, DR.md documents the step); `docs/dependency-tree.md` and `README.md` updated (CILIUM subgraph, sync-wave row, notes entry). Unblocks the two NetworkPolicy items. (auto/cilium-manifest-infra-flip)
- [x] **Lab — Garage S3 dashboard** + Alloy scrape job — Added `grafana/dashboards/lab-garage.json` ("Lab — Garage S3 (Object Storage)") with 13 panels: About text, 8 stat panels (Garage pod running, memory, bucket count, ArgoCD sync state, total objects, storage used GiB, block resync queue, restarts from KSM/cAdvisor), S3 API request rate by handler (`garage_s3_api_request_total`), S3 API error rate (`garage_s3_api_error_total`), block resync rate by status (`garage_block_resync_total`), and storage bytes over time (`garage_storage_bytes`). One new Alloy scrape job `prometheus.scrape "garage"` targeting `garage.storage.svc.cluster.local:3903/metrics` in `gitops/platform/observability-alloy.yaml`. 12 new bats tests in `tests/observability.bats`; `docs/dependency-tree.md` updated with Alloy→Garage scrape edge, integration edge row, and notes entry. Covers the S3-compatible-storage CHARTER learning objective. ADR-0004: all data from real metrics. (auto/garage-s3-dashboard)
- [x] **Lab — Envoy Gateway dashboard** + Alloy scrape job — Added `grafana/dashboards/lab-envoy.json` ("Lab — Envoy Gateway (Ingress)") with 11 panels: About text, 4 stat panels (controller pod running, proxy pod running, active downstream connections, request rate), per-listener request rate timeseries, request latency p50/p95/p99 histogram, 5xx error ratio timeseries, upstream cluster active connections, controller reconcile rate + errors, and memory by container. Two new Alloy scrape jobs in `gitops/platform/observability-alloy.yaml`: static `envoy-gateway-controller` (`:19001/metrics` on the `envoy-gateway` Service) and pod-discovery `envoy-proxy` (`:19000/stats/prometheus` on proxy pods in `envoy-gateway-system`, filtered by `app.kubernetes.io/component=proxy`). No new dependencies — Alloy's existing pod discovery RBAC already covers the new relabel block. 12 new bats tests in `tests/observability.bats`; `docs/dependency-tree.md` updated with scrape edges and dashboard note. ADR-0004: all data from real metrics. (auto/envoy-gateway-dashboard)
- [x] **Lab — ArgoCD dashboard** — Added `grafana/dashboards/lab-argocd.json` ("Lab — ArgoCD (GitOps)") with 16 panels: About text, 8 stat panels (pod-running for server/app-controller/repo-server/appset-controller + total-apps/healthy/synced/memory, mirroring the `lab-vault` stat-row pattern), per-app sync/health state table (`argocd_app_info`), sync attempt rate by phase (`argocd_app_sync_total`), reconcile duration heatmap (`argocd_app_reconcile_duration_seconds_bucket`), repo-server git request latency p50/p95/p99 (`argocd_git_request_duration_seconds_bucket`), ApplicationSet controller reconcile rate (`controller_runtime_reconcile_total{job="argocd-applicationset-controller"}`), and memory/CPU timeseries by container. No Alloy config changes needed (all four ArgoCD scrape targets already configured). New `tests/observability.bats` (11 tests); `docs/dependency-tree.md` updated. ADR-0004: all data from real metrics. (auto/argocd-dashboard)
- [x] **Capstone step 5 — Vault secret + `ExternalSecret` for the capstone app** — Seeded `secret/capstone/app` (app-key) in `scripts/vault-bootstrap.sh` (mirrors the `tidb/demo` pattern); added `gitops/secrets/capstone-app-externalsecret.yaml` (`ExternalSecret capstone-app-creds` in namespace `capstone`, sourcing `capstone/app` from the vault `ClusterSecretStore`); updated `gitops/apps/capstone/deployment.yaml` to inject `APP_KEY` from the rendered Secret via `secretKeyRef` (`optional: true` so pods start before ESO syncs on cold bootstrap); 7 new bats tests in `tests/capstone.bats` covering ExternalSecret existence, kind, namespace, vault key reference, Secret name, vault-bootstrap seeding, and Deployment env injection. (auto/capstone-step-5)
- [x] **Capstone step 4 — Grafana dashboard tile for the capstone app** ("Lab — Capstone"): Added `grafana/dashboards/lab-capstone.json` with 10 panels — About text, 4 stat panels (pod running / memory / restarts / ArgoCD sync from Mimir/KSM/cAdvisor), 2 timeseries panels (memory + CPU), log rate + logs panels (Loki, filtered to namespace `capstone`), and a Tempo traces table (TraceQL `{.service.name=~"capstone|frontend|..."}` matching the HotROD service names the capstone app emits). All data from real metrics (ADR-0004). 6 new bats tests in `tests/capstone.bats`; `docs/dependency-tree.md` updated (CAPSTONE subgraph, integration edges, notes). (auto/capstone-step-4)
- [x] **Capstone step 3 — Envoy `HTTPRoute` for the capstone app** — Added `gitops/apps/capstone/route.yaml` (HTTPRoute `capstone.127.0.0.1.nip.io` → capstone Service port 8080, namespace `capstone`; auto-synced via the existing capstone ArgoCD Application); updated the Grafana "Lab UIs" panel in `grafana/dashboards/stack-health.json` (new capstone row, :8000 front door); 6 new bats tests in `tests/capstone.bats` (route file exists, kind, hostname, port, gateway, Lab UIs panel); `docs/dependency-tree.md` updated (CAPSTONE subgraph now shows capstone app node + step 3 ingress edge, integration-edges table rows, notes entry updated to cover steps 1–3). (auto/capstone-step-3)
- [x] **Aiven Inkless (KIP-1150 diskless Kafka) on-demand** — Added `docs/decisions/adr-0015-inkless-diskless-kafka.md` (ADR choosing Inkless over Strimzi/Redpanda; PostgreSQL batch coordinator; Garage S3 backend; ~1.1 GB on-demand budget); `gitops/platform/inkless.yaml` (non-auto-synced ArgoCD Application, image `ghcr.io/aiven/inkless:latest`, namespace `inkless`); `gitops/inkless/inkless-statefulset.yaml` (single-node KRaft, diskless, Garage S3, PostgreSQL JDBC); `gitops/inkless/postgres-statefulset.yaml` (PostgreSQL 17 batch coordinator); `gitops/inkless/externalsecret.yaml` (two ExternalSecrets: `inkless/postgres` + `inkless/s3`); `scripts/vault-bootstrap.sh` updated (seeds `secret/inkless/postgres`); `scripts/garage-bootstrap.sh` updated (creates `inkless-key`, stores `secret/inkless/s3`, creates `inkless` bucket); `make inkless-up` / `make inkless-down` targets; `tests/inkless.bats` (structural tests: no auto-sync, Vault/Garage seeding, ExternalSecrets, make targets, dashboard, ADR); `grafana/dashboards/lab-inkless.json` (KSM/cAdvisor-only dashboard: pod status, memory, restarts, ArgoCD sync, timeseries, logs); `README.md` and `docs/dependency-tree.md` updated (INKLESS subgraph, edges, integration table). (auto/inkless)
- [x] **Capstone step 2 — ArgoCD Application for the pipeline-deployed app variant** — Added `gitops/apps/capstone/deployment.yaml` (Deployment + Service sourcing `artifactory.127.0.0.1.nip.io/docker-local/hello:latest` with `imagePullSecrets: artifactory-registry`); `gitops/platform/capstone.yaml` (auto-synced ArgoCD Application, sync-wave 4, targeting `gitops/apps/capstone`); updated `gitops/secrets/artifactory-registry-externalsecret.yaml` to use ESO v2 template producing a `kubernetes.io/dockerconfigjson` Secret (so Kubernetes can use it as an imagePullSecret); 6 new bats tests covering the Application, deployment, image reference, and Secret type. Steps 3–5 remain in the backlog. (auto/capstone-step-2)
- [x] **Capstone step 1 — GitLab CI: build the demo app image and push it to Artifactory** — Added `.gitlab-ci.yml` with a `build-and-push` Docker-in-DinD job targeting the in-lab Artifactory registry; `gitops/apps/demo/Dockerfile` (thin wrapper on `jaegertracing/example-hotrod:latest`); `secret/artifactory/registry` seeding in `scripts/vault-bootstrap.sh`; `gitops/secrets/artifactory-registry-externalsecret.yaml` (ESO ExternalSecret + `capstone` Namespace for in-cluster imagePullSecret material); `tests/capstone.bats` (9 structural tests: CI file shape, no plaintext creds, Vault path seeded, ExternalSecret wired, Dockerfile present); `docs/dependency-tree.md` updated (CAPSTONE subgraph, pipeline edges, integration-edges table rows, capstone Note); `README.md` updated. No plaintext credentials — `ARTIFACTORY_USER` / `ARTIFACTORY_PASSWORD` are masked GitLab CI variables sourced from Vault. (auto/capstone-step-1)
- [x] **Longhorn on-demand manifests + tooling** — Added `gitops/platform/longhorn.yaml` (non-auto-synced ArgoCD Application, chart `longhorn/longhorn` v1.7.2 from `https://charts.longhorn.io`, namespace `longhorn-system`; replica count 1 for single-node lab); `gitops/longhorn/route.yaml` (Envoy HTTPRoute `longhorn.127.0.0.1.nip.io`); `gitops/platform/longhorn-extras.yaml` (Application sourcing the route); `make longhorn-up` / `make longhorn-down` targets; 5 bats tests (no auto-sync on both Applications, HTTPRoute wired, make targets present); Grafana "Lab UIs" panel updated; `README.md` and `docs/dependency-tree.md` updated with Longhorn subgraph, sync-wave rows, integration edge, and notes entry. (auto/longhorn-manifests)
- [x] **ADR-0013 — Longhorn distributed block storage on-demand** — Added `docs/decisions/adr-0013-longhorn-block-storage.md` documenting why Longhorn is un-deferred (on-demand pattern proven by TiDB/Artifactory/Istio; learning objective: StorageClass + snapshot API + UI; CNCF graduated 2022); the official `longhorn/longhorn` chart from `charts.longhorn.io`; footprint estimate (~350–400 MB, on-demand non-auto-synced); complementarity with ADR-0002 (Garage=S3 object, Longhorn=block/filesystem — different interfaces, not alternatives); and relationships to ADRs 0001/0002/0003/0005/0008. Updated `docs/decisions/context.md` to replace the "Deferred" note with the un-defer rationale. Linked from `docs/decisions/README.md`. (auto/adr-0013-longhorn)
- [x] **Kiali on-demand manifests + Lab UIs panel wiring** — Added `gitops/platform/kiali.yaml` (non-auto-synced ArgoCD Application, chart `kiali-server` v1.89.0 from `https://kiali.org/helm-charts`, namespace `istio-system`; anonymous auth; Mimir Prometheus datasource with `X-Scope-OrgID: lab`); `gitops/kiali/route.yaml` (Envoy HTTPRoute `kiali.127.0.0.1.nip.io`); `gitops/platform/kiali-extras.yaml` (Application sourcing the route); `make kiali-up` / `make kiali-down` targets; combined `make mesh-up` / `make mesh-down` (Istio + Kiali together, correct order); 5 bats tests (no auto-sync, HTTPRoute wired, make targets present); Grafana "Lab UIs" panel updated; `README.md` and `docs/dependency-tree.md` updated.
- [x] **Istio ambient on-demand manifests + tooling** — Added four non-auto-synced ArgoCD Applications (`gitops/platform/istio-base.yaml`, `istio-cni.yaml`, `istiod.yaml`, `ztunnel.yaml`; chart `istio/{base,cni,istiod,ztunnel}` v1.24.3 from `istio-release.storage.googleapis.com/charts`, namespace `istio-system`); `make istio-up` / `make istio-down` targets; 6 bats tests asserting no auto-sync + make targets present; `docs/dependency-tree.md` updated with ISTIO subgraph and sync-wave rows; `README.md` updated with make targets. Kiali HTTPRoute + Lab UIs panel wiring is the next ROADMAP item.
- [x] **ADR-0012 — Istio ambient mesh + Kiali on-demand (not sidecar)** — Added `docs/decisions/adr-0012-istio-ambient-not-sidecar.md` documenting why ambient over sidecar (no per-pod injection; ~480 MB total vs ~1–2 GB for 20 sidecar-injected Pods; same Envoy data plane as ADR-0008); the four official Istio Helm charts (`istio/base`, `istio/istiod`, `istio/cni`, `istio/ztunnel`) plus Kiali (`kiali-server`); the on-demand / non-auto-synced deployment pattern (mirrors TiDB/Artifactory); footprint estimate within the 12 GB budget; and relationships to ADRs 0001/0003/0005/0008. Linked from `docs/decisions/README.md`. (auto/adr-0012-istio-ambient)
- [x] **Artifactory on-demand manifests + tooling** — Added `gitops/platform/artifactory.yaml` (non-auto-synced ArgoCD Application, chart `jfrog/artifactory-oss` from `charts.jfrog.io`, namespace `artifactory`); `gitops/artifactory/route.yaml` (Envoy HTTPRoute `artifactory.127.0.0.1.nip.io`); `gitops/platform/artifactory-extras.yaml` (Application sourcing the route); `make artifactory-up` / `make artifactory-down` targets; `tests/platform.bats` (5 clusterless tests asserting no auto-sync, route wired, make targets present); Grafana "Lab UIs" panel updated; `docs/dependency-tree.md` and `README.md` updated. (auto/artifactory-manifests)
- [x] **ADR-0011 — Artifactory as the on-demand artifact registry (not Nexus)** — Added `docs/decisions/adr-0011-artifactory-not-nexus.md` documenting why Artifactory OSS over Nexus (first-party `jfrog/artifactory-oss` chart from `charts.jfrog.io`; industry prevalence; OCI-native free tier); the 12 GB budget constraint that mandates non-auto-synced deployment (same pattern as TiDB); the capstone dependency chain (RFC #62 build pipeline blocked on Artifactory manifests); and ADR cross-references. Linked from `docs/decisions/README.md`. (auto/adr-0011-artifactory)
- [x] **Real Tempo trace producer — swap `hello` demo to HotROD** — Replaced `nginx:alpine` in `gitops/apps/demo/deployment.yaml` with `jaegertracing/example-hotrod:latest`; added `OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo.observability.svc.cluster.local:4318`. Updated `docs/dependency-tree.md` to show the `hello → tempo` OTLP edge (removed the "no producer yet" placeholder). Updated the "Lab — Traces" Grafana dashboard About panel to document HotROD as the trace producer with example TraceQL queries. (auto/tempo-trace-producer)
- [x] **Wire Git Sync bootstraps into `make up` / DR (survive Grafana rolls)** — Both ADR-0006
  imperative seams now run automatically: `gitlab-tls-bootstrap` (mkcert cert + nginx TLS proxy +
  publish `gitlab-tls-ca` ConfigMap, rolls Grafana if the CA arrives after it was already running)
  is called after `vault-bootstrap` in `make up`; `grafana-gitsync-bootstrap` (create the Pure Git
  `Repository` + set the home dashboard, waits up to 5 min for Grafana health) is called last. DR is
  covered: `make dr-test` rebuilds via `make up`, which includes both steps. Recovery cookbook in
  `docs/DR.md` updated; `tests/bootstrap-seams.bats` (9 structural tests) added.
- [x] **RabbitMQ + Redis data layer (always-on, fully integrated)** — Added an always-on
  data layer in namespace `data`, deployed by ArgoCD (auto-synced, ADR-0001): **RabbitMQ**
  (single-node broker, management UI via Envoy at `rabbitmq.127.0.0.1.nip.io`, `rabbitmq_prometheus`
  plugin) and **Redis** (single-node cache/KV, `--requirepass` auth, `redis_exporter` sidecar).
  Credentials flow Vault → ESO (`secret/rabbitmq/default`, `secret/redis/default`, seeded by
  `vault-bootstrap.sh`). Alloy scrapes both (`:15692` / `:9121`); two real-metric dashboards
  ("Lab — RabbitMQ", "Lab — Redis", ADR-0004). A `data-demo` workload (`redis-load` +
  `rabbitmq-load`) generates continuous real traffic. New ADR-0009 (RabbitMQ) + ADR-0010
  (Redis); README / dependency-tree / Lab UIs panel / `make creds` updated; `tests/data-layer.bats`
  added. (human-directed; branch `claude/roadmap-state-pUXWw`)
- [x] **Routine governance: never go silent when idle** — Updated the binding ROADMAP rules
  (#6, #8, #9) and both routine prompts so every scheduled run ends in either a PR or a
  refreshed `executor idle — needs work` GitHub issue that prompts the maintainer (with what's
  blocked + which RFC/ADR is owed). Removed the "stop without opening a PR" silent no-op.
  (human-directed; branch `claude/roadmap-state-pUXWw`)
- [x] **Dependency-tree sync** — Updated `docs/dependency-tree.md` to match current repo state: added TiDB on-demand components (Operator, Cluster, Demo App) to the Mermaid integration graph with dashed on-demand edges; added the two missing ESO secret-chain edges (`grafana-admin ← grafana/admin`, `tidb-demo-creds ← tidb/demo`); added the Envoy → `tidb-demo.127.0.0.1.nip.io` HTTPRoute edge; added two new rows to the integration edges table; expanded the Day-0 vault-bootstrap step to enumerate exactly which Vault paths it seeds. (PR #28)
- [x] **Vault & Secrets dashboard** — Added `grafana/dashboards/lab-vault.json`: a "Lab — Vault & Secrets" Grafana dashboard with 11 panels covering pod-running status, memory, CPU, restart counts, and ArgoCD sync state for both Vault and External Secrets Operator. All panels use real KSM/cAdvisor/ArgoCD metrics already scraped by Alloy — no fabricated data (ADR-0004). Delivered through Grafana native Git Sync (ADR-0006). Covers the "Add Grafana dashboards for always-on components lacking them" backlog item. (PR #TBD)
- [x] **Expand bats coverage** — Added 11 new tests across two files: `tests/adr-guard.bats` (7 tests — verifies the PostToolUse ADR guard exits 0 on clean/excluded paths and exits 2 with the correct message when a rejected term such as "minio" appears in a guarded file) + 4 uptime-math edge cases in `tests/bluegreen-probe.bats` (all-failures → 0%, single-pass, single-fail, and the outage-uses-maxrun-not-fail-count invariant). Suite grows from 15 to 26 tests. (auto/expand-bats-coverage)
- [x] **Resource CPU limits** — Added `cpu:` limits to every `Deployment`/`StatefulSet` in `gitops/` (9 direct-manifest workloads + 11 Helm-chart `Application` values entries, including both containers in the TiDB Operator chart and the Grafana sidecar). All workloads already had memory limits and cpu/memory requests; this completes the resource envelope. (auto/resource-cpu-limits)
- [x] **TiDB operator** — `gitops/platform/tidb-operator.yaml` (manual-sync ArgoCD Application, chart `tidb-operator` v1.6.1 from charts.pingcap.org, namespace `tidb-admin`). Makefile targets `tidb-operator-up` / `tidb-operator-down`. Docs updated in README + dependency-tree. (auto/tidb-operator)
- [x] **TiDB cluster** — `gitops/platform/tidb-cluster.yaml` (manual-sync ArgoCD Application, git-path `gitops/tidb/`). `TidbCluster` CR v8.1.2 with 1×PD + 1×TiKV + 1×TiDB (ADR-0005 lab trade-off; production uses ≥3+3+2). `make tidb-up` / `make tidb-down`. Docs updated in README + dependency-tree. (PR to be referenced)
- [x] **TiDB demo app** — `gitops/platform/tidb-demo.yaml` (manual-sync ArgoCD Application, git-path `gitops/tidb-demo/`). nginx demo workload in namespace `tidb` reading Vault credentials (`secret/tidb/demo`) via `ExternalSecret tidb-demo-creds`. Envoy HTTPRoute `tidb-demo.127.0.0.1.nip.io`. Grafana dashboard "Lab — TiDB Demo App" (real pod/container metrics). `make tidb-demo-up` / `make tidb-demo-down`. Vault-bootstrap seeding added. Docs updated in README + dependency-tree + stack-health panel.
- [x] **ADR-0007 — Off-cluster Garage Terraform-state backend** — Added `docs/decisions/adr-0007-off-cluster-garage-tfstate-backend.md` documenting why a second off-cluster Garage instance is used as the Terraform state backend (avoids the cluster→state bootstrap loop), the `generate "backend"` choice over `remote_state` (Garage compatibility), the explicit disabling of state locking, and the relationship to ADRs 0001/0002/0003/0005. Linked from `docs/decisions/README.md`.
- [x] **ADR-0008 — Envoy Gateway for north-south ingress** — Added `docs/decisions/adr-0008-envoy-gateway-not-traefik.md` documenting the choice of Envoy Gateway (Gateway API: HTTPRoute) over the k3s-default Traefik and Kubernetes `Ingress`; covers the shared-gateway pattern (`allowedRoutes: All`), the `*.127.0.0.1.nip.io` hostname strategy, and the rationale for using the same Envoy data plane as the planned Istio ambient mesh. Linked from `docs/decisions/README.md`. (PR #32)
