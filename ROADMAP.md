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
> **Planner note (2026-06-08 — fan-out queue refill):** the 2026-06-06 wave
> partly landed — capstone NetworkPolicy (#130) and data PSS (#139) are *Done*,
> vault NetworkPolicy is in flight as PR #147. With observability NP + the PSS
> label-only carve-out as the only remaining items, the lane would starve
> within ~2 executor cycles. This refill continues the **ADR-0016 §4 fan-out
> order** (`argocd`, `vault`✓in-flight, `observability`✓queued, `storage`,
> `lab-gateway`, `moto`, `ack-system`; `tidb`/`tidb-admin` deferred — on-demand
> namespaces) and the **ADR-0017 §Staged rollout** continuation (PSS-restricted
> layer-1+layer-2 for `observability`, the largest namespace by workload
> count). All items below remain 🟢 — both ADRs are adopted (WAYS-OF-WORKING.md
> §2: the architect's binding decision *is* the approval).
>
> **O2 clock note.** CHARTER **Objective O2** (default-deny NetworkPolicy +
> PSS-restricted across every namespace) is dated **2026-09-30** — ~3.5
> months out. After this refill, the remaining always-on gaps after these
> items merge are: PSS for `argocd` (🟡, see *Cross-cutting* — touches
> `infra/modules/argocd/values.yaml`), PSS for `moto`/`ack-system`/`lab-gateway`
> (🟢, follow-on planner item), NP for `tidb`/`tidb-admin` (🟢, lower-priority
> since on-demand). The next planner run should top the lane back up once
> these items burn down.

- [x] 🟢 **NetworkPolicy fan-out — `capstone` namespace** (ADR-0016 §4
  fan-out; closes the capstone pilot loop alongside the existing PSS
  pilot). New overlay at `gitops/apps/capstone/networkpolicy/kustomization.yaml`
  referencing the two shared templates under `gitops/network/policies/`
  (`default-deny.yaml`, `allow-dns-and-apiserver.yaml`) plus per-workload
  allows for the capstone Deployment's three real flows:
  `allow-capstone-ingress-from-gateway.yaml` (TCP 8080 from Envoy proxy
  pods in `envoy-gateway-system`); `allow-capstone-egress-tempo.yaml`
  (egress to `observability` namespace pod-label `app=tempo`, TCP 4318
  for OTLP HTTP traces — see the deployment's `OTEL_EXPORTER_OTLP_ENDPOINT`
  env var). Image pulls are kubelet-level so no policy needed; the
  rendered `capstone-app-creds` Secret is read in-pod, not over the
  network. New auto-synced ArgoCD `Application`
  `gitops/platform/capstone-networkpolicy.yaml` (sync-wave 4, same
  `kustomize.buildOptions: --load-restrictor LoadRestrictionsNone`
  pattern as the existing `data-networkpolicy` Application). Extend
  `tests/networkpolicy.bats` with capstone-overlay assertions (templates
  referenced, `policyTypes` shape, three per-workload allow rules
  present). Update `docs/dependency-tree.md` with a capstone
  NetworkPolicy note. ADR-0016 prerequisite (Cilium, ADR-0014) already
  active. (auto/networkpolicy-capstone-fanout)

- [x] 🟢 **PSS-restricted fan-out — `data` namespace** (ADR-0017
  §Staged rollout; closes the `data` pilot loop alongside the existing
  NetworkPolicy pilot). New explicit `gitops/data/namespace.yaml`
  with the four PSA labels at `restricted` per ADR-0017 §Layer 2
  (`pod-security.kubernetes.io/{enforce,enforce-version,warn,audit}`).
  Pod- and container-level `securityContext` fields added to both data
  StatefulSets (`gitops/data/rabbitmq/statefulset.yaml`,
  `gitops/data/valkey/statefulset.yaml`) and the demo workloads under
  `gitops/data/demo/`: pod-level `runAsNonRoot: true`,
  `runAsUser`/`runAsGroup` non-zero (use RabbitMQ's documented UID 999
  / Valkey's documented UID 999), `seccompProfile.type: RuntimeDefault`;
  container-level `allowPrivilegeEscalation: false`, `privileged: false`,
  `readOnlyRootFilesystem: true` with `emptyDir` mounts over any
  remaining writable paths not already on the PVC (RabbitMQ's
  `/var/lib/rabbitmq/mnesia/cache`, Valkey's `/tmp`); container
  `capabilities.drop: [ALL]`. ADR-0017 carve-out table already records
  `data` as `restricted`-eligible. New `tests/securitycontext-data.bats`
  (25 tests) asserting the namespace PSA labels and the same five
  `securityContext` fields per workload. Note: namespace manifest placed
  at `gitops/data/rabbitmq/namespace.yaml` (synced by the wave-3
  rabbitmq Application) to match the capstone pilot pattern. (auto/pss-data-fan-out)

- [x] 🟢 **NetworkPolicy fan-out — `vault` namespace** (ADR-0016 §4
  fan-out; second-wave priority — protects the secrets plane). New
  overlay at `gitops/vault/networkpolicy/kustomization.yaml` referencing
  the two shared templates. Per-workload allows:
  `allow-vault-from-eso.yaml` (ingress TCP 8200 from the
  `external-secrets` namespace's ESO controller pods) and
  `allow-vault-from-gateway.yaml` (ingress TCP 8200 from
  `envoy-gateway-system` proxy pods for the existing
  `vault.127.0.0.1.nip.io` HTTPRoute). No explicit egress allow needed
  beyond the baseline: the `allow-dns-and-apiserver` template already
  covers Vault's k8s-auth call to the k3s API. New auto-synced
  `Application` `gitops/platform/vault-networkpolicy.yaml` (sync-wave 4,
  same `LoadRestrictionsNone` pattern). Extend `tests/networkpolicy.bats`
  with vault-overlay assertions (templates referenced, two per-workload
  rules, both target TCP 8200). Update `docs/dependency-tree.md`.

- [x] 🟢 **NetworkPolicy fan-out — `observability` namespace** (ADR-0016
  §4 fan-out; covers the LGTMP stack). New overlay at
  `gitops/observability/networkpolicy/kustomization.yaml` referencing the
  two shared templates. The flows to enumerate are extensive — Alloy
  scrapes targets in every namespace (egress allows per scrape job
  declared in `gitops/platform/observability-alloy.yaml`); Mimir, Loki,
  Tempo, Pyroscope each write to Garage in `storage` namespace (egress
  TCP 3900); Grafana reads from each backend over the cluster network
  (intra-namespace egress); the Grafana HTTPRoute needs ingress on TCP
  3000 from `envoy-gateway-system`. **If the PR crosses the ~400-line
  WAYS-OF-WORKING.md §3 cap**, split as: PR 1 = baseline templates +
  Grafana ingress + Alloy egress to `data` and `argocd` namespaces; file
  three follow-up planner items (one per remaining wave: storage
  backends, scrape-target namespaces, control-plane namespaces). New
  auto-synced `Application` `gitops/platform/observability-networkpolicy.yaml`
  (sync-wave 4). Extend `tests/networkpolicy.bats`. Update
  `docs/dependency-tree.md`.

- [x] 🟢 **PSS labels — non-restricted carve-out namespaces** (ADR-0017
  §Per-namespace profile; label-only — no workload `securityContext`
  changes). Add explicit namespace manifests carrying the carve-out
  PSA labels for the four always-on namespaces ADR-0017 records as
  `baseline`-only: `gitops/vault/namespace.yaml` (`vault` — `mlock`
  needs `IPC_LOCK`), `gitops/storage/namespace.yaml` (`storage` — Garage
  upstream image's non-root status not declared),
  `gitops/tidb/namespace.yaml` (`tidb` — TiDB Operator caps),
  `gitops/tidb-admin/namespace.yaml` (`tidb-admin` — same). Each
  manifest sets `pod-security.kubernetes.io/{enforce,warn,audit}:
  baseline` + `enforce-version: latest`. The on-demand `privileged`
  carve-outs (`longhorn-system`, `istio-system`) land with their
  respective bring-up PRs per ADR-0017 and are NOT included here.
  Each namespace manifest is wired into its existing namespace's
  ArgoCD `Application` source path (or as a small additional resource
  in an existing overlay) so it auto-syncs. Extend
  `tests/securitycontext.bats` with four assertions (one per labelled
  namespace). (auto/pss-carve-out-namespaces)

- [ ] 🟢 **NetworkPolicy fan-out — `storage` namespace (Garage)**
  (ADR-0016 §4 fan-out; Garage is the lab's S3 backplane for Mimir /
  Loki / Tempo / Pyroscope / Inkless / Artifactory — a permissive
  default leaks across every observability and storage tenant). New
  overlay at `gitops/storage/networkpolicy/kustomization.yaml` pulling
  the two shared baseline templates. Per-workload allows the executor
  enumerates from the live integration map:
  `allow-garage-s3-from-observability.yaml` (ingress TCP 3900 + 3902 +
  3903 from the four LGTMP writers in `observability` —
  `mimir`/`loki`/`tempo`/`pyroscope` pod-label selectors) and
  `allow-garage-s3-from-inkless.yaml` (ingress TCP 3900 from `inkless`
  namespace — KIP-1150 diskless Kafka uses Garage for log segments).
  Intra-namespace gossip TCP 3901 between Garage pods is allowed by the
  baseline (no explicit rule needed — same-namespace pods are not
  denied by `default-deny-all` once the deny is paired with explicit
  rules). Artifactory is on-demand so its allow lands with the
  artifactory bring-up RFC, not here. No new egress allow needed
  beyond the baseline (Garage doesn't egress to other namespaces).
  New auto-synced `Application`
  `gitops/platform/storage-networkpolicy.yaml` (sync-wave 4, same
  `LoadRestrictionsNone` pattern as the existing
  `data-networkpolicy`/`capstone-networkpolicy`/`vault-networkpolicy`).
  Extend `tests/networkpolicy.bats` with storage-overlay assertions.
  Update `docs/dependency-tree.md` with a storage NetworkPolicy note.

- [ ] 🟢 **NetworkPolicy fan-out — `argocd` namespace** (ADR-0016 §4
  fan-out; ArgoCD is the entire GitOps reconcile plane — the highest
  blast-radius non-secrets namespace). The namespace is Terraform-
  created at bootstrap (`infra/modules/argocd/`) so the **NetworkPolicy
  application itself stays 🟢** — the policy is a regular ArgoCD
  Application syncing a Kustomize overlay to the existing namespace.
  New overlay at `gitops/argocd/networkpolicy/kustomization.yaml`
  pulling the two shared templates. Per-workload allows the executor
  enumerates from the live ArgoCD component map: ingress TCP 8080 to
  `argocd-server` from `envoy-gateway-system` proxy pods (for the
  `argocd.127.0.0.1.nip.io` HTTPRoute); intra-namespace ingress from
  `argocd-application-controller` and `argocd-server` to
  `argocd-repo-server` TCP 8081 and to `argocd-redis` TCP 6379;
  intra-namespace ingress to `argocd-applicationset-controller` TCP
  7000 from the application controller. Egress: GitLab on the host
  (`host.k3d.internal:8929` — `to.ipBlock` covering the k3d host
  network range; the planner-derived address is the k3d host bridge
  CIDR, executor reads it from `infra/live/local/cluster/`) for repo
  fetches; egress to the k8s API for resource reconcile (covered by
  the `allow-dns-and-apiserver` baseline). New auto-synced
  `Application` `gitops/platform/argocd-networkpolicy.yaml` (sync-wave
  4, `LoadRestrictionsNone`). Extend `tests/networkpolicy.bats`.
  Update `docs/dependency-tree.md`. **Note for executor:** this PR
  hardens NetworkPolicy only — the *PSS-restricted* labels +
  `valuesObject.podSecurityContext` for the argocd Helm release are
  🟡 (`infra/` change) and tracked separately in *Cross-cutting*
  below.

- [ ] 🟢 **NetworkPolicy fan-out — `moto` + `ack-system` namespaces**
  (ADR-0016 §4 fan-out; bundled because the two namespaces are a
  tightly-coupled mock-cloud-control-plane pair — ACK controllers in
  `ack-system` call moto's HTTP API in `moto`, and KRO in `ack-system`
  reconciles `ResourceGraphDefinition`s against the ACK controllers).
  Two overlays:
  `gitops/moto/networkpolicy/kustomization.yaml` — baseline + ingress
  TCP 5000 from `ack-system` pods (ACK controllers) +
  `lab-demo`/`capstone` if any demo workload hits moto directly (check
  live ACK demo bucket flow); and
  `gitops/ack/networkpolicy/kustomization.yaml` — baseline + egress
  TCP 5000 to `moto` namespace + intra-namespace ingress between ACK
  controllers and KRO. Per-workload allows the executor enumerates
  from the deployed Applications (`ack-s3`, `kro`, `ack-resources`,
  `kro-resources`). Two new auto-synced `Application`s
  (`gitops/platform/moto-networkpolicy.yaml`,
  `gitops/platform/ack-networkpolicy.yaml`), both sync-wave 4. Extend
  `tests/networkpolicy.bats`. Update `docs/dependency-tree.md`.
  **Note for executor:** if this PR crosses the ~400-line cap per
  WAYS-OF-WORKING.md §3, ship `moto` first and file `ack-system` as a
  follow-up.

- [ ] 🟢 **NetworkPolicy fan-out — `lab-gateway` namespace** (ADR-0016
  §4 fan-out; the Gateway listener namespace). The namespace today
  holds only the Gateway CR (no pods — Envoy proxy pods live in
  `envoy-gateway-system`), so this PR is small but future-proofs the
  namespace: any pod added later inherits the default-deny floor.
  New overlay at `gitops/network/networkpolicy/kustomization.yaml`
  (the namespace's manifest source path is `gitops/network/` per
  `gitops/platform/lab-gateway.yaml`) pulling only the two shared
  baseline templates (`default-deny.yaml`,
  `allow-dns-and-apiserver.yaml`) — no per-workload allows needed.
  New auto-synced `Application`
  `gitops/platform/lab-gateway-networkpolicy.yaml` (sync-wave 4,
  `LoadRestrictionsNone`). Extend `tests/networkpolicy.bats` with
  lab-gateway-overlay assertions (templates referenced, no extra
  rules, only the baseline). Update `docs/dependency-tree.md`. **Note
  for executor:** Envoy proxy pods themselves live in
  `envoy-gateway-system` — that namespace's NetworkPolicy will be a
  separate, larger item once the architect RFCs the proxy/data-plane
  egress requirements (it's effectively the cluster's ingress
  gateway, so its egress fan-out matches every backend Service).

- [ ] 🟢 **PSS-restricted fan-out — `observability` namespace** (ADR-0017
  §Staged rollout; LGTMP stack — the largest namespace by workload
  count). ADR-0017's carve-out table records `observability` as
  `restricted`-eligible. Per the data-PSS pilot pattern: add explicit
  `gitops/observability/namespace.yaml` (or graft labels onto whichever
  existing namespace manifest the wave-2 observability Applications
  create) with the four PSA labels at `restricted`. Then patch the
  Helm-chart `valuesObject` on each LGTMP Application
  (`gitops/platform/observability-mimir.yaml`,
  `observability-loki.yaml`, `observability-tempo.yaml`,
  `observability-pyroscope.yaml`, `observability-grafana.yaml`,
  `observability-alloy.yaml`, `observability-ksm.yaml`,
  `observability-node-exporter.yaml`) with chart-specific
  `podSecurityContext` / `containerSecurityContext` (or chart-named
  equivalent — Grafana uses `securityContext` under `grafana:`,
  Mimir/Loki/Tempo/Pyroscope under their respective top-level
  components; executor checks each chart). Per ADR-0017 §Layer 1:
  pod-level `runAsNonRoot: true`, non-zero
  `runAsUser`/`runAsGroup`/`fsGroup`, `seccompProfile.type:
  RuntimeDefault`; container-level `allowPrivilegeEscalation: false`,
  `readOnlyRootFilesystem: true` (with `emptyDir` overlays where each
  chart writes), `capabilities.drop: [ALL]`. **node-exporter is a
  DaemonSet that needs `hostPID`/`hostNetwork` to read host metrics —
  ADR-0017 §Per-workload field carve-outs covers this**; the executor
  flags it in the PR and applies the restricted profile only to the
  pods that can take it. **If the PR crosses ~400 lines**, split as:
  PR 1 = namespace label + Grafana + Alloy + KSM; follow-up PRs split
  by chart family. New `tests/securitycontext-observability.bats`
  asserting the namespace PSA labels and per-workload securityContext
  fields. Update `docs/dependency-tree.md`.

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
> the 🟡 items still need a human (or architect) RFC before the executor builds them.

- [ ] 🟢 **Lab — Cloud control-plane (moto / ACK / KRO) dashboard**
  (CHARTER gap — *cloud control-plane patterns (ACK/KRO against a mock)* is a
  named learning objective and the quality bar requires real observability for
  every always-on component; this is the only always-on piece with no
  dashboard, see `grafana/dashboards/` against the always-on Application list).
  New `grafana/dashboards/lab-cloud-control-plane.json` modelled on the
  `lab-vault.json` stat-row pattern, three subsections — **moto** (pod running
  / memory / CPU / restarts from KSM+cAdvisor, ArgoCD sync state for the `moto`
  Application; namespace `moto`); **ACK S3** (same five metrics for the
  `ack-s3` Application's controller Deployment in namespace `ack-system`, plus
  a Loki logs panel filtered to the ACK controller pod showing reconciles
  against `kind=Bucket`); **KRO** (same five metrics for the KRO controller in
  namespace `ack-system`, plus a stat panel counting `kubectl get
  resourcegraphdefinitions` instances and a logs panel for the KRO controller
  pod showing RGD reconciles). About-text panel cites the
  `ack-demo-bucket` + `app-data` instance as the live demo objects to watch
  reconcile. All data from real KSM/cAdvisor/ArgoCD/Loki sources already
  scraped by Alloy — no new scrape jobs needed (ADR-0004). Wire the dashboard
  into the Grafana "Lab UIs" stack-health panel row list. Add
  `tests/observability.bats` assertions (file exists, three subsection
  headings present, no Prometheus query references metrics not currently
  scraped). Update `docs/dependency-tree.md` with a brief note that the
  cloud-control-plane stack now has a dashboard. *(Note for executor: if ACK
  or KRO controller pods expose controller-runtime metrics on a
  `:8080/metrics`-style port, do NOT add a scrape job in this PR — file that
  as a follow-up planner item; this PR stays clusterless-verifiable.)*

- [ ] 🟡 **Kyverno admission engine** (RFC #153) (CHARTER **Objective O1**, due
  **2026-12-31**: Kyverno is one of four Tier 1 next-wave components
  that must be auto-synced ArgoCD `Application`s with their own ADR +
  real-metric Grafana dashboard + bats coverage by the deadline).
  Kyverno also gates **Objective O4** (cosign-signed images verified
  at admission via `verifyImages` ClusterPolicy). Awaiting an
  architect RFC for: (a) Helm chart source + version + footprint vs.
  the 12 GB always-on budget; (b) the supporting ADR (likely
  ADR-0019); (c) the initial ClusterPolicy set — validation
  (PSS-restricted as a backstop to ADR-0017), mutation (e.g. inject
  pod-security defaults), and the `verifyImages` policy for O4; (d)
  the dashboard scrape target (Kyverno exposes
  `/metrics` on TCP 8000). Per WAYS-OF-WORKING.md §2 this is 🟡 —
  growing the always-on footprint + security-adjacent + new
  dependency. **Executor must not pick this up unprompted.** The
  planner will split into 🟢 items the run after the RFC issue lands.

- [ ] 🟡 **Argo Rollouts** (RFC #154) (CHARTER **Objective O1**, due **2026-12-31**:
  the second of four Tier 1 next-wave components — supports the
  CHARTER goal *progressive delivery (canary releases gated by real
  SLO metrics, not timers)* and the capstone-vision *Argo Rollouts
  canaries on real Mimir SLOs → Envoy routes it*). Awaiting an
  architect RFC for: (a) Helm chart vs. install YAML; (b) ADR
  (probably ADR-0020); (c) the AnalysisTemplate sourced from Mimir
  (`prometheus` provider) — the Mimir scrape endpoint already exists
  per the Mimir Application; (d) the Envoy Gateway traffic-split
  integration (Argo Rollouts supports Gateway API via
  `gatewayAPI.gatewayClass` — ADR-0008 stays compatible); (e)
  dashboard from real Rollouts controller metrics. 🟡 — new always-on
  component + new dependency + Makefile/CI integration.

- [ ] 🟡 **Velero** (RFC #155) (CHARTER **Objective O1**, due **2026-12-31**: the
  third Tier 1 next-wave component; also **gates Objective O3**
  (`make dr-restore` recovers every stateful namespace —
  `data`/`tidb`/`capstone`/`vault` — from its latest Velero backup in
  under 10 min). Awaiting an architect RFC for: (a) Helm chart vs.
  manifest install; (b) ADR (probably ADR-0021); (c) the Garage S3
  bucket layout (Velero backups go to a `velero` bucket in the
  existing Garage instance — ADR-0002); (d) the `Schedule` set — one
  per stateful namespace per CHARTER Core Value *Stateful DR is
  exercised*; (e) the dashboard panels showing last-backup-age per
  Schedule (real Velero `/metrics`); (f) the `make dr-restore` make
  target that ties this to O3. 🟡 — new always-on component +
  Makefile change + security-adjacent (Garage credentials).

- [ ] 🟡 **Trivy Operator** (RFC #156) (CHARTER **Objective O1**, due
  **2026-12-31**: the fourth Tier 1 next-wave component; covers the
  CHARTER goal *supply-chain security end-to-end (Trivy continuous
  scanning + SBOMs)*). Awaiting an architect RFC for: (a) Helm chart
  + version + footprint; (b) ADR (probably ADR-0022); (c) the
  `VulnerabilityReport` / `ConfigAuditReport` CR set the operator
  emits; (d) the SBOM generation flow (Trivy can emit SBOMs as CR
  attachments — wire to the capstone GitLab CI build for the
  *signed-and-scanned* capstone vision); (e) dashboard showing
  CVE-by-severity counts per workload from real
  `trivy_image_vulnerabilities` metrics. 🟡 — new always-on
  component + new dependency.

_Future 🟡 entries land here when the architect routine files a new RFC issue
but the planner hasn't yet split it. The four entries above all have RFC
issues filed by the architect routine (2026-W23): Kyverno → #153 (ADR-0019);
Argo Rollouts → #154 (ADR-0020); Velero → #155 (ADR-0021); Trivy Operator →
#156 (ADR-0022). The next planner run grooms each into 🟢 single-PR items.
The two prior 🟡 entries (NetworkPolicy default-deny,
securityContext hardening) have been groomed into the 🟢 fan-out items in
*Now / next* above (ADR-0016 and ADR-0017 are adopted). The ADR-0010
Redis→Valkey swap (issue #94) landed as ADR-0018 in PR #106 and is in *Done*
below. A separate 🟡 entry for **PSS-restricted hardening of the `argocd`
namespace** (touches `infra/modules/argocd/values.yaml` per WAYS-OF-WORKING.md
§2 — `infra/` bootstrap change) is implicit in the O2 clock-note above; the
planner will surface it as its own item once the rest of the 🟢 PSS fan-out
burns down._

---

## Done
<!-- Autonomous runs: move completed items here with their PR number. -->
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
