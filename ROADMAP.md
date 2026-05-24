# ROADMAP

The backlog for **k8s-lab**, and the operating contract for the **autonomous dev
routine** that works this repo whenever spare credit is available.

The always-on stack is already built (Envoy, Vault, External Secrets, Garage,
the full LGTMP observability stack, moto/ACK/KRO, the demo app — 25 ArgoCD apps).
What's left is the heavy *on-demand* components, the end-to-end capstone, and
cross-cutting hardening.

---

## How the autonomous routine uses this file

A scheduled **remote** agent reads this file each run. It has **only this repo** —
no access to anyone's local notes — so every rule it must follow lives here or in
`docs/decisions/` (the ADRs). The rules below are binding.

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

---

## Backlog

### Now / next
> Pick the topmost unchecked item. If it can't be done cleanly this run, fall
> through to the next.

- [ ] **TiDB operator** — add the TiDB Operator as an on-demand ArgoCD
  `Application` (manual-sync, not in the always-on set) + its namespace + docs.
- [ ] **TiDB cluster** — a minimally-sized `TidbCluster` CR (PD + TiKV + TiDB,
  smallest viable replicas) + `make tidb-up` / `make tidb-down`.
- [ ] **TiDB demo app** — a demo workload that reads its TiDB credentials from
  Vault via an `ExternalSecret`, with an Envoy route and a real Grafana dashboard
  (learning-path step 4).

### Heavy on-demand components (README "Planned" row)
- [ ] **Artifactory or Nexus** artifact registry, on-demand. Pick one; record the
  choice as a new ADR. Manifests + `make` target + docs.
- [ ] **Istio ambient mesh + Kiali**, on-demand. Ambient profile; wire Kiali into
  the Lab UIs panel. Manifests + `make` target + docs + ADR.
- [ ] **Longhorn** distributed block storage, on-demand. Manifests + `make` target
  + docs + ADR.

### Capstone — "tie it together" (learning-path step 5)
- [ ] **End-to-end pipeline** — a GitLab CI pipeline that builds the demo app image
  → pushes to an in-lab registry → ArgoCD deploys it → Envoy routes it → Grafana
  shows its metrics & logs → Vault holds its secrets. Author the pipeline +
  manifests as code; validate clusterless.

### Cross-cutting hardening & quality (always-safe filler)
> Use these when nothing above can be done cleanly in a single run.

- [ ] Audit every workload for resource requests/limits; add the missing ones.
- [ ] Add default-deny `NetworkPolicy` per namespace + the minimal allows each
  component needs.
- [ ] Harden `securityContext` (runAsNonRoot, drop ALL caps, readOnlyRootFilesystem
  where viable) across manifests.
- [ ] Expand `bats` coverage (script guards, drift detectors, uptime-math edges).
- [ ] Add Grafana dashboards/alerts for any always-on component lacking them —
  real metrics only (ADR-0004).
- [ ] Keep `docs/dependency-tree.md` current as components are added.
- [ ] Add an ADR for any new non-trivial decision.

---

## Done
<!-- Autonomous runs: move completed items here with their PR number. -->
- _nothing yet_
