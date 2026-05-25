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

- [x] **TiDB operator** — add the TiDB Operator as an on-demand ArgoCD
  `Application` (manual-sync, not in the always-on set) + its namespace + docs.
- [x] **TiDB cluster** — a minimally-sized `TidbCluster` CR (PD + TiKV + TiDB,
  smallest viable replicas) + `make tidb-up` / `make tidb-down`.
- [ ] **TiDB demo app** — 🟢 Green. A demo workload that reads its TiDB
  credentials from Vault via an `ExternalSecret`, with an Envoy route and a real
  Grafana dashboard (learning-path step 4). **Must be non-auto-synced** — it
  belongs to the on-demand TiDB profile, so bring it up via `make tidb-up` (or its
  own `make` target) and keep it out of the always-on app-of-apps
  (`gitops/bootstrap/root-app.yaml`), per the 12 GB budget rule.

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

- [ ] 🟢 Audit every workload for resource requests/limits; add the missing ones.
  (Today every `Deployment`/`StatefulSet` in `gitops/` carries limits; remaining
  work is completeness — CPU limits and multi-container coverage.)
- [ ] 🟡 Add default-deny `NetworkPolicy` per namespace + the minimal allows each
  component needs. *(Security-adjacent / network exposure — needs human RFC first;
  there are currently zero `NetworkPolicy` objects, so this is a from-scratch
  cross-cutting design, not a one-PR tweak — the planner should split it per
  namespace once a human signs off on the deny-by-default direction.)*
- [ ] 🟡 Harden `securityContext` (runAsNonRoot, drop ALL caps, readOnlyRootFilesystem
  where viable) across manifests. *(Security-adjacent — needs human RFC first.)*
- [ ] 🟢 Expand `bats` coverage (script guards, drift detectors, uptime-math edges).
- [ ] 🟢 Add Grafana dashboards/alerts for any always-on component lacking them —
  real metrics only (ADR-0004).
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
- [ ] 🟢 Keep `docs/dependency-tree.md` current as components are added.
- [ ] 🟢 **ADR for the off-cluster Garage Terraform-state backend.** The remote
  `backend "s3"` over an off-cluster Garage (`infra/tfstate/`, `make tfstate-up`,
  `scripts/tfstate-bootstrap.sh`) shipped in `a07a1d2` and is described in
  `docs/dependency-tree.md` / `DR.md` / `platform-products.md`, but the *decision*
  has no ADR. Record one (`adr-0006-…`): why off-cluster Garage state (no
  cluster→state bootstrap loop; distinct from in-cluster Garage and from moto's
  S3) and the `generate "backend.tf"` choice; link it from `docs/decisions/README.md`.
  (🟢 — this records an *already-shipped* decision, i.e. documentation; it does not
  change an existing ADR, which would be 🔴.)
- [ ] 🟢 Add an ADR for any new non-trivial decision (documenting a decision already
  made/shipped; changing an *existing* ADR is 🔴 humans-only).

---

## Done
<!-- Autonomous runs: move completed items here with their PR number. -->
- [x] **TiDB operator** — `gitops/platform/tidb-operator.yaml` (manual-sync ArgoCD Application, chart `tidb-operator` v1.6.1 from charts.pingcap.org, namespace `tidb-admin`). Makefile targets `tidb-operator-up` / `tidb-operator-down`. Docs updated in README + dependency-tree. (auto/tidb-operator)
- [x] **TiDB cluster** — `gitops/platform/tidb-cluster.yaml` (manual-sync ArgoCD Application, git-path `gitops/tidb/`). `TidbCluster` CR v8.1.2 with 1×PD + 1×TiKV + 1×TiDB (ADR-0005 lab trade-off; production uses ≥3+3+2). `make tidb-up` / `make tidb-down`. Docs updated in README + dependency-tree. (PR to be referenced)
