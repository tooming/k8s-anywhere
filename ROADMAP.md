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
> **Planner note (2026-05-29):** the maintainer answered the executor's idle
> notice (issue #57) by filing five RFCs (#58 Artifactory, #59 Istio ambient,
> #60 Longhorn, #61 Tempo producer, #62 capstone) — those RFCs ARE the
> human-authored design input the 🟡 items were waiting on (per
> [docs/WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md) §2). Each RFC has been
> groomed into single-PR 🟢 items below, ordered so the smallest, highest-value
> work (Tempo producer — completes the LGTMP traces pillar with no new heavy
> deps) runs first, then the heavy on-demand components in the order
> Artifactory → Istio + Kiali → Longhorn (Artifactory first because the
> Capstone, RFC #62, chains behind it). NetworkPolicies and `securityContext`
> hardening remain 🟡 and still need their own RFCs.
>
> ADR items are 🟢 because they *record decisions already made* by the RFC
> issues — the same precedent as ADR-0007/ADR-0008. Manifest items for the new
> heavy components are 🟢 because each lands as a **non-auto-synced** ArgoCD
> `Application` (rule #4) — the executor pattern proven by the TiDB track.

- [x] 🟢 **Real Tempo trace producer — swap the `hello` demo image for a small
  OTel-instrumented public image.** RFC #61 directs us to instrument the
  existing `hello` demo (not a new emitter, not the TiDB demo). The current
  `gitops/apps/demo/deployment.yaml` runs `nginx:alpine`, which can't emit
  OTLP. Replace the image with `jaegertracing/example-hotrod:latest` (canonical
  small public OTel demo from the Jaeger project) and set
  `OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo.observability.svc.cluster.local:4318`
  via env so spans land in Tempo's OTLP HTTP receiver (the existing
  `tempo.observability.svc:4317`/`:4318` is already configured —
  `gitops/observability/tempo/deployment.yaml`). Keep replicas=1 and the
  existing CPU/memory limits (hotrod is ~80 MB image, fits the 12 GB budget).
  Acceptance: dashboard ("Lab — Traces") expectation documented; clusterless
  `make ci` gates pass; `docs/dependency-tree.md` updated to show the new
  `hello → tempo` OTLP edge. (🟢 — RFC #61 is the human RFC; image choice is
  named here so the executor doesn't pick. *Maintainer may swap to a different
  small public OTel image by editing this item before the executor runs.*)
- [x] 🟢 **ADR-0011 — Artifactory as the on-demand artifact registry (not
  Nexus).** Records the RFC #58 decision. Add
  `docs/decisions/adr-0011-artifactory-not-nexus.md`: why Artifactory over
  Nexus (single, well-known, JFrog OSS chart; learning value); chart source
  (`jfrog/artifactory-oss` Helm chart, or named alternative); expected
  footprint within the 12 GB budget (heavy → manual-sync ADR-0001 + ADR-0005
  trade-off); relationship to RFC #62 (capstone consumer). Link from
  `docs/decisions/README.md`. (🟢 — documents a decision already taken by
  RFC #58; same pattern as ADR-0007/0008.)
- [x] 🟢 **Artifactory on-demand manifests + tooling.** Add
  `gitops/platform/artifactory.yaml` as an ArgoCD `Application` with **no
  `automated:` block** (manual sync, ROADMAP rule #4 — see the TiDB pattern in
  `gitops/platform/tidb-operator.yaml`). Add `make artifactory-up` /
  `make artifactory-down` targets. Add a `bats` test asserting the Application
  is NOT auto-synced (mirror `tests/data-layer.bats`). Update `README.md`,
  `docs/dependency-tree.md` (add the on-demand component row + dashed edge),
  and wire the Artifactory UI into the Grafana "Lab UIs" panel via an Envoy
  `HTTPRoute` (e.g. `artifactory.127.0.0.1.nip.io`) so `make lab-ui-check`
  stays green. Use values from the ADR (chart, footprint). (🟢 — non-auto-synced
  heavy component; the executor pattern is proven by `tidb-operator`,
  `tidb-cluster`, `tidb-demo`.)
- [ ] 🟢 **ADR-0012 — Istio ambient mesh + Kiali on-demand (not sidecar).**
  Records the RFC #59 decision. Add
  `docs/decisions/adr-0012-istio-ambient-not-sidecar.md`: why ambient over
  sidecar (no per-pod injection, lighter memory footprint, simpler on a single
  host); chart sources (`istio/base`, `istio/istiod`, `istio/cni`,
  `istio/ztunnel` for ambient; Kiali official chart); relationship to
  ADR-0008 (Envoy data plane shared with the north-south gateway); expected
  footprint within the 12 GB budget. Link from `docs/decisions/README.md`.
- [x] 🟢 **Istio ambient on-demand manifests + tooling.** Add `gitops/istio/`
  and `gitops/platform/istio-*.yaml` ArgoCD `Application`s **without
  `automated:`** (one app per istio component: `istio-base`, `istiod`,
  `istio-cni`, `ztunnel` — or bundle as the ADR resolves). Add `make istio-up`
  / `make istio-down`. Bats test asserts no auto-sync. Update `README.md`,
  `docs/dependency-tree.md`. (Kiali wiring goes in the next item.)
- [ ] 🟢 **Kiali on-demand manifests + Lab UIs panel wiring.** Add
  `gitops/platform/kiali.yaml` as a manual-sync ArgoCD `Application`. Add the
  Kiali UI to the Lab UIs panel via an Envoy `HTTPRoute`
  (`kiali.127.0.0.1.nip.io`) so `make lab-ui-check` covers it. Add `bats` +
  docs updates (`README.md`, `docs/dependency-tree.md`). Document that
  `make istio-up` must precede `make kiali-up` (or fold into a combined
  `mesh-up` target — executor's call within the ADR).
- [ ] 🟢 **ADR-0013 — Longhorn distributed block storage on-demand.** Records
  the RFC #60 decision. Add
  `docs/decisions/adr-0013-longhorn-block-storage.md`: why we're un-deferring
  Longhorn (`docs/decisions/context.md` currently says "Deferred"); chart
  source (`longhorn/longhorn` official Helm chart); expected footprint within
  the 12 GB budget; relationship to ADR-0002 (Garage is S3; Longhorn is block).
  Update `docs/decisions/context.md` in the same PR to reflect the un-defer.
  Link from `docs/decisions/README.md`.
- [ ] 🟢 **Longhorn on-demand manifests + tooling.** Add
  `gitops/platform/longhorn.yaml` (or `gitops/storage/longhorn.yaml`) as a
  manual-sync ArgoCD `Application`. Add `make longhorn-up` /
  `make longhorn-down`. Bats test asserts no auto-sync. Update `README.md` and
  `docs/dependency-tree.md`. Wire the Longhorn UI into the Lab UIs panel via
  an Envoy `HTTPRoute` (`longhorn.127.0.0.1.nip.io`).
- [x] 🟢 **ADR for the off-cluster Garage Terraform-state backend.** The remote
  `backend "s3"` over an off-cluster Garage (`infra/tfstate/`, `make tfstate-up`,
  `scripts/tfstate-bootstrap.sh`) shipped in `a07a1d2` and is described in
  `docs/dependency-tree.md` / `DR.md` / `platform-products.md`, but the *decision*
  has no ADR. Record one (`adr-0007-…` — note: `adr-0006` is now taken by the
  merged Grafana Git Sync ADR): why off-cluster Garage state (no cluster→state
  bootstrap loop; distinct from in-cluster Garage and from moto's S3) and the
  `generate "backend.tf"` choice; link it from `docs/decisions/README.md`.
  (🟢 — records an *already-shipped* decision, i.e. documentation; it does not
  change an existing ADR, which would be 🔴.)
- [x] 🟢 Keep `docs/dependency-tree.md` current as components are added.

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
> **Artifactory** (RFC #58 → ADR-0011), so this whole chain is **blocked on
> the Artifactory manifest item landing first** (see *Now / next*). When that
> lands, the planner promotes the steps below into *Now / next* one at a time
> in the order shown.

- [ ] 🟢 **Capstone step 1 — GitLab CI: build the demo app image and push it to
  Artifactory.** Add `.gitlab-ci.yml` (or update if present) with a build job
  that produces an image of the `hello` demo (or its capstone successor) and
  pushes to the in-lab Artifactory Docker registry endpoint. Vault-stored
  registry creds via ESO; no plaintext creds in CI vars. Clusterless gates:
  `make ci` lints the YAML, structural bats. *(Blocked on the Artifactory
  manifest item.)*
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
- [x] 🟢 **Real trace producer for Tempo** — RFC #61 set the direction
  (instrument the `hello` demo, not a separate emitter); groomed into
  *Now / next* above.
- [x] 🟡 **Wire the Git Sync bootstraps into `make up` / DR (and survive Grafana rolls).**
  ADR-0006 left two imperative seams run by hand: `scripts/gitlab-tls-bootstrap.sh` (mkcert
  cert + nginx TLS proxy on `:8930` + publish the `gitlab-tls-ca` ConfigMap) and
  `scripts/grafana-gitsync-bootstrap.sh` (create the Pure Git `Repository` + set the home
  dashboard). Two fragilities, both hit live when Grafana was bumped to 13.0.1 (#35):
  (a) `gitlab-tls-ca` isn't GitOps-managed, so if it's absent when the Grafana pod
  (re)starts, the CA-bundle init builds a bundle WITHOUT the mkcert CA → Git Sync fails
  `x509: unknown authority` and dashboards vanish; (b) the `Repository` lives in Grafana
  unified storage and did NOT survive the 12.4→13 upgrade, so it must be re-created. `make up`
  (and DR) must run both bootstraps in order — cert before the proxy; CA published before
  Grafana starts (restart Grafana if the CA arrives late so the init re-runs); `Repository`
  re-created once Grafana is healthy — so a rebuilt/upgraded lab self-heals with no manual
  steps. Add the wiring + DR coverage + bats/docs. *(🟡 — Makefile + DR/bootstrap-ordering,
  infra-critical; a human owns the ordering. Until then `make gitlab-tls-bootstrap` +
  `make grafana-gitsync-bootstrap` are the manual recovery steps.)*
- [x] 🟢 Add an ADR for any new non-trivial decision (documenting a decision already
  made/shipped; changing an *existing* ADR is 🔴 humans-only).

---

## Done
<!-- Autonomous runs: move completed items here with their PR number. -->
- [x] **Istio ambient on-demand manifests + tooling** — Added four non-auto-synced ArgoCD Applications (`gitops/platform/istio-base.yaml`, `istio-cni.yaml`, `istiod.yaml`, `ztunnel.yaml`; chart `istio/{base,cni,istiod,ztunnel}` v1.24.3 from `istio-release.storage.googleapis.com/charts`, namespace `istio-system`); `make istio-up` / `make istio-down` targets; 6 bats tests asserting no auto-sync + make targets present; `docs/dependency-tree.md` updated with ISTIO subgraph and sync-wave rows; `README.md` updated with make targets. Kiali HTTPRoute + Lab UIs panel wiring is the next ROADMAP item.
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
