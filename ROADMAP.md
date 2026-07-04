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
7. **Check it off in the same PR.** Mark the item `[x]` in the backlog, then create
   `docs/done/YYYY-MM-DD-<slug>.md` (today's date + your branch slug) with the full
   item description and the PR number. Do **not** prepend anything to the `## Done`
   section — that section is now just a pointer to `docs/done/`.
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
>
> **Conflict-free editing (binding rule).** Add/edit the discrete 🟡/🟢/🔴 **items**
> inline here as normal. But record any per-run **narrative commentary** (grooming
> summaries, "what was filed/unblocked this run", `**Planner note (…)**` blocks) as a
> new file under [`docs/backlog/`](docs/backlog/) (`YYYY-MM-DD-<slug>.md`) — **never
> inline anywhere in this file**: not as a header block at the top of a section, not as
> a footer paragraph at the end of one. (Putting them at the top instead of the bottom
> caused the exact same conflict twice — PRs #209 and #236.) One file per run means
> concurrent PRs never touch the same lines. This is enforced mechanically by
> `make ci` (`scripts/roadmap-check.sh` fails on any inline `**Planner note (…)**`
> block). Same rule, same reason as `## Done` → [`docs/done/`](docs/done/).

### Now / next
> Pick the topmost unchecked item. If it can't be done cleanly this run, fall
> through to the next.
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
>
> _Per-run planner narrative (what was groomed/filed/unblocked each run) lives in
> [`docs/backlog/`](docs/backlog/), one dated file per run — never inline here (see
> the **Conflict-free editing** binding rule above). History through 2026-06-20:
> [`docs/backlog/2026-06-20-planner-note-migration.md`](docs/backlog/2026-06-20-planner-note-migration.md)._

- [x] 🟢 **Kyverno engine + observability** (CHARTER **Objective O1**,
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

- [x] 🟢 **Kyverno initial ClusterPolicies (validate + mutate +
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

- [x] 🟢 **cosign-bootstrap.sh day-0 seam (key generation +
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

- [x] 🟢 **Velero controller + Garage S3 backend** (CHARTER
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

- [x] 🟢 **Velero Schedules — four stateful namespaces** (CHARTER
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

- [x] 🟢 **make dr-restore + scripts/dr-restore.sh — Objective O3
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

- [x] 🟢 **Argo Rollouts controller** (CHARTER **Objective O1**,
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

- [x] 🟢 **Capstone Rollout overlay + success-rate
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

- [x] 🟢 **Trivy Operator continuous scanning + SBOMs** (CHARTER
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

- [x] 🟢 **ADR-0017 amendment — four Tier 1 next-wave namespace
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

- [x] 🟢 **Lab — Cloud control-plane (moto / ACK / KRO)
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

- [x] 🟢 **PSS-restricted fan-out — `moto` + `ack-system`
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

- [x] 🟢 **NetworkPolicy fan-out — `tidb` + `tidb-admin`
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

- [x] 🟢 **Argo Rollouts dashboard + Alloy scrape job** (CHARTER **Objective O1** +
  **O5**; deferred from `auto/argo-rollouts-controller` per the 400-line budget rule
  — see `docs/done/2026-06-13-argo-rollouts-controller.md` and the
  `docs/dependency-tree.md` Argo Rollouts note). The NetworkPolicy ingress on TCP
  8090 from `observability` is pre-wired; the scrape job and dashboard are the only
  missing pieces. Add `prometheus.scrape "argo_rollouts"` block to
  `gitops/platform/observability-alloy.yaml` (single static target
  `argo-rollouts-metrics.argo-rollouts.svc.cluster.local:8090`; `scrape_interval =
  "30s"`; mirrors the adjacent `trivy_operator` / `velero` scrape pattern). New
  `grafana/dashboards/lab-argo-rollouts.json` ("Lab — Argo Rollouts (Progressive
  Delivery)") modelled on `lab-kyverno.json` stat-row: stat panels for controller
  running + rollouts-dashboard running (KSM
  `kube_deployment_status_replicas_available{namespace="argo-rollouts"}`); ArgoCD
  sync state (`argocd_app_info{name=~"argo-rollouts.*"}`); reconcile rate timeseries
  (`controller_runtime_reconcile_total{controller="rollout"}`); Rollout phase
  distribution stat panels from `rollout_phase{phase=~"Healthy|Paused|Degraded"}`;
  canary weight gauge (`rollout_canary_weight`). All panels real Mimir data with
  `X-Scope-OrgID: lab` tenant header (ADR-0004 — no fabricated data; if a metric
  is not yet emitted before a Rollout runs, document it in the panel description and
  do NOT substitute a placeholder). The `rollouts.127.0.0.1.nip.io:8000` row in the
  stack-health Lab UIs panel was added in the controller PR — no new row needed.
  Extend `tests/argo-rollouts.bats`: scrape job block for `"argo_rollouts"` exists
  in `observability-alloy.yaml`; `lab-argo-rollouts.json` exists; dashboard
  references `controller_runtime_reconcile_total`; no fabricated/placeholder data.
  Update `docs/dependency-tree.md` Argo Rollouts note to confirm Alloy scrape and
  dashboard are now present. (auto/argo-rollouts-dashboard)

- [x] 🟢 **Trivy Operator dashboard** (CHARTER **Objective O1** + **O5**; deferred
  from `auto/trivy-operator` per the 400-line budget rule — see
  `docs/done/auto-trivy-operator.md` and the `docs/dependency-tree.md` Trivy note:
  "Dashboard `grafana/dashboards/lab-trivy.json` is the next planner item
  (ADR-0004 compliance)"). The Alloy scrape job (`prometheus.scrape "trivy_operator"`
  targeting `trivy-operator.trivy-system.svc.cluster.local:8080`) is already wired in
  `gitops/platform/observability-alloy.yaml` — no scrape change needed. New
  `grafana/dashboards/lab-trivy.json` ("Lab — Trivy Operator (Supply Chain)")
  modelled on `lab-kyverno.json` stat-row: operator running (KSM
  `kube_deployment_status_replicas_available{namespace="trivy-system"}`); ArgoCD
  sync state; CVE-by-severity stat panels (Critical / High / Medium / Low) from
  `trivy_image_vulnerabilities{severity=~"CRITICAL|HIGH|MEDIUM|LOW"}` aggregated
  across all workloads; top-10 vulnerable-workload bar chart (sum by `resource` label
  with `topk(10, …)`); configAudit pass/fail pie
  (`trivy_config_audit_checks_total{severity=…}`); SBOM report count stat panel
  (`trivy_sbom_reports_total` by namespace — direct CHARTER supply-chain goal).
  All panels real Mimir data (ADR-0004 — any panel whose metric has not yet emitted
  a series must show "No data" naturally, not a fabricated fallback). Extend
  `tests/trivy-operator.bats`: `lab-trivy.json` exists; dashboard references
  `trivy_image_vulnerabilities`; references `trivy_sbom_reports_total`; no
  fabricated/placeholder data. Update `docs/dependency-tree.md` Trivy note to
  confirm dashboard present. (auto/trivy-dashboard)

- [x] 🟢 **ArgoCD PSS Phase 1 — namespace warn+audit labels** (CHARTER
  **Objective O2**, due **2026-09-30**; RFC #205 — ADR-0017 argocd PSS
  two-phase rollout, Phase 1 🟢 immediately). Create
  `gitops/argocd/namespace.yaml` with PSA labels `warn: restricted`,
  `audit: restricted`, `warn-version: latest`, `audit-version: latest`
  only — `enforce` label is absent (that is Phase 2). ArgoCD
  Server-Side-Applies this onto the existing Terraform-created
  namespace; no `infra/` touch needed (SSA merges labels safely). Deliver
  via a new auto-synced ArgoCD `Application`
  `gitops/platform/argocd-extras.yaml` (sync-wave 0,
  `LoadRestrictionsNone`, `CreateNamespace=false` — namespace is
  pre-created by Terraform; this Application only manages the PSA
  labels). Follow the existing `kyverno-extras` / `trivy-extras` naming
  convention — RFC #205 refers to it as `argocd-namespace.yaml` but the
  repo uses the `-extras` suffix for this class of Application. Extend
  `tests/securitycontext.bats` asserting: `gitops/argocd/namespace.yaml`
  exists; the four warn/audit labels are present; `enforce` label is
  absent. Update `docs/dependency-tree.md` with an argocd PSS Phase 1
  note. `docs/done/2026-06-15-argocd-pss-warn-audit.md` required.
  (auto/argocd-pss-warn-audit)

- [x] 🟢 **External Secrets dashboard + Alloy scrape** (CHARTER **Objective O5**,
  due **2026-09-30**; O5 gap — `external-secrets` is auto-synced in
  `gitops/bootstrap/root-app.yaml` but has no Alloy scrape job and no Grafana
  dashboard. The ESO controller exposes Prometheus metrics at `:8080/metrics`
  by default via controller-runtime; no chart `valuesObject` change needed to
  enable metrics collection). Add `prometheus.scrape "external_secrets"` block
  to `gitops/platform/observability-alloy.yaml` targeting
  `external-secrets.external-secrets.svc.cluster.local:8080`; `scrape_interval =
  "30s"`; mirrors the adjacent `kyverno` / `trivy_operator` / `velero` /
  `argo_rollouts` scrape pattern. New `grafana/dashboards/lab-external-secrets.json`
  ("Lab — External Secrets") modelled on `lab-kyverno.json` stat-row: ESO
  controller running (KSM
  `kube_deployment_status_replicas_available{namespace="external-secrets"}`);
  ArgoCD sync state (`argocd_app_info{name="external-secrets"}`); ExternalSecret
  sync success rate timeseries
  (`externalsecret_sync_calls_total{status="success"}` by namespace); sync error
  count stat (`externalsecret_sync_calls_total{status="error"}`); sync duration
  p95 (`externalsecret_sync_calls_duration_seconds_bucket`). All panels use real
  Mimir data with `X-Scope-OrgID: lab` tenant header (ADR-0004 — no fabricated
  data; if a metric has not yet emitted a series, the panel shows "No data"
  naturally). No HTTPRoute — ESO has no web UI, so no Lab UIs panel row needed
  (`make lab-ui-check` unaffected). Extend `tests/observability.bats` with four
  assertions: scrape job block `"external_secrets"` exists in
  `observability-alloy.yaml`; `lab-external-secrets.json` exists; dashboard
  references `externalsecret_sync_calls_total`; no fabricated/placeholder data.
  Update `docs/dependency-tree.md` with External Secrets dashboard note (parallel
  to the Argo Rollouts / Trivy dashboard notes added in recent runs). `docs/done/`
  entry required. (auto/external-secrets-dashboard)

- [x] 🟢 **ArgoCD PSS Phase 2 — securityContext hardening + enforce
  flip** (CHARTER **Objective O2**, RFC #205 — Phase 2; buildable after
  Phase 1 is **verified green in cluster** by maintainer). Update
  `infra/modules/argocd/values.yaml` adding the exact
  `global.podSecurityContext` + `global.containerSecurityContext` block
  from RFC #205 §Decision (`runAsNonRoot: true`, `runAsUser/Group: 1000`,
  `seccompProfile.type: RuntimeDefault`; `allowPrivilegeEscalation:
  false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`);
  add `emptyDir` at `/tmp` for `repoServer` (git clone scratch) and
  `server` (session token files) via `volumes` + `volumeMounts`. Update
  `gitops/argocd/namespace.yaml` to add `enforce: restricted` +
  `enforce-version: latest`. Verify the bundled `argocd-redis`
  sub-chart's own securityContext is not adversely overridden by the
  global block — add per-component override if needed. Extend
  `tests/securitycontext.bats` asserting `enforce: restricted` label is
  present in `gitops/argocd/namespace.yaml`. `docs/done/` entry required.
  **Executor note:** the `infra/` touch is 🟡 by default, but RFC #205
  (the architect's binding decision per WAYS-OF-WORKING.md §2) explicitly
  names this `infra/` change as part of the implementation spec — the
  RFC IS the approval; no additional human sign-off needed before
  building. (auto/argocd-pss-enforce)

- [x] 🟢 **NetworkPolicy fan-out — `envoy-gateway-system` namespace**
  (CHARTER **Objective O2**, due **2026-09-30**; RFC #206 — ADR-0016 §4
  fan-out completion; closes the last always-on namespace without a
  NetworkPolicy floor). Two pod types need distinct policies
  (differentiated by `podSelector`). Create
  `gitops/envoy-gateway-system/networkpolicy/kustomization.yaml`
  referencing the two baseline templates
  (`../../network/policies/default-deny.yaml`,
  `../../network/policies/allow-dns-and-apiserver.yaml`) plus four allow
  files: `allow-envoy-controller-metrics-ingress.yaml` (ingress TCP 19001
  from `namespaceSelector: kubernetes.io/metadata.name: observability`;
  `podSelector: app.kubernetes.io/name: envoy-gateway`);
  `allow-envoy-proxy-metrics-ingress.yaml` (ingress TCP 19000 from
  `observability`; `podSelector: app.kubernetes.io/name: envoy-proxy`);
  `allow-envoy-proxy-listener-ingress.yaml` (ingress TCP 10080 from
  `ipBlock: cidr: 0.0.0.0/0`; `podSelector: app.kubernetes.io/name:
  envoy-proxy` — **executor must verify the actual proxy container port
  before finalizing**; RFC #206 §Decision notes the lab maps Service
  port 80 → container 10080, but verify against the pod spec);
  `allow-envoy-proxy-backend-egress.yaml` (egress from proxy pods to the
  twelve named backend namespaces via `namespaceSelector` with
  `matchExpressions: operator: In`, no port restriction — backend list
  per RFC #206: `argocd`, `capstone`, `vault`, `observability`, `data`,
  `storage`, `moto`, `ack-system`, `argo-rollouts`, `kyverno`, `velero`,
  `trivy-system`). New auto-synced `Application`
  `gitops/platform/envoy-gateway-system-networkpolicy.yaml` (sync-wave 4,
  `LoadRestrictionsNone`) — same pattern as all other `*-networkpolicy`
  Applications. Extend `tests/networkpolicy.bats`: kustomization exists;
  baseline refs present; each allow file exists and targets the correct
  port + selector per above; Application file present. Update
  `docs/dependency-tree.md` with envoy-gateway-system NP note.
  `docs/done/` entry required. (auto/envoy-gateway-system-networkpolicy)

- [x] 🟢 **cosign-bootstrap wiring into `make up`** (CHARTER **Objective O4**, RFC #214
  Item 1; `scripts/cosign-bootstrap.sh` already merged in `auto/cosign-bootstrap-script`).
  Add a `cosign-bootstrap` phony target to `Makefile` calling `bash
  scripts/cosign-bootstrap.sh` (mirrors `make vault-bootstrap` / `make garage-bootstrap`
  pattern). Insert `$(MAKE) cosign-bootstrap` into the `make up` target **after**
  `$(MAKE) garage-bootstrap` and **before** `$(MAKE) grafana-gitsync-bootstrap` per RFC
  #214 §Decision (kyverno namespace is synced by ArgoCD by the time garage-bootstrap
  completes; the script is idempotent). Extend `tests/cosign-bootstrap.bats` with two
  structural assertions: Makefile `cosign-bootstrap` target exists; the `make up`
  insertion order is correct (grep for the two adjacent calls in the documented sequence).
  `make ci` must pass. **Executor note:** Makefile change is normally 🟡 but RFC #214
  explicitly names this target in its binding Decision — the RFC IS the approval per
  WAYS-OF-WORKING.md §2. (auto/cosign-make-up-wiring)

- [x] 🟢 **`cosign sign` stage in `.gitlab-ci.yml`** (CHARTER **Objective O4**, RFC #214
  Item 2; wait for `auto/cosign-make-up-wiring` to merge first). Add `sign` to the
  `stages:` list. New `sign-image` job: `image: bitnami/cosign:2`; variables
  `COSIGN_PASSWORD: ""` and `COSIGN_EXPERIMENTAL: "0"` (disables Rekor transparency
  upload — no outbound internet in lab); `before_script` copies `$COSIGN_KEY` (GitLab
  File CI variable) to `/tmp/cosign/cosign.key`; `script` runs `cosign sign --key
  /tmp/cosign/cosign.key --allow-insecure-registry --registry-username "$ARTIFACTORY_USER"
  --registry-password "$ARTIFACTORY_PASSWORD" "$REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHORT_SHA"`
  (pushes `.sig` OCI tag back to Artifactory; `--allow-insecure-registry` because the
  Artifactory route uses HTTP); `after_script: [rm -rf /tmp/cosign]`; `needs:
  [build-and-push]`; `rules: if $CI_COMMIT_BRANCH == "main"`. Add a comment above the
  job explaining `COSIGN_KEY` is a GitLab CI File variable the maintainer must set
  (masked, type File — same doc pattern as existing `ARTIFACTORY_USER`/`ARTIFACTORY_PASSWORD`
  comment block). `make ci` must pass. **Executor note:** CI change is normally 🟡 but
  RFC #214 explicitly specifies this job in its binding Decision — the RFC IS the approval.
  (auto/cosign-ci-sign-step)

- [x] 🟢 **`make capstone-demo` + `scripts/capstone-demo.sh`** (CHARTER **Objective O6**,
  RFC #215 — demo-only wall-clock scope, 900 s budget; no dependency on other items).
  New `scripts/capstone-demo.sh` per RFC #215 §Decision: records `START_EPOCH`; (1) waits
  for capstone ArgoCD app Healthy (`argocd app wait capstone --health --timeout 120`; exits
  1 on timeout); (2) asserts capstone ExternalSecret Ready (`kubectl -n capstone get
  externalsecret` jsonpath `.status.conditions[?(@.type=="Ready")].status == "True"` within
  30 s); (3) sends synthetic curl to `http://capstone.127.0.0.1.nip.io:8000/` asserting
  HTTP 200; (4) verifies a Tempo trace via `kubectl -n observability port-forward
  svc/tempo-query-frontend 3100:3100 &` + Tempo HTTP `/api/search?service.name=capstone`
  (OS-portable `date` arithmetic per RFC #215 — macOS `-v-5M` vs Linux
  `$(( $(date +%s) - 300 ))`); (5) enforces 900 s budget with per-step elapsed check;
  (6) prints a summary table (elapsed per step + total, same pattern as
  `scripts/dr-restore.sh`). New `make capstone-demo` phony target (`##@ Capstone` section
  or nearest existing section) calling `bash scripts/capstone-demo.sh`. New
  `tests/capstone-demo.bats` (clusterless structural): script exists + is executable; 900 s
  budget check present; `argocd app wait capstone` invocation present;
  `tempo-query-frontend` present; `externalsecret` check present. Update `docs/DR.md` with
  a `## Capstone demo (O6)` section (prereqs: healthy cluster + `argocd` CLI logged in;
  900 s budget). **Executor note:** `make capstone-demo` is a live-cluster target (like
  `make dr-restore`), not a `make ci` gate; the bats tests are clusterless and must pass
  without a live cluster. Makefile change is RFC #215-approved per WAYS-OF-WORKING.md §2.
  (auto/capstone-demo-target)

- [x] 🟢 **PSS-restricted hardening — `external-secrets` namespace** (CHARTER **Objective O2**,
  due **2026-09-30**; RFC #229 — architect decision 2026-06-19). Add
  `gitops/external-secrets/namespace.yaml` with all four PSA labels at `restricted`
  (`enforce: restricted`, `enforce-version: latest`, `warn: restricted`,
  `audit: restricted`). Add new auto-synced `Application`
  `gitops/platform/external-secrets-extras.yaml` (sync-wave 0, `ServerSideApply=true`,
  `CreateNamespace=false` — namespace pre-created by the existing `external-secrets`
  Application; follows the `argocd-extras` / `kyverno-extras` naming convention). Patch
  `gitops/platform/external-secrets.yaml` `valuesObject` with `global.podSecurityContext`
  (`runAsNonRoot: true`, `runAsUser: 65534`, `runAsGroup: 65534`, `seccompProfile.type:
  RuntimeDefault`) + `global.containerSecurityContext` (`allowPrivilegeEscalation: false`,
  `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`) per RFC #229 §Decision. If
  `readOnlyRootFilesystem: true` causes a startup failure, add an `emptyDir` at `/tmp` via
  `extraVolumes`/`extraVolumeMounts` in `valuesObject`; do NOT relax `readOnlyRootFilesystem`
  without a follow-up issue. Add `external-secrets → restricted` row to ADR-0017
  §"Per-namespace profile" table citing RFC #229. Extend `tests/securitycontext.bats`:
  namespace PSA-label assertions + `runAsNonRoot: true` in the chart `valuesObject`. `make
  ci` must pass. `docs/done/` entry required. **Executor note:** the `valuesObject` patch
  is security-adjacent (🟡 by default) but RFC #229 is the binding architect decision
  (WAYS-OF-WORKING.md §2) — the RFC IS the approval. (auto/pss-external-secrets)

- [x] 🟢 **PSS-baseline hardening — `envoy-gateway-system` namespace** (CHARTER **Objective O2**,
  due **2026-09-30**; RFC #230 — architect decision 2026-06-19). Add
  `gitops/envoy-gateway-system/namespace.yaml` with all four PSA labels at `baseline`
  (`enforce: baseline`, `enforce-version: latest`, `warn: baseline`, `audit: baseline`).
  Add new auto-synced `Application` `gitops/platform/envoy-gateway-system-extras.yaml`
  (sync-wave 0, `ServerSideApply=true`, `CreateNamespace=false` — namespace pre-created by
  the existing `envoy-gateway` Application; follows the `argocd-extras` / `kyverno-extras`
  naming convention). **No workload securityContext patches in this PR** — `baseline` does
  not require field-level securityContext changes; proxy pod root UID is the documented
  carve-out (RFC #230 §Rationale). Add `envoy-gateway-system → baseline` row to ADR-0017
  §"Per-namespace profile" table with explicit flip condition to `restricted` (when
  `gateway-helm` chart supports non-root proxy pods), citing RFC #230. Extend
  `tests/securitycontext.bats`: namespace PSA-label assertions; assert `enforce: baseline`
  present and `enforce: restricted` absent (safety check). `make ci` must pass. `docs/done/`
  entry required. (auto/pss-envoy-gateway-system)

- [x] 🟢 **zz-dns-clusterip-bridge — bring out-of-band CNPs under GitOps** (CHARTER
  **Core Values** §"Everything as code; GitOps deploys it" + ADR-0004 §"never fabricate
  or hold safety-relevant state out-of-band"; issue #315 — 2026-07-01; **no
  prerequisites — executor may pick up immediately**). The
  `zz-dns-clusterip-bridge` CiliumNetworkPolicy (egress to `10.43.0.0/16`, the Service
  ClusterIP CIDR — required for any default-deny pod to reach a ClusterIP service before
  Cilium's socket-LB translates it to a backend pod IP) exists only as manually-applied
  live-cluster state in 15+ namespaces; `gitops/harbor/networkpolicy/` is the sole
  GitOps-managed copy (added as `allow-harbor-clusterip-egress.yaml` in the
  `auto/harbor-application` PR — this file is the canonical reference shape). Without
  it in GitOps, `make up` rebuilds silently break ClusterIP egress for every default-deny
  namespace; any new namespace added via the NP fan-out pattern also inherits the gap.
  Implementation (three sub-tasks):
  (a) **Shared template** — add
  `gitops/network/policies/zz-dns-clusterip-bridge.yaml` (a `CiliumNetworkPolicy`,
  `endpointSelector: {}`, `egress: toCIDR: 10.43.0.0/16` — no port restriction, because
  per-service pod-selector egress rules still gate which backends a pod may reach; this
  only permits the ClusterIP frontend to be evaluated before Cilium's socket-LB
  translates it). Copy the body verbatim from
  `gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml`, updating the inline
  comment to say "shared template" instead of harbor-specific; keep `metadata.name:
  zz-dns-clusterip-bridge` (matches the live out-of-band name).
  (b) **Per-overlay reference** — add the bridge template reference to every existing
  per-namespace kustomization overlay (top-level namespaces use
  `../../network/policies/zz-dns-clusterip-bridge.yaml`; `apps/*` namespaces use
  `../../../network/policies/zz-dns-clusterip-bridge.yaml`). Affected overlays (24
  total, listed by `gitops/*/networkpolicy/kustomization.yaml` and
  `gitops/apps/*/networkpolicy/kustomization.yaml` at executor pickup — excludes harbor,
  which already has `allow-harbor-clusterip-egress.yaml`; keep that harbor-specific file
  but ALSO add the shared template reference so it is adopted consistently). For the
  `gitops/argocd/networkpolicy/kustomization.yaml`, check if the existing
  `allow-argocd-service-frontends.yaml` already covers `10.43.0.0/16` without port
  restriction; if so, skip argocd to avoid a duplicate CNP; if it covers only specific
  ports, add the bridge. For namespaces with no workloads today (`lab-gateway`, `network`
  namespace overlay), still add the reference — the policy is a no-op when no pods exist
  and prevents the gap recurring when pods are eventually added.
  (c) **CI drift guard** — extend `tests/networkpolicy.bats` with a loop assertion: for
  every `kustomization.yaml` under `gitops/` that references `default-deny.yaml`, assert
  that the same `kustomization.yaml` also references `zz-dns-clusterip-bridge` (either
  the shared template or an equivalent per-namespace file). This prevents a new namespace
  being added via the NP fan-out pattern without the bridge — the same failure mode that
  caused #315 originally. Update `docs/dependency-tree.md` with a one-line note that
  `zz-dns-clusterip-bridge` is now a shared baseline template alongside `default-deny`
  and `allow-dns-and-apiserver`. `docs/done/` entry required. `make ci` must pass.
  **Executor note:** if the 24-file fan-out crosses ~400 lines per WAYS-OF-WORKING.md
  §3, ship the shared template + always-on namespace overlays in PR 1 and the on-demand
  namespace overlays (tidb, tidb-admin, inkless, longhorn, istio-system, artifactory,
  harbor) in PR 2. The CI drift guard must land with PR 1. Closes #315.
  (auto/gitops-clusterip-bridge)

- [ ] 🟢 **verifyImages ClusterPolicy — Audit → Enforce flip** (CHARTER **Objective O4**,
  RFC #214 Item 3; **only pick up after `auto/cosign-ci-sign-step` has merged AND the
  maintainer confirms at least one CI run pushed a `.sig` tag to Artifactory** — check
  `curl http://artifactory.127.0.0.1.nip.io:8000/artifactory/docker-local/hello/.sig`
  returns 200). Edit `gitops/kyverno/policies/verify-image-signatures.yaml`:
  `validationFailureAction: Audit` → `validationFailureAction: Enforce`;
  `failurePolicy: Ignore` → `failurePolicy: Fail`. Extend `tests/kyverno-policies.bats`
  (or `tests/kyverno.bats`) asserting `Enforce` and `Fail` values are present in the
  policy file. PR body must document the flip condition and the rollback path (revert
  both fields to `Audit` + `Ignore`, push → ArgoCD syncs within 30 s, no cluster
  downtime per RFC #214 §"Rollback path"). `make ci` must pass. **Executor note:** this
  item has a maintainer-confirmation prerequisite; skip to the next item if the condition
  cannot be verified this run. (auto/cosign-enforce-flip)

- [x] 🟢 **Lab — Grafana Alloy self-monitoring dashboard + self-scrape** (CHARTER
  **Objective O5**, due **2026-09-30**; O5 gap — `observability-alloy` is
  auto-synced in `gitops/bootstrap/root-app.yaml` but has no scrape job for
  its own metrics and no Grafana dashboard. The Alloy chart exposes metrics at
  port 12345 via the default `listenAddr`; the chart also creates a ClusterIP
  Service so a static scrape target is stable). Add `prometheus.scrape "alloy_self"`
  block to `gitops/platform/observability-alloy.yaml` (static target
  `alloy.observability.svc.cluster.local:12345`; `scrape_interval = "30s"`;
  mirrors the adjacent `external_secrets` / `kyverno` / `argo_rollouts` pattern).
  New `grafana/dashboards/lab-alloy.json` ("Lab — Grafana Alloy (Collector)")
  modelled on `lab-kyverno.json` stat-row: Alloy pod running (KSM
  `kube_deployment_status_replicas_available{namespace="observability",deployment=~"alloy.*"}`);
  ArgoCD sync state (`argocd_app_info{name="alloy"}`); active scrape targets
  (`prometheus_sd_discovered_targets{job="alloy"}`); samples ingested rate
  (`rate(prometheus_tsdb_head_samples_appended_total[5m]){job="alloy"}`);
  remote_write component health (`prometheus_remote_storage_sent_bytes_total{job="alloy"}`);
  Alloy component errors (`alloy_component_evaluation_seconds_sum` filtered by
  `namespace="observability"`). All panels real Mimir data with `X-Scope-OrgID: lab`
  (ADR-0004 — any panel whose metric has not yet emitted a series shows "No data"
  naturally). No HTTPRoute (Alloy has no web UI; port 12345 is metrics-only; `make
  lab-ui-check` unaffected). Extend `tests/observability.bats`: scrape block
  `"alloy_self"` exists in `observability-alloy.yaml`; `lab-alloy.json` exists;
  dashboard references `prometheus_sd_discovered_targets`; no fabricated data.
  Update `docs/dependency-tree.md` with Alloy self-scrape + dashboard note.
  `docs/done/` entry required. (auto/alloy-self-monitoring)

- [x] 🟢 **Lab — Kube State Metrics cluster-health dashboard** (CHARTER
  **Objective O5**, due **2026-09-30**; O5 gap — `observability-ksm` is
  auto-synced in `gitops/bootstrap/root-app.yaml` but has no Grafana dashboard.
  KSM metrics are already scraped via the `prometheus.scrape "ksm"` block in
  `gitops/platform/observability-alloy.yaml` — no new scrape job needed). New
  `grafana/dashboards/lab-ksm.json` ("Lab — Cluster Health (KSM)") providing a
  K8s resource state overview: pod phase distribution stat panels
  (`kube_pod_status_phase{phase=~"Running|Pending|Failed|Succeeded"}` across all
  namespaces); deployment replica health (sum of
  `kube_deployment_status_replicas_available` vs
  `kube_deployment_spec_replicas`); PersistentVolumeClaim phase
  (`kube_persistentvolumeclaim_status_phase` by namespace + claim); node
  readiness (`kube_node_status_condition{condition="Ready",status="true"}`);
  KSM self-health stat (`kube_state_metrics_build_info` version label +
  `kube_state_metrics_watch_total` by resource for watch health). Modelled on
  `lab-kyverno.json` stat-row: KSM pod running (KSM
  `kube_deployment_status_replicas_available{namespace="observability",deployment=~"ksm.*"}`);
  ArgoCD sync state. All panels real Mimir data (ADR-0004). No HTTPRoute. Extend
  `tests/observability.bats`: `lab-ksm.json` exists; dashboard references
  `kube_pod_status_phase`; references `kube_state_metrics_build_info`; no
  fabricated data. Update `docs/dependency-tree.md` with KSM dashboard note.
  `docs/done/` entry required. (auto/ksm-cluster-health-dashboard)

- [x] 🟢 **Lab — Node Exporter cluster-vitals dashboard** (CHARTER
  **Objective O5**, due **2026-09-30**; O5 gap — `observability-node-exporter`
  is auto-synced in `gitops/bootstrap/root-app.yaml` but has no Grafana
  dashboard. Node Exporter metrics are already scraped via the
  `prometheus.scrape "node_exporter"` block — no new scrape job needed). New
  `grafana/dashboards/lab-node-exporter.json` ("Lab — Node Vitals") showing
  host-level infrastructure metrics: CPU usage gauge
  (`1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))`); memory pressure
  gauge (`1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)`);
  disk usage per mount
  (`1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} /
  node_filesystem_size_bytes)` by device); network throughput timeseries
  (`rate(node_network_receive_bytes_total[5m])` +
  `rate(node_network_transmit_bytes_total[5m])` by interface, excluding
  `lo`); node uptime stat (`time() - node_boot_time_seconds`);
  node-exporter pod running (KSM); ArgoCD sync state. Modelled on
  `lab-kyverno.json` stat-row format. All panels real Mimir data (ADR-0004).
  No HTTPRoute. Extend `tests/observability.bats`: `lab-node-exporter.json`
  exists; dashboard references `node_cpu_seconds_total`; references
  `node_memory_MemAvailable_bytes`; no fabricated data. Update
  `docs/dependency-tree.md` with node-exporter dashboard note.
  `docs/done/` entry required. (auto/node-exporter-vitals-dashboard)

- [x] 🟢 **NetworkPolicy fan-out — `external-secrets` namespace** (CHARTER
  **Objective O2**, due **2026-09-30**; ADR-0016 §4 fan-out completion —
  the `external-secrets` namespace received PSA labels via `auto/pss-external-secrets`
  but has no default-deny NetworkPolicy overlay; it is the last always-on namespace
  without an ADR-0016 floor). Add
  `gitops/external-secrets/networkpolicy/kustomization.yaml` referencing the two
  baseline templates (`../../network/policies/default-deny.yaml`,
  `../../network/policies/allow-dns-and-apiserver.yaml`) plus two allow files:
  `allow-eso-metrics-ingress.yaml` (ingress TCP 8080 from `namespaceSelector:
  kubernetes.io/metadata.name: observability`; `podSelector: app.kubernetes.io/name:
  external-secrets`); `allow-eso-vault-egress.yaml` (egress TCP 8200 to
  `namespaceSelector: kubernetes.io/metadata.name: vault`; `podSelector:
  app.kubernetes.io/name: external-secrets` — ESO calls the Vault k8s auth endpoint
  to review tokens). Add an `external-secrets-networkpolicy` entry to the
  `networkpolicy-appset.yaml` list generator (`gitPath:
  gitops/external-secrets/networkpolicy`, `destNamespace: external-secrets`). Sync
  policy is `automated: {prune: true, selfHeal: true}` via the appset template.
  Extend `tests/networkpolicy.bats` with external-secrets overlay assertions:
  kustomization exists; baseline refs present; allow-metrics-ingress on port 8080
  present; allow-vault-egress on port 8200 present. Update `docs/dependency-tree.md`.
  `docs/done/` entry required. (auto/networkpolicy-external-secrets)

- [x] 🟢 **PSS-restricted + NetworkPolicy — `kro` namespace** (CHARTER
  **Objective O2**, due **2026-09-30**; O2 gap — the `kro` namespace hosts the KRO
  controller (auto-synced via `gitops/platform/kro.yaml`) but has neither PSA labels
  nor a NetworkPolicy overlay; ADR-0017 §"Per-namespace profile" has no `kro` row).
  Two changes bundled (both small): (a) PSA labels: add `gitops/kro/namespace.yaml`
  with all four PSA labels at `restricted` (`enforce: restricted`,
  `enforce-version: latest`, `warn: restricted`, `audit: restricted`); add new
  auto-synced `Application` `gitops/platform/kro-extras.yaml` (sync-wave 0,
  `ServerSideApply=true`, `CreateNamespace=false` — namespace pre-created by the
  existing `kro` Application; follows the `argocd-extras` / `kyverno-extras` naming
  convention); add `kro → restricted` row to ADR-0017 §"Per-namespace profile" table
  (the chart `kro.yaml` already carries hardened `podSecurityContext` +
  `containerSecurityContext`; `restricted` is safe). (b) NetworkPolicy: add
  `gitops/kro/networkpolicy/kustomization.yaml` referencing the two baseline templates
  plus `allow-kro-ack-egress.yaml` (egress to `ack-system` namespace — KRO reconciles
  ACK S3 Bucket CRs; no port restriction per the existing appset pattern). Add
  `kro-networkpolicy` entry to `networkpolicy-appset.yaml` (`gitPath:
  gitops/kro/networkpolicy`, `destNamespace: kro`). New
  `tests/securitycontext-kro.bats`: namespace PSA-label assertions; `enforce:
  restricted` present; `kro-extras` Application file exists. Extend
  `tests/networkpolicy.bats` with kro overlay assertions. `make ci` must pass.
  `docs/done/` entry required. (auto/pss-kro-namespace)

- [x] 🟢 **Lab — s3manager (S3 bucket browser) dashboard** (CHARTER **Objective O5**,
  due **2026-09-30**; O5 gap — `s3manager` is auto-synced in the always-on stack
  (`gitops/platform/s3manager.yaml`) but has no Grafana dashboard;
  `grafana/dashboards/lab-s3manager.json` is absent). New
  `grafana/dashboards/lab-s3manager.json` ("Lab — s3manager (S3 Browser)") modelled
  on `lab-kyverno.json` stat-row: s3manager pod running (KSM
  `kube_deployment_status_replicas_available{namespace="storage",deployment="s3manager"}`);
  ArgoCD sync state (`argocd_app_info{name="s3manager"}`); memory usage (cAdvisor
  `container_memory_working_set_bytes{namespace="storage",container="s3manager"}`);
  CPU usage rate (cAdvisor
  `rate(container_cpu_usage_seconds_total{namespace="storage",container="s3manager"}[5m])`).
  Note: `cloudlena/s3manager` does not expose Prometheus metrics; all panels use KSM +
  cAdvisor data already scraped by Alloy (ADR-0004 — real auto-discovered data only;
  any panel whose metric is not yet emitting a series naturally shows "No data"). No
  new HTTPRoute row needed — the `s3.127.0.0.1.nip.io:8000` row already exists in the
  "Lab UIs" panel; `make lab-ui-check` is unaffected. Extend `tests/observability.bats`:
  `lab-s3manager.json` exists; dashboard references
  `kube_deployment_status_replicas_available`; no fabricated/placeholder data. Update
  `docs/dependency-tree.md` with s3manager dashboard note. `docs/done/` entry required.
  (auto/s3manager-dashboard)

- [x] 🟢 **PSA baseline + NetworkPolicy — `lab-demo` namespace** (CHARTER **Objective
  O2**, due **2026-09-30**; O2 fan-out gap — the `lab-demo` namespace hosts the
  always-on HotROD demo Application (`gitops/platform/demo.yaml`, `automated:
  {prune: true, selfHeal: true}`) but has no PSA labels and no default-deny
  NetworkPolicy floor; it is absent from ADR-0017 §"Per-namespace profile". Three
  small changes bundled because each is tiny individually:
  (a) **PSA labels** — add `gitops/apps/demo/namespace.yaml` with all four PSA
  labels at `baseline` (`enforce: baseline`, `enforce-version: latest`, `warn:
  baseline`, `audit: baseline`). `restricted` is not yet viable —
  `jaegertracing/example-hotrod` runs as root (no `USER` instruction in the upstream
  Dockerfile); `baseline` blocks privileged containers and host-namespace use while
  permitting the root UID. Document the flip condition to `restricted` in ADR-0017's
  `lab-demo` row: when the image ships a non-root UID or is superseded by the
  capstone build.
  (b) **NetworkPolicy** — add
  `gitops/apps/demo/networkpolicy/kustomization.yaml` referencing the two shared
  baseline templates (`../../network/policies/default-deny.yaml`,
  `../../network/policies/allow-dns-and-apiserver.yaml`) plus one allow file:
  `allow-demo-egress-tempo.yaml` (egress TCP 4318 to `namespaceSelector:
  kubernetes.io/metadata.name: observability` — HotROD sends OTLP traces to
  `tempo.observability.svc.cluster.local:4318` continuously; the observability
  NetworkPolicy already has the matching ingress allow in
  `allow-tempo-ingress-otlp.yaml`). No ingress allow needed — `lab-demo` has no
  HTTPRoute (the HotROD Service is not exposed via Envoy Gateway).
  (c) **appset entry** — add `lab-demo-networkpolicy` entry to the
  `networkpolicy-appset.yaml` list generator (`gitPath:
  gitops/apps/demo/networkpolicy`, `destNamespace: lab-demo`). Sync policy is
  `automated: {prune: true, selfHeal: true}` via the appset template — same as all
  other ADR-0016 floor Applications.
  Add `lab-demo → baseline` row to ADR-0017 §"Per-namespace profile" table, citing
  the upstream root-UID constraint and the flip condition. New
  `tests/networkpolicy-lab-demo.bats`: kustomization exists; baseline refs present;
  `allow-demo-egress-tempo.yaml` exists targeting TCP 4318 to `observability`. New
  `tests/securitycontext-lab-demo.bats`: `gitops/apps/demo/namespace.yaml` exists;
  `enforce: baseline` present; `enforce: restricted` absent (safety check). Update
  `docs/dependency-tree.md` with `lab-demo` PSA + NP note. `docs/done/` entry
  required. `make ci` must pass. (auto/pss-np-lab-demo)

- [x] 🟢 **PSA baseline + NetworkPolicy — `inkless` namespace** (CHARTER **Objective O2**,
  due **2026-09-30**; RFC #257 — architect decision 2026-06-23; closes O2 fan-out for the
  last on-demand namespace missing PSA labels and a NetworkPolicy floor). Two changes
  bundled (both small, same shape as `auto/pss-np-lab-demo`): (a) **PSA labels** — add
  `gitops/inkless/namespace.yaml` with all four PSA labels at `baseline` (`enforce:
  baseline`, `enforce-version: latest`, `warn: baseline`, `audit: baseline`). The Aiven
  Inkless broker (`ghcr.io/aiven/inkless:latest`) runs as root UID 0 (no USER directive
  in the base image); `baseline` is the correct profile. Add new auto-synced `Application`
  `gitops/platform/inkless-extras.yaml` (sync-wave 0, `ServerSideApply=true`,
  `CreateNamespace=false` — namespace pre-created by `make inkless-up`; follows the
  `argocd-extras` / `kyverno-extras` naming convention). Add `inkless → baseline` row to
  ADR-0017 §"Per-namespace profile" table citing RFC #257; document flip condition to
  `restricted` (when `ghcr.io/aiven/inkless` ships with explicit non-root USER directive).
  (b) **NetworkPolicy** — add
  `gitops/inkless/networkpolicy/kustomization.yaml` referencing the two shared baseline
  templates (`../../network/policies/default-deny.yaml`,
  `../../network/policies/allow-dns-and-apiserver.yaml`) plus three allow files:
  `allow-inkless-intra-namespace.yaml` (ingress+egress `podSelector: {}` within the
  `inkless` namespace — covers broker↔postgres JDBC on TCP 5432, kafka-load→broker on TCP
  9092, KRaft internal TCP 19092/29090); `allow-inkless-garage-egress.yaml` (egress TCP
  3900 to `namespaceSelector: kubernetes.io/metadata.name: storage` — inkless broker
  streams topic segments to Garage S3 per ADR-0002); `allow-inkless-metrics-ingress.yaml`
  (ingress TCP 9308 from `namespaceSelector: kubernetes.io/metadata.name: observability`
  — Alloy kafka-exporter scrape already wired in `observability-alloy.yaml`). Add
  `inkless-networkpolicy` entry to `networkpolicy-appset.yaml` list generator (`gitPath:
  gitops/inkless/networkpolicy`, `destNamespace: inkless`); sync policy is `automated:
  {prune: true, selfHeal: true}` via the appset template (same as tidb pattern — NP is
  cheap; in place before `make inkless-up` brings pods up). Extend
  `tests/securitycontext.bats`: `gitops/inkless/namespace.yaml` exists; `enforce:
  baseline` present; `enforce: restricted` absent (safety check). Extend
  `tests/networkpolicy.bats`: kustomization exists; baseline refs present; each allow file
  exists targeting the documented port + selector; appset entry `inkless-networkpolicy`
  present. `docs/done/` entry required. `make ci` must pass. (auto/pss-np-inkless)

- [x] 🟢 **Lab — `demo` + `data-demo` dashboards (O5 completion)** (CHARTER **Objective O5**,
  due **2026-09-30**; O5 gap — `demo` (HotROD in `lab-demo` namespace) and `data-demo`
  (data-layer traffic generators in `data` namespace) are the last two auto-synced
  always-on Applications without a `grafana/dashboards/lab-<name>.json`, leaving O5
  incomplete before its 2026-09-30 deadline. Two small dashboards bundled (same
  KSM/cAdvisor stat-row pattern — no new scrape jobs needed; Alloy already scrapes
  KSM and cAdvisor):
  (a) New `grafana/dashboards/lab-demo.json` ("Lab — demo (HotROD)") modelled on
  `lab-kyverno.json` stat-row: demo pod running (KSM
  `kube_deployment_status_replicas_available{namespace="lab-demo",deployment="hello"}`);
  ArgoCD sync state (`argocd_app_info{name="demo"}`); memory usage (cAdvisor
  `container_memory_working_set_bytes{namespace="lab-demo",container="hello"}`); CPU
  usage rate (cAdvisor
  `rate(container_cpu_usage_seconds_total{namespace="lab-demo",container="hello"}[5m])`).
  Note: `jaegertracing/example-hotrod` does not expose Prometheus metrics; span/trace
  data is visible in `lab-traces.json` (Tempo). Document this in the dashboard's
  about-text panel (ADR-0004 — no fabricated data; any panel not yet emitting shows
  "No data" naturally). No HTTPRoute row in the Lab UIs panel (HotROD is not exposed
  via Envoy Gateway); `make lab-ui-check` unaffected.
  (b) New `grafana/dashboards/lab-data-demo.json` ("Lab — data-demo (Traffic
  Generators)") modelled on the same stat-row: rabbitmq-load pod running (KSM
  `kube_deployment_status_replicas_available{namespace="data",deployment="rabbitmq-load"}`);
  valkey-load pod running
  (`kube_deployment_status_replicas_available{namespace="data",deployment="valkey-load"}`);
  ArgoCD sync state (`argocd_app_info{name="data-demo"}`); memory for rabbitmq-load
  (cAdvisor
  `container_memory_working_set_bytes{namespace="data",container="rabbitmq-load"}`).
  Note: these workloads exist to drive real traffic into RabbitMQ and Valkey so those
  dashboards show non-zero metrics; document this in the about-text panel. No HTTPRoute.
  Extend `tests/observability.bats` with four assertions: `lab-demo.json` exists;
  references `kube_deployment_status_replicas_available` with `namespace="lab-demo"`;
  no fabricated/placeholder data; `lab-data-demo.json` exists; references
  `kube_deployment_status_replicas_available` with `deployment="rabbitmq-load"` in
  namespace `data`; no fabricated/placeholder data. Update `docs/dependency-tree.md`
  with brief `demo` and `data-demo` dashboard notes. `docs/done/` entry required.
  `make ci` must pass. **Executor note:** if the PR crosses ~400 lines per
  WAYS-OF-WORKING.md §3, ship `lab-demo.json` first and file `lab-data-demo.json` as
  a follow-up. (auto/demo-data-demo-dashboards)

- [x] 🟢 **`docs/00-architecture.md` — current-state rewrite** (CHARTER **Core Values**
  §"Docs & dashboards don't drift"; docs-only). The file is 70 lines and was written when
  the platform had ~8 components; it now runs ~28 ArgoCD Applications across four
  categories (always-on core, LGTMP observability, Tier 1 next-wave, on-demand heavy)
  and the doc mentions none of the new components. Rewrite `docs/00-architecture.md` to
  reflect the current platform state:
  (a) **Updated tool table** — expand the "Who does what" table to cover the full
  always-on stack: Cilium (CNI), External Secrets Operator, Garage (S3), s3manager,
  RabbitMQ, Valkey, Alloy, Mimir, Loki, Tempo, Pyroscope, Grafana, kube-state-metrics,
  node-exporter, moto, ACK S3, KRO, Kyverno, Argo Rollouts, Velero, Trivy Operator, and
  the capstone pipeline (cosign → verifyImages → progressive canary). Describe each
  tool's role in one line. Group rows by layer (matching the README table structure so
  they stay in sync).
  (b) **Updated learning path** — the current five-step path ends with "Tie it together"
  via GitLab CI; expand to cover the full CHARTER Goals: supply-chain security
  (cosign → Kyverno verifyImages), progressive delivery (Argo Rollouts canary on Mimir
  SLOs), stateful backup/restore (Velero → `make dr-restore`), and continuous scanning
  (Trivy Operator). The existing steps 0–5 can stay; add steps 6–9 or rewrite them.
  (c) **Updated diagram** — either expand the ASCII diagram or replace it with a prose
  description of the platform's current data-flow layers: bootstrap → GitOps → ingress
  → workloads → secrets → observability → security (admission + supply-chain) → backup.
  No new CI gates; no new code. All assertions about what's deployed must reflect what's
  actually in `gitops/` (ADR-0004 — no fabricated state). `make ci` must pass.
  `docs/done/` entry required. (auto/architecture-doc-rewrite)

- [x] 🟢 **ADR-0017 `velero` PSA row correction + `docs/dependency-tree.md` stale
  notes** (CHARTER **Core Values** §"Docs & dashboards don't drift"; docs-only, two
  small corrections bundled because both are tiny). (a) **ADR-0017 velero row**: the
  per-namespace profile table currently says `velero → baseline`, but the actual
  `gitops/velero/namespace.yaml` enforces `restricted` and `tests/velero.bats` asserts
  `enforce: restricted`. The implementation uses a per-workload annotation on the
  node-agent DaemonSet for the `hostPath` carve-out (matching the node-exporter pattern
  in ADR-0017 §"Per-workload field carve-outs"), making the `restricted` profile viable.
  Update the ADR-0017 table: `velero | restricted | Controller runs non-root (UID
  65534); node-agent DaemonSet uses a per-workload annotation to mount
  `/var/lib/kubelet/pods` for Kopia FS-backup (matches the node-exporter hostPath
  carve-out pattern in §"Per-workload field carve-outs"). Per ADR-0021 §"PSA profile"
  (implementation adopted restricted, overriding the initial baseline estimate).`
  (b) **dependency-tree.md stale notes**: fix two stale references — (1) the capstone
  subgraph label `"Capstone — build pipeline (steps 1–4 done; step 5 pending)"` should
  read `"Capstone — build pipeline (all 5 steps done)"` (step 5 shipped in
  `auto/capstone-step-5`, see `docs/done/auto-capstone-step-5.md`); (2) the argocd
  PSS Phase 1 note says `"Phase 2 (separate ROADMAP item, pending …)"` but Phase 2
  shipped in `auto/argocd-pss-enforce` (see `docs/done/`). Remove or update that
  parenthetical. No code changes. `make ci` must pass. `docs/done/` entry required.
  (auto/adr0017-velero-row-depTree-fix)

- [x] 🟢 **PSS `privileged` labels + NetworkPolicy — `longhorn-system`** (CHARTER
  **Objective O2**, due **2026-09-30**; O2 fan-out completion — ADR-0017
  §"Per-namespace profile" already lists `longhorn-system → privileged` (longhorn-manager
  and longhorn-csi-plugin require `SYS_ADMIN`, mount propagation, host `/dev`; per
  ADR-0013) but no `gitops/longhorn/namespace.yaml` with PSA labels exists yet. Two
  changes bundled: (a) **PSA labels** — add `gitops/longhorn/namespace.yaml` with all
  four PSA labels at `privileged` (`enforce: privileged`, `enforce-version: latest`,
  `warn: privileged`, `audit: privileged`); add new auto-synced `Application`
  `gitops/platform/longhorn-extras.yaml` (sync-wave 0, `ServerSideApply=true`,
  `CreateNamespace=true` — an empty `longhorn-system` namespace with privileged labels
  before `make longhorn-up` is harmless; follows the `kargo-extras` / `argocd-extras`
  naming convention). (b) **NetworkPolicy** — add
  `gitops/longhorn/networkpolicy/kustomization.yaml` referencing the two shared baseline
  templates plus allow files: `allow-longhorn-intra-namespace.yaml` (intra-namespace
  `podSelector: {}` — longhorn-manager ↔ longhorn-engine + csi-plugin communication);
  `allow-longhorn-metrics-ingress.yaml` (ingress TCP 9500 from `observability` — Longhorn
  exposes Prometheus metrics at `:9500/metrics`); egress to kube-apiserver via baseline.
  Add `longhorn-networkpolicy` entry to `networkpolicy-appset.yaml` list generator
  (`gitPath: gitops/longhorn/networkpolicy`, `destNamespace: longhorn-system`); sync
  policy `automated: {prune: true, selfHeal: true}` via the appset template — same
  on-demand NP pattern as `tidb-networkpolicy` (NP floor is in place before
  `make longhorn-up` brings pods up). New `tests/securitycontext-longhorn.bats`:
  `gitops/longhorn/namespace.yaml` exists; `enforce: privileged` present; `enforce:
  restricted` absent (safety check). Extend `tests/networkpolicy.bats` with longhorn
  overlay assertions (kustomization exists, baseline refs present, metrics-ingress on TCP
  9500, appset entry `longhorn-networkpolicy` present). Update `docs/dependency-tree.md`
  with a Longhorn PSS + NP note. `docs/done/` entry required. `make ci` must pass.
  (auto/pss-np-longhorn)

- [x] 🟢 **PSS `privileged` labels + NetworkPolicy — `istio-system`** (CHARTER
  **Objective O2**, due **2026-09-30**; O2 fan-out completion — ADR-0017
  §"Per-namespace profile" already lists `istio-system → privileged` (istio-cni DaemonSet
  mutates host CNI config; ztunnel requires `NET_ADMIN`; per ADR-0012) but no
  `gitops/istio-system/namespace.yaml` exists. The istiod, istio-base, ztunnel, and
  istio-cni Applications (all on-demand via `make istio-up`) deploy into this namespace.
  Two changes bundled: (a) **PSA labels** — create `gitops/istio-system/namespace.yaml`
  with all four PSA labels at `privileged` (`enforce: privileged`, `enforce-version:
  latest`, `warn: privileged`, `audit: privileged`); add new auto-synced `Application`
  `gitops/platform/istio-system-extras.yaml` (sync-wave 0, `ServerSideApply=true`,
  `CreateNamespace=true` — harmless empty namespace before `make istio-up`; follows the
  `kargo-extras` / `argocd-extras` naming convention). Confirm the ADR-0017
  `istio-system → privileged` row cites ADR-0012 §"PSA profile" (add citation if
  absent). (b) **NetworkPolicy** — add
  `gitops/istio-system/networkpolicy/kustomization.yaml` referencing the two shared
  baseline templates plus allow files: `allow-istio-intra-namespace.yaml`
  (intra-namespace `podSelector: {}` — istiod control-plane internal traffic);
  `allow-istio-metrics-ingress.yaml` (ingress TCP 15014 from `observability` — istiod
  Prometheus scrape port); egress to kube-apiserver via baseline. Add
  `istio-system-networkpolicy` entry to `networkpolicy-appset.yaml` (`gitPath:
  gitops/istio-system/networkpolicy`, `destNamespace: istio-system`); sync policy
  `automated: {prune: true, selfHeal: true}`. New `tests/securitycontext-istio.bats`:
  `gitops/istio-system/namespace.yaml` exists; `enforce: privileged` present;
  `enforce: restricted` absent. Extend `tests/networkpolicy.bats` with istio-system
  overlay assertions. Update `docs/dependency-tree.md` with istio-system PSS + NP note.
  `docs/done/` entry required. `make ci` must pass. (auto/pss-np-istio-system)

- [x] 🟢 **ADR-0017 amendment — add `kargo` namespace row** (CHARTER **Objective O2**,
  due **2026-09-30**; docs-only O2 gap — surfaced 2026-06-27 planner run). The
  `kargo` namespace already carries `restricted` PSA labels in
  `gitops/kargo/namespace.yaml` (Kargo api/controller/webhooks-server all run as
  UID 65532, `restricted`-compatible) and a full default-deny NetworkPolicy overlay
  in `gitops/kargo/networkpolicy/`, but the namespace is **absent** from ADR-0017
  §"Per-namespace profile" — the table records every other PSA-labelled namespace
  except kargo. Two changes bundled (both tiny): (a) **ADR-0017 table row** — add
  `kargo → restricted | Kargo api/controller/webhooks-server all run as UID 65532
  (non-root); no host volumes, no special capabilities. Per ROADMAP
  auto/pss-kro-namespace pattern.` to the per-namespace profile table, placed after
  the `kro → restricted` row (same non-root controller pattern, share the citation
  convention). (b) **New `tests/securitycontext-kargo.bats`** — per-scope file
  (NOT the frozen monolith per `scripts/securitycontext-tests-check.sh`): assert
  `gitops/kargo/namespace.yaml` exists; `enforce: restricted` present;
  `enforce: baseline` and `enforce: privileged` absent (safety checks);
  `gitops/platform/kargo-extras.yaml` exists and its `syncPolicy` includes
  `automated:` (auto-synced). No Makefile change, no new Application — the
  `kargo-extras` Application already exists and is already auto-synced. Update
  `docs/dependency-tree.md` with a kargo PSS note (parallel to the kro PSS note
  added in `auto/pss-kro-namespace`). `docs/done/` entry required. `make ci` must
  pass. (auto/adr-0017-kargo-row)

- [x] 🟢 **PSA `baseline` labels + NetworkPolicy — `artifactory` namespace** (CHARTER
  **Objective O2**, due **2026-09-30**; RFC #287 — architect decision 2026-06-27). O2
  fan-out completion for the on-demand Artifactory namespace. Two changes bundled:
  (a) **PSA labels** — add `gitops/artifactory/namespace.yaml` with all four PSA labels
  at `baseline` (`enforce: baseline`, `enforce-version: latest`, `warn: baseline`,
  `audit: baseline`). JVM init containers run as root UID 0 for `chown`; main JVM
  process runs as UID 1030; `restricted` is not viable without upstream chart changes
  (`jfrog/artifactory-oss`); `baseline` blocks privileged containers and host namespaces
  while permitting the init root UID. Update `gitops/platform/artifactory-extras.yaml`:
  add `automated: {prune: true, selfHeal: true}` to `syncPolicy` + `argocd.argoproj.io/sync-wave:
  "0"` annotation (mirrors `longhorn-extras` / `istio-system-extras` — pre-creates the
  namespace with PSA floor before `make artifactory-up` admits pods). (b) **NetworkPolicy** —
  add `gitops/artifactory/networkpolicy/kustomization.yaml` referencing the two shared
  baseline templates (`../../network/policies/default-deny.yaml`,
  `../../network/policies/allow-dns-and-apiserver.yaml`) plus
  `allow-artifactory-ingress.yaml` (ingress TCP 8082 from `namespaceSelector:
  kubernetes.io/metadata.name: envoy-gateway-system` — Envoy HTTPRoute proxies to the
  `artifactory-oss` Service on port 8082 per `gitops/artifactory/route.yaml`) and
  `allow-artifactory-garage-egress.yaml` (egress TCP 3900 to `namespaceSelector:
  kubernetes.io/metadata.name: storage` — Garage S3 binary store per ADR-0002). Add
  `artifactory-networkpolicy` entry to `gitops/platform/networkpolicy-appset.yaml`
  (`gitPath: gitops/artifactory/networkpolicy`, `destNamespace: artifactory`); sync
  policy is `automated: {prune: true, selfHeal: true}` via the appset template. Add
  `artifactory → baseline` row to ADR-0017 §"Per-namespace profile" table with RFC
  citation and flip condition (when upstream `jfrog/artifactory-oss` chart documents
  `restricted`-compatible initContainers). New `tests/securitycontext-artifactory.bats`:
  `gitops/artifactory/namespace.yaml` exists; `enforce: baseline` present; `enforce:
  restricted` absent (safety check); `artifactory-extras` Application has `automated:`
  block (auto-sync present). New `tests/networkpolicy-artifactory.bats`: kustomization
  exists; baseline templates referenced; `allow-artifactory-ingress.yaml` exists
  targeting TCP 8082 from `envoy-gateway-system`; `allow-artifactory-garage-egress.yaml`
  exists targeting TCP 3900 to `storage`; appset entry `artifactory-networkpolicy`
  present. `make ci` must pass. `docs/done/` entry required. (auto/pss-np-artifactory)

- [x] 🟢 **NetworkPolicy extensions — Kiali allows in `istio-system`** (CHARTER
  **Objective O2**, due **2026-09-30**; RFC #288 — architect decision 2026-06-27;
  dependency **already met**: `auto/pss-np-istio-system` (PR #285) is merged in main —
  `gitops/istio-system/networkpolicy/` and the `istio-system-networkpolicy` appset entry
  are confirmed present). Kiali co-resides in `istio-system` (no separate namespace per
  RFC #288); its PSA profile is already covered by `istio-system → privileged` (PR #285).
  This item adds two Kiali-specific per-pod NetworkPolicy allows to the existing overlay.
  Add `gitops/istio-system/networkpolicy/allow-kiali-ingress.yaml` — ingress TCP 20001
  from `namespaceSelector: kubernetes.io/metadata.name: envoy-gateway-system`; `podSelector:
  app.kubernetes.io/name: kiali` (Envoy HTTPRoute `kiali.127.0.0.1.nip.io` per
  `gitops/kiali/route.yaml`). Add
  `gitops/istio-system/networkpolicy/allow-kiali-observability-egress.yaml` — egress TCP
  9009 to `namespaceSelector: kubernetes.io/metadata.name: observability`; `podSelector:
  app.kubernetes.io/name: kiali` (Kiali queries Mimir Prometheus at port 9009 per
  `gitops/platform/kiali.yaml` `valuesObject.external_services.prometheus.url`). Update
  `gitops/istio-system/networkpolicy/kustomization.yaml` to reference both new allow
  files. Update ADR-0017 `istio-system → privileged` row to add parenthetical: "(Kiali
  co-resides in this namespace; no separate `kiali` row needed.)". No new ArgoCD
  Application or appset entry needed — the `istio-system-networkpolicy` appset entry from
  PR #285 covers the full overlay directory (auto-synced via the appset template).
  Extend `tests/networkpolicy-istio-system.bats`: `allow-kiali-ingress.yaml` exists and
  targets TCP 20001 from `envoy-gateway-system`; `allow-kiali-observability-egress.yaml`
  exists and targets TCP 9009 to `observability`; both are referenced in
  `kustomization.yaml`. `make ci` must pass. `docs/done/` entry required.
  (auto/kiali-np-istio-system)

- [ ] 🟢 **O4 CI gate — `verify-image-rejection` job in GitLab CI** (CHARTER **Objective
  O4**, due **2026-12-31**; RFC #289 — architect decision 2026-06-27; **pick up ONLY after
  `auto/cosign-enforce-flip` merges** — check `grep -q "validationFailureAction: Enforce"
  gitops/kyverno/policies/verify-image-signatures.yaml` returns 0 before starting). Add
  `verify-rejection` to `stages:` list in `.gitlab-ci.yml` (after `sign`). New
  `verify-image-rejection` job: `image: docker:24` + `docker:24-dind` service with
  `--insecure-registry=artifactory.127.0.0.1.nip.io`; `before_script` logs in to
  Artifactory + exports `KUBECONFIG` (GitLab CI File variable, same pattern as `COSIGN_KEY`
  — add comment documenting masked, protected, type File requirement) + installs `kubectl`
  via `apk`; `script` pulls `busybox:1.37.0`, retags to
  `$REGISTRY/docker-local/test-unsigned:rejection-test`, pushes unsigned (no cosign sign
  step), runs `kubectl run test-rejection-pod --image=... --restart=Never -n capstone`,
  asserts Kyverno blocks admission (grep output for
  `denied|policy|verify|signature|admission webhook` keywords); `after_script` deletes
  the Pod + docker logout; `needs: [sign-image]`; `rules: if: $CI_COMMIT_BRANCH == "main"`.
  New `tests/gitlab-ci.bats` (clusterless structural): `verify-rejection` appears in
  `stages:` list; job references `test-unsigned:rejection-test`; `needs: [sign-image]`
  present; `after_script` has `kubectl delete` cleanup; `KUBECONFIG` comment present.
  `make ci` must pass. `docs/done/` entry required. **CI change is RFC #289-approved per
  WAYS-OF-WORKING.md §2.** (auto/o4-ci-rejection-gate)

- [x] 🟢 **Platform Governance appset — `gitops/governance/` structure +
  ApplicationSet** (CHARTER **Core Values** §"Everything as code; GitOps deploys
  it", RFC #293 — architect decision 2026-06-28). Add
  `gitops/platform/governance-appset.yaml` (ApplicationSet with list-generator,
  sync-wave annotation `"3"` on the ApplicationSet metadata; generated Applications
  at sync-wave `"4"` via template annotation; auto-synced via template syncPolicy;
  follows the existing `networkpolicy-appset.yaml` pattern). Each namespace that
  needs governance objects gets a leaf directory `gitops/governance/<namespace>/`
  containing `kustomization.yaml` + `limitrange.yaml`. Seed two entries to
  demonstrate the pattern (`argocd` and `capstone` from the RFC #294 standard-tier
  list). Each `kustomization.yaml` lists `resources: [limitrange.yaml]`; each
  `limitrange.yaml` is a `standard`-tier LimitRange (`type: Container`;
  `default.cpu: "500m"`, `default.memory: "512Mi"`; `defaultRequest.cpu: "50m"`,
  `defaultRequest.memory: "64Mi"`; `max.cpu: "2000m"`, `max.memory: "4Gi"`).
  Kyverno ClusterPolicies stay in `gitops/kyverno/policies/` — do NOT move them.
  Update `docs/dependency-tree.md` with a governance layer note (parallel to the
  networkpolicy-appset notes). New `tests/governance.bats`: governance-appset file
  exists; is an ApplicationSet; has list-generator; has auto-sync template; the two
  seed namespace dirs exist each with `kustomization.yaml` and `limitrange.yaml`.
  `make ci` must pass. `docs/done/` entry required. Closes #293.
  (auto/platform-governance-appset)

- [x] 🟢 **Namespace Resource Profiles — LimitRange defaults fan-out**
  (CHARTER **Core Values** §"Fits the 16 GB reality", RFC #294 — architect
  decision 2026-06-28; **prerequisite: `auto/platform-governance-appset` merges
  first**). Extend `gitops/platform/governance-appset.yaml` list with all namespace
  entries from the RFC #294 mapping table. Add
  `gitops/governance/<namespace>/limitrange.yaml` for every `standard`-tier
  namespace: `argocd`, `capstone`, `kyverno`, `external-secrets`, `velero`,
  `argo-rollouts`, `trivy-system`, `moto`, `ack-system`, `kro`, `kargo`,
  `lab-demo`, `data`, `storage`, `vault`, `lab-gateway`, `artifactory`, `kiali`.
  Add `gitops/governance/observability/limitrange.yaml` with the `heavy` profile:
  `default.cpu: "2000m"`, `default.memory: "2Gi"`; `defaultRequest.cpu: "100m"`,
  `defaultRequest.memory: "128Mi"`; `max.cpu: "4000m"`, `max.memory: "8Gi"`.
  Excluded namespaces (no LimitRange — document in PR body): `kube-system`,
  `kube-public`, `kube-node-lease` (cluster-managed); `tidb`, `longhorn-system`,
  `istio-system`, `inkless` (on-demand heavy — too variable for static defaults).
  Extend `tests/governance.bats`: each namespace's `limitrange.yaml` exists; each
  has `type: Container`; `defaultRequest.cpu: "50m"` present for standard-tier;
  `default.memory: "2Gi"` present for `observability` (heavy tier). Update
  `docs/dependency-tree.md` with a one-line note that all always-on namespaces
  have LimitRange defaults. `make ci` must pass. `docs/done/` entry required.
  Closes #294. (auto/namespace-resource-profiles)

- [x] 🟢 **Harbor on-demand Application + namespace + Envoy route**
  (CHARTER **Core Values** §"Everything as code; GitOps deploys it" +
  **Objective O1**, RFC #297 /
  [ADR-0024](docs/decisions/adr-0024-harbor-not-artifactory.md) — architect
  decision 2026-06-30; **Yellow work — new chart source + namespace — is
  pre-approved by the superseding ADR per WAYS-OF-WORKING.md §2**). First slice
  of the Artifactory→Harbor migration. Add `gitops/platform/harbor.yaml`: a
  **non-auto-synced** ArgoCD `Application` (NO `automated:` block — mirror
  `gitops/platform/artifactory.yaml`), chart `harbor` from
  `https://helm.goharbor.io` (pin a specific chart version at executor pickup —
  current line is chart v1.16.x / appVersion v2.12.x), namespace `harbor`.
  `valuesObject` **minimal profile** per ADR-0024 §"Minimal profile":
  `trivy.enabled: false` (cluster scanning is Trivy Operator, ADR-0022),
  `notary.enabled: false`, `expose.type: clusterIP` + `expose.tls.enabled:
  false` (Envoy HTTPRoute fronts ingress, ADR-0008 — disable the chart's own
  ingress), `externalURL: http://harbor.127.0.0.1.nip.io:8000`,
  `persistence.imageChartStorage.type: s3` with the registry bucket pointed at
  **Garage S3** (ADR-0002 — `regionendpoint` the in-cluster Garage Service in
  `storage`; credentials via the existing Vault→ESO pattern, never inline),
  `redis.type: external` pointed at the platform **Valkey** (ADR-0018, `data`
  ns) where the chart allows; bundled internal Postgres is acceptable for the
  first cut. Set modest `resources` requests/limits per enabled component
  (core/registry/jobservice/portal). Add `gitops/platform/harbor-extras.yaml`
  (auto-synced, sync-wave 0 — mirror `artifactory-extras.yaml`) sourcing
  `gitops/harbor` so the namespace PSA floor + HTTPRoute exist before
  `make harbor-up`. Add `gitops/harbor/namespace.yaml` with PSA **`restricted`**
  + `enforce-version: latest` per ADR-0017/ADR-0024 (Harbor is Go/non-root →
  target restricted, advancing the hardening track); fall back to `baseline`
  only with a documented justification + flip condition (mirror the
  `artifactory` namespace comment style) if a chart component genuinely cannot
  render restricted-compatible even with `securityContext` overrides. Add
  `gitops/harbor/route.yaml`: an Envoy `HTTPRoute` `harbor.127.0.0.1.nip.io`
  (ADR-0008, parentRef `eg`/`lab-gateway`) backendRef'ing the Harbor
  portal/core Service + port (mirror `gitops/artifactory/route.yaml`). Wire the
  new UI into the Grafana "Lab UIs" panel (`grafana/dashboards/stack-health.json`)
  so `make lab-ui-check` stays green. New `tests/harbor.bats`: Application has
  **no** `automated:` block (on-demand); chart `harbor` from `helm.goharbor.io`
  with a pinned version; `trivy.enabled: false` + `notary.enabled: false`;
  storage type `s3`; namespace PSA labels present; route host
  `harbor.127.0.0.1.nip.io`. `make ci` must pass. `docs/done/` entry required.
  **Executor note:** if the PR crosses ~400 lines (WAYS-OF-WORKING.md §3), ship
  the Application + extras + namespace in PR 1 and the route + Lab-UIs wiring +
  bats as the next item. (auto/harbor-application)

- [x] 🟢 **Harbor NetworkPolicy floor + appset entry** (CHARTER **Core
  Values**, RFC #297 / ADR-0024 — architect decision 2026-06-30; **NP fan-out
  pre-approved by ADR-0024 per WAYS-OF-WORKING.md §2**; **prerequisite:
  `auto/harbor-application` merges first**). Mirror the artifactory NP overlay
  (ADR-0016 §4 fan-out). Add `gitops/harbor/networkpolicy/kustomization.yaml`
  (`namespace: harbor`) referencing the shared
  `../../network/policies/default-deny.yaml` +
  `../../network/policies/allow-dns-and-apiserver.yaml`, plus:
  `allow-harbor-ingress.yaml` (ingress from `envoy-gateway-system` to the Harbor
  core/portal/registry ports), `allow-harbor-garage-egress.yaml` (egress TCP
  3900 to the `storage` Garage S3 backend), and an egress allow to the platform
  **Valkey** in `data` (Harbor's external Redis) — plus internal DB egress as
  the chosen profile requires. Add a `harbor-networkpolicy` entry to
  `gitops/platform/networkpolicy-appset.yaml` (auto-synced, wave 4 — mirror the
  `artifactory-networkpolicy` entry: `appName: harbor-networkpolicy`,
  `gitPath: gitops/harbor/networkpolicy`, `destNamespace: harbor`). Do **not**
  remove the `artifactory-networkpolicy` entry yet (decommission item). Extend
  `tests/harbor.bats`: NP overlay references default-deny + allow-dns-and-apiserver
  + ingress-from-envoy + egress-to-storage; appset has the `harbor-networkpolicy`
  entry. `make ci` must pass. `docs/done/` entry required.
  (auto/harbor-networkpolicy)

- [x] 🟢 **`make harbor-up` / `harbor-down` targets** (CHARTER **Core Values**
  §"Everything as code", RFC #297 / ADR-0024 — architect decision 2026-06-30;
  **Makefile change pre-approved by ADR-0024 per WAYS-OF-WORKING.md §2**;
  **prerequisite: `auto/harbor-application` merges first**). Add `make harbor-up`
  (`$(call argocd-sync,harbor)` then `$(call argocd-sync,harbor-extras)`) and
  `make harbor-down` (`$(call argocd-delete,harbor-extras)` then
  `$(call argocd-delete,harbor)`) — mirror the existing
  `artifactory-up`/`artifactory-down` targets exactly; keep the help text honest
  (Harbor minimal profile, on-demand). Do **not** remove the
  `artifactory-up/down` targets yet (decommission item). Extend
  `tests/harbor.bats` (clusterless, structural): `harbor-up` and `harbor-down`
  `.PHONY` targets present and each references both `harbor` and `harbor-extras`.
  `make ci` must pass. `docs/done/` entry required. (auto/harbor-make-targets)

- [x] 🟢 **ADR-0017 amendment — `harbor` PSA row** (RFC #297 / ADR-0024 —
  architect decision 2026-06-30; **prerequisite: `auto/harbor-application`
  merges first** so the chosen profile is known). Add a `harbor` row to
  ADR-0017's per-namespace profile table recording the profile the `harbor`
  namespace actually carries (`restricted` if the chart rendered non-root, else
  `baseline` with the documented justification + flip condition copied from the
  namespace manifest). Pure docs. `make ci` must pass. `docs/done/` entry
  required. (auto/harbor-pss-adr0017-row)

- [x] 🟢 **Lab — Harbor OCI registry dashboard + observability metrics** (CHARTER
  **Core Values** §"Real observability only"; ADR-0024 §observability; follows
  the on-demand dashboard precedent from `lab-inkless.json`;
  **prerequisite: `auto/harbor-application` merged ✓**). Harbor exposes
  Prometheus metrics via its built-in exporter. Enable metrics by patching
  `gitops/platform/harbor.yaml` `valuesObject` with `metrics.enabled: true`
  (creates a `harbor-metrics` Service; executor must verify the exact port
  at pickup — chart v1.16.x uses port 9090 on the `harbor-metrics` Service by
  default, but check `kubectl get svc harbor-metrics -n harbor` or the chart
  source). Add `allow-harbor-metrics-ingress.yaml` to
  `gitops/harbor/networkpolicy/kustomization.yaml` (ingress TCP from
  `namespaceSelector: kubernetes.io/metadata.name: observability` on the
  verified metrics port; mirrors the existing `allow-trivy-metrics-from-observability`
  NP pattern). Add `prometheus.scrape "harbor"` block to
  `gitops/platform/observability-alloy.yaml` (static target
  `harbor-metrics.harbor.svc.cluster.local:<port>` where `<port>` is the
  verified metrics port; `scrape_interval = "30s"`; mirrors the adjacent
  `inkless` / `trivy_operator` scrape pattern). New
  `grafana/dashboards/lab-harbor.json` ("Lab — Harbor (OCI Registry)") modelled
  on `lab-kyverno.json` stat-row: harbor-core pod running (KSM
  `kube_deployment_status_replicas_available{namespace="harbor",deployment=~"harbor-core.*"}`);
  ArgoCD sync state (`argocd_app_info{name="harbor-extras"}`); image artifact
  total (`harbor_artifact_total` by project); image push/pull counts
  (`harbor_artifact_total{operation=~"push|pull"}`). All panels real Mimir data
  with `X-Scope-OrgID: lab` (ADR-0004 — panels not yet emitting series show
  "No data" naturally; Harbor is on-demand). No new HTTPRoute row needed —
  `harbor.127.0.0.1.nip.io` row already exists; `make lab-ui-check`
  unaffected. Extend `tests/harbor.bats`: scrape block `"harbor"` present in
  `observability-alloy.yaml`; `lab-harbor.json` exists; dashboard references
  `harbor_artifact_total`; no fabricated data. Update
  `docs/dependency-tree.md` with Harbor observability note. `docs/done/`
  entry required. `make ci` must pass. (auto/harbor-observability-dashboard)

- [x] 🟢 **Lab — Kargo promotion-pipeline dashboard + observability metrics**
  (CHARTER **Core Values** §"Real observability only"; ADR-0023; follows the
  on-demand dashboard precedent from `lab-inkless.json`). Kargo api, controller,
  and webhooks-server expose controller-runtime Prometheus metrics (default port
  8080 per chart v1.2.0; executor must verify the actual port by checking the
  `kargo-api` and `kargo-controller` Services before finalizing). The kargo
  NetworkPolicy currently has no observability ingress allow. Add
  `allow-kargo-metrics-ingress.yaml` to
  `gitops/kargo/networkpolicy/kustomization.yaml` (ingress TCP 8080 from
  `namespaceSelector: kubernetes.io/metadata.name: observability`; `podSelector:
  {}` covers all kargo pods; mirrors the existing kyverno/trivy NP allow
  pattern). Add `prometheus.scrape "kargo"` block to
  `gitops/platform/observability-alloy.yaml` (static target
  `kargo-api.kargo.svc.cluster.local:8080`; `scrape_interval = "30s"`; mirrors
  the adjacent `velero` / `argo_rollouts` scrape pattern). New
  `grafana/dashboards/lab-kargo.json` ("Lab — Kargo (GitOps Promotion)") modelled
  on `lab-kyverno.json` stat-row: kargo-api pod running (KSM
  `kube_deployment_status_replicas_available{namespace="kargo",deployment=~"kargo-api.*"}`);
  ArgoCD sync state (`argocd_app_info{name="kargo-extras"}`); Stage promotion
  count timeseries (`controller_runtime_reconcile_total{controller=~"stage.*"}`);
  Freight creation rate (`controller_runtime_reconcile_total{controller=~"freight.*"}`);
  Warehouse reconcile count (`controller_runtime_reconcile_total{controller=~"warehouse.*"}`).
  All panels real Mimir data with `X-Scope-OrgID: lab` (ADR-0004 — panels not
  yet emitting series show "No data" naturally; Kargo is on-demand). No HTTPRoute
  row needed (Kargo UI at `kargo.127.0.0.1.nip.io` row already exists in the Lab
  UIs panel); `make lab-ui-check` unaffected. Extend `tests/kargo.bats`: scrape
  block `"kargo"` present in `observability-alloy.yaml`; `lab-kargo.json` exists;
  dashboard references `controller_runtime_reconcile_total`; no fabricated data.
  Update `docs/dependency-tree.md` with Kargo observability note. `docs/done/`
  entry required. `make ci` must pass. (auto/kargo-observability-dashboard)

- [ ] 🟢 **Capstone pipeline re-wire — Artifactory → Harbor registry host**
  (CHARTER **Objective O4** + capstone RFC #62, RFC #297 / ADR-0024 — architect
  decision 2026-06-30; **CI / security-adjacent changes pre-approved by ADR-0024
  per WAYS-OF-WORKING.md §2**; **maintainer-confirmation prerequisite: pick up
  ONLY after the maintainer confirms on #297 that the minimal Harbor profile was
  measured on the live cluster and fits the 12 GB budget on-demand — the
  ADR-0024 go/no-go gate; skip to the next item if it cannot be verified this
  run**). Cut the capstone image flow over from `artifactory.127.0.0.1.nip.io`
  to `harbor.127.0.0.1.nip.io`: `.gitlab-ci.yml` (registry host + login),
  `gitops/secrets/artifactory-registry-externalsecret.yaml` → a `harbor-registry`
  ExternalSecret (Vault path), `gitops/kargo-project/project.yaml`,
  `gitops/apps/capstone/rollout.yaml` + `deployment.yaml` (image refs),
  `gitops/kyverno/policies/verify-image-signatures.yaml` (verifyImages scope
  `artifactory.127.0.0.1.nip.io/**` → `harbor.127.0.0.1.nip.io/**` — independent
  of the separate Audit→Enforce flip item, coordinate if both are open),
  `gitops/kargo/networkpolicy/allow-kargo-egress-registry.yaml`, and the README /
  `docs/dependency-tree.md` references. Update the relevant bats (capstone /
  kargo / kyverno) for the new host. `make ci` must pass. `docs/done/` entry
  required. **Executor note:** if this crosses ~400 lines, split the
  CI/secret/registry-credential cutover from the GitOps app/image-ref cutover.
  (auto/harbor-capstone-rewire)

- [ ] 🟢 **Decommission Artifactory manifests** (RFC #297 / ADR-0024 — architect
  decision 2026-06-30; **maintainer-confirmation prerequisite: pick up ONLY
  after `auto/harbor-capstone-rewire` merges AND the maintainer has confirmed the
  Harbor footprint gate on #297; skip if not verifiable this run**). Remove
  `gitops/platform/artifactory.yaml`, `gitops/platform/artifactory-extras.yaml`,
  the entire `gitops/artifactory/` tree (namespace, route, networkpolicy), the
  `make artifactory-up`/`artifactory-down` targets, the `artifactory-networkpolicy`
  entry in `gitops/platform/networkpolicy-appset.yaml`, the `artifactory` row in
  ADR-0017's profile table, the `artifactory` LimitRange entry in the governance
  appset / `gitops/governance/`, the artifactory nodes/edges in
  `docs/dependency-tree.md`, the now-superseded
  `gitops/secrets/artifactory-registry-externalsecret.yaml`, and the artifactory
  rows in README. Add a recurrence guard — extend `tests/harbor.bats` (or a
  dedicated `tests/no-artifactory.bats`) asserting no `artifactory` ArgoCD
  Application / route / make-target / appset entry remains (a
  `grep -r artifactory gitops/ Makefile` guard allowing only historical
  `docs/done/` + ADR-0011/0024 mentions). `make ci` must pass. `docs/done/` entry
  required. **Closes #297** — the migration's final slice; close the issue once
  this lands and the footprint gate is on record.
  (auto/harbor-artifactory-decommission)

- [ ] 🟢 **Harbor governance LimitRange** (CHARTER **Core Values** §"Fits the
  16 GB reality" + §"Everything as code; GitOps deploys it"; RFC #294 /
  RFC #297 — follow-up; **no prerequisites — executor may pick up
  immediately**). The `gitops/platform/governance-appset.yaml` already
  carries an explicit TODO comment: "A harbor governance overlay is added
  once its namespace lands." The harbor namespace landed in
  `auto/harbor-application` (checked off above). Close that gap now:
  add `gitops/governance/harbor/kustomization.yaml` (listing
  `resources: [limitrange.yaml]`) and
  `gitops/governance/harbor/limitrange.yaml` using the **standard** tier
  profile from RFC #294 (`type: Container`; `default.cpu: "500m"`,
  `default.memory: "512Mi"`; `defaultRequest.cpu: "50m"`,
  `defaultRequest.memory: "64Mi"`; `max.cpu: "2000m"`,
  `max.memory: "4Gi"`) — same values as every other standard-tier
  namespace (argocd, capstone, kyverno, etc.). Add the
  `harbor-governance` entry to the list-generator in
  `gitops/platform/governance-appset.yaml`:
  `appName: harbor-governance`, `gitPath: gitops/governance/harbor`,
  `destNamespace: harbor` (insert after the `kiali-governance` entry,
  before the `# heavy tier` comment, consistent with the existing
  ordering). Extend `tests/governance.bats` with two assertions:
  `gitops/governance/harbor/limitrange.yaml` exists; the `harbor`
  entry appears in `gitops/platform/governance-appset.yaml`.
  Update `docs/dependency-tree.md` with a one-line note that the
  `harbor` namespace now has a LimitRange. `make ci` must pass.
  `docs/done/` entry required. (auto/harbor-governance-limitrange)

- [x] 🟢 **O5 dashboard-coverage bats — always-on service apps** (CHARTER
  **Objective O5**, due **2026-09-30**; O5 says "measured by a drift
  check wired into make ci" but the current CI only checks HTTPRoute ↔
  panel sync via `lab-ui-check.sh` — it does NOT verify that each
  always-on service app has a `lab-<name>.json` file. This item adds
  the O5 measurement mechanism as bats assertions; no Makefile change
  needed — bats already runs in `scripts/test.sh` which is in
  `make ci`). Add to `tests/observability.bats` (or a new
  `tests/dashboard-coverage.bats`) one `@test` block per always-on
  service application verifying its `grafana/dashboards/lab-<name>.json`
  exists and contains at least one reference to `"uid": "mimir"` (a
  real Mimir datasource panel, not a stub — ADR-0004). Cover these
  apps (18 total): `argo-rollouts` → `lab-argo-rollouts.json`;
  `capstone` → `lab-capstone.json`; `data-demo` → `lab-data-demo.json`;
  `demo` → `lab-demo.json`; `envoy-gateway` → `lab-envoy.json`;
  `external-secrets` → `lab-external-secrets.json`; `garage` →
  `lab-garage.json`; `kro` + `moto` + `ack-s3` → `lab-cloud-control-plane.json`;
  `kyverno` → `lab-kyverno.json`; `observability-alloy` → `lab-alloy.json`;
  `observability-grafana` → `lab-grafana.json`; `observability-ksm` →
  `lab-ksm.json`; `observability-loki` → `lab-logs.json`;
  `observability-mimir` → `lab-mimir.json`;
  `observability-node-exporter` → `lab-node-exporter.json`;
  `observability-pyroscope` → `lab-profiles.json`;
  `observability-tempo` → `lab-traces.json`; `rabbitmq` →
  `lab-rabbitmq.json`; `s3manager` → `lab-s3manager.json`;
  `trivy-operator` → `lab-trivy.json`; `valkey` → `lab-valkey.json`;
  `vault` → `lab-vault.json`; `velero` → `lab-velero.json`. Each test
  only checks file existence + mimir uid presence — no panel-count
  assertions (those are in the per-dashboard tests already). Note: the
  multi-app shared dashboard (`lab-cloud-control-plane.json`) is tested
  once, citing all three apps it covers. **Executor note:** if this
  pushes `tests/observability.bats` past reasonable size, split into a
  new `tests/dashboard-coverage.bats`; the existing per-dashboard bats
  tests stay where they are. `make ci` must pass. `docs/done/` entry
  required. (auto/o5-dashboard-coverage-bats)

- [ ] 🟢 **NetworkPolicy bats fan-out — Tier-1 wave overlays** (CHARTER
  **Objective O2**, due **2026-09-30**; O2 gap — four Tier-1 next-wave
  namespaces have NetworkPolicy overlays but lack dedicated
  `tests/networkpolicy-<ns>.bats` files; their NP assertions are
  currently embedded in the component bats files
  (`tests/kyverno.bats`, `tests/argo-rollouts.bats`,
  `tests/velero.bats`, `tests/trivy-operator.bats`); O2's
  measurement criterion says "tests/networkpolicy.bats +
  per-scope files cover every namespace in gitops/" — the
  per-scope files should exist for every namespace with an overlay,
  mirroring the established pattern from all other namespace bats.
  Wait for PR #324 (`auto/gitops-clusterip-bridge`) to merge first —
  it adds the path variables `KYVERNO_NP`, `ARGO_ROLLOUTS_NP`,
  `VELERO_NP`, `TRIVY_NP` to `tests/lib/networkpolicy-paths.bash`
  that these new bats files will `load lib/networkpolicy-paths` to
  use). Create four new files: `tests/networkpolicy-kyverno.bats`,
  `tests/networkpolicy-argo-rollouts.bats`,
  `tests/networkpolicy-velero.bats`,
  `tests/networkpolicy-trivy-system.bats` — each structured as a
  per-scope bats file (mirrors `tests/networkpolicy-kro.bats` as the
  template; `load lib/networkpolicy-paths`; section header; assertions
  for: overlay `kustomization.yaml` exists; references
  `default-deny.yaml`; references `allow-dns-and-apiserver.yaml`;
  references the `zz-dns-clusterip-bridge` template (post-PR-#324 the
  shared template is the baseline); references each namespace's
  specific allow files by name). For each file's specific allow
  assertions, use the actual files present in the overlay at executor
  pickup (e.g. for kyverno: `allow-kyverno-webhook-from-apiserver.yaml`
  TCP 9443 from apiserver ipBlock, `allow-kyverno-metrics-from-observability.yaml`
  TCP 8000; for argo-rollouts: the dashboard-from-gateway, metrics,
  mimir-egress, plugin-egress allows; for velero: garage-egress,
  metrics-ingress, kopia-egress allows; for trivy-system:
  ghcr-egress, metrics-ingress allows). These tests are additive
  — they do NOT remove the existing NP checks from the component
  bats files; they exist for O2 measurement completeness.
  `make ci` must pass. `docs/done/` entry required.
  (auto/networkpolicy-tier1-bats)

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
> the 🟡 items without an RFC still need an architect RFC before the executor builds
> them. Items that received RFCs (#205, #206) have been groomed into 🟢 items in
> *Now / next* above (planner 2026-06-15); RFCs #214 + #215 groomed 2026-06-16
> (four new 🟢 items — three from RFC #214, one from RFC #215); RFCs #229 + #230
> groomed 2026-06-20 (two new 🟢 PSS items — `restricted` for `external-secrets`,
> `baseline` for `envoy-gateway-system`). Two new 🟢 docs-only items groomed
> 2026-06-25 (architecture doc rewrite + ADR-0017/dependency-tree corrections). The
> 🟢 cloud-control-plane dashboard item that previously lived here has been promoted
> to *Now / next* above (CHARTER **O5** carrier).
>
> **O4 gap (surfaced 2026-06-25):** CHARTER O4 is measured by "a CI step that
> pushes an unsigned image and asserts Kyverno rejection." This step does not exist
> yet. It depends on the verifyImages flip to Enforce (the unchecked item above) AND
> needs an architect RFC to define the exact GitLab CI job shape, unsigned-image
> source, and rejection assertion method before the executor can build it.

- ~~🟡 **PSS-restricted hardening — `argocd` namespace**~~ (RFC #205)
  **Groomed ↗** into two 🟢 Phase items in *Now / next* above
  (`auto/argocd-pss-warn-audit` + `auto/argocd-pss-enforce`),
  planner run 2026-06-15.

- ~~🟡 **NetworkPolicy fan-out — `envoy-gateway-system` namespace**~~
  (RFC #206) **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/envoy-gateway-system-networkpolicy`), planner run 2026-06-15.

- [ ] 🟡 **ADR-0017 audit — vault PSA-restricted after Vault v2.0.2
  upgrade** (issue #157 — resolved as **keep** on 2026-06-11; see
  ADR-0017 §"Re-evaluation log"). The audit determined: keep
  `vault: baseline` until a real, pinnable chart/image that no longer
  holds `cap_ipc_lock` is available. The flip condition is documented
  in the ADR. **No RFC or 🟢 executor item is needed now.** This
  ROADMAP entry is a reminder: when the Vault Helm chart ships an image
  that drops `cap_ipc_lock`, open a new `adr-audit` issue to trigger
  the Convert path (bump chart + `disable_mlock = true` + flip labels
  baseline → restricted + ADR-0017 row update). Until then, the
  executor skips this item.

- ~~🟡 **O4 completion — cosign signing in GitLab CI + verifyImages Enforce flip**~~
  (RFC #214) **Groomed ↗** into three 🟢 items in *Now / next* above
  (`auto/cosign-make-up-wiring` + `auto/cosign-ci-sign-step` +
  `auto/cosign-enforce-flip`), planner run 2026-06-16.

- ~~🟡 **O6 — make capstone-demo wall-clock target**~~ (RFC #215) **Groomed ↗**
  into one 🟢 item in *Now / next* above (`auto/capstone-demo-target`),
  planner run 2026-06-16.

- ~~🟡 **PSS hardening — `external-secrets` namespace**~~ (RFC #229)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/pss-external-secrets`), planner run 2026-06-20.

- ~~🟡 **PSS hardening — `envoy-gateway-system` namespace**~~ (RFC #230)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/pss-envoy-gateway-system`), planner run 2026-06-20.

- ~~🟡 **O4 completion gate — CI rejection test for unsigned images**~~
  (RFC #289) **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/o4-ci-rejection-gate`), planner run 2026-06-28. Item carries the
  `cosign-enforce-flip` prerequisite — executor skips until that item merges.

- ~~🟡 **PSS profile decision + NetworkPolicy spec — `artifactory` namespace**~~
  (RFC #287) **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/pss-np-artifactory`), planner run 2026-06-28. Decision: `baseline` profile;
  NP allows TCP 8082 ingress from `envoy-gateway-system` + TCP 3900 egress to `storage`.

- ~~🟡 **PSS profile decision + NetworkPolicy spec — `kiali` namespace**~~
  (RFC #288) **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/kiali-np-istio-system`), planner run 2026-06-28. Resolved: Kiali co-resides
  in `istio-system` (no separate namespace); item extends the istio-system NP overlay
  with two per-pod allows (TCP 20001 ingress from `envoy-gateway-system`, TCP 9009
  egress to `observability`).

- ~~🟡 **Platform Governance layer — `gitops/governance/` structure**~~ (RFC #293)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/platform-governance-appset`), planner run 2026-06-30.

- ~~🟡 **Namespace Resource Profiles — standardized ResourceQuota tiers**~~ (RFC #294)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/namespace-resource-profiles`), planner run 2026-06-30.

_New 🟡 items proposed by the architect live in
[`docs/roadmap/incoming/`](docs/roadmap/incoming/) — one file per run — until
the planner absorbs them here. Do **not** append new 🟡 items directly to this
section; concurrent arch + plan PRs both appending here is what causes merge
conflicts._

Per-run grooming notes (which 🟡 items got RFCs, which were groomed into 🟢,
which ADRs landed) live in [`docs/backlog/`](docs/backlog/) — one Markdown file
per run, named `YYYY-MM-DD-<slug>.md`. Do **not** append run narrative to this
section; each PR writing its own file is what keeps concurrent PRs conflict-free.
<!-- Autonomous runs: new 🟡 items → docs/roadmap/incoming/YYYY-MM-DD-arch-<slug>.md (NOT inline here). Grooming notes → docs/backlog/YYYY-MM-DD-<slug>.md. The planner absorbs incoming/ into ROADMAP.md on its next run. -->


---

## Done

Completed items live in [`docs/done/`](docs/done/) — one Markdown file per delivery,
named `YYYY-MM-DD-<slug>.md` for new entries (or `<slug>.md` for legacy pre-migration entries).
<!-- Autonomous runs: create docs/done/YYYY-MM-DD-<slug>.md — do NOT prepend entries here. -->
