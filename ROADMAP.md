# ROADMAP

The backlog for **k8s-lab**, derived from [CHARTER.md](CHARTER.md) (the north-star this
is projected from) and worked by two decoupled routines: a weekly **planner** that
proposes items here (plan-only PRs) and an every-6h **executor** that implements one item
per run. CHARTER = the goals; this file = the next steps.

The always-on stack is already built (Envoy, Vault, External Secrets, Garage,
the full LGTMP observability stack, moto/ACK/KRO, the RabbitMQ + Redis data layer,
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
  - **gap analysis** — a charter target not yet built, or a quality bar not yet met,
    becomes a proposed item;
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
> needs a human-authored issue/RFC *first* (the executor must skip it and open an issue,
> per rule #10, never build it unprompted); **🔴 Red** humans only. *Now / next* holds
> only 🟢 items.

### Now / next
> Pick the topmost unchecked item. If it can't be done cleanly this run, fall
> through to the next.
>
> **Planner note (2026-06-01):** the previous wave landed — Tempo trace
> producer (HotROD swap), Artifactory (ADR-0011 + manifests + tooling), Istio
> ambient + Kiali (ADR-0012 + manifests), and Longhorn (ADR-0013 + manifests).
> All three heavy on-demand components are now in the repo, each as a
> non-auto-synced ArgoCD `Application` with a `make <name>-up`/`-down` pair,
> Envoy `HTTPRoute`, Grafana "Lab UIs" tile, and `bats` coverage. With
> Artifactory live, **the Capstone (RFC #62) is unblocked**: step 1 (GitLab
> CI builds the demo image and pushes it to Artifactory) is promoted below.
> Steps 2–5 stay in the Capstone section, each blocked on its predecessor —
> the planner will promote them one at a time as each lands.
> NetworkPolicies and `securityContext` hardening remain 🟡 and still need
> their own RFCs before the executor may build them.

- [ ] 🟢 **Capstone step 1 — GitLab CI builds the demo image and pushes it to
  Artifactory.** RFC #62 directs the end-to-end pipeline; ADR-0011 records
  Artifactory as the in-lab registry, and the Artifactory manifests landed in
  `auto/artifactory-manifests` (`gitops/platform/artifactory.yaml`,
  `make artifactory-up`/`-down`, `artifactory.127.0.0.1.nip.io`). This step
  adds the *build + push* half of the inner loop.
  - Add a thin, buildable capstone image source under `gitops/apps/capstone/`
    — a minimal `Dockerfile` wrapping a tiny static-content or hello-world
    workload (e.g. nginx + a single index.html, or a Go `net/http` "hello
    capstone" binary). Living in this repo keeps the build reproducible from
    code (CHARTER recreate-from-code). *(Reusing HotROD as base is acceptable
    if the executor judges the diff is smaller; either way the source lives
    here so a re-clone rebuilds the image.)*
  - Add `.gitlab-ci.yml` at the repo root (no file exists today) with a single
    `build` job that builds the image and pushes it to Artifactory's Docker
    registry endpoint (`artifactory.127.0.0.1.nip.io` from the existing
    `HTTPRoute`, or the in-cluster service URL). Pull credentials at runtime
    via env vars sourced from a Kubernetes `Secret` — **no plaintext creds
    in CI vars**.
  - Seed registry credentials in Vault from `scripts/vault-bootstrap.sh` at a
    new path (e.g. `secret/artifactory/registry` with `username` +
    `password`); add an `ExternalSecret` in `gitops/secrets/` that
    materializes the Secret the runner reads (mirror the
    `tidb-demo-creds` / `rabbitmq-creds` patterns).
  - Acceptance: `make ci` stays green — `yamllint` lints the new
    `.gitlab-ci.yml`; structural `bats` asserts (a) `.gitlab-ci.yml` defines
    the `build` job and references `$ARTIFACTORY_*` env vars sourced from a
    Secret rather than plaintext, (b) `vault-bootstrap.sh` seeds the new
    Vault path, (c) the new `ExternalSecret` exists with matching
    `remoteRef`. `README.md` and `docs/dependency-tree.md` updated with the
    new GitLab CI → Artifactory edge and the new ESO secret edge.
  - (🟢 — RFC #62 is the human RFC; same single-PR shape the executor used
    for the earlier capstone-prereq items. *Maintainer may pre-pick the
    image source flavor, Vault path, or registry hostname by editing this
    item before the executor runs.*)

### Heavy on-demand components (README "Planned" row)
> **All three heavy components have human RFCs (#58 Artifactory, #59 Istio
> ambient, #60 Longhorn) and have been groomed into 🟢 ADR + manifest pairs in
> *Now / next* above.** Any future heavy/on-demand component goes through the
> same grooming flow: human files an RFC issue → planner splits into ADR +
> non-auto-synced manifest + `make` target + docs + bats items → executor builds.
> Heavy components MUST stay out of `gitops/bootstrap/root-app.yaml`'s
> auto-synced set (rule #4).

### Capstone — "tie it together" (learning-path step 5)
> RFC #62 directs the capstone end-to-end pipeline. The in-lab registry is
> **Artifactory** (RFC #58 → ADR-0011), and the Artifactory manifests landed
> in `auto/artifactory-manifests`, **unblocking step 1**. Step 1 is now in
> *Now / next*; steps 2–5 remain here, each blocked on its predecessor — the
> planner promotes them one at a time as each lands.

- [ ] 🟢 **Capstone step 2 — ArgoCD `Application` for the pipeline-deployed
  app variant.** New `gitops/apps/capstone/` Application sourcing the
  pipeline-built image (via Argo image-updater annotation or a values bump in
  the same repo). Auto-synced is fine here — the workload itself is light.
  *(Blocked on step 1.)*
- [ ] 🟢 **Capstone step 3 — Envoy `HTTPRoute` for the capstone app**
  (`capstone.127.0.0.1.nip.io`). Wire it into the Grafana "Lab UIs" panel so
  `make lab-ui-check` covers it. *(Blocked on step 2.)*
- [ ] 🟢 **Capstone step 4 — Grafana dashboard tile for the capstone app**
  ("Lab — Capstone"): real pod/container metrics + Loki log panel filtered to
  the capstone namespace + Tempo traces panel if the app is OTel-instrumented
  (see the Tempo-producer item above). ADR-0004: real metrics only.
  *(Blocked on step 2.)*
- [ ] 🟢 **Capstone step 5 — Vault secret + `ExternalSecret` for the capstone
  app.** Seed via `scripts/vault-bootstrap.sh` (mirror the `tidb/demo` pattern);
  `ExternalSecret` in `gitops/secrets/`. *(Blocked on step 2.)*

### Cross-cutting hardening & quality (always-safe filler)
> Use these when nothing above can be done cleanly in a single run. Mixed tiers —
> the 🟡 items still need a human RFC before the executor builds them.

- [ ] 🟡 Add default-deny `NetworkPolicy` per namespace + the minimal allows each
  component needs. *(Security-adjacent / network exposure — needs human RFC first;
  there are currently zero `NetworkPolicy` objects, so this is a from-scratch
  cross-cutting design, not a one-PR tweak — the planner should split it per
  namespace once a human signs off on the deny-by-default direction.)*
- [ ] 🟡 Harden `securityContext` (runAsNonRoot, drop ALL caps, readOnlyRootFilesystem
  where viable) across manifests. *(Security-adjacent — needs human RFC first.)*

---

## Done
<!-- Autonomous runs: move completed items here with their PR number. -->
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
