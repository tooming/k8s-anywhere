# ROADMAP

The backlog for **k8s-lab**, derived from [CHARTER.md](CHARTER.md) (the north-star this
is projected from) and worked by two decoupled routines: a weekly **planner** that
proposes items here (plan-only PRs) and an every-6h **executor** that implements one item
per run. CHARTER = the goals; this file = the next steps.

The always-on stack is already built (Envoy, Vault, External Secrets, Garage,
the full LGTMP observability stack, moto/ACK/KRO, the demo app — 25 ArgoCD apps).
What's left is the heavy *on-demand* components, the end-to-end capstone, and
cross-cutting hardening.

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
6. **Deliver a GitHub PR — never push to `main`, never self-merge.** One branch per
   run (`auto/<short-slug>`). Title it clearly; the body should say what + why and
   note it's an autonomous run. CI runs on the PR; the user reviews and merges.
7. **Check it off in the same PR.** Mark the item `[x]`, move it to *Done*, and
   reference the PR number.
8. **If the top item can't be done cleanly in one run, take the next feasible
   item** instead of committing something that fails `make ci`. If you genuinely
   can't make any gate-passing progress, stop **without** opening a PR.
9. **Never invent new backlog items.** You only implement items already listed below.
   If there's no actionable item, **stop** — the weekly planner refills the backlog
   (see next section). An idle executor is fine; make-work is not.
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
- de-dupes against existing items and open PRs, and may open **no PR** if there's nothing
  to do (no churn for its own sake).

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
> **Planner note (2026-05-26):** the whole TiDB track (operator → cluster → demo)
> is **done** and moved to *Done*; the always-on resource/bats/dashboard hardening
> items are likewise complete. The 🟢 executor lane is now nearly empty — almost all
> remaining high-value work (real Tempo trace producer, NetworkPolicies,
> `securityContext` hardening, the heavy on-demand components, the capstone) is 🟡
> and **blocked on a human RFC**. Until a human writes those RFCs, the executor will
> only have the documentation items below. See the plan-PR body.

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
> All 🟡 Yellow — each introduces a **new platform component + new third-party
> chart/dependency + a new ADR** (the tech choice is a human decision). The executor
> must **not** build these unprompted: open a GitHub issue naming the decision a human
> owes (which product, which chart source, footprint within the 12 GB budget) and move
> to the next 🟢 item. A human RFC + the ADR unblock the build.

- [ ] 🟡 **Artifactory or Nexus** artifact registry, on-demand. Pick one; record the
  choice as a new ADR. Manifests + `make` target + docs. *(needs human RFC first)*
- [ ] 🟡 **Istio ambient mesh + Kiali**, on-demand. Ambient profile; wire Kiali into
  the Lab UIs panel. Manifests + `make` target + docs + ADR. *(needs human RFC first)*
- [ ] 🟡 **Longhorn** distributed block storage, on-demand. Manifests + `make` target
  + docs + ADR. *(needs human RFC first; context.md currently defers Longhorn —
  reconcile that note when the RFC lands.)*

### Capstone — "tie it together" (learning-path step 5)
- [ ] 🟡 **End-to-end pipeline** — a GitLab CI pipeline that builds the demo app image
  → pushes to an in-lab registry → ArgoCD deploys it → Envoy routes it → Grafana
  shows its metrics & logs → Vault holds its secrets. Author the pipeline +
  manifests as code; validate clusterless. *(needs human RFC first — pulls in a new
  in-lab registry component and touches CI; large enough that the planner should split
  it into staged items once a human sets direction.)*

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
- [ ] 🟡 **Real trace producer for Tempo.** Tempo is deployed always-on and the
  "Lab — Traces" dashboard exists, but **nothing emits OTLP** — no workload outside
  Tempo references `4317`/`4318`/`otel`, so the traces pillar carries no real data
  (a learning objective unmet + an ADR-0004 "no fabricated/empty real-state panel"
  smell). Add an OTel-instrumented producer that emits real spans to Tempo's OTLP
  receiver, then confirm the dashboard populates. *(🟡 because it introduces a new
  instrumented workload/image and touches the always-on observability data flow —
  needs a human RFC on what to instrument: the existing `hello` demo, a purpose-built
  tiny emitter, or fold it into the TiDB/capstone demo. Keep footprint inside the
  12 GB budget.)*
- [ ] 🟡 **Wire the Git Sync bootstraps into `make up` / DR (and survive Grafana rolls).**
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
- [x] **Dependency-tree sync** — Updated `docs/dependency-tree.md` to match current repo state: added TiDB on-demand components (Operator, Cluster, Demo App) to the Mermaid integration graph with dashed on-demand edges; added the two missing ESO secret-chain edges (`grafana-admin ← grafana/admin`, `tidb-demo-creds ← tidb/demo`); added the Envoy → `tidb-demo.127.0.0.1.nip.io` HTTPRoute edge; added two new rows to the integration edges table; expanded the Day-0 vault-bootstrap step to enumerate exactly which Vault paths it seeds. (PR #28)
- [x] **Vault & Secrets dashboard** — Added `grafana/dashboards/lab-vault.json`: a "Lab — Vault & Secrets" Grafana dashboard with 11 panels covering pod-running status, memory, CPU, restart counts, and ArgoCD sync state for both Vault and External Secrets Operator. All panels use real KSM/cAdvisor/ArgoCD metrics already scraped by Alloy — no fabricated data (ADR-0004). Delivered through Grafana native Git Sync (ADR-0006). Covers the "Add Grafana dashboards for always-on components lacking them" backlog item. (PR #TBD)
- [x] **Expand bats coverage** — Added 11 new tests across two files: `tests/adr-guard.bats` (7 tests — verifies the PostToolUse ADR guard exits 0 on clean/excluded paths and exits 2 with the correct message when a rejected term such as "minio" appears in a guarded file) + 4 uptime-math edge cases in `tests/bluegreen-probe.bats` (all-failures → 0%, single-pass, single-fail, and the outage-uses-maxrun-not-fail-count invariant). Suite grows from 15 to 26 tests. (auto/expand-bats-coverage)
- [x] **Resource CPU limits** — Added `cpu:` limits to every `Deployment`/`StatefulSet` in `gitops/` (9 direct-manifest workloads + 11 Helm-chart `Application` values entries, including both containers in the TiDB Operator chart and the Grafana sidecar). All workloads already had memory limits and cpu/memory requests; this completes the resource envelope. (auto/resource-cpu-limits)
- [x] **TiDB operator** — `gitops/platform/tidb-operator.yaml` (manual-sync ArgoCD Application, chart `tidb-operator` v1.6.1 from charts.pingcap.org, namespace `tidb-admin`). Makefile targets `tidb-operator-up` / `tidb-operator-down`. Docs updated in README + dependency-tree. (auto/tidb-operator)
- [x] **TiDB cluster** — `gitops/platform/tidb-cluster.yaml` (manual-sync ArgoCD Application, git-path `gitops/tidb/`). `TidbCluster` CR v8.1.2 with 1×PD + 1×TiKV + 1×TiDB (ADR-0005 lab trade-off; production uses ≥3+3+2). `make tidb-up` / `make tidb-down`. Docs updated in README + dependency-tree. (PR to be referenced)
- [x] **TiDB demo app** — `gitops/platform/tidb-demo.yaml` (manual-sync ArgoCD Application, git-path `gitops/tidb-demo/`). nginx demo workload in namespace `tidb` reading Vault credentials (`secret/tidb/demo`) via `ExternalSecret tidb-demo-creds`. Envoy HTTPRoute `tidb-demo.127.0.0.1.nip.io`. Grafana dashboard "Lab — TiDB Demo App" (real pod/container metrics). `make tidb-demo-up` / `make tidb-demo-down`. Vault-bootstrap seeding added. Docs updated in README + dependency-tree + stack-health panel.
- [x] **ADR-0007 — Off-cluster Garage Terraform-state backend** — Added `docs/decisions/adr-0007-off-cluster-garage-tfstate-backend.md` documenting why a second off-cluster Garage instance is used as the Terraform state backend (avoids the cluster→state bootstrap loop), the `generate "backend"` choice over `remote_state` (Garage compatibility), the explicit disabling of state locking, and the relationship to ADRs 0001/0002/0003/0005. Linked from `docs/decisions/README.md`.
- [x] **ADR-0008 — Envoy Gateway for north-south ingress** — Added `docs/decisions/adr-0008-envoy-gateway-not-traefik.md` documenting the choice of Envoy Gateway (Gateway API: HTTPRoute) over the k3s-default Traefik and Kubernetes `Ingress`; covers the shared-gateway pattern (`allowedRoutes: All`), the `*.127.0.0.1.nip.io` hostname strategy, and the rationale for using the same Envoy data plane as the planned Istio ambient mesh. Linked from `docs/decisions/README.md`. (PR #32)
