# ROADMAP

The backlog for **k8s-lab**, derived from [CHARTER.md](CHARTER.md) (the north-star this
is projected from) and worked by one scheduled routine: the **executor**, which fires
several times a day (see `routines/routines.yaml` for the current cadence) and
implements ROADMAP items back-to-back for as long as each run continues (STEP 8's loop
— no longer one item per run). The **planner** that proposes items here (plan-only PRs)
has no cron of its own anymore — the executor invokes it as a fallback role (STEP 6b)
whenever its own lane runs dry, which can happen more than once in a single run. CHARTER
= the goals; this file = the next steps.

The always-on stack is already built (Envoy, Vault, External Secrets, Garage,
the full LGTMP observability stack, moto/ACK/KRO, the RabbitMQ + Valkey data layer,
the demo app — ~33 ArgoCD apps). What's left is the heavy *on-demand* components,
the end-to-end capstone, and cross-cutting hardening.

---

## How the executor uses this file

The **executor** routine (several times a day — see `routines/routines.yaml` for the
current cadence) reads this file at the start of every cycle. It has **only this repo** — no access to anyone's local notes — so every rule it
must follow lives here, in `docs/decisions/` (the ADRs), or in
[docs/WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md) (agent governance & review). The
rules below are binding.

1. **One item per PR — but a run keeps going until it's cut off.** Take the single
   topmost unchecked `[ ]` item under *Backlog* (prefer the *Now / next* list). Keep the
   change to one reviewable PR. That PR merging completes one *cycle*, not the whole
   *run* — per `executor.prompt.md` STEP 8, loop back and do the next item, back-to-back.
   The only thing that ends a run is the run itself being cut off by its own resource
   limits ("credit runs out") — not an empty lane, not a fallback role's deliverable, not
   even a cycle whose honest outcome was the idle issue. A run is no longer capped at one
   item; only each PR is, and there is no voluntary stopping point short of running out
   of resources.
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
6. **Every item lands as a PR, self-reviewed and self-merged by the same run** (per
   WAYS-OF-WORKING.md §0.1/§3/§4 — this superseded the old human-merge model on
   2026-07-14; this rule was stale until 2026-07-16 and still said otherwise). One
   branch per item (`auto/<short-slug>`). Title it clearly; the body should say what +
   why and note it's an autonomous run. `make ci` runs on the PR; the executor
   self-reviews it (the `[self-review]` comment), then merges it — CI-green +
   self-review is the gate, not a human click. Never commit straight to a branch
   without opening a PR, and never silently do nothing (see rule #9).
7. **Check it off in the same PR.** Mark the item `[x]` in the backlog, then create
   `docs/done/YYYY-MM-DD-<slug>.md` (today's date + your branch slug) with the full
   item description and the PR number. Do **not** prepend anything to the `## Done`
   section — that section is now just a pointer to `docs/done/`.
8. **If the top item can't be done cleanly, take the next feasible
   item** instead of committing something that fails `make ci`.
9. **Never invent new backlog items. Never go silent. And never declare idle — an
   "idle" GitHub issue/comment is now a forbidden outcome, full stop.** You only
   implement items already listed below; the planner (an executor fallback role, no
   cron of its own — see next section) refills the backlog. But "the Now/next items
   are all gated" is never where a run ends —
   every run lands a PR. This was tried the other way first (issues #52, #56, #57,
   #76, #89, #121, #262, #390, #398 are all "executor idle — needs work" issues that
   piled up instead of shipping work) and the maintainer ended it explicitly
   (2026-07-14): stop opening/commenting on idle issues, every run creates a PR,
   permanently.

   **When `Now / next` is gated, use judgment — weighted toward CHARTER progress, not
   a fixed checklist.** A run on 2026-07-16 found every `Now / next` item gated and
   shipped six real PRs — but all six were test coverage or new drift gates, *zero*
   CHARTER-objective progress, because a prior version of this rule prescribed a rigid
   ordered sequence of named "checks" and coverage/hardening (an inexhaustible, easy
   lane) sat late enough in that sequence to feel like a legitimate stop before ever
   seriously attempting to unblock what the backlog is actually blocked on. Don't
   repeat that: the default move on a gated `Now / next` is to try to **split the
   gate** — carve out whatever part of the topmost gated item does *not* mutate
   live-synced cluster state (CI/build-time config, additive secrets, doc prep,
   manifest scaffolding not yet wired into an auto-synced `Application`) from the part
   that does (an auto-synced Application's image ref, an admission-policy enforcement
   flip — anything ArgoCD would reconcile onto the running cluster on next sync, which
   stays gated). Build and land the safe slice as its own item in this run; mirrors
   RFC #214's cosign split (`auto/cosign-make-up-wiring` + `auto/cosign-ci-sign-step`
   + `auto/cosign-enforce-flip`, only the last slice gated). This is
   executor-sanctioned, same-run work, not planner-only.
   Doc drift, an uncovered `Objective`, an un-RFC'd 🟡 item, an ungroomed issue, a
   script with no bats coverage — all of that is still real, still worth doing, and
   still not an excuse to go idle. But treat it as what it is: filler for when there's
   truly nothing left to push on the actual blockers, not the first place to look. If
   a run genuinely can't find any live-state-safe slice of the gated item worth
   building, say so in the PR body or a `docs/backlog/` note — with the actual
   reasoning, not just "it's all one atomic action" — and only then fall back to the
   rest. Fabricated make-work is still forbidden either way — every item above is
   real, verifiable work, not busywork invented to have something to commit.
10. **A 🟡-tagged item still needs its architect RFC first.** The tag marks an open
    decision, not a permission boundary — build 🟢 items directly. For a 🟡 item with no
    linked RFC yet, don't build around the open question: either author the RFC yourself
    (rule #9 covers writing it, same-run, executor-sanctioned) or open a GitHub issue
    naming the decision needed, then move to the next feasible 🟢 item.
11. **A `maintainer-confirmation prerequisite` item is tracked by a standing
    `[Action required]` GitHub issue, not just prose.** This is a different mechanism
    from rule #9's `[Action needed]` PR fallback — don't conflate them. `[Action
    needed]` PRs are a self-merging breadcrumb for a cycle that found nothing
    buildable at all; they exist and merge in the same run, purely as a record.
    `[Action required]` issues are for the narrower, specific case of a named ROADMAP
    item that's ready to build except for one live-cluster/external-system fact only
    the maintainer can observe (e.g. "did a CI run push a signed image", "does Harbor's
    measured footprint fit the budget") — the issue **stays open**, unmerged, unclosed,
    until the maintainer comments confirmation, so it's visible in the maintainer's
    normal open-issues list rather than buried in merged-PR history. Each such gated
    item names its tracking issue inline (e.g. #631/#632/#633 as of 2026-07-21). When
    picking up a gated item: check its linked issue for a confirmation comment before
    treating the gate as satisfied; if none, skip to the next item as usual (unchanged
    from before). When the gated item finally lands, its PR closes the issue (`Closes
    #NNN`). Never open a *second* standing issue for the same named gate — search
    open issues titled `[Action required]` first, same "search before creating"
    discipline as the `[Action needed]` PR pattern. If a genuinely new
    maintainer-confirmation gate appears on a future item with no issue yet, open one
    following this same shape (title `[Action required] <what to confirm>`, body states
    exactly what to check/run and what it unblocks) rather than falling back to prose
    alone.

---

## Where new items come from — the planner

The executor never invents work — it only implements items already listed below. New
items come from the **planner** role — no cron of its own, invoked as an executor
fallback (STEP 6b) whenever the "Now / next" lane runs dry, which can happen more than
once in a single run now that a run cycles through many items (STEP 8) — that:

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

> **Readiness tags** are tagged inline on every item: **🟢 Green** — ready, the executor
> may build it now; **🟡 Yellow** — blocked on an architect decision, not on any
> permission boundary: it needs an RFC *first* (the architect's RFC is binding, no
> human-approval step), and the planner grooms it into a 🟢 item once decided. *Now /
> next* holds only 🟢 items. There's no third, human-only tag — per
> [WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md) §0.1, no category of repo work is
> reserved for a human.
>
> **Conflict-free editing (binding rule).** Add/edit the discrete 🟡/🟢 **items**
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
> **Status (updated 2026-07-16): O1 and O2 are both done.** All four Tier 1
> next-wave components (Kyverno, Argo Rollouts, Velero, Trivy Operator) are
> long since auto-synced with their own ADR, dashboard, and bats coverage —
> CHARTER.md records O1 as met ahead of its 2026-12-31 date. The O2 tail this
> section used to track (PSS-restricted for `moto`/`ack-system`/`lab-gateway`,
> NP for `tidb`/`tidb-admin`, both coverage-loop recurrence guards) is fully
> checked off below; O2's own `argocd` PSS and `envoy-gateway-system` NP gaps
> closed earlier still. The cloud-control-plane dashboard (O5) shipped too
> (`lab-cloud-control-plane.json`, covering kro+moto+ack-s3). The remaining
> unchecked items in this section are almost entirely **Objective O4** (image
> signing/verification enforcement) plus the ADR-0024 Harbor/Artifactory
> migration and its dependents — see each item's own prerequisite note for
> what it's gated on. When every item here is gated, use rule #9's
> split-the-gate judgment before falling back to coverage/hardening filler —
> don't assume there's nothing left just because the checkboxes are gated.
>
> **WIP / size discipline reminder.** Per WAYS-OF-WORKING.md §3, target ≤ 400
> changed lines per PR. Items below that risk crossing the cap carry a
> "split if oversized" executor note matching the RFC's own split guidance.
>
> _Per-run planner narrative (what was groomed/filed/unblocked each run) lives in
> [`docs/backlog/`](docs/backlog/), one dated file per run — never inline here (see
> the **Conflict-free editing** binding rule above). History through 2026-06-20:
> [`docs/backlog/2026-06-20-planner-note-migration.md`](docs/backlog/2026-06-20-planner-note-migration.md)._

**GitLab → Forgejo migration (ADR-0035, 2026-08-11, superseding ADR-0033) — seven items
(originally six; item 4 split in two on 2026-08-11 per rule #9 below), work
top-to-bottom, each its own PR.** GitLab keeps running unmodified until the last item;
there is no point where the lab loses a working git source or CI path.

- [x] 🟢 **Forgejo compose stack, additive alongside GitLab** — `forgejo/docker-compose.yml`
  (`forgejo` + `forgejo-runner` services, reuse the existing `nginx` TLS-terminator
  pattern from `gitlab/docker-compose.yml`), `make forgejo-up`/`forgejo-down` targets,
  `tests/forgejo-compose.bats`. Zero risk to the current CI path — GitLab is untouched.
  No prerequisites, executor may pick up immediately. (feat/forgejo-compose-stage1, #1105)
- [x] 🟢 **`infra/modules/forgejo-config` Terraform module** — org/repo/branch-protection/
  deploy-token resources via `svalabs/terraform-provider-forgejo` (or
  `adyxax/terraform-provider-forgejo` if its resource coverage fits better — check both
  before committing), `infra/live/{local,oracle}/forgejo/`. Parallels `gitlab-config`.
  Prerequisite: previous item (needs a live Forgejo instance to point Terraform at).
  (auto/forgejo-config-terraform-module)
- [x] 🟢 **Port `.gitlab-ci.yml` → `.forgejo/workflows/build-sign-push.yml`** — same
  build → `cosign sign` → push-to-Harbor job (ADR-0011/ADR-0024). Verify live (ADR-0004):
  a real pipeline run must push a genuinely signed image to Harbor, not just parse.
  Prerequisite: previous item. (auto/forgejo-ci-workflow)
- [x] 🟢 **Wire ArgoCD's repo-credential Secret for the Forgejo remote (prep slice)** —
  split from this list's original single item via ROADMAP rule #9's split-the-gate
  judgment (2026-08-11, reached via `executor.prompt.md` STEP 3 — this was the
  topmost unchecked item and no open PR claimed it): repointing `Application`
  `repoURL`s (including `root-app.yaml`, the always-on-synced app-of-apps entrypoint)
  is exactly the live-reconcile-affecting "flip" rule #9 says must stay gated for a
  clusterless session — ArgoCD would attempt to re-sync every Application from
  Forgejo on the next live reconcile, and neither the Forgejo repo's content (no
  `forgejo-push` mechanism exists yet — that's item 5, below) nor its CI/runner
  (item 3's own docs/done record: unverified) are confirmed live-working. Building
  that flip anyway would risk the same fleet-wide blast radius the cosign
  `enforce-flip` slice was split out to avoid (RFC #214 precedent, cited by this
  list's own item 3). What *is* safe and additive: `infra/modules/forgejo-config`'s
  `kubernetes_secret.argocd_repo` resource (SSH-keyed, named `repo-forgejo-gitops` —
  distinct from the still-used `repo-gitlab-gitops`) plus the `repo_url_in_cluster`/
  `argocd_namespace` variables and both live Terragrunt units' `kubernetes` provider
  wiring, all parallel to the predecessor module's own resource shape. No
  `gitops/**/*.yaml` Application references the new URL yet, so this is inert until
  the next item flips it — `make ci` (kubeconform, kustomize, terraform fmt/validate,
  bats) confirms the module is well-formed without needing a live cluster.
  (auto/forgejo-argocd-repo-secret)
- [ ] 🟢 **Flip `Application` `repoURL`s (including `root-app.yaml`) to the Forgejo
  remote, verify a real sync** — the gated slice split out of the item above. Needs,
  in order: (1) Forgejo's actual repo content pushed (no automated mechanism yet —
  can be done with a manual `git remote add`/`git push` even before item 5's renamed
  script exists), (2) `infra/modules/forgejo-config` `terraform apply`'d so the
  `repo-forgejo-gitops` Secret exists in-cluster, (3) `.forgejo/workflows/
  build-sign-push.yml` (item 3) confirmed running for real. Only a live-cluster
  session can do all three and then verify ArgoCD's actual sync status — a
  clusterless remote session must not flip this and merely hope. Prerequisite:
  previous item (this one) and, functionally, item 3's live verification.
- [ ] 🟢 **Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh` + matching `Makefile`
  targets** (bootstrap, TLS bootstrap, push, force-push, `rebase-prs`' GitLab leg);
  `tests/gitlab-compose.bats`/`tests/gitlab-push.bats` → `forgejo-*` bats files with
  equivalent coverage (mechanical-guard parity, not a regression). Prerequisite: previous
  item — don't rename the scripts the still-live pipeline depends on before the CI-workflow
  and repoURL-flip items above land and are verified live.
- [ ] 🟢 **Decommission `gitlab/docker-compose.yml` + `infra/modules/gitlab-config`** —
  only once every item above is verified live and stable for a real work cycle, matching how
  Artifactory's decommission followed (not preceded) Harbor's proven-live cutover
  (`docs/done/2026-07-29-harbor-artifactory-decommission.md`). Update
  `docs/dependency-register.md`'s GitLab row (currently flagged "still the live, running
  component" pending this) to a Forgejo row once this lands.

- [x] 🟢 **Vault pod-readiness alert rule — extend Grafana Unified Alerting (RFC #1084)**
  (CHARTER **Core Values** §"operational-resilience discipline"; planner-fallback gap
  analysis 2026-08-11, reached via `executor.prompt.md` STEP 6b, PLANNER role — the
  three standing Now/next migration items above remain gated on unconfirmed
  maintainer-confirmation issues #631/#633, and this run's own sweep found no
  un-RFC'd 🟡 item and no other lane holding an unpromoted item. **No prerequisites —
  executor may pick up immediately.**) `docs/dora-audit-readiness.md` Q7's own gap
  line names this exact hole: "Vault sealed has no metric to alert on at all, since
  Vault isn't currently scraped by Alloy... A future item could add a Vault-health
  scrape job + alert rule if that gap is worth closing." Verified directly (not
  assumed, ADR-0004): `gitops/platform/observability-alloy.yaml` has no
  `prometheus.scrape "vault"` block (grepped every `prometheus.scrape` name in the
  file — 25 jobs, none named vault); RFC #1084's four rules
  (`gitops/platform/observability-grafana.yaml` `valuesObject.alerting`) cover
  ArgoCD health/sync, `kube_deployment_*` replica availability, and PVC phase — none
  scoped to Vault, and Vault runs as a `StatefulSet` (`server.statefulSet` in
  `gitops/platform/vault.yaml`), which `DeploymentReplicasUnavailable`'s
  `kube_deployment_*` metric family structurally cannot match regardless of label
  selectors. This is a real, previously-lived incident, not speculative: the
  `vault-unsealer`'s own header comment (`gitops/vault/unsealer.yaml`) documents
  Vault staying sealed for 4+ days after a 2026-07-29 outage, "silently breaking
  every ExternalSecret refresh cluster-wide... but nothing surfaced that anywhere
  visible" — exactly the detection gap this item closes, using a metric already
  scraped today (no new scrape job needed, unlike the audit doc's own suggested
  shape): `kube_state_metrics` already emits `kube_pod_status_ready` for every pod
  via the existing `ksm` scrape job (`observability-alloy.yaml`).

  Add a fifth rule to `gitops/platform/observability-grafana.yaml`'s existing
  `alerting.rules.yaml.groups[0].rules` list (same `lab-alerts` group, same
  threshold-over-instant-Mimir-query shape as the other four — refId A queries
  Mimir, refId B is a `threshold` expression `gt 0`, `noDataState: NoData`,
  `execErrState: Error`, `datasourceUid: mimir`): `uid: vault-pod-not-ready`,
  `title: VaultPodNotReady`, `for: 10m` (matches the other three non-OutOfSync
  rules' cadence), `expr: kube_pod_status_ready{namespace="vault",
  pod=~"vault-[0-9]+", condition="true"} == 0` — the `pod=~"vault-[0-9]+"` regex
  scopes the rule to the Vault server StatefulSet pod (`vault-0`) specifically,
  excluding the separate `vault-unsealer` Deployment pod in the same namespace
  (label `app: vault-unsealer`, pod name prefix `vault-unsealer-`, which the regex
  does not match) — alerting on the unsealer's own liveness would be a different,
  narrower signal than "is Vault itself serving," and conflating the two would
  misattribute which component actually failed. `annotations.summary`: "The Vault
  server pod has not been Ready for 10+ minutes (sealed, crashed, or otherwise
  unreachable)." No `contactPoints`/notification receiver — stays visual-only per
  RFC #1084's own decision, unchanged by this item.

  Extend `tests/observability-alerting.bats` (the per-scope alerting file, not the
  frozen `observability.bats` monolith): new assertion for
  `title: VaultPodNotReady` + its exact `expr:`; bump the existing `'for: 10m'`
  count assertion from `3` to `4` (this rule adds a fourth 10m-duration rule) and
  the existing `'datasourceUid: mimir'` count assertion from `4` to `5` — both
  existing count-based tests, not new ones, so this is a real regression risk if
  left unbumped (`make ci` would fail red on the count mismatch, catching it).
  Update `docs/dependency-tree.md`'s Vault sub-graph with a one-line note that
  Vault's pod-readiness is now alerted on via the existing KSM scrape (no new
  scrape target). `make ci` must pass — this is a structural YAML + bats change,
  no live cluster needed to confirm the rule's shape matches the other four.
  PR body must document the ADR-0004 caveat that this remote clusterless session
  cannot verify the rule actually fires against a live sealed Vault, and note the
  rollback path (delete the `vault-pod-not-ready` rule block; ArgoCD syncs the
  removal within 30s, same as any other alerting.yaml edit, per RFC #1084's own
  rollback precedent). `docs/done/` entry required. (auto/vault-pod-readiness-alert)

- [x] 🟢 **k3d containerd registry mirror — resolve `harbor.127.0.0.1.nip.io` in-cluster**
  (CHARTER **Core Values** §"Recreate-from-code" (`make up` should let the capstone demo
  actually run) + §"Images are signed and verified" (O4's admission-signing chain needs a
  real image to reach the pod before it's exercisable at all); planner gap-analysis
  2026-08-07, reached via `executor.prompt.md` STEP 6b — Now/next's three standing items
  remain gated on unconfirmed maintainer-confirmation issues #631/#633/#1034 (re-checked
  this cycle, unchanged), and this run's own sweep found no un-RFC'd 🟡 item and no later
  section holding an unpromoted item — this is fresh gap-analysis, not a promotion. **No
  prerequisites — executor may pick up immediately** (this item is orthogonal to the
  live-cluster confirmation #631/#633 need; it fixes a structural bug that *causes* part
  of what's blocking them, but doesn't require the cluster to be up to write correctly).
  Source: issue #633's 2026-08-07 00:11 UTC comment (a live-cluster session), which found
  that once Kargo's Warehouse resource finally validated for the first time, artifact
  discovery immediately failed with `dial tcp 127.0.0.1:443: connect: connection refused`
  resolving `harbor.127.0.0.1.nip.io` — and separately confirmed the capstone Rollout/
  Deployment pod has been stuck `ImagePullBackOff` on the identical error the entire time
  (117+ minutes old at observation, pre-existing, unrelated to that session's other
  fixes). Root cause, verified directly in this repo (not assumed, ADR-0004): `nip.io`
  is a wildcard DNS service that resolves `<anything>.<IP>.nip.io` to the literal `<IP>`
  embedded in the hostname, regardless of *where* the DNS query originates — so
  `harbor.127.0.0.1.nip.io`, which correctly means "the Colima host" from *outside* the
  cluster (where a human's browser or `curl` runs), means "this pod's own loopback"
  from *inside* any pod. `gitops/apps/capstone/deployment.yaml` and
  `gitops/apps/capstone/rollout.yaml` both pull `image:
  harbor.127.0.0.1.nip.io/library/hello:latest` (grepped directly), and
  `gitops/kargo-project/project.yaml`'s Warehouse subscribes to the same
  `harbor.127.0.0.1.nip.io/library/hello` repoURL for digest discovery — every one of
  these is an in-cluster containerd/Kargo-controller pull, not a browser request, so all
  three hit this bug identically. This is a structural, environment-wide gap (any future
  on-demand component whose manifests reference a `*.127.0.0.1.nip.io` image host would
  hit the same wall), not a one-off capstone bug.

  Fix: add a k3d **containerd registry mirror** so in-cluster pulls of
  `harbor.127.0.0.1.nip.io` transparently redirect to Harbor's real in-cluster Service —
  `harbor.harbor.svc.cluster.local` port 80 (confirmed directly: `gitops/harbor/route.yaml`
  backendRefs the `harbor` Service in the `harbor` namespace on port 80, which
  `gitops/harbor/networkpolicy/allow-harbor-ingress.yaml`'s own comment confirms
  targetPorts to the `harbor-nginx` container's 8080, TLS disabled per ADR-0024 §"Minimal
  profile" `expose.tls.enabled: false` — so the mirror endpoint is plain HTTP, no cert
  needed). Edit `infra/modules/k3d-cluster/k3d-config.yaml.tftpl`: add a top-level
  `registries:` block (k3d's Simple-config field, independent of the existing
  `options:`/`ports:` blocks — no conditional needed, always include it, mirrors the
  unconditional `ports:` block already in this file) with inline `config:` content
  matching containerd's own `registries.yaml` mirror shape:
  ```yaml
  registries:
    config: |
      mirrors:
        "harbor.127.0.0.1.nip.io":
          endpoint:
            - "http://harbor.harbor.svc.cluster.local"
  ```
  Add a code comment above it explaining the nip.io loopback problem (mirrors this item's
  own reasoning, so a future reader doesn't need to rediscover it) and noting that Harbor
  is itself on-demand (ADR-0024) — this mirror sits inert, harmlessly, whenever Harbor
  isn't running; it only matters once `make harbor-up` is used. Scope note: the Oracle
  backend (`infra/modules/oracle-k3s-cluster`) is explicitly **out of scope** for this
  item — per ROADMAP's own existing note (`infra/live/README.md` "Status" section), that
  backend has never actually been deployed, so there is nothing live to fix there yet;
  file a follow-up when it is.

  New `tests/k3d-registry-mirror.bats` (clusterless, structural — mirrors
  `tests/k3s-version-pin.bats`'s file-content-assertion pattern): the tftpl contains a
  top-level `registries:` key; the mirror block names
  `"harbor.127.0.0.1.nip.io"`; the endpoint is `http://harbor.harbor.svc.cluster.local`
  (not `https://`, matching Harbor's TLS-disabled minimal profile); a recurrence guard
  that the endpoint is NOT `127.0.0.1` (the exact bug this item fixes — same
  "does not pin/contain the stale value" shape as this repo's other version-pin test
  pairs). Update `docs/dependency-tree.md`'s Harbor/capstone sub-graph with a one-line
  note that in-cluster pulls of `harbor.127.0.0.1.nip.io` resolve via a k3d containerd
  mirror to the real Service, not via nip.io DNS. `make ci` must pass (this is a
  `terraform validate`/`fmt`-checked template plus a new bats file — no live k3d cluster
  needed to confirm the YAML is well-formed and the mirror block is present and correctly
  shaped). PR body must document the root-cause finding above and the ADR-0004 caveat
  that this remote clusterless session cannot verify the mirror actually redirects a real
  containerd pull on a live cluster — call out the rollback path (revert the `registries:`
  block; the next `k3d cluster create`/`terraform apply` for a fresh cluster reverts to
  unmirrored pulls; existing clusters would need `k3d cluster delete && terraform apply`
  to pick up the change, since k3d has no in-place registries-reload — note this plainly,
  it is the same "cluster recreate" cost every other k3d-config.yaml.tftpl change in this
  repo already carries) and a note asking the maintainer to retry #631's/#633's pipeline
  run only *after* this lands and a cluster recreate has picked it up, since it removes a
  root cause those issues' own comments trace their most recent blocker to. `docs/done/`
  entry required. (auto/k3d-registry-mirror-harbor)

- [x] 🟢 **Bump Terraform-bootstrapped `argo-cd` chart `10.2.3` → `10.3.0`**
  (CHARTER **Core Values** §"Everything as code" + general hardening;
  planner-fallback upstream check 2026-08-06, reached via
  `executor.prompt.md` STEP 6b after Now/next's three standing items were
  found gated (unchanged) on unconfirmed maintainer-confirmation issues
  #631/#633. **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): `git ls-remote --tags
  argoproj/argo-helm` shows `argo-cd-10.3.0` one release ahead of
  `infra/modules/argocd/variables.tf`'s pinned `chart_version` default
  `"10.2.3"` (the bump this same file's `auto/argocd-chart-10-2-3` item
  landed 2026-08-05). A full clone diff (`git diff argo-cd-10.2.3
  argo-cd-10.3.0 -- charts/argo-cd/`) touches exactly three lines across
  three files: `Chart.yaml` (`version` 10.2.3→10.3.0 only — `appVersion`
  stays `v3.5.0`, so this is **not** an ArgoCD version bump, only a chart
  packaging bump) and its `artifacthub.io/changes` annotation; `README.md`'s
  auto-generated table; and `values.yaml`'s bundled `redis.image.tag`
  (`8.2.3-alpine` → `8.6.4-alpine`, the chart's own mandatory Redis
  dependency used for ArgoCD's API-server cache — unrelated to ADR-0018's
  Valkey decision per the existing header comment in
  `infra/modules/argocd/values.yaml`, which this bump doesn't touch). Zero
  CRD changes, zero other `values.yaml` changes — confirmed RFC #785's
  `global.networkPolicy.create: false` companion override
  (`infra/modules/argocd/values.yaml`) stays correct: the chart's own
  `global.networkPolicy.create` default is unchanged (`true`) in both
  10.2.3 and 10.3.0, so the repo's override is still needed and still
  applies untouched.

  Because `appVersion` doesn't move, there is no ArgoCD upgrade guide to
  re-check (unlike the 10.2.2→10.2.3 minor bump, which required reading
  ArgoCD's `3.4-3.5` upgrade doc) — this is the smallest possible currency
  delta: a same-appVersion chart repackage bumping one bundled dependency's
  patch tag.

  Bump `infra/modules/argocd/variables.tf`'s `chart_version` default
  `"10.2.3"` → `"10.3.0"` (inline comment already reads `"10.2.3 => ArgoCD
  v3.5.0"` — update only the chart-version half to `"10.3.0 => ArgoCD
  v3.5.0"`, appVersion unchanged). Update both
  `infra/live/local/argocd/terragrunt.hcl` and
  `infra/live/oracle/argocd/terragrunt.hcl`'s `chart_version = "10.2.3"`
  input to `"10.3.0"` (both must move together with the module default —
  RFC #785's own recurrence-guard rationale for why all three sites are
  checked in the same bats file). Update `tests/argocd-chart-pin.bats`'s
  three assertions (`chart_version` default, both terragrunt.hcl inputs)
  from `10.2.3` to `10.3.0`. No `docs/dependency-tree.md` or `context.md`
  update needed — neither cites this chart's specific version (checked
  directly). Update `docs/dependency-register.md`'s ArgoCD row "Last
  reviewed" cell to cite this bump. `make ci` (specifically `terraform
  validate`/`fmt`, clusterless — this Terraform-bootstrap seam needs no live
  OCI/cloud credentials per ADR-0001) must pass. PR body must document the
  three-line upstream diff above and the ADR-0004 caveat that this remote
  clusterless session cannot verify a real `terraform apply` against this
  pin succeeds end-to-end — call out the rollback path (revert the three
  pins; the next `terraform apply` re-installs the prior chart version;
  ArgoCD's own state — Applications, RBAC, repo credentials — lives in the
  `argocd` namespace's Secrets/ConfigMaps on the cluster, untouched by a
  chart-version revert in the bootstrap module). `docs/done/` entry
  required. (auto/argocd-chart-10-3-0)

- [x] 🟢 **Bump Trivy Operator chart `0.34.0` → `0.35.0` (appVersion `0.32.0` →
  `0.33.0`, bundled Trivy scanner `0.72.0` → `0.73.0`)** (CHARTER **Objective O1**
  + **Core Values** §"Everything as code" + general hardening; executor-fallback
  currency sweep 2026-08-07, reached via `executor.prompt.md` STEP 6b after
  Now/next's three standing items were re-checked and found still gated
  (unchanged) on unconfirmed maintainer-confirmation issues #631/#633, and this
  same run's first cycle (`auto/argocd-chart-10-3-0`) already claimed the
  ArgoCD chart gap a prior planner-fallback cycle surfaced. This cycle's fresh
  angle: `docs/dependency-register.md`'s per-component "Last reviewed" column
  flagged Trivy Operator's 2026-07-28 entry as the most stale among the four
  CHARTER O1 next-wave components (Kyverno 07-29, Argo Rollouts 07-20 flip-met,
  Velero 07-29, Trivy Operator 07-28 — all older than this run's date). **No
  prerequisites — executor may pick up immediately.**) Verified directly (not
  assumed, ADR-0004): `aquasecurity/helm-charts`' `main` branch no longer
  carries chart source (the repo migrated to a chart-releaser flow that
  publishes packaged `.tgz` release assets + a `gh-pages` Helm-repo index
  instead of per-tag directories) — verification here downloaded and
  `diff -ru`'d the two real release tarballs
  (`trivy-operator-0.34.0.tgz`/`trivy-operator-0.35.0.tgz`) directly rather
  than a git-tag diff. The `gh-pages` index shows `trivy-operator-0.35.0`
  published 2026-08-06T03:12:49Z, one release past the pinned `0.34.0`.

  The tarball diff touches exactly: `Chart.yaml`'s `version`/`appVersion`
  fields (`0.34.0`→`0.35.0`, `appVersion` `0.32.0`→`0.33.0`), the generated
  `README.md` badges/table for the same, and the bundled `trivy.image.tag`
  default (`0.72.0`→`0.73.0`, in both `values.yaml` and the README row) — plus
  the same version-label bump repeated across five `templates/specs/*.yaml`
  compliance-scan CronJob manifests (label only, not behavior). No other
  `values.yaml` key changed shape — every key this lab's `valuesObject` sets
  (`operator.*`, `trivy.resources`/`storageClassName`/`storageSize`,
  `nodeCollector.*`) is present and unchanged. A real clone's `git log
  v0.32.0..v0.33.0` (trivy-operator app repo) shows 4 commits: 2 routine
  dependency bumps and the `trivy` scanner version bump itself. The bundled
  scanner bump (`v0.72.0`→`v0.73.0`, `aquasecurity/trivy`) carries two real
  detection-accuracy fixes: `fix(vuln): don't skip packages covered by a
  driver's own advisory feed` (#10980) and `fix(vex): reject non-local VEX
  repository names` (#10987) — the same "ships with a real fix" bar this
  repo's other non-CVE currency bumps (e.g. Loki's ingester flush-race fix)
  use. Does not affect ADR-0022's existing March-2026 Trivy supply-chain
  compromise finding (`v0.69.4` is still the only affected tag; `0.73.0`
  postdates it by many releases).

  Bump `gitops/platform/trivy-operator.yaml`'s `targetRevision: 0.34.0` →
  `0.35.0`. Update `tests/trivy-operator.bats`'s pin assertion to `0.35.0` and
  add a "does not pin the stale `0.34.0` chart" recurrence guard (mirrors this
  repo's other exact-version-pin test pairs). Update
  `docs/dependency-tree.md`'s Trivy Operator citation (`v0.34.0`→`v0.35.0`).
  Update `docs/dependency-register.md`'s Trivy Operator row "Last reviewed"
  cell. Add a new dated entry to
  [ADR-0022](docs/decisions/adr-0022-trivy-operator-supply-chain.md)'s `##
  Re-evaluation log` documenting the findings above and reconfirming the
  supply-chain-compromise finding is unaffected. No `context.md` update
  needed — it doesn't cite this chart's specific version (checked directly).
  `make ci` must pass. PR body must document the tarball-diff findings above
  and the ADR-0004 caveat that this remote clusterless session cannot verify
  the operator reconciles cleanly and continues scanning post-bump on a live
  cluster — call out the rollback path (revert `targetRevision`; ArgoCD
  re-syncs the prior chart version on next reconciliation; the operator is
  stateless apart from its ephemeral vuln-DB cache PVC, so a rollback recovers
  immediately with no data loss). `docs/done/` entry required.
  (auto/trivy-operator-chart-0-35-0)

- [x] 🟢 **Bump Grafana image tag `13.0.3` → `13.0.5` (security fix) + correct
  ADR-0006's stale Tempo pin citation** (CHARTER **Core Values** §"Everything as
  code" + general hardening; planner-fallback currency sweep 2026-08-06,
  second pass this run, reached via `executor.prompt.md` STEP 6b — Now/next's
  three standing items remain gated on unconfirmed maintainer-confirmation
  issues #631/#633 (re-checked this cycle, unchanged). This cycle's angle
  (deliberately different from the immediately-prior cycle's Loki-only
  re-check, per rule #9/STEP 8's "widen the lens" guidance): a batch
  `git ls-remote --tags` sweep of every GitHub-hosted `image:` pin under
  `gitops/` not yet re-checked this run (Mimir, Grafana's `image.tag` override,
  RabbitMQ, Valkey) — Mimir (`3.1.4`), RabbitMQ (`4.3.4`), and Valkey (`8.0.10`)
  are all already the newest tag on their respective pinned lines (no gap);
  Grafana's `image.tag` override (`13.0.3`, tracked separately from the chart's
  own `targetRevision` per ADR-0006) is one line behind. **No prerequisites —
  executor may pick up immediately.**) Verified directly (not assumed,
  ADR-0004): a real clone of `github.com/grafana/grafana` shows `v13.0.5` as
  the newest tag on the `13.0.x` line (no minor/major jump — `13.1.x` exists
  but per ADR-0006's own precedent a chart/version-line jump needs its own
  deeper diligence, not bundled into a routine patch bump). `git log
  v13.0.3..v13.0.5 --no-merges` (37 commits) contains one explicitly
  `[release-13.0.4] Security:` tagged commit: "Bump go-pkcs12 to v0.7.2
  (GO-2026-5052)" — fixes GHSA-mpwr-8vm7-h73f, a PKCS#12 password
  authentication bypass in `software.sslmate.com/src/go-pkcs12` (affected
  v0.6.0–v0.7.2-minus-fix, pulled in transitively via `grafana-azure-sdk-go`).
  This satisfies ADR-0006's own Grafana flip condition ("advisory naming a
  version at or above the current pin") the same way the 2026-07-19 CVE bump
  did. `git diff v13.0.3 v13.0.5 -- packaging/docker/` is **empty** — the
  Docker image's `run.sh`/`Dockerfile` are byte-identical across the whole
  range, so the existing ADR-0006 packaging-verification analysis (read-only-root
  write paths, entrypoint behavior) carries forward unchanged, no re-diffing
  needed beyond confirming the diff is empty (which it is).

  Also corrects a **log-drift gap** found while re-checking Tempo as part of
  this same sweep (mirrors the exact pattern the 2026-08-06 Loki entry caught
  for its own pin): ADR-0006's last two dated entries (2026-07-28, 2026-08-06)
  both still cite Tempo's pin as `2.10.5`, but the live pin in
  `gitops/observability/tempo/deployment.yaml` is already `2.10.7` — confirmed
  via `git ls-remote --tags grafana/tempo` that `2.10.7` is the current newest
  `2.10.x` tag, so the **live pin itself is correct and current**, only the
  ADR's own tracking log lagged behind an earlier, undocumented bump (same
  class of gap as Loki's `3.7.2`→`3.7.4` catch-up note). No code change needed
  for Tempo — this is a pure record correction, noted honestly in the new ADR
  entry rather than silently re-dating the old ones.

  Bump `gitops/platform/observability-grafana.yaml`'s
  `valuesObject.image.tag: "13.0.3"` → `"13.0.5"` **and** the `ca-bundle`
  `extraInitContainers` entry's `image: docker.io/grafana/grafana:13.0.3` →
  `:13.0.5` (both must move together — same pin, same CVE analysis, mirrors
  how the 2026-07-19 bump kept them in lockstep). Update the adjacent comment
  block (lines ~29–34) to cite `13.0.5` and this bump's CVE. Update
  `tests/observability-grafana.bats`'s two exact-version-pin assertions
  (`image.tag` + ca-bundle init container) to `13.0.5`. Update
  `docs/decisions/context.md`'s "Grafana 13.0.3 on `kubernetesDashboards`"
  citation to `13.0.5` (required — `make context-doc-version-sync-check`
  mechanically enforces this). Add a new dated entry to
  [ADR-0006](docs/decisions/adr-0006-grafana-native-git-sync.md)'s
  `## Re-evaluation log` documenting both the Grafana CVE bump and the Tempo
  log-drift correction above, with a new flip condition ("revisit when a new
  advisory names a version at or above `13.0.5`"). No `docs/dependency-tree.md`
  update needed — it doesn't cite Grafana's specific image tag (checked
  directly). `make ci` must pass. PR body must document the CVE finding, the
  empty packaging diff, the Tempo log-drift correction, and the ADR-0004
  caveat that this remote clusterless session cannot verify Grafana starts
  cleanly and Git Sync/dashboard provisioning continues working post-bump on a
  live cluster — call out the rollback path (revert both `image:` references;
  Grafana's chart Application syncs via ArgoCD, so a revert takes effect on
  the next automated sync; Grafana's session/dashboard state lives on its PVC,
  untouched by an image-tag change). `docs/done/` entry required.
  (auto/grafana-image-13-0-5)

- [x] 🟢 **Bump Loki image `grafana/loki:3.7.5` → `3.7.6`** (CHARTER **Core
  Values** §"Everything as code" + general hardening; planner-fallback currency
  sweep 2026-08-06, reached via `executor.prompt.md` STEP 6b — Now/next's three
  standing items remain gated on unconfirmed maintainer-confirmation issues
  #631/#633 (re-checked this cycle: latest comments on both, 2026-08-06 07:38 UTC,
  still report the same live-cluster blocker, no maintainer confirmation). This
  cycle's angle: re-running the same per-`image:`-line inventory the prior
  `3.7.4`→`3.7.5` bump (merged today) used turned up a brand-new `3.7.6` tag —
  published *today*, after that bump already merged, so it's a genuinely fresh
  gap, not a miss by the prior sweep. **No prerequisites — executor may pick up
  immediately.**) Verified directly (not assumed, ADR-0004): a real clone of
  `github.com/grafana/loki` (`git ls-remote --tags` / `git log
  v3.7.5..v3.7.6`) shows `v3.7.6` as the newest tag on the `3.7.x` line (no
  major/minor jump; next-newest after that is unreleased). The Docker Hub tags
  API for `grafana/loki` confirms the `3.7.6` image itself is published
  (multi-arch manifest, pushed 2026-08-06) — not just a source-repo tag with no
  matching image. Two substantive commits in the range (a third is the
  `3.7.5` release-bump commit itself, mechanically re-listed by git's ref
  math, not new content): a docs backport, and a real bug fix
  `fix(queryrange): Preserve sketch in MergeLabels [release-3.7.x]` (#23770) —
  a query-correctness fix in `pkg/storage/detected/labels.go` (topk/sketch
  merging for detected-labels queries returned wrong results without it). No
  `[SECURITY]`-tagged commit this time, but a real, verified correctness fix on
  the exact patch line this lab already tracks is the same bar the prior
  `3.7.4`→`3.7.5` bump used for its own non-CVE commit
  (`fix(ingester): Fix flush race`) — smallest-safe-delta, not a blind patch
  assumption.

  Bump `gitops/observability/loki/deployment.yaml`'s `image: grafana/loki:3.7.5`
  → `grafana/loki:3.7.6`. Update `tests/observability-loki.bats`'s assertion to
  `3.7.6` and flip its "does not pin the stale tag" guard to check for `3.7.5`
  (mirrors the exact-version-pin test-pair pattern this file itself just
  demonstrated). Add a new dated entry to
  [ADR-0006](docs/decisions/adr-0006-grafana-native-git-sync.md)'s
  `## Re-evaluation log` (after the existing 2026-08-06 `3.7.4`→`3.7.5` entry)
  recording this bump the same way. `make ci` must pass. `docs/done/` entry
  required. (auto/loki-3-7-6 or upgrade/loki-3-7-5-to-3-7-6)

- [x] 🟢 **Bump Loki image `grafana/loki:3.7.4` → `3.7.5`** (CHARTER **Core
  Values** §"Everything as code" + general hardening; this run's second-cycle
  currency sweep 2026-08-06, reached via `executor.prompt.md` STEP 6b — Now/next's
  three items remain gated on #631/#633 (re-checked this cycle, unchanged), this
  same run's first cycle's PLANNER/ARCHITECT fallback passes found no ungroomed
  issues, no un-RFC'd 🟡 items, and resolved the only fresh ADR-audit trigger found
  (ADR-0032, TiDB) already. This cycle's fresh angle: a full inventory of every
  `image:` line under `gitops/` — not just ArgoCD `Application` `targetRevision`s,
  which the day's earlier sweeps focused on — surfaced a one-patch-behind Loki pin.
  **No prerequisites — executor may pick up immediately.**) Verified directly (not
  assumed, ADR-0004): `git ls-remote --tags grafana/loki` shows `v3.7.5` as the
  newest tag on the `3.7.x` line this lab already runs (no major/minor jump). A
  real clone's `git log v3.7.4..v3.7.5` (25 commits) shows six `[SECURITY]`-tagged
  dependency-CVE fixes (`klauspost/compress` → `v1.18.7` ×3 module paths,
  `golang.org/x/text` → `v0.39.0` ×2, `go.opentelemetry.io/otel` → `v1.42.0`,
  `google.golang.org/grpc` → `v1.82.1`) plus a real reliability fix
  (`fix(ingester): Fix flush race in ingester`, #23682) — the same "ships with a
  security fix" flip-condition standard this repo's k3s (RFC #995) and Vault
  (2026-08-05) bumps used, not a blind patch assumption. This also catches up a
  small pre-existing gap: the live pin had already moved `3.7.2` → `3.7.4` since
  [ADR-0006](docs/decisions/adr-0006-grafana-native-git-sync.md)'s last dated log
  entry (2026-07-28, which still cited `3.7.2`) without a matching log update or
  `docs/done/` record — noted honestly in the ADR's new entry rather than silently
  re-dated.

  Bump `gitops/observability/loki/deployment.yaml`'s `image: grafana/loki:3.7.4`
  → `grafana/loki:3.7.5`. Update `tests/observability-loki.bats`'s assertion to
  `3.7.5` and add a "does not pin the stale `3.7.4` tag" recurrence guard (mirrors
  this repo's other exact-version-pin test pairs, e.g. `ack-s3.bats`). Add a new
  dated entry to ADR-0006's `## Re-evaluation log` (after the existing 2026-07-28
  entry) recording the security-fix findings above, the log-drift note, and a new
  flip condition for the next audit ("revisit when a new advisory/fix range names
  a version at or above `3.7.5` as affected"). No `docs/dependency-tree.md` update
  needed — it doesn't cite Loki's specific version (checked directly). `make ci`
  must pass. PR body must document the security-fix findings above and the
  ADR-0004 caveat that this remote clusterless session cannot verify Loki starts
  cleanly and continues ingesting logs post-bump on a live cluster — call out the
  rollback path (revert the `image:` tag; Loki is a plain `Deployment`, not an
  ArgoCD-templated Helm release, so a revert takes effect on the next manual
  apply/GitOps sync; no data loss either way since Loki's log storage lives in
  Garage S3, untouched by an image-tag change). `docs/done/` entry required.
  (auto/loki-image-3-7-5)

- [x] 🟢 **Bump `kube-state-metrics` chart `8.0.0` → `8.1.3`** (CHARTER **Core
  Values** §"Everything as code" + general hardening; planner-fallback upstream
  check 2026-08-05, reached via `executor.prompt.md` STEP 6b, Now/next starved
  by #631/#633 (re-checked this run, no new comment) — this run's chart-currency
  sweeps to date had checked `harbor`, `kiali`, `kro`, `argo-rollouts`,
  `envoy-gateway`, `pyroscope`, `node-exporter`, `velero`, `grafana`, `ack-s3`,
  `argo-cd`, `cilium` but never `kube-state-metrics` — this pass closed that
  gap. **No prerequisites — executor may pick up immediately.**) Verified
  directly (not assumed, ADR-0004): a real clone of
  `github.com/prometheus-community/helm-charts` (the `repoURL`
  `gitops/platform/observability-ksm.yaml` actually uses) shows
  `kube-state-metrics-8.1.3` as the newest stable tag, three minor/patch
  releases past this lab's pinned `8.0.0` (`8.1.0`, `8.1.1`, `8.1.2`, `8.1.3`,
  no pre-release beyond it). `git diff kube-state-metrics-8.0.0
  kube-state-metrics-8.1.3 -- charts/kube-state-metrics/Chart.yaml` shows
  `appVersion: 2.19.1` **unchanged** at both tags — the underlying
  kube-state-metrics binary this lab runs does not change at all; this is a
  packaging-only bump, the same smallest-safe-delta pattern as the
  Grafana/Harbor/cert-manager/Kiali/kro precedents already in `## Done`.
  `git log kube-state-metrics-8.0.0..kube-state-metrics-8.1.3 --
  charts/kube-state-metrics/` shows 4 commits: two purely additive
  (`collectorsExclude`/`collectorsExtra` values + a `nameOverride`/
  `fullnameOverride` doc comment) and one CI-testing-only change — no `values.yaml`
  key this lab's `valuesObject` sets (`fullnameOverride`, `securityContext.*`,
  `containerSecurityContext.*`, `resources.*`) was renamed or removed. The
  `role.yaml`/`deployment.yaml` diff (`$.Values.collectors` →
  `$activeCollectors`, a helper that layers the new
  `collectorsExclude`/`collectorsExtra` on top of `.Values.collectors`) is a
  behavior-preserving refactor: this lab's Application sets neither new key, so
  `$activeCollectors` resolves to the exact same list `.Values.collectors` did
  before — RBAC rules and the `--resources` flag are unchanged for this lab's
  config. No breaking changes in the range.

  Bump `gitops/platform/observability-ksm.yaml`'s `targetRevision: 8.0.0` →
  `8.1.3`. Re-verify directly at pickup time that the `8.1.3` chart's
  `values.yaml` still contains every key this Application's `valuesObject` sets
  unchanged in shape — confirm against a fresh clone, don't trust this note's
  cached read. Add a new chart-pin recurrence-guard assertion to
  `tests/securitycontext-observability.bats` (or a new
  `tests/observability-ksm.bats` if that file's scope doesn't fit) asserting
  `targetRevision: 8.1.3` is present in `observability-ksm.yaml` — mirrors the
  `ack-s3.bats`/`observability-grafana.bats` per-component exact-version pin
  pattern (no such assertion exists for this chart yet). No
  `docs/dependency-tree.md`/`context.md` update needed — neither cites this
  chart's specific version (checked directly). `make ci` must pass. PR body
  must document the diff/commit findings above (appVersion unchanged, packaging
  + additive-only diff, why `8.1.3` is the smallest safe delta) and the
  ADR-0004 caveat that this remote clusterless session cannot verify
  kube-state-metrics reconciles cleanly and the stack-health/KSM dashboards
  keep populating post-bump on a live cluster — call out the rollback path
  (revert `targetRevision`; ArgoCD re-syncs the prior chart version on next
  reconciliation; kube-state-metrics is stateless, so a rollback recovers
  immediately with no data loss). `docs/done/` entry required.
  (auto/ksm-chart-8-1-3)

- [x] 🟢 **Pin Inkless's batch-coordinator `postgres` image explicitly —
  `postgres:17` → `postgres:17.10`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; planner-fallback finding 2026-08-05, surfaced
  during this run's ARCHITECT-fallback audit of ADR-0015 (issue #1013/PR
  #1014, which held Inkless's Postgres at the `17.x` line rather than jump to
  the released `18.x` major) — that audit's body flagged this as a separate,
  non-architectural gap: `postgres:17` is a **floating tag**, unlike every
  other version-sensitive pin in this repo (Vault, Grafana, Argo Rollouts,
  Envoy Gateway, Kiali, k3s), which all pin an exact patch explicitly. **No
  prerequisites — executor may pick up immediately** (Now/next's three
  standing items remain gated on #631/#633, no new comment). Verified
  directly (not assumed, ADR-0004): Docker Hub's tags API
  (`hub.docker.com/v2/repositories/library/postgres/tags?name=17.`) shows
  `17.10` as the newest patch on the `17.x` line (`17.0` through `17.10`, no
  `17.11` yet), matching `postgres/postgres`'s own `REL_17_10` git tag. This
  is a **pin-what's-already-running** change, not a version bump — the
  floating `postgres:17` tag already resolves to `17.10` on any fresh image
  pull today; explicit pinning only makes that fact durable and inspectable,
  mirroring the 2026-07-24 Vault server-image-pin precedent
  (`docs/done/2026-07-24-vault-server-image-tag-pin.md`) exactly.

  Bump `gitops/inkless/postgres-statefulset.yaml`'s `image: postgres:17` →
  `image: postgres:17.10`. Add a new recurrence-guard assertion to
  `tests/inkless.bats` (currently that file only asserts the StatefulSet
  manifest *exists* — `"postgres StatefulSet manifest exists"` — no test
  guards the image tag at all yet): assert `image: postgres:17.10` is
  present in `postgres-statefulset.yaml`, and a second assertion that the
  bare floating `image: postgres:17` (no patch suffix) is NOT present, same
  shape as this repo's other per-component exact-version pin recurrence
  guards (mirrors `ack-s3.bats`/`envoy-gateway.bats`). No ADR-0015 edit
  needed beyond what PR #1014 already added — that re-evaluation log entry
  already documents the `17.x` vs `18.x` major-line decision; this item only
  makes the *current* `17.x` patch explicit, it doesn't re-litigate the
  major-version hold. No `docs/dependency-tree.md`/`context.md` update
  needed — neither cites this image's specific version (checked directly).
  `make ci` must pass. PR body must document the Docker Hub tag-currency
  finding above and the ADR-0004 caveat that this remote clusterless session
  cannot verify `inkless-postgres` starts cleanly post-pin on a live cluster
  — call out the rollback path (revert the tag; Inkless is on-demand/never
  auto-synced, so this has zero live-cluster blast radius until the
  maintainer next runs `make inkless-up`; no data-loss risk either way since
  `17.10` and floating `17` are the same actual image content today).
  `docs/done/` entry required. (auto/inkless-postgres-explicit-pin)

- [x] 🟢 **Bump Vault's pinned image `hashicorp/vault:2.0.3` → `2.0.4` (server +
  unsealer)** (CHARTER **Core Values** §"Everything as code" + general hardening;
  planner-fallback upstream check 2026-08-05, reached via `executor.prompt.md`
  STEP 6b — Now/next re-confirmed still gated on #631/#633, no new comment; this
  run's first PLANNER-fallback pass (ack-s3, merged as #1008/#1009) exhausted the
  chart-`targetRevision` currency angle (every other pin in `gitops/**/*.yaml`
  re-verified current against real upstream tags: harbor, kiali, kro,
  argo-rollouts, envoy-gateway, pyroscope, node-exporter, velero — all clean),
  so this pass checked plain container `image:` tags instead — a lens today's
  earlier cycles hadn't used. **No prerequisites — executor may pick up
  immediately.**) Verified directly (not assumed, ADR-0004): `git ls-remote
  --tags hashicorp/vault` shows `v2.0.4` as the newest tag on the `2.0.x` line
  this lab already runs (`gitops/platform/vault.yaml`'s
  `server.image.tag: "2.0.3"` and `gitops/vault/unsealer.yaml`'s
  `image: hashicorp/vault:2.0.3` — both pinned 2026-07-24, RFC/audit trail in
  `vault.yaml`'s own inline `## Re-evaluation log`-style comment, mirroring an
  ADR's re-evaluation log since Vault itself has no dedicated numbered ADR).
  A full clone (`git clone hashicorp/vault`) + `git log v2.0.3..v2.0.4`
  (real commit history, not the published `CHANGELOG.md`, which has no `2.0.x`
  section at either tag — a pre-existing gap in HashiCorp's own changelog
  publishing for this release line, flagged here per ADR-0004 rather than
  silently worked around) shows the real fix set: three "security:" commits
  turn out to be **false-positive suppressions**, not real vulnerabilities —
  `git log --grep` on the suppressed IDs finds their origin commits titled
  "Suppress false positive for GO-2026-5856 & 4970" and (same shape) for
  GO-2026-5298; these do NOT count toward the flip condition. Two more ARE
  real: `go.mod`/`go.sum` bump `klauspost/compress` → `v1.18.7` and
  `go.opentelemetry.io/otel` → `v1.44.0`, resolving GO-2026-5158 and
  GO-2026-5841 (real dependency CVEs, not suppressions — commit
  `e6dfd6375b`, "security: bump klauspost/compress to v1.18.7 and otel to
  v1.44.0"). Separately, `af5fd5a1cc` ("Fix Goroutine Leak in Seal
  Encryption") touches `vault/seal/seal.go` — the shared encrypt/decrypt path
  every seal type (including this lab's Shamir/file-storage seal) goes
  through, a real reliability fix, not seal-type-specific. This satisfies
  this pin's own flip condition in spirit (a real security-relevant fix past
  `2.0.3`) even though no public CVE bulletin names `2.0.3` itself as
  affected — same "ships with a security fix" standard this run's earlier
  k3s bump (RFC #995) used, not a blind patch assumption.

  Bump `gitops/platform/vault.yaml`'s `server.image.tag: "2.0.3"` → `"2.0.4"`
  (server) AND `gitops/vault/unsealer.yaml`'s `image: hashicorp/vault:2.0.3`
  → `hashicorp/vault:2.0.4` (unsealer CLI) — both must move together, same
  footgun-avoidance pattern as k3s's two-tag-format note (RFC #995) and
  ADR-0030's own history. Update `tests/securitycontext-vault.bats`'s two
  pin assertions (`"vault Application server image pinned to 2.0.3"` →
  `2.0.4`; `"vault-unsealer image bumped to hashicorp/vault:2.0.3"` →
  `2.0.4`). Extend `vault.yaml`'s inline `## Re-evaluation log`-style comment
  with a new dated entry (after the existing 2026-07-24 entry) recording this
  bump: cite the false-positive-suppression findings (GO-2026-5856/4970/5298),
  the two real dependency-CVE fixes (GO-2026-5158/5841 via
  klauspost/compress + otel bumps), and the goroutine-leak fix, with a new
  flip condition for the next audit (e.g. "revisit when a bulletin names a
  version above `2.0.4` as affected, or when bumping the chart
  `targetRevision` past `0.34.0`"). No ADR-0017 edit needed — its `2.0.3`
  mentions are historical narrative describing the 2026-07-17 PSS-flip
  decision, not a live pin the drift checks track (confirmed directly:
  `scripts/adr-image-pin-sync-check.sh` does not reference vault/2.0.3 at
  all — only `adr-0009-rabbitmq-message-broker.md` is wired into that check).
  `make ci` must pass. PR body must document the false-positive-vs-real
  finding above (don't just cite "three security commits exist" — say which
  ones are noise) and the ADR-0004 caveat that this remote clusterless
  session cannot verify Vault starts cleanly / unseals correctly post-bump on
  a live cluster — call out the rollback path (revert both tags; ArgoCD
  re-syncs the server image on next reconciliation; the unsealer Deployment
  picks up the reverted tag on its next rollout; no data-loss risk — Vault's
  file-storage PVC data is untouched by an image-tag revert).
  `docs/done/` entry required. (auto/vault-image-2-0-4)

- [x] 🟢 **Bump `ack-s3` (AWS Controllers for Kubernetes S3 chart) `1.8.2` → `1.9.0`**
  (CHARTER **Core Values** §"Everything as code" + general hardening;
  planner-fallback upstream check 2026-08-05, reached via `executor.prompt.md`
  STEP 6b after all three standing Now/next items were re-confirmed gated on
  unconfirmed maintainer-confirmation issues #631/#633 (both re-checked this
  run, no new comment) with no live-state-safe slice to split off, and Planner
  STEP 2's own intake pass found zero ungroomed issues and zero un-RFC'd 🟡
  items to promote — this is a genuine upstream-currency gap-analysis finding,
  not manufactured filler. **No prerequisites — executor may pick up
  immediately.**) Verified directly (not assumed, ADR-0004): `git ls-remote
  --tags aws-controllers-k8s/s3-controller` shows `v1.9.0` as the newest stable
  tag (no pre-release beyond it), one **minor** release ahead of this lab's
  pinned `1.8.2` (`gitops/platform/ack-s3.yaml`) — not a major bump, so within
  this routine's mandate. A full clone diff (`git diff v1.8.2 v1.9.0 --
  helm/`) touches **only** three files: `helm/Chart.yaml` (`version`/
  `appVersion` `1.8.2` → `1.9.0`), `helm/templates/NOTES.txt`, and
  `helm/values.yaml`'s `image.tag` — all three are just the version-string
  bump itself. `git log v1.8.2..v1.9.0 -- helm/` shows exactly one commit:
  "Update to ACK runtime `v0.62.0`, code-generator `v0.62.0`" (#240) — a
  routine ACK-framework dependency bump, not a behavioral change to the S3
  controller's own reconciliation logic. Every key this lab's
  `ack-s3.yaml` Application sets in `valuesObject` (`aws.*`, `installScope`,
  `podSecurityContext.*`, `securityContext.*`, `resources.*`) is unchanged in
  the new chart's `values.yaml` — confirmed directly, not assumed.

  Bump `gitops/platform/ack-s3.yaml`'s `targetRevision: 1.8.2` → `1.9.0`.
  Update `tests/ack-s3.bats`'s two chart-pin assertions (the "pins chart
  version" assertion to `1.9.0`, the "does not pin the stale ... version"
  assertion to the now-stale `1.8.2`) — this is the existing recurrence-guard
  pattern, mirroring `envoy-gateway.bats`/`harbor.bats`. No
  `docs/dependency-tree.md` or `context.md` update needed — neither cites this
  chart's specific version number (checked directly; the dependency-tree's
  wave-3 table row lists `ack-s3` by name only, no version). `make ci` must
  pass. PR body must document the diff/commit findings above, why `1.9.0`
  (smallest safe delta past a routine framework bump, not a blind assumption),
  and the ADR-0004 caveat that this remote clusterless session cannot verify
  the ACK S3 controller reconciles a live `Bucket` CR against moto
  post-bump on a real cluster — call out the rollback path (revert
  `targetRevision`; ArgoCD re-syncs the prior chart version on next
  reconciliation; no CRD/CR schema change in this bump, so no data-loss risk).
  `docs/done/` entry required. (auto/ack-s3-chart-1-9-0)

- [x] 🟢 **Bump k3s pin `v1.36.2+k3s1` → `v1.36.3+k3s1` on both backends** (CHARTER
  **Core Values** §"Recreate-from-code" + general hardening; RFC #995 — architect
  decision 2026-08-05, ADR-0030 audit #994 resolved as **Convert**. **No
  prerequisites — executor may pick up immediately.**) Verified directly (not
  assumed, ADR-0004): `git ls-remote --tags k3s-io/k3s` shows `v1.36.3+k3s1` as
  the newest stable tag, one patch ahead of ADR-0030's pinned `v1.36.2+k3s1`
  (kept at the 2026-07-28 re-evaluation, audit #770). `git log
  v1.36.2+k3s1..v1.36.3+k3s1` on a real clone contains one security-relevant
  fix among ~35 commits: `11f5071f57` ("Redact single-dash secret flags in the
  node args annotation") — the `k3s.io/node-args` annotation's redaction logic
  previously only matched double-dash secret flags, letting a single-dash
  secret flag's value leak in plaintext into a `Node` object annotation,
  readable by anyone with `get`/`list` RBAC on `nodes`. No formal CVE/GHSA is
  attached to this specific commit (checked GitHub's published security
  advisories for `k3s-io/k3s` directly — none matches), but it satisfies
  ADR-0030's flip condition ("ships with a security fix", broader than "a CVE
  is disclosed"). No breaking changes in the range — the rest is routine
  dependency bumps (etcd, Traefik, CoreDNS, Metrics Server, spegel, kine,
  dynamiclistener) and CI/build chores. Full record: RFC #995, ADR audit #994.

  Bump `infra/modules/k3d-cluster/k3d-config.yaml.tftpl`'s `image:
  rancher/k3s:v1.36.2-k3s1` → `rancher/k3s:v1.36.3-k3s1` (Docker Hub hyphen
  tag format). Bump `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s
  `INSTALL_K3S_VERSION=v1.36.2+k3s1` → `v1.36.3+k3s1` (GitHub release/installer
  plus-sign tag format — both formats must move together per ADR-0030's own
  footgun note; re-verify both are updated at pickup time, don't trust this
  note's cached read). Update `docs/decisions/context.md`'s k3s version line to
  match. Extend `tests/k3s-version-pin.bats`'s recurrence-guard assertions from
  `v1.36.2` to `v1.36.3` in both tag formats. Add a new dated entry to
  ADR-0030's `## Re-evaluation log` (after the existing 2026-07-28 audit #770
  entry) recording this bump, citing RFC #995 and commit `11f5071f57`, with a
  new flip condition for the next audit (e.g. "revisit when a k3s stable
  release at or above `v1.36.3` ships with a security fix, or a CVE is
  disclosed against `v1.36.3` specifically"). `make ci` (specifically
  `terraform validate`/`fmt`, clusterless — this seam needs no live
  cluster/cloud credentials) must pass. PR body must document the
  secret-redaction finding above, why `v1.36.3+k3s1` (smallest safe delta past
  a verified security fix), and the ADR-0004 caveat that this remote
  clusterless session cannot verify a `make up`/Oracle bootstrap with this pin
  succeeds end-to-end — call out the rollback path (revert both pins; the next
  `make up`/Oracle instance launch picks up the reverted version; no
  live-cluster state depends on this pin beyond cluster bootstrap itself, per
  ADR-0030's own Scope & exceptions). `docs/done/` entry required. Closes #995.
  (auto/k3s-1-36-3)

- [x] 🟢 **Bump Terraform-bootstrapped `argo-cd` chart `10.2.2` → `10.2.3`** (CHARTER
  **Core Values** §"Everything as code" + general hardening; planner-fallback
  upstream check 2026-08-05, reached via `executor.prompt.md` STEP 6b, Now/next
  starved by #631/#633 — follow-up from this same run's earlier Grafana-currency
  sweep note (`docs/backlog/2026-08-05-planner-note-grafana-chart-currency.md`),
  which flagged this delta but declined to add it without checking argo-cd's own
  `v3.4.6`→`v3.5.0` release notes for breaking changes first. **No
  prerequisites — executor may pick up immediately** — that diligence is now
  done, see below.) Verified directly (not assumed, ADR-0004): `git ls-remote
  --tags argoproj/argo-helm` shows `argo-cd-10.2.3` one patch ahead of
  `infra/modules/argocd/variables.tf`'s pinned `chart_version` default
  `"10.2.2"` (RFC #785's approved 9.x→10.x major-bump target line). A full
  clone diff (`git diff argo-cd-10.2.2 argo-cd-10.2.3 -- charts/argo-cd/`)
  shows only `Chart.yaml` (`version` 10.2.2→10.2.3, `appVersion` `v3.4.6`→
  `v3.5.0`) plus 336 added lines of new *optional* fields across the
  `Application`/`ApplicationSet`/`AppProject` CRDs — zero `values.yaml`
  changes, so RFC #785's `global.networkPolicy.create: false` companion
  override is untouched.

  The `appVersion` jump is a **minor** ArgoCD release, not a patch, so this
  run read ArgoCD's own official upgrade guide
  (`docs/operator-manual/upgrading/3.4-3.5.md` at the `v3.5.0` tag, not
  training knowledge) rather than assuming a chart patch bump is automatically
  safe. It lists six real breaking/behavioral changes; checked each directly
  against this repo's actual `gitops/**/*.yaml` + `infra/**` config:
  - **Helm v3→v4 (plain-HTTP OCI registries need `--insecure-oci-force-http`
    now):** this lab has zero `oci://`-scheme `repoURL`s and zero
    `enableOCI`/`enable-oci` settings anywhere in `gitops/`/`infra/` (checked
    directly). The one Application that *is* OCI-shaped
    (`gitops/platform/ack-s3.yaml`, `repoURL: public.ecr.aws/aws-controllers-k8s`)
    talks to AWS public ECR, which is TLS-only by construction — not a plain-HTTP
    registry. **Not applicable.**
  - **UI extensions must externalize `react/jsx-runtime` (React 16→19):** this
    lab installs no custom ArgoCD UI extensions. **Not applicable** (guide's own
    "no action required" carve-out).
  - **Event-listing gRPC methods return a new type:** only affects custom/
    generated gRPC clients calling those specific RPCs directly; this lab has
    none (grepped for gRPC-client code — none exists). REST/UI paths are
    explicitly unchanged per the guide. **Not applicable.**
  - **Impersonation extended to server operations:** this lab's `argocd`
    `AppProject`/RBAC config sets no `destinationServiceAccounts` — impersonation
    is not enabled (checked directly, and RFC #785's own decision record for the
    9.x→10.x bump never mentions impersonation). **Not applicable** (guide's own
    "no action required" carve-out).
  - **SSH `known_hosts` behavior change:** every `repoURL` in this lab is
    `http://`/`https://` (checked directly — zero `ssh://`/`git@` entries).
    **Not applicable.**
  - **GnuPG signature verification → Source Integrity:** this lab configures no
    `AppProject.spec.signatureKeys` anywhere (checked directly). **Not
    applicable.**

  None of the six documented breaking changes touch this lab's actual
  configuration. This is Terraform-bootstrap-only (ADR-0001 seam) — the module
  only re-applies on the maintainer's next explicit `terraform apply` against
  the `argocd` unit, so this bump has zero live-cluster blast radius until
  then regardless.

  Bump `infra/modules/argocd/variables.tf`'s `chart_version` default `"10.2.2"`
  → `"10.2.3"` (update the inline comment's `"10.2.2 => ArgoCD v3.4.6"` to
  `"10.2.3 => ArgoCD v3.5.0"`). Update both `infra/live/local/argocd/terragrunt.hcl`
  and `infra/live/oracle/argocd/terragrunt.hcl`'s `chart_version = "10.2.2"`
  input to `"10.2.3"` (both must move together — a prior currency gap here sat
  undetected for two sweep cycles specifically because these three sites drifted
  independently, `docs/done/2026-07-23-argocd-chart-bump-9-5-20-to-9-7-1.md`).
  Update `tests/argocd-chart-pin.bats`'s three assertions (`chart_version`
  default, both terragrunt.hcl inputs) from `10.2.2` to `10.2.3` — this file is
  the RFC #785 recurrence guard verifying the chart pin and its
  `global.networkPolicy.create: false` companion move together; re-verify that
  key is still `false` in the `10.2.3` chart's `values.yaml` at pickup time
  (confirmed unchanged in this run's diff, but re-check against a fresh clone
  per this repo's own due-diligence convention). No `docs/dependency-tree.md`
  or `context.md` update needed — neither cites this chart's version. `make ci`
  (specifically `terraform validate`/`fmt`, clusterless — this seam needs no
  live OCI/cloud credentials) must pass. PR body must document the six
  breaking-change findings above, why `10.2.3` (smallest safe delta past a
  verified-safe minor bump, not a blind patch assumption), and the ADR-0004
  caveat that this remote clusterless session cannot verify a real
  `terraform apply` against this pin succeeds end-to-end — call out the
  rollback path (revert the three pins; the next `terraform apply` re-installs
  the prior chart version; ArgoCD's own state — Applications, RBAC, repo
  credentials — lives in the `argocd` namespace's Secrets/ConfigMaps on the
  cluster, untouched by a chart-version revert in the bootstrap module).
  `docs/done/` entry required. (auto/argocd-chart-10-2-3)

- [x] 🟢 **Bump `grafana` chart `12.10.2` → `12.10.3`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; planner-fallback upstream check
  2026-08-05, reached via `executor.prompt.md` STEP 6b, Now/next starved by
  #631/#633. **No prerequisites — executor may pick up immediately.**) Verified
  directly (not assumed, ADR-0004): a real clone of
  `github.com/grafana-community/helm-charts` (the actual `repoURL` this lab's
  `gitops/platform/observability-grafana.yaml` Application uses — note this is
  the community-maintained fork, a **different** repo than `grafana/helm-charts`,
  which is stale/archived upstream and does not carry recent tags) shows
  `grafana-12.10.3` as a genuine tag past the currently-pinned
  `grafana-12.10.2`. `git diff grafana-12.10.2 grafana-12.10.3 -- charts/grafana/`
  on that real clone touches **only** `charts/grafana/Chart.yaml` — `version:
  12.10.2` → `12.10.3` and `appVersion: 13.1.1` → `13.1.2` — zero changes to
  `values.yaml` or any template. This chart bump does **not** change the Grafana
  binary this lab actually runs: `observability-grafana.yaml`'s
  `valuesObject.image.tag` override (currently `13.0.3`) and the matching
  ca-bundle init-container image both pin the running Grafana version
  independently of the chart's own `appVersion` default, per ADR-0006's
  CVE-driven re-evaluation log (last audited 2026-07-28, kept at `13.0.3` — this
  bump doesn't touch or reset that pin, and does not itself constitute a new
  audit of it). `git log grafana-12.10.2..grafana-12.10.3 -- charts/grafana` on
  the real clone shows one commit, a routine renovate-bot Docker-tag bump
  (`Update docker.io/grafana/grafana Docker tag to v13.1.2`) — packaging-only,
  same smallest-safe-delta pattern as the Harbor/cert-manager/Kiali/kro bumps
  already in `## Done`.

  Bump `gitops/platform/observability-grafana.yaml`'s `targetRevision: 12.10.2`
  → `12.10.3`. Re-verify directly at pickup time that the `12.10.3` chart's
  `values.yaml` still contains every key this Application's `valuesObject` sets
  unchanged in shape (`image.tag`, `persistence.*`, `provisioning.*`,
  `grafana.ini.*`, `resources.*` — whatever the Application actually sets;
  confirm against a fresh clone, don't trust this note's cached read). Add a new
  `tests/observability-grafana.bats` assertion (that file currently only guards
  the `image.tag`/ca-bundle pins, RFC #563 — no test guards the chart
  `targetRevision` at all yet) asserting
  `targetRevision: 12.10.3` is present in `observability-grafana.yaml` — a
  recurrence guard mirroring this repo's other per-component exact-version pin
  assertions (Harbor/cert-manager/Kiali/kro precedent). No ADR re-evaluation-log
  entry is needed — ADR-0006's log tracks the CVE-driven `image.tag` pin, not
  chart packaging currency, and this bump doesn't touch that pin. No
  `docs/dependency-tree.md` or `docs/decisions/context.md` update needed —
  neither cites the chart's `targetRevision` (checked directly: only the image
  tag `13.0.3` is cited, in `context.md`, and that citation is unaffected).
  `make ci` must pass. PR body must document the diff findings above, why
  `12.10.3` (smallest safe delta, packaging-only, non-security), and the
  ADR-0004 caveat that this remote clusterless session cannot verify Grafana's
  Git Sync / dashboard provisioning starts cleanly post-bump on a live cluster
  — call out the rollback path (revert `targetRevision`; ArgoCD self-heals
  within its sync interval; Grafana's DB lives on a PVC untouched by a chart
  revert, so a rollback recovers immediately with no data loss). `docs/done/`
  entry required. (auto/grafana-chart-12-10-3)

- [x] 🟢 **Bump `kiali-server` chart `2.29.0` → `2.30.0`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; ADR-0012's own Re-evaluation log flip
  condition ("revisit when a Kiali-specific CVE is published against `kiali-server`
  at or above `2.29.0`") has fired — planner-fallback upstream check 2026-08-04
  (reached via `executor.prompt.md` STEP 6b, Now/next starved by #631/#633). **No
  prerequisites — executor may pick up immediately.**) Verified directly (not
  assumed, ADR-0004): a real clone of `github.com/kiali/helm-charts` shows `v2.30.0`
  as a genuine tag past the currently-pinned `v2.29.0` (both non-`-master` stable
  tags); a real clone of the `kiali/kiali` app repo (same versioning — chart version
  tracks app version 1:1 in this project, confirmed at the prior `1.89.8`→`2.29.0`
  Convert audit too) shows `git log v2.29.0..v2.30.0` contains three named CVE fixes
  in Kiali's bundled frontend dependencies: **CVE-2026-59877** (`protobufjs` →
  `7.6.5`), **CVE-2026-49978** (`dompurify` → `3.4.7+`), and **CVE-2026-59869**
  (`js-yaml` → `4.3.0`) — each affects versions up to and including `2.29.0` and is
  fixed in `2.30.0`, which is exactly ADR-0012's recorded flip condition. The rest of
  the `v2.29.0..v2.30.0` range is feature work (opt-in OpenShift impersonation mode,
  Gateway API TCPRoute/UDPRoute support, Ambient-mesh validation improvements) plus
  CI/chore commits — none of it touches this lab's `valuesObject` keys (`auth.strategy`,
  `external_services.prometheus.{url,custom_headers}`, `external_services.tracing.enabled`,
  `deployment.resources`); the new opt-in `auth.openshift.impersonation.*` block this
  lab doesn't set stays at its (still-present) default.

  Bump `gitops/platform/kiali.yaml`'s `targetRevision: 2.29.0` → `2.30.0`. Re-verify
  directly at pickup time that the `2.30.0` chart's `values.yaml` still contains every
  key this Application's `valuesObject` sets unchanged in shape (same due-diligence
  pattern as the Harbor/cert-manager/kro bumps). Update `tests/platform.bats`'s
  `"kiali Application pins kiali-server chart 2.29.0"` assertion to assert `2.30.0`
  instead — a recurrence guard mirroring this repo's other per-component
  exact-version pin assertions. Update `docs/dependency-tree.md`'s kiali bullet
  (line ~326), which cites the chart version explicitly (`v2.29.0` → `v2.30.0`). Add
  a new dated entry to ADR-0012's `## Re-evaluation log` (after the existing
  2026-07-28 audit #778 entry) recording this bump, citing the three CVE IDs above
  and the CVE-fix-floor reasoning, with a new flip condition for the next audit
  (e.g. "revisit when a Kiali-specific CVE is published against `kiali-server` at or
  above `2.30.0`, or the chart repo prunes `2.30.0` itself"). `make ci` must pass. PR
  body must document the three CVEs, why `2.30.0` (smallest safe delta that clears
  the CVE floor — the next tag is a real minor bump, not a patch, but Kiali's
  versioning scheme doesn't publish narrower patch releases for the `2.29.x` line),
  and the ADR-0004 caveat that this remote clusterless session cannot verify Kiali's
  UI starts cleanly post-bump on a live cluster (Kiali is on-demand/never
  auto-synced per ADR-0012, so this bump has zero live-cluster blast radius until
  the maintainer next runs `make kiali-up`) — call out the rollback path (revert
  `targetRevision`; next `make kiali-up` picks up the reverted chart; Kiali is a
  stateless UI/API service reading from Prometheus, so a revert recovers immediately
  with no data loss). `docs/done/` entry required. (auto/kiali-chart-2-30-0)

- [x] 🟢 **Bump Harbor chart `1.19.1` → `1.19.2`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; planner gap-analysis sweep 2026-08-03 —
  the architect-fallback ADR upstream sweep (`routines/architect.prompt.md` STEP 1)
  checked all 17 checklist components plus Harbor/Garage directly; every other
  component was already current, this was the one real delta. **No prerequisites —
  executor may pick up immediately.**) Verified directly (not assumed, ADR-0004): a
  full clone of `github.com/goharbor/harbor-helm` shows `v1.19.2` tagged and
  published 2026-08-03 (same day), one patch ahead of this lab's pinned `1.19.1`
  (`gitops/platform/harbor.yaml`). `git diff v1.19.1 v1.19.2 -- Chart.yaml
  values.yaml` on that real clone shows: `appVersion: 2.15.1` → `2.15.2` (every
  component image tag bumped `v2.15.1` → `v2.15.2` — `nginx`, `portal`, `core`,
  `jobservice`, `registry`/`registryctl`, `trivy` adapter, `database`, `redis`,
  `exporter`); and one structural change — the bundled cache's image repository
  changed from `docker.io/goharbor/redis-photon` to
  `docker.io/goharbor/valkey-photon` (upstream's own bundled-cache image switching
  base, unrelated to this lab's separate ADR-0018 Valkey-not-Redis choice for the
  platform-wide cache — this is Harbor's *own* internal instance, `redis.type:
  internal`, per the ADR-0024 exception documented in `harbor.yaml`'s header
  comment). No `values.yaml` key was added, removed, or renamed — every key this
  Application's `valuesObject` sets (`expose`, `trivy.enabled`, `notary.enabled`,
  `persistence.imageChartStorage`, `database.type`, `redis.type`, `registry`,
  `core`, `jobservice`, `portal`, `metrics.enabled`) is unchanged in shape. ADR-0024's
  Re-evaluation log's most recent entry (audit #774, 2026-07-28) confirmed
  `1.19.1`/`appVersion 2.15.1` already sat past CVE-2026-4404's fix floor
  (`2.15.1`+) with a flip condition of "a future chart bump ever drops or
  overrides `existingSecretAdminPassword`, or a new CVE is disclosed against
  `2.15.1`+" — neither triggers here (no CVE against `2.15.2`; the diff above
  shows `existingSecretAdminPassword`/`existingSecretAdminPasswordKey` untouched
  by the chart bump), so this is a routine currency bump, not a CVE response —
  same "smallest safe delta, bug-fix-only" pattern as the `kro 0.9.2→0.9.3` bump.

  Bump `gitops/platform/harbor.yaml`'s `targetRevision: 1.19.1` → `1.19.2`.
  Update `docs/dependency-tree.md`'s harbor bullet (line ~318), which cites the
  chart version explicitly (`v1.19.1` → `v1.19.2`) — **while there, also fix a
  separate, pre-existing inaccuracy in the same sentence found during this
  verification**: it currently says Harbor uses "platform Valkey for cache",
  which contradicts `harbor.yaml`'s own header comment and `redis.type: internal`
  setting (Harbor uses its own bundled internal cache instance, not the lab's
  shared `data`-namespace Valkey — the ADR-0018 exception documented in
  `harbor.yaml` since 2026-07-21 because ArgoCD's template-only rendering can't
  resolve the chart's `lookup()`-based external-Valkey wiring); correct the
  phrase to describe the bundled internal cache instead (e.g. "bundled internal
  cache, `redis.type: internal` — an ADR-0018 exception, ADR-0024 §recorded").
  Tighten `tests/harbor.bats`'s existing chart-pin assertion (`"harbor
  Application pins a specific 1.19.x chart version"`, currently the loose regex
  `1\.19\.`) to assert the specific patch `targetRevision: 1\.19\.2` — a
  recurrence guard mirroring this repo's other per-component exact-version pin
  assertions (matches the kro/cert-manager precedent). Add a new dated entry to
  ADR-0024's `## Re-evaluation log` (after the existing 2026-07-28 audit #774
  entry) recording this bump, citing the appVersion bump + the redis→valkey
  bundled-image change, with a new flip condition for the next audit (e.g.
  "revisit when a Harbor security advisory names a version at or above
  `2.15.2` as affected"). `make ci` must pass. PR body must document the diff
  findings above, why `1.19.2` (smallest safe delta, non-security), and the
  ADR-0004 caveat that this remote clusterless session cannot verify Harbor
  starts cleanly post-bump on a live cluster (Harbor is on-demand/never
  auto-synced per ADR-0024, so this bump has zero live-cluster blast radius
  until the maintainer next runs `make harbor-up`) — call out the rollback path
  (revert `targetRevision`; next `make harbor-up` picks up the reverted chart;
  no data loss since Harbor's registry/database state lives in Garage S3 plus
  a PVC-backed internal Postgres, both untouched by a chart-version revert).
  `docs/done/` entry required. (auto/harbor-chart-1-19-2)

- [x] 🟢 **Bump cert-manager chart `1.21.0` → `1.21.1`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC #933 — architect decision
  2026-07-31, ADR-0028 audit #931 resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) `v1.21.1` exists — confirmed directly via
  `git ls-remote --tags https://github.com/cert-manager/cert-manager.git` (not
  training knowledge, ADR-0004) and a shallow clone at that tag showing the
  commit dates to 2026-07-29, two days after ADR-0028's most recent audit
  (#763, 2026-07-27). `git log refs/tags/v1.21.0..refs/tags/v1.21.1` on that
  real clone shows: a fix for a controller panic/incorrect-renewal bug
  (`fix(renew): Do not renew a certificate if its renewPolicy=Disabled`), and
  four dependency bumps cert-manager's own renovate automation tagged
  `[security]`: `golang.org/x/text` → `v0.40.0`, `google.golang.org/grpc` →
  `v1.82.1`, `github.com/google/cel-go` → `v0.29.0`, `go.opentelemetry.io/otel`
  → `v1.44.0`.

  Bump `gitops/platform/cert-manager.yaml`'s `targetRevision: 1.21.0` →
  `1.21.1` (same source, same major.minor line — patch bump only). Re-verify
  directly at pickup time that the `1.21.1` chart's `values.yaml` still
  contains every key this Application's `valuesObject` sets unchanged in shape
  (`crds.enabled`, `resources.limits.memory`, `webhook.resources.limits.memory`,
  `cainjector.resources.limits.memory`). Add a new dated entry to ADR-0028's
  `## Re-evaluation log` (after the existing 2026-07-27 audit #763 entry)
  recording this bump, citing audit #931, the four security-tagged dependency
  bumps, and the renewal-policy panic fix, with a new flip condition for the
  next audit (e.g. "revisit when a cert-manager security advisory names a
  version at or above `1.21.1` as affected"). Extend `tests/cert-manager.bats`'s
  existing chart-pin assertion (`"cert-manager Application pins chart version
  1.21.0"`) to assert `1.21.1` instead — a recurrence guard mirroring this
  repo's other per-component exact-version pin assertions. Update
  `docs/dependency-tree.md`'s cert-manager bullet, which cites the chart
  version explicitly (`v1.21.0` → `v1.21.1`). `make ci` must pass. PR body must
  document the security-tagged dependency bumps + panic fix, why `1.21.1`
  (smallest safe delta), and the ADR-0004 caveat that this remote clusterless
  session cannot verify cert-manager issues/renews certificates cleanly
  post-bump on a live cluster — call out the rollback path (revert
  `targetRevision`; ArgoCD self-heals within its sync interval; cert-manager is
  a stateless controller Deployment, so a revert recovers immediately with no
  data loss — existing `Certificate`/`ClusterIssuer` objects and their Secrets
  are untouched by a controller-image rollback). `docs/done/` entry required.
  Closes #933. (auto/cert-manager-chart-1-21-1)

- [x] 🟢 **Bump `kro` chart `0.9.2` → `0.9.3`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; planner gap-analysis sweep 2026-07-30 — all three
  standing "Now / next" items gated on maintainer-confirmation issues #631/#633, no
  ADR/RFC decision required for this one. **No prerequisites — executor may pick up
  immediately.**) Verified directly (not assumed, ADR-0004): `git ls-remote --tags
  https://github.com/kro-run/kro.git` (git protocol — this sandbox's proxy blocks the
  `ghcr.io`/chart-index HTTPS host directly, same constraint noted on prior chart-pin
  bumps) shows `v0.9.3` as the newest stable tag, one patch ahead of this lab's pinned
  `0.9.2` (`gitops/platform/kro.yaml`). `v0.9.3`'s release notes (fetched from the real
  GitHub release page) describe bug fixes only — a nil-pointer dereference fix in
  ExternalDocs conversion, a fix for instance deletion getting stuck when SSA field
  managers owned finalizers, panic recovery during dynamic-controller reconciliation,
  and a dependency bump (OpenTelemetry to a version addressing a CVE in that
  dependency) — with no breaking changes noted. This is the same smallest-safe-delta
  pattern as this lab's other chart-pin bumps (patch-only, no minor/major jump).

  Bump `gitops/platform/kro.yaml`'s `targetRevision: 0.9.2` → `0.9.3`. Also update
  `docs/decisions/context.md`'s "KRO chart version: 0.9.2" line to `0.9.3` — `make ci`'s
  context.md-version-sync check (`scripts/`, the "context.md version sync" gate)
  cross-checks this literal citation against `gitops/platform/kro.yaml`'s live pin and
  fails the PR if they drift, same mechanism already catching Grafana/Pyroscope
  version citations. Update `tests/securitycontext-kro.bats`'s `"kro Application chart
  pin is 0.9.x (not the old 0.4.1)"` test to also assert the specific patch
  (`targetRevision: 0\.9\.3` alongside or replacing the looser `0\.9\.` match) — a
  recurrence guard mirroring this repo's other per-component exact-version pin
  assertions. No topology change, so no README/`docs/dependency-tree.md` update is
  expected — note that explicitly in the PR body, which must also document: the fix
  summary above, why `0.9.3` (smallest safe delta), and the ADR-0004 caveat that this
  remote clusterless session cannot verify
  `kro` starts cleanly post-bump on a live cluster — call out the rollback path (revert
  `targetRevision`; ArgoCD self-heals within its sync interval; `kro` is a stateless
  controller Deployment, so a revert recovers immediately with no data loss, same
  pattern as the Envoy Gateway/Vault/Valkey/Grafana chart-pin bumps). `make ci` must
  pass. `docs/done/` entry required. (auto/kro-cve-bump-0-9-3)

- [x] 🟢 **Lab — Istio ambient mesh (`istio-system`) observability wiring: Alloy
  scrape + Grafana dashboard** (CHARTER **Objective O5**, due **2026-09-30**; O5 gap
  — planner gap-analysis sweep 2026-07-28, all five prior "Now / next" items being
  gated on maintainer-confirmation issues #631/#632/#633. `istio-system-extras`
  (`gitops/platform/istio-system-extras.yaml`) is auto-synced under
  `gitops/bootstrap/root-app.yaml`'s recursive `gitops/platform/` watch — the same
  ALWAYS-ON PSA-floor pattern as `kargo-extras`/`longhorn-extras` (namespace +
  privileged PSA labels pre-created ahead of `make istio-up`, the empty namespace
  itself cheap to keep auto-synced) — but unlike those two it has **no Grafana
  dashboard and no Alloy scrape wiring at all**: verified directly, zero
  `grafana/dashboards/lab-istio*.json` files exist and `grep -rl "lab-istio"
  tests/` returns nothing. `docs/dependency-tree.md`'s istio-system NetworkPolicy
  note already anticipates this gap: `allow-istio-metrics-ingress.yaml` opens
  ingress TCP 15014 from `observability` "for future istiod Prometheus scrape" —
  that scrape was never actually added to `observability-alloy.yaml`. **No
  prerequisites — executor may pick up immediately.**)

  Mirror the `auto/longhorn-dashboard` / `auto/kargo-observability-dashboard`
  precedent exactly (same always-present-namespace-but-component-may-be-off shape):
  add a `prometheus.scrape "istiod"` block to
  `gitops/platform/observability-alloy.yaml` (static target
  `istiod.istio-system.svc.cluster.local:15014`, `scrape_interval = "30s"`,
  mirroring the adjacent `longhorn`/`kargo` blocks) — the scrape naturally returns
  no series until `make istio-up` actually runs istiod (ADR-0004-compliant "No
  data" until then, same as every other on-demand component's always-on scrape
  job). New `grafana/dashboards/lab-istio.json` (`uid: "lab-istio"`, title "Lab —
  Istio Ambient Mesh") modelled on `lab-longhorn.json`'s stat-row: ArgoCD sync
  state (`argocd_app_info{name="istio-system-extras", sync_status="Synced"}`);
  namespace-present stat via KSM (`kube_pod_info{namespace="istio-system"}` count
  or `kube_namespace_created{namespace="istio-system"}`) so at least one panel
  returns real data via the always-on KSM scrape even before Istio's own
  components ever run; istiod control-plane health once the scrape target exists
  (verify istiod's actual exposed metric names against the pinned `istio/istiod`
  chart version before committing an `expr` — e.g. `pilot_xds` push/connection
  counters — ADR-0004: check the real metric name, don't guess one); ztunnel/
  istio-cni pod readiness via KSM
  (`kube_daemonset_status_number_ready{namespace="istio-system",
  daemonset=~"ztunnel.*|istio-cni.*"}`). No HTTPRoute (istiod has no web UI of its
  own; Kiali already has its own separate on-demand dashboard/route). New
  `tests/istio-observability.bats` (clusterless structural, mirrors
  `tests/longhorn.bats`'s shape): scrape block `"istiod"` exists in
  `observability-alloy.yaml`; scrape target references port 15014; `lab-istio.json`
  exists; has uid `lab-istio`; references the `istio-system` namespace in a real
  KSM/ArgoCD query; no fabricated/placeholder content (ADR-0004 grep guard: `grep
  -iE '"(fake|mock|placeholder|dummy|todo|fixme)"'`). Update
  `docs/dependency-tree.md`'s istio-system entry to note the new dashboard + scrape
  wiring (the existing NetworkPolicy note's "future istiod Prometheus scrape"
  becomes real — update that sentence too). `make ci` must pass. `docs/done/` entry
  required. (auto/istio-observability-dashboard)

- [x] 🟢 **Bump Envoy Gateway chart `v1.8.2` → `v1.8.3`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC #671 — architect decision
  2026-07-23, ADR-0008 audit resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) ADR-0008's 2026-07-18 Re-evaluation log
  entry (audit #515) recorded an explicit flip condition: "revisit when a new
  Envoy Gateway security bulletin names a version above `v1.8.2` as affected."
  Issue #663 (2026-07-22T05:46 UTC) found `v1.8.3` existed as a GitHub tag but
  its chart/image weren't yet published to Docker Hub (404), so the bump was
  correctly held back. Re-verified 2026-07-23: `v1.8.3` is now live — GitHub
  release published 2026-07-22T18:59:00Z (stable, not pre-release; changelog:
  dependency updates + a fix that "rejects TLS secret when certificate and
  private key do not match"), and the Docker Hub OCI artifact
  `envoyproxy/gateway-helm:v1.8.3` resolves for real (`tag_status: active`,
  digest `sha256:cfb34ff4266c87a394cd6be5c13607a2dd47083aef771368302eaeaa99c4a0a9`,
  content-type `application/vnd.cncf.helm.config.v1+json`, `last_updated:
  2026-07-22T18:57:28Z` — confirmed via direct query against
  `https://hub.docker.com/v2/repositories/envoyproxy/gateway-helm/tags/v1.8.3`,
  not just training knowledge, per ADR-0004).

  Bump `gitops/platform/envoy-gateway.yaml`'s `targetRevision: v1.8.2` →
  `v1.8.3` (same source, same major.minor line — patch bump only). Add a new
  dated entry to ADR-0008's `## Re-evaluation log` (after the existing
  2026-07-18 audit #515 entry) recording this bump, citing the GitHub release
  + Docker Hub verification above, with a new flip condition for the next
  audit (e.g. "revisit when a bulletin names a version above `v1.8.3` as
  affected"). Add or extend a `tests/*.bats` chart-pin assertion for
  envoy-gateway (check for an existing one first) asserting `v1.8.3` is
  present in `envoy-gateway.yaml` — a recurrence guard mirroring the existing
  Argo Rollouts/Grafana/Valkey image-tag pin assertions. Update
  `docs/dependency-tree.md` only if it references the pinned chart version
  explicitly. `make ci` must pass. PR body must note the ADR-0004 caveat that
  this remote clusterless session cannot verify Envoy Gateway starts cleanly
  post-bump on a live cluster — call out the rollback path (revert
  `targetRevision`; ArgoCD self-heals within its sync interval; Envoy Gateway
  is stateless control plane, so a revert recovers immediately with no data
  loss). `docs/done/` entry required. Closes #671.
  (auto/envoy-gateway-chart-1-8-3)

- [x] 🟢 **Bump kiali-server chart `1.89.8` → `2.29.0`** (CHARTER **Core Values**
  §"Everything as code" + §"Docs & dashboards don't drift"; RFC #668 — architect
  decision 2026-07-23, ADR-0012 audit resolved as **Convert**.) Discovered live:
  `gitops/platform/kiali.yaml`'s pinned `kiali-server` chart `1.89.8` (the last
  pre-2.0 release) no longer resolves in the live `kiali.org/helm-charts` index,
  breaking `make ci`'s `helm-chart-pin-check.sh` drift gate for every PR on
  `main` regardless of diff — verified not transient (main's own CI passed this
  exact check 4.5 hours before the break was found). Decision + implementation
  landed in the same PR (rather than the usual RFC-then-separate-executor-PR
  split) because the break affects the base branch itself: any subsequent PR's
  CI would also show this same unrelated failure until the pin is fixed, so
  waiting for a second PR would mean deliberately merging over a known-red
  check with no way to get green first. See ADR-0012's Re-evaluation log
  (2026-07-23 entry) and RFC #668 for the full verification trail (confirmed
  the Kiali 2.0 breaking changes — Discovery Selectors, `kubernetes_config.
  cache_*` removal, `istio_namespace` removal — don't touch this lab's
  `valuesObject` keys). `docs/dependency-tree.md` and `tests/platform.bats`
  updated. Kiali is on-demand/non-auto-synced (ADR-0012) — zero live-cluster
  blast radius. `make ci` must pass. `docs/done/` entry required. Closes #668.
  (arch/adr-0012-kiali-chart-index-audit)

- [x] 🟢 **Bump Valkey image tag `8.0-alpine` → `8.0.10-alpine`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC/issue #655 — architect decision
  2026-07-22, ADR-0018 audit #654 resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) Valkey shipped a coordinated security release
  across every maintained branch on 2026-07-21 (`8.0.10`/`8.1.9`/`9.0.5`/`9.1.1`),
  fixing **CVE-2026-56684** (TLS use-after-free, authenticated-client DoS via
  `CLIENT KILL`) and **CVE-2026-63639** (corrupt stream RDB with shared NACK across
  consumers) — confirmed directly from Valkey's own GitHub release page
  (`github.com/valkey-io/valkey/releases/tag/8.0.10`), marked "Upgrade Urgency:
  SECURITY". This lab pins the floating tag `valkey/valkey:8.0-alpine`
  (`gitops/data/valkey/statefulset.yaml`, `gitops/data/demo/valkey-load.yaml`) — this
  is exactly the flip condition ADR-0018's own prior audit (#627, 2026-07-20) recorded
  in advance: "A CVE ... disclosed against the `8.0.x` line that `8.1.x` (or later)
  fixes."

  Bump both files' `image:` field from `valkey/valkey:8.0-alpine` to
  `valkey/valkey:8.0.10-alpine` (the smallest safe delta on the `8.0.x` line — same
  reasoning as the Cilium/Kargo/Grafana pin bumps; deliberately not jumping to
  `8.1.x`/`9.x` since the fix is fully available on `8.0.x` and no lab-teaching need
  exists for those minors). Grep both files for every literal `8.0-alpine` occurrence
  to catch any other reference. Add a new dated entry to ADR-0018's
  `## Re-evaluation log` (after the existing 2026-07-20 audit #627 entry) recording
  this bump, citing both CVE IDs and the 8.0.10 release date, with a new flip
  condition for the next audit.

  Extend the relevant `tests/*.bats` file covering Valkey (check for an existing
  image-tag pin assertion first; add one if none exists) asserting
  `valkey:8.0.10-alpine` is present in both files — a recurrence guard mirroring the
  existing Argo Rollouts/Grafana image-tag pin assertions. No topology change, so no
  README/`docs/dependency-tree.md` update is expected — note that explicitly in the
  PR body. PR body must document: both CVE IDs, why `8.0.10` (smallest safe delta),
  and the ADR-0004 caveat that this remote clusterless session cannot verify Valkey
  starts cleanly post-bump on a live cluster — call out the rollback path (revert the
  image tag; ArgoCD self-heals; Valkey is a single-replica StatefulSet with an RDB
  snapshot every 60s, so a revert re-rolls the same way the bump did, recovering in
  place per ADR-0018's "Single node" section). `make ci` must pass. `docs/done/`
  entry required. Closes #655. (auto/valkey-cve-bump-8-0-10)

- [x] 🟢 **`docs/dora-resilience-mapping.md` — DORA (EU regulation) pillar mapping,
  explicitly not a compliance claim** (RFC #586 — architect decision 2026-07-19.
  **No prerequisites — executor may pick up immediately.**) Implement RFC #586's
  binding spec exactly — the applicability question is already decided, do not
  re-litigate it: this lab is not an EU-regulated "financial entity" or a
  designated critical ICT third-party provider under Regulation (EU) 2022/2554
  Article 2, so it must never claim DORA regulatory compliance anywhere in the
  repo.

  New `docs/dora-resilience-mapping.md`. Opens with an explicit, prominent
  disclaimer naming DORA's real Article 2 scope and this lab's non-membership in
  it — do not bury or soften this. Then one section per pillar:
  1. **ICT risk management framework** → cite this repo's ADR process
     (`docs/decisions/`) + CHARTER Core Values, naming at least
     [ADR-0016](docs/decisions/adr-0016-default-deny-networkpolicy.md)
     (default-deny NetworkPolicy),
     [ADR-0017](docs/decisions/adr-0017-pod-security-standards-restricted.md)
     (PSS-restricted), and
     [ADR-0022](docs/decisions/adr-0022-trivy-operator-supply-chain.md) (Trivy
     continuous scanning) as concrete evidence.
  2. **ICT incident management/classification/reporting** → cite
     `docs/dora-metrics.md`'s real "Time to restore service" row (RFC #580 /
     Objective O7, `make dora-metrics`) directly — do not re-derive or duplicate
     that computation.
  3. **Digital operational resilience testing** → cite `make dr-verify`,
     `make dr-test`, `make dr-bluegreen` by name as real, exercised recovery
     drills (see `docs/DR.md`).
  4. **ICT third-party risk management** → cite Trivy Operator continuous
     scanning ([ADR-0022](docs/decisions/adr-0022-trivy-operator-supply-chain.md)),
     `scripts/helm-chart-pin-check.sh`, and
     [ADR-0025](docs/decisions/adr-0025-free-oss-tiers-only.md)'s free/OSS-tier
     policy.
  5. **Information-sharing arrangements** → explicit **"not applicable"** note
     (one line: this pillar concerns inter-financial-entity threat-intel
     consortiums; nothing in a solo personal lab maps to it honestly) — do not
     omit this section or stretch a mapping onto it.

  Every citation must point at something that actually exists in the repo today —
  verify each ADR number, script path, and `make` target resolves before
  committing (ADR-0004; `make markdown-links-check` will catch broken relative
  links but not a wrong ADR *number* cited in prose, so check by hand). Add the
  CHARTER Goals-section sentence only if it isn't already present — verify first,
  it may already have landed via RFC #586's own architect PR (#587). `make ci`
  must pass. `docs/done/` entry required. Closes #586.
  (auto/dora-resilience-mapping)

- [x] 🟢 **`scripts/dora-metrics.sh` + `make dora-metrics` — DORA metrics from git/CI
  history** (CHARTER new **Objective O7**; RFC #580 — architect decision 2026-07-19.
  **No prerequisites — executor may pick up immediately.**) Implement RFC #580's
  binding spec exactly — do not re-derive the definitions, they are already decided:

  1. **Deployment frequency** = count of merge commits to `main` per calendar week,
     across every agent branch prefix (`auto/*`, `plan/*`, `arch/*`, `upgrade/*`,
     `sync/*`, `chore/*`) plus human `feat/*`/`fix/*`. Compute via `git log --merges
     --since=<start> --until=<end> main` (default window: trailing 90 days).
  2. **Lead time for changes** = median wall-clock time between a merged PR's first
     commit's author-date and its merge-commit date on `main`, per PR in the window.
  3. **Change failure rate** = (reverts + same-area fix-forwards) / total deployments
     in the window. A "failure" is either (a) a merge commit whose message contains
     "revert" referencing an earlier in-window commit, or (b) a `fix:`-titled PR
     merged within 72h of a prior merge that touched at least one overlapping file
     path (compare `git show --name-only` file lists between the two merge commits).
  4. **Time to restore service** = for each red→green transition of `main`'s
     `ci.yml` workflow (GitHub Actions API, `branch=main`, `workflow=ci.yml`), the
     wall-clock delta between the first failing run's `created_at` and the next
     successful run's `updated_at`.

  New `scripts/dora-metrics.sh` (clusterless — no `kubectl`/`argocd`/`vault`/
  `colima`; reads `git log` directly + calls the GitHub Actions API the same way
  other routines already do) computes all four for the default 90-day window
  (overridable via a `DORA_SINCE`/`DORA_UNTIL` env var pair) and regenerates
  `docs/dora-metrics.md` as a plain markdown table. **Per ADR-0004: any metric that
  cannot be computed for lack of evidence (e.g. zero CI runs in the window) MUST
  render as the literal string "insufficient data" — never a fabricated or
  extrapolated number.** New `dora-metrics` `.PHONY` Makefile target invoking the
  script (mirror the `dr-verify` target's on-demand, non-`make up`-wired shape —
  this is explicitly NOT registered in any auto-run path). Commit
  `docs/dora-metrics.md` with one real generated snapshot from this repo's actual
  history (not a stub/template — run the script for real and commit its output).

  New `tests/dora-metrics.bats` (clusterless structural — no live git-log/API calls
  required to run in CI beyond what this repo's own history already provides):
  script exists + is executable; `Makefile` declares the `dora-metrics` target and
  it is NOT invoked from the `up`/`ci` targets (on-demand only, mirroring the
  `dr-verify` pattern); the script handles a synthetic zero-data window (e.g.
  `DORA_SINCE`/`DORA_UNTIL` set to a date range with no commits) by printing
  "insufficient data" and exiting 0, not crashing or fabricating a number.

  Add **Objective O7** cross-reference: this item alone satisfies O7's `make ci`
  presence check (script exists + executable + Makefile target wired) — O7 itself
  was already added to CHARTER.md by RFC #580's own architect PR (#581), no further
  CHARTER edit needed here. `make ci` must pass. `docs/done/` entry required.
  **Executor note:** RFC #580's full spec (rationale, scope & exceptions, exact
  acceptance criteria) is the binding source — read it before starting, don't
  re-derive from this summary alone. Closes #580. (auto/dora-metrics)

- [x] 🟢 **Replace the dead "idle issue" fallback across every routine prompt with a
  `[Action needed]` PR** (CHARTER **Core Values** §"Docs & dashboards don't drift" +
  governance correctness; user-filed issue #569 — **no prerequisites, executor may pick
  up immediately**; this is a workflow/governance fix per CLAUDE.md's "governance...
  and workflow (routines, CI, Makefile, hooks) are all yours to propose, implement, and
  merge", not an ADR/RFC-gated technical choice). Verified directly against the actual
  repo state (not assumed, ADR-0004): `scripts/idle-issue-guard-check.sh`, wired as a
  `PostToolUse` hook on `mcp__github__issue_write`/`mcp__github__add_issue_comment` in
  `.claude/settings.json` (matcher block ~line 147), unconditionally flags **any** issue
  title/body containing the standalone word "idle" (regex `\bidle\b|\bno work\b|nothing
  to do|no actionable`) and instructs the routine to close the issue and undo the
  action. Every routine's own documented "never end empty-handed" terminal fallback
  creates or refreshes an issue whose title contains "idle" as a standalone word —
  `executor.prompt.md` STEP 6b ("executor idle — needs work"), `planner.prompt.md`
  STEP 4 (same title), `janitor.prompt.md` STEP 6 ("janitor idle — no cleanup found"),
  `triager.prompt.md` STEP 6 ("triager idle — no untriaged issues"),
  `doc-drift-author.prompt.md` STEP 7 ("doc-drift idle — docs are in sync"),
  `upgrade-drafter.prompt.md` STEP 7 ("upgrade idle — everything at latest"),
  `learning-post-writer.prompt.md` STEP 7 ("learning idle — quiet week, no post") —
  every one of these is dead code: the moment a routine executes its own documented
  last resort, the hook fires and tells it to reverse the very action its own prompt
  just told it to take. This is the concrete gap issue #569 names ("If there are some
  actions needed from the repo owner, then leave an open PR, starting with
  [Action needed]...").

  Fix, applied uniformly to all seven prompt files above: replace each "file/refresh a
  `<role> idle — ...` GitHub issue" terminal step with — open (or refresh, if a
  matching one is already open: search `gh pr list --state open --search "in:title
  [Action needed]"` first) a PR on a new branch (the role's own existing prefix, e.g.
  `auto/action-needed-<slug>` from the executor, `chore/action-needed-<slug>` from the
  janitor, etc. — never a new dedicated prefix) whose only content is a new
  `docs/backlog/YYYY-MM-DD-action-needed-<slug>.md` file stating precisely what is
  blocked and, if applicable, exactly what maintainer action (outside the repo, e.g.
  confirming a live-cluster state, setting a CI secret) would unblock it. Title the PR
  `[Action needed] <one-line summary>` (never containing the word "idle" — the guard's
  scrub only strips hyphenated `idle-*` compounds, so keep the word out of both title
  and body entirely). Run the normal self-review + self-merge contract on it
  (WAYS-OF-WORKING.md §0.1/§3/§4 apply to every PR, no exception) — it is a real,
  reviewable, `make ci`-trivial diff (a single new markdown file), so it merges the
  same run; the `[Action needed]` prefix makes it a low-noise, filterable signal in the
  maintainer's normal PR list, not a blocked state. This satisfies rule #9's "every run
  ships a PR" **literally** (a PR, not an issue) instead of relying on a mechanism the
  repo's own hook already disables.

  Recurrence guard: extend `tests/drift-detectors.bats` (or add a dedicated
  `scripts/idle-issue-hook-coverage-check.sh` wired into `make ci` if a bats-only
  assertion can't reach across all seven files cleanly — check the existing pattern
  first) asserting no `routines/*.prompt.md` file pairs `gh issue create` or
  `mcp__github__issue_write` with the standalone word "idle" in the same step — a
  grep-based structural check mirroring this repo's other `scripts/<thing>-check.sh`
  drift detectors. This is the mechanical guard per CLAUDE.md's bugfix-prevents-
  recurrence rule, preventing a future edit from reintroducing a fallback path the hook
  will immediately undo. `make ci` must pass. `docs/done/` entry required. **Delivered
  as PR 1 of 2:** the combined seven-file diff crossed the ~400 changed-line budget
  (WAYS-OF-WORKING.md §3), so this PR fixes `executor.prompt.md` + `planner.prompt.md`
  only (the two roles STEP 6b's fallback chain actually reaches) plus
  `tests/action-needed-fallback.bats` covering those two files. The remaining five
  roles are split into the follow-up item directly below. Closes #569.
  (auto/action-needed-pr-fallback)

- [x] 🟢 **`[Action needed]` PR fallback — remaining five routine prompts** (CHARTER
  **Core Values** §"Docs & dashboards don't drift"; PR 2 of 2, follow-up to the item
  directly above — **no prerequisites, executor may pick up immediately**). Apply the
  same fix to `janitor.prompt.md` STEP 6, `doc-drift-author.prompt.md` STEP 7, and
  `upgrade-drafter.prompt.md` STEP 7: replace each "file/refresh a `<role> idle — ...`
  GitHub issue" terminal step with opening/refreshing a PR titled `[Action needed]
  <one-line summary>` on the role's own branch prefix (`chore/action-needed-<slug>`
  for janitor, `sync/action-needed-<slug>` for doc-drift-author,
  `upgrade/action-needed-<slug>` for upgrade-drafter) whose only content is a new
  `docs/backlog/YYYY-MM-DD-action-needed-<slug>.md` note — same shape as the executor
  and planner fix above.

  **`triager.prompt.md` and `learning-post-writer.prompt.md` need a *different* fix,
  not the uniform one** — verify this before writing either file (ADR-0004): both
  declare themselves PR-less by design (`triager.prompt.md`'s own CONSTRAINTS: "Labels
  only... no PRs"; `learning-post-writer.prompt.md` writes exactly one
  `docs/learnings/` file per run, no code). Opening an `[Action needed]` PR from either
  would contradict their own stated contract. Instead, for both: drop the
  issue-filing fallback entirely and treat "nothing to triage" / "quiet week, nothing
  pedagogically interesting merged" as an accepted no-op — mirror
  `routines/architect.prompt.md` STEP 9's precedent ("If there were no 🟡 items without
  RFCs AND no ADR audit flags this week, do NOT open a churn PR... A no-op is
  acceptable for the architect"). Each already ends with (or can easily gain) a
  one-line summary in its own output (triager's CONSTRAINTS already require
  `Triaged: N — needs-domain: M — skipped: K`) — that line is sufficient; no artifact
  needed when there's genuinely nothing to do.

  Extend `tests/action-needed-fallback.bats` with the same two-assertion pattern (no
  `issue create`/`issue_write`, contains `[Action needed]`) for `janitor.prompt.md`,
  `doc-drift-author.prompt.md`, and `upgrade-drafter.prompt.md`; add a third assertion
  for `triager.prompt.md` and `learning-post-writer.prompt.md` confirming neither
  contains `issue create`/`issue_write` either (their fix removes the call entirely
  rather than replacing it with a PR). Update this bats file's own header comment to
  drop the "tracked follow-up, not yet covered" note once all seven files are done.
  `make ci` must pass. `docs/done/` entry required. (auto/action-needed-pr-fallback-2)

- [x] 🟢 **Bump Grafana image tag `13.0.1` → `13.0.3`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC/issue #563 — architect decision
  2026-07-19, ADR audit #562 resolved as **Convert**. **No prerequisites — executor
  may pick up immediately.**) `13.0.1` (our current pin, released 2026-04-17) is
  vulnerable to seven CVEs fixed in `13.0.2` (2026-06-09): `CVE-2026-9029`,
  `CVE-2026-33382`, `CVE-2026-42127`, `CVE-2026-42129`, `CVE-2026-10601`,
  `CVE-2026-8609`, `CVE-2026-8595` — confirmed directly from Grafana's own
  `CHANGELOG.md` fetched at the real `v13.0.2` git tag via
  `raw.githubusercontent.com` (not inferred; `github.com`/`api.github.com` are
  proxy-blocked in this environment but the raw CDN host is not), and via a real,
  `active` `13.0.2` Docker Hub image (confirmed against Docker Hub's real tags
  API). A distinct `v13.0.1+security-01` tag (different commit SHA than plain
  `v13.0.1`) further confirms Grafana Labs shipped an out-of-band security
  backport for exactly our pinned version. No ADR governs Grafana as a
  technology/version choice (ADR-0006 only covers the git-sync delivery
  mechanism), so this needs no ADR file change — same shape as the Kargo CVE
  bumps.

  Bump `gitops/platform/observability-grafana.yaml`'s `image.tag` override from
  `"13.0.1"` to `"13.0.3"` — the newest patch on the `13.0.x` line (no distinct
  new CVEs documented for it beyond `13.0.2`'s, likely a base-image maintenance
  rebuild; it is the smallest safe delta that carries every known fix without
  jumping to the `13.1.x` minor line, same reasoning as the Cilium 1.17.18 pick,
  RFC #501). Do **not** change the chart `targetRevision` (`12.7.2` stays — the
  CVEs are in Grafana's own binary, not the chart's templating; this is an
  image-tag-only override, identical technique to the Argo Rollouts bump,
  RFC #552). Grep the file for every literal `13.0.1` occurrence (the
  `valuesObject.image.tag` field and the informational
  `docker.io/grafana/grafana:13.0.1` reference) and update all of them.

  Extend the relevant `tests/observability*.bats` file (check for an existing
  Grafana image-tag pin assertion first; add one if none exists) asserting
  `tag: "13.0.3"` / `grafana:13.0.3` is present — a recurrence guard mirroring
  `tests/argo-rollouts.bats`'s image-tag assertions. No topology change, so no
  README/`docs/dependency-tree.md` update is expected — note that explicitly in
  the PR body. PR body must document: the seven CVE IDs, why `13.0.3` (smallest
  safe delta), and the ADR-0004 caveat that this remote clusterless session
  cannot verify Grafana actually starts cleanly post-bump on a live cluster —
  call out the rollback path (revert the `image.tag` override; ArgoCD self-heals;
  Grafana is a single Deployment so a revert re-rolls the same way the bump did).
  Note explicitly that full CVSS/description detail for the seven CVE IDs could
  not be fetched from this sandbox (`grafana.com/security/...` and
  `github.com/advisories/...` were both unreachable/blocked) — the CVE IDs and
  fixed-version mapping are grounded in Grafana's own official CHANGELOG.md, not
  fabricated severity detail (ADR-0004). `make ci` must pass. `docs/done/` entry
  required. Closes #563. (auto/grafana-cve-bump-13-0-3)

- [x] 🟢 **Pin k3s to an explicit version on every backend** (CHARTER **Core Values**
  §"Recreate-from-code" + §"Clusterless gates stay green"; RFC/issue #558 — architect
  decision 2026-07-19, new [ADR-0030](docs/decisions/adr-0030-pin-k3s-version-explicitly.md)
  (no existing ADR governed k3s's version — adopted directly per WAYS-OF-WORKING.md
  §0.1/§2). **No prerequisites — executor may pick up immediately.**) Neither backend
  pins a k3s version today: `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` has no
  `image:` key (k3d uses whatever's bundled with the installed CLI), and
  `infra/modules/oracle-k3s-cluster/cloud-init.yaml` installs via
  `curl -sfL https://get.k3s.io | sh -` with no `INSTALL_K3S_VERSION` (always fetches
  current `stable`). This broke CHARTER's "recreate-from-code" Core Value (two `make up`
  runs months apart aren't reproducing the same lab) and meant k3s — the most privileged
  layer in the stack — had no recorded version for the architect's weekly CVE sweep to
  check against (the concrete trigger this pass: CVE-2026-54250, K3s ZIP path traversal
  in etcd-snapshot decompression, fixed in `1.33.10`/`1.34.6`/`1.35.3` — whether this lab
  was affected was unanswerable with no pin on record).

  Pin **`v1.36.2+k3s1`** on both backends — verified directly (not assumed, ADR-0004):
  the git tag is real (corroborated via a second independent source alongside the
  latest `1.34.x`/`1.35.x` patches, confirming `1.36.2` is genuinely the current stable
  line), and the `rancher/k3s:v1.36.2-k3s1` Docker Hub image was **positively confirmed**
  via Docker Hub's real tags API (`tag_status: active`, multi-arch, real digest and
  `last_updated` timestamp) — a direct registry check, not an indirect inference.
  Comfortably past CVE-2026-54250's fix lines on every supported branch.

  Add `image: rancher/k3s:v1.36.2-k3s1` (hyphen tag format) as a new top-level key in
  `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` — `image` is a documented top-level
  field of k3d's own `k3d.io/v1alpha5` `Simple` config schema, sibling to the existing
  `servers`/`agents`/`kubeAPI`/`ports`/`options` keys already in that file. Change
  `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s install line to
  `curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.36.2+k3s1 sh -` — note the
  **different tag format** (`+` here vs. the Docker Hub tag's hyphen — a real footgun,
  see ADR-0030's "Tag-format note"). Update `docs/decisions/context.md`'s stale
  "k3s v1.33.6, 2 nodes" line to reflect the pin. Add `tests/k3s-version-pin.bats`
  (clusterless — no `terraform apply`, no cluster) asserting both backends reference
  `v1.36.2+k3s1`/`v1.36.2-k3s1` respectively (the correct format each) — a recurrence
  guard so a future bump that updates one backend and forgets the other's different tag
  format fails `make ci`, mirroring this repo's existing per-component pin-assertion
  pattern (`argo-rollouts.bats`'s `targetRevision` checks, etc.).

  **ADR-0004 caveat, carry into the PR body:** this is a Terraform-bootstrap-seam change
  (ADR-0001's boundary — never workload/GitOps) that this remote clusterless session
  cannot verify against a live `make up` or a real Oracle instance launch (the Oracle
  path is separately still blocked on an unrelated Always Free capacity constraint per
  `infra/live/README.md`). State plainly in the PR that live verification is pending the
  maintainer's next local `make up` / cloud apply — do not claim it was exercised.
  `make ci` (terraform fmt/validate, no live apply) must pass. `docs/done/` entry
  required. Closes #558. (auto/k3s-version-pin)

- [x] 🟢 **Bump Argo Rollouts image tag `v1.9.0` → `v1.9.1`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC/issue #552 — architect decision
  2026-07-19, ADR-0020 audit resolved as **Convert** (converts the 2026-07-18
  "Keep" from audit #520 with new signal). **No prerequisites — executor may pick
  up immediately.**)
  [CVE-2026-35469](https://github.com/argoproj/argo-rollouts/releases/tag/v1.9.1)
  (fixed in `v1.9.1`, released 2026-07-17): a `google.golang.org/grpc` dependency
  fix closing upstream issue #4667. Audit #520 correctly kept the chart pin
  because the `argo/argo-rollouts` Helm chart (this lab's deploy mechanism,
  `gitops/platform/argo-rollouts.yaml`, `targetRevision: 2.41.0`) has not yet
  published a release tracking `appVersion >= 1.9.1` — bumping `targetRevision`
  today would assert a fixed posture with nothing newer to actually pin to
  (ADR-0004). That audit did not consider a second lever this repo already uses
  elsewhere: pinning the **image tag** independently of the chart version, the
  same technique `gitops/platform/observability-grafana.yaml` uses (`image.tag:
  "13.0.1"` on top of an unrelated chart version) — the `argo/argo-rollouts`
  chart's `values.yaml` exposes the identical override for both
  `controller.image.tag` and `dashboard.image.tag`.

  Edit `gitops/platform/argo-rollouts.yaml`'s `spec.source.helm.valuesObject`:
  add `image: { tag: "v1.9.1" }` under both the existing `controller:` block and
  the existing `dashboard:` block (do not touch `targetRevision`, which stays
  `2.41.0`). Extend `tests/argo-rollouts.bats` with two new assertions — grep
  for `tag: "v1.9.1"` appearing under both the controller and dashboard sections
  — alongside the existing, unchanged `targetRevision: 2\.41\.` pin assertion.
  No topology change, so no README/`docs/dependency-tree.md` update is expected
  — note that explicitly in the PR body so a reviewer doesn't wonder why it's
  missing. See RFC #552 and
  [ADR-0020's Re-evaluation log](docs/decisions/adr-0020-argo-rollouts-progressive-delivery.md#re-evaluation-log)
  (2026-07-19 entry) for the full verification reasoning, including an explicit
  ADR-0004 note that the `quay.io` image manifest itself could not be directly
  confirmed from this environment (registry API blocked by the sandbox's egress
  policy) — grounded instead via the real `v1.9.1` git tag plus the project's
  own tag-triggered release workflow, which pushes that exact image as part of
  the same pipeline that published the live GitHub Release. If the executor CAN
  reach the registry directly and wants to double-check the tag pulls before
  landing this, that's a welcome belt-and-suspenders step, not a blocker. `make
  ci` must pass. `docs/done/` entry required. Closes #552.
  (auto/argo-rollouts-cve-image-tag)

- [x] 🟢 **ADR-0006 — remove stale "Follow-up: wire both bootstraps into `make up`/DR"
  note** (CHARTER **Core Values** §"Docs & dashboards don't drift"; planner gap-analysis
  finding, 2026-07-18 — **no prerequisites, executor may pick up immediately**). The
  ADR-0006 `## Decision` §Status paragraph ends with "(Follow-up: wire both bootstraps
  into `make up`/DR.)" — but both bootstraps are already wired: `Makefile`'s `up` target
  calls `$(MAKE) gitlab-tls-bootstrap` (line 187) and `$(MAKE) grafana-gitsync-bootstrap`
  (line 191), both between `vault-bootstrap` and `frontdoor`/root-app sync, and both
  `.PHONY` targets (`gitlab-tls-bootstrap` line 371, `grafana-gitsync-bootstrap` line 375)
  exist and run their respective scripts. Verified directly against the current
  `Makefile` (not assumed, per ADR-0004) before filing this item. This is stale-doc
  drift, not a missing feature: the ADR's own claim about its still-open follow-up no
  longer matches the repo's actual state. Fix: delete the parenthetical
  "(Follow-up: wire both bootstraps into `make up`/DR.)" sentence from ADR-0006's
  `## Decision` §Status paragraph (`docs/decisions/adr-0006-grafana-native-git-sync.md`)
  — the preceding sentences in that paragraph ("Implemented + verified live... The
  Repository connection is bootstrapped imperatively... Community (gnetId) dashboards
  are unaffected.") already stand on their own without it, so no replacement text is
  needed. No `make ci` gate exercises ADR prose today; if the executor wants a mechanical
  recurrence guard, a lightweight one is welcome (e.g. extend
  `scripts/adr-guard-hook.sh` or add a small `tests/` assertion that no ADR under
  `docs/decisions/` contains the literal string "Follow-up:" once its named target
  Makefile line is confirmed present — optional, not required to land this fix). `make
  ci` must pass. `docs/done/` entry required. (auto/adr-0006-stale-followup-note)

- [x] 🟢 **Bump Cilium `1.16.6` → `1.17.18`** (CHARTER **Core Values** §"Everything
  as code" + general hardening; RFC/issue #501 — architect decision 2026-07-18,
  ADR audit resolved as **Convert**. **No prerequisites — executor may pick up
  immediately.**)
  [CVE-2026-49445](https://github.com/cilium/cilium/security/advisories/GHSA-3fcv-jvfp-m4q9)
  (disclosed 2026-07-15): Cilium's Envoy proxy creates a world-accessible
  `admin.sock` on cluster nodes when Envoy runs — a local attacker on the node
  can reach Envoy's admin endpoints (expose TLS secrets, disrupt traffic, kill
  the Envoy process). Affects all versions before 1.17.14, 1.18.0–1.18.7, and
  1.19.0–1.19.1; fixed in 1.17.14, 1.18.8, 1.19.2. This lab pins Cilium at
  `1.16.6` (`gitops/platform/cilium.yaml`, ADR-0014) — in the affected range.
  Verified applicability against the actual deployed config (not just the
  version number, per ADR-0004): the pinned chart's `values.yaml` at tag
  `v1.16.6` defaults `envoy.enabled: ~` (null), and the chart's own comment
  states this means Envoy's standalone DaemonSet "is enabled by default for
  new installation" — i.e. Envoy (and its admin.sock) runs in this lab's
  cluster today regardless of whether any L7 `CiliumNetworkPolicy` is
  authored. `gitops/platform/cilium.yaml` does not override `envoy.enabled`,
  so the default applies. (A second CVE found in the same sweep,
  CVE-2026-56742 — Gateway API traffic mirroring — does NOT apply: it requires
  Cilium's own Gateway API implementation, which this lab does not use;
  ingress is Envoy Gateway per ADR-0008, a separate product. No action needed
  for that one.)

  Bump `gitops/platform/cilium.yaml`'s `targetRevision` from `1.16.6` to
  `1.17.18` (the latest patch on the 1.17.x line — includes the CVE-2026-49445
  fix at the smallest version delta from the current pin, deliberately not
  jumping to 1.18.x/1.19.x). No `valuesObject` change is required — the fix is
  internal to the bundled Envoy binary, not a values-schema change. ADR-0014
  already states "chart `cilium/cilium` ≥ v1.16" so no ADR text change is
  needed; 1.17.18 still satisfies that floor. Extend `tests/cilium.bats` (or
  add a chart-pin assertion if none exists yet — check first) asserting the
  new pinned version. PR body must document: the CVE, why it's applicable to
  this lab's actual config (Envoy runs by default), why 1.17.18 was chosen
  (smallest safe delta), and the ADR-0004 caveat that this remote clusterless
  session cannot verify pod networking stays healthy post-bump on a live
  cluster — call out the rollback path prominently (revert `targetRevision`,
  ArgoCD self-heals; Cilium is a DaemonSet so a revert re-rolls the same way
  the bump did) given Cilium is the CNI and the highest-blast-radius bump in
  the stack. `make ci` must pass. `docs/done/` entry required. Closes #501.
  (auto/cilium-cve-bump-1-17-18)

- [x] 🟢 **Bump Kargo `1.2.3` → `1.6.4`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; RFC/issue #508 — architect decision 2026-07-18,
  ADR audit resolved as **Convert**. **No prerequisites — executor may pick up
  immediately.**)
  [CVE-2026-24748](https://github.com/akuity/kargo/security/advisories/GHSA-w5wv-wvrp-v5m5)
  (medium, CVSS 6.9): Kargo's `GetConfig()` and `RefreshResource()` API
  endpoints have a broken authentication check — an unauthenticated caller can
  access them by supplying a non-empty (even invalid) `Bearer` token,
  exfiltrating sensitive configuration data including connected ArgoCD cluster
  endpoints, and enabling denial-of-service against `RefreshResource`.
  Affected: all versions up to and including v1.8.6. Fixed in three parallel
  branch releases: `v1.6.3`, `v1.7.7`, `v1.8.7`. This lab pins Kargo at `1.2.3`
  (`gitops/platform/kargo.yaml`) — well inside the affected range.
  Two other Kargo CVEs found in the same sweep do NOT apply to our current pin
  (both require code introduced at 1.7.0+ or 1.9.0+, above our current
  version): [CVE-2026-27112](https://github.com/akuity/kargo/security/advisories/GHSA-7g9x-cp9g-92mr)
  (critical, affects >=1.7.0 <1.7.8/<1.8.11/<1.9.3) and
  [CVE-2026-27111](https://github.com/akuity/kargo/security/advisories/GHSA-5vvm-67pj-72g4)
  (affects only 1.9.0–1.9.2). Bump to `1.6.4` (latest patch on the `1.6.x`
  line — one better than the `1.6.3` minimum fix) deliberately to resolve
  CVE-2026-24748 **without** entering the 1.7.0+ range the other two CVEs
  cover — the smallest safe delta, same reasoning as the Cilium bump
  (RFC #501) above.
  **Important — this is a 4-minor-version jump, not a routine patch bump.**
  `gitops/kargo-project/project.yaml`'s `Warehouse`/`Project` resources are
  still on `kargo.akuity.io/v1alpha1` (pre-stable API, no cross-minor-version
  compatibility guarantee). The executor picking this up MUST verify the
  actual CRD schema for `Warehouse`/`Project`/any `PromotionTask` fields this
  repo uses is unchanged (or update accordingly) at the `v1.6.4` tag before
  landing this — fetch the real CRD definitions (sparse git clone of
  `akuity/kargo` at that tag; `ghcr.io`'s OCI registry doesn't expose an easy
  diff), do not assume a clean drop-in the way the Cilium/Kyverno bumps were
  (those only crossed one minor version each with a stable, well-documented
  values schema). Document what was checked in the PR body. Extend
  `tests/kargo.bats` asserting the new pin. PR body must document the CVE, why
  `1.6.4`, the CRD-compatibility verification performed, and the ADR-0004
  caveat that this remote clusterless session cannot verify Kargo actually
  starts cleanly on a live cluster post-bump — note the rollback path (revert
  `targetRevision`; Kargo is on-demand and not currently synced anywhere, so
  rollback carries zero live-cluster risk beyond what a `make kargo-up` would
  encounter). `make ci` must pass. `docs/done/` entry required. Closes #508.
  (auto/kargo-cve-bump-1-6-4)

- [x] 🟢 **Bump Kargo `1.6.4` → `1.10.9`** (CHARTER **Core Values** §"Everything
  as code" + general hardening; same-day follow-up to the `1.2.3`→`1.6.4`
  bump above, executor-initiated — **no prerequisites, no RFC needed**: this
  is a same-source patch/minor bump within upgrade-drafter's normal scope,
  just requiring the same CRD-compatibility rigor as the prior Kargo bump
  because of its pre-1.0-caliber API surface). A fresh audit of every
  published `github.com/akuity/kargo/security/advisories` entry against the
  `1.6.4` pin (chosen by the item above) found **four** advisories affecting
  it with no `1.6.x`-branch fix available (that branch is EOL upstream):
  [GHSA-xx8h-gw9m-m95p](https://github.com/akuity/kargo/security/advisories/GHSA-xx8h-gw9m-m95p)
  and [GHSA-f72x-6fm6-94rq](https://github.com/akuity/kargo/security/advisories/GHSA-f72x-6fm6-94rq)
  (privilege escalation / missing authorization via Generic Resource Creation
  API endpoints, affected `>=v0.1.0 <v1.11.0`, fixed `1.9.10`/`1.10.9`);
  [GHSA-wp4p-hr79-q4g8](https://github.com/akuity/kargo/security/advisories/GHSA-wp4p-hr79-q4g8)
  / CVE-2026-61850 (privilege escalation via Project RBAC management,
  affected `>=0.6.0`, fixed `1.8.14`/`1.9.9`/`1.10.8`); and
  [GHSA-g7gw-m874-7rmf](https://github.com/akuity/kargo/security/advisories/GHSA-g7gw-m874-7rmf)
  / CVE-2026-42350 (open redirect in the UI OIDC login flow, affected
  `<=v1.10.1`, fixed `1.10.2`+). The two CVEs the `1.6.4` bump deliberately
  stayed below (GHSA-7g9x critical, affects `>=1.7.0 <=1.9.2`; GHSA-5vvm,
  affects `1.9.0-1.9.2`) and the original CVE-2026-24748 remain correctly
  not-applicable/already-fixed at any version `>= 1.6.4` — that prior
  reasoning still holds, it was just stale relative to advisories disclosed
  since (three of the four newly-closed ones were published after the
  `1.6.4` pin was chosen). `1.10.9` is the highest stable release (verified
  against the real tag list, not inferred) and closes every open advisory.
  CRD/values compatibility re-verified the same way as the prior bump:
  `global.securityContext`, `api.{replicas,resources,tls.selfSignedCert,secret}`
  and `controller`/`webhooksServer` `resources` are all unchanged in path
  (only new, unrelated optional fields added elsewhere in `values.yaml`); the
  `Warehouse` `ImageSubscription` type (`RepoURL`/`ImageSelectionStrategy`/
  `DiscoveryLimit`, json tags unchanged) moved from `warehouse_types.go` to a
  new `zz_subscription_types.go` file, and the `argocd-update` step's config
  schema moved from `internal/promotion/runner/builtin/schemas/` to
  `pkg/promotion/runner/builtin/schemas/` (`internal/` was restructured into
  `pkg/` across this version range) — both are pure code-reorganization
  moves verified field-for-field, not schema changes. `make ci` must pass.
  `docs/done/` entry required.
  (auto/kargo-cve-bump-1-10-9)

- [x] 🟢 **`kyverno` PSA `baseline` → `restricted` flip** (CHARTER **Objective
  O2** hardening, RFC #483 — architect decision 2026-07-17, converting audit
  #482). Kyverno's own official docs (`kyverno.io/docs/installation/platform-notes/`)
  state the chart's default securityContext "conforms to the upstream Pod
  Security Standards' restricted profile" (the only documented incompatibility
  is OpenShift SCCs, irrelevant to this plain-k3d/k3s lab); independently
  verified against the actual pinned `kyverno-chart-3.3.4` tag that all four
  controllers (admission/background/cleanup/reports) already default to the
  full restricted container securityContext with no hostPath/host-namespace
  usage. No chart bump needed. **Executor must independently re-verify the
  pinned chart's rendered manifests before flipping — not just trust the
  RFC's citation — and flag rather than force the flip if a gap surfaces**
  (higher blast radius than the vault flip: Kyverno is the cluster-wide
  admission controller — a bad flip risks breaking admission for every
  namespace). Flip `gitops/kyverno/namespace.yaml`'s four PSA labels
  `baseline` → `restricted` only after that verification passes clean; if a
  gap is found, add the minimal `valuesObject` override needed to close it,
  or leave `kyverno` at `baseline` with the gap documented in the PR (per
  RFC #483's acceptance criteria — don't force the flip over an unresolved
  finding). Update the `kyverno` row in both ADR-0017's §Per-namespace
  profile table and ADR-0019's equivalent note/table to `restricted`; append
  a dated entry to ADR-0017's §Re-evaluation log. Extend
  `tests/securitycontext-kyverno.bats` (or similar) with the four PSA labels
  (and any `valuesObject` securityContext fields added). `make ci` must pass
  — PR body must document HOW the executor verified the chart (source fetch,
  not assumption) and note the ADR-0004 caveat that this remote clusterless
  session cannot confirm the admission webhook stays healthy under
  `restricted` on a live cluster; call out the rollback path (revert PSA
  labels, ArgoCD self-heals) prominently given the higher stakes.
  `docs/done/` entry required. Closes #483.
  (auto/kyverno-psa-restricted)

- [x] 🟢 **`vault` PSA `baseline` → `restricted` flip** (CHARTER **Objective
  O2** hardening, RFC #478 — architect decision 2026-07-17, converting audit
  #477; supersedes the 2026-06-11 audit #157 "keep" — see ADR-0017
  §"Re-evaluation log" for both entries). The flip condition #157 was waiting
  on is now met: a real, pinnable `hashicorp/vault-helm` chart release
  (`v0.34.0`, 2026-07-02) ships a Vault server (`v2.0.3`) that no longer holds
  `cap_ipc_lock` at build time (verified against `hashicorp/vault` release
  `v2.0.2`'s changelog, 2026-06-05). Bump `gitops/platform/vault.yaml` chart
  `0.32.0` → `0.34.0`; add `disable_mlock = true` to the standalone config;
  flip `gitops/vault/namespace.yaml`'s four PSA labels `baseline` →
  `restricted`; add the standard ADR-0017 §Layer 1 `securityContext` (verify
  exact chart value keys against the pinned `0.34.0` `values.yaml` — don't
  guess, ADR-0004) with an `emptyDir` carve-out for any non-PVC write path;
  bump `gitops/vault/unsealer.yaml`'s image `hashicorp/vault:1.21.2` →
  `hashicorp/vault:2.0.3`; update the ADR-0017 `vault` row to `restricted`.
  Extend `tests/securitycontext.bats` (or a dedicated vault test file) with
  the four PSA labels + the five Layer-1 securityContext fields. `make ci`
  must pass — note in the PR body that whether Vault actually starts cleanly
  under `restricted` + `disable_mlock` is not verifiable in this remote
  clusterless environment (same caveat every other chart bump here already
  carries). `docs/done/` entry required. Closes #478.
  (auto/vault-psa-restricted)

- [x] 🟢 **Governance LimitRange fan-out — `cert-manager` + `keda`** (CHARTER
  **Core Values** §"Fits the 16 GB reality" + §"Everything as code; GitOps
  deploys it"; RFC #294 / RFC #293 follow-up — **no prerequisites, executor may
  pick up immediately**). `gitops/platform/governance-appset.yaml`'s
  list-generator fans out a standard-tier LimitRange to every always-on
  namespace, but `cert-manager` (ADR-0028) and `keda` (ADR-0029) both landed
  after RFC #294's fan-out completed and were never added — each already has
  its own namespace + default-deny NetworkPolicy overlay, just no governance
  leaf (same gap `auto/harbor-governance-limitrange` closed for `harbor`).
  Add `gitops/governance/cert-manager/kustomization.yaml` and
  `gitops/governance/keda/kustomization.yaml` (each: `namespace: <ns>` +
  `resources: [../base/limitrange-standard.yaml]`, mirroring
  `gitops/governance/harbor/kustomization.yaml` exactly — no new
  `limitrange.yaml`; both use the shared standard-tier base). Add
  `cert-manager-governance` and `keda-governance` entries to the
  list-generator in `gitops/platform/governance-appset.yaml` (insert after the
  `node-exporter-governance` entry, before the `# heavy tier` comment, same
  ordering convention as every existing entry). Extend `tests/governance.bats`:
  add `cert-manager` and `keda` to the `STANDARD_NS` list (both checks that
  iterate it — leaf-dir-exists and appset-lists-every-standard-namespace —
  then cover both automatically), plus two dedicated test pairs mirroring the
  existing harbor block (kustomization exists + references the shared base;
  appset has the `<ns>-governance` entry, one pair per namespace). Update
  `docs/dependency-tree.md`'s wave-3 governance note (the `governance` AppSet
  parenthetical namespace list) to add `cert-manager` and `keda`. `make ci`
  must pass. `docs/done/` entry required. (auto/governance-cert-manager-keda)

- [x] 🟢 **`observability` readOnlyRootFilesystem tighten — Alloy** (CHARTER
  **Objective O2** hardening, ADR-0017 §"Per-workload field carve-outs"; split from the
  combined Alloy/Grafana/Pyroscope item filed 2026-07-14 — see that run's note below
  for the network-access finding that unblocked this). Verified against the actual
  `alloy` chart source at the pinned tag (`grafana/alloy` repo, tag `helm-chart/1.8.2`,
  `operations/helm/charts/alloy/templates/controllers/_pod.yaml` +
  `templates/containers/_agent.yaml`): contrary to this item's original comment, the
  chart does **not** create an `emptyDir` for `--storage.path` (default `/tmp/alloy`) —
  there is no volume or mount matching that path at all, so it was landing on the
  container's writable root fs. Fixed by adding an explicit `alloy-storage` `emptyDir`
  via `controller.volumes.extra` + `alloy.mounts.extra` at `/tmp/alloy`, then flipping
  `readOnlyRootFilesystem: false` → `true`. Extended
  `tests/securitycontext-observability.bats` with assertions for
  `readOnlyRootFilesystem: true` and the new mount. `make ci` must pass. `docs/done/`
  entry required. (auto/observability-readonlyrootfs-alloy)

- [x] 🟢 **`observability` readOnlyRootFilesystem tighten — Grafana** (CHARTER
  **Objective O2** hardening, ADR-0017 §"Per-workload field carve-outs"; split from the
  combined item filed 2026-07-14). Verified against the pinned chart source
  (`grafana-community/helm-charts` repo — the chart migrated off `grafana/helm-charts`
  — tag `grafana-10.5.15`, `charts/grafana/templates/_pod.tpl`) and the
  `grafana/grafana` image source (tag `v13.0.1`, `pkg/infra/log/log.go` +
  `packaging/docker/run.sh`): `GF_PATHS_DATA` (`/var/lib/grafana`, including the
  plugins subdir) is our existing PVC; `/var/lib/grafana-search`
  (`unified_storage.index_path`) is an unconditional chart-managed `emptyDir`
  regardless of values; `GF_PATHS_LOGS` (`/var/log/grafana`) is only `MkdirAll`'d by
  Grafana under `log.mode: file` — our config's `log.mode: console` (the chart
  default) never reaches that code path, so the directory is never created or
  written. No new mount was needed — flipped `readOnlyRootFilesystem: false` → `true`
  directly, replaced the stale "follow-up item" comment with the verified rationale,
  and extended `tests/securitycontext-observability.bats` with a
  `readOnlyRootFilesystem: true` assertion. `make ci` passes. `docs/done/` entry
  required. (auto/observability-readonlyrootfs-grafana)

- [x] 🟢 **`observability` readOnlyRootFilesystem tighten — Pyroscope** (CHARTER
  **Objective O2** hardening, ADR-0017 §"Per-workload field carve-outs"; split from the
  combined item filed 2026-07-14). Verified against the pinned chart source
  (`grafana/pyroscope` repo — the chart lives in the app's own repo, not
  `grafana/helm-charts` — tag `pyroscope-2.0.3`,
  `operations/pyroscope/helm/pyroscope/templates/deployments-statefulsets.yaml`): with
  this config (v1 storage disabled, v2 enabled — the chart default — single "all"
  component), the container mounts the same `data` PVC (our existing
  `persistence.enabled: true, size: 4Gi`) twice — at `/data` (no subPath) and at
  `/data-metastore` (subPath `.metastore`, the chart default, since `$isMetastore` is
  true for the `all` component under v2) — confirmed via the image's Dockerfile
  (`cmd/pyroscope/Dockerfile`, no `WORKDIR` override so `./data-metastore/...` CLI args
  resolve to `/data-metastore/...`) that both are the only local write paths; actual
  profile blocks go to the S3 backend (Garage) per `structuredConfig.storage.backend:
  s3`. No new mount was needed — flipped `readOnlyRootFilesystem: false` → `true`
  directly and replaced the stale comment with the verified rationale. Extended
  `tests/securitycontext-observability.bats` with a `readOnlyRootFilesystem: true`
  assertion. `make ci` passes. `docs/done/` entry required.
  (auto/observability-readonlyrootfs-pyroscope)

  > **Network-access note (found 2026-07-15, resolving the 2026-07-14 filing's
  > "proxy-restricted" blocker):** `https://grafana.github.io/helm-charts` (the Helm
  > repo index) and `https://api.github.com` are proxy-blocked in this environment, but
  > **`https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>`** for exact known
  > paths, and **`git clone --filter=blob:none --sparse https://github.com/<owner>/<repo>.git`**
  > (plus `git ls-remote --tags` to resolve a chart version to its tag) both work —
  > `github.com` and `api.github.com` are gated by this session's repo-scope allowlist,
  > but the raw CDN host and the git wire protocol are not. Use the sparse-clone
  > approach to read a pinned chart's actual `templates/` when the values-based
  > `helm show values` path isn't available locally — that satisfies this item's
  > "(a) ... cross-checked against the chart's `templates/` on GitHub" verification
  > method without needing a live cluster. Note some charts have migrated repos (e.g.
  > `grafana/helm-charts`'s `grafana` chart moved to `grafana-community/helm-charts`
  > as of this writing) — if a raw fetch 404s, check the old repo's chart README for a
  > migration notice before assuming the path is wrong.

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

- [x] 🟢 **`tests/dr-bluegreen.bats` — structural test gate for zero-downtime blue/green DR
  scripts** (CHARTER Goal "DR / blue-green on a single host"; `make ci` coverage gap —
  `docs/00-architecture.md` step 10 and `docs/DR.md §Zero-downtime blue/green` document
  the drill, and Makefile targets `dr-bluegreen`/`dr-bluegreen-down`/`dr-bluegreen-promote`
  exist, but no bats gate validates the underlying scripts' structural integrity or prevents
  the zero-downtime thresholds from being silently changed; the existing `bluegreen-probe.bats`
  only unit-tests the probe math — it doesn't assert the scripts exist, are executable, or
  reference the right GitOps resource. **No prerequisites — executor may pick up
  immediately.**) New `tests/dr-bluegreen.bats` with clusterless structural assertions
  (mirrors the `dr-restore.bats` pattern — no k3d, no kubectl, pure grep/bash):
  `gitops/bluegreen/green-root.yaml` exists (the serving-tier ArgoCD root planted on green);
  all six bluegreen scripts exist and are executable: `scripts/dr-bluegreen.sh`,
  `scripts/bluegreen-up.sh`, `scripts/bluegreen-frontdoor.sh`, `scripts/bluegreen-down.sh`,
  `scripts/bluegreen-probe.sh`, `scripts/dr-bluegreen-promote.sh`;
  `scripts/dr-bluegreen.sh` defines `MIN_UPTIME=99.0` (the uptime PASS threshold — the
  zero-downtime claim; changing this would silently weaken the drill verdict);
  `scripts/dr-bluegreen.sh` defines `MAX_OUTAGE=2.0` (the maximum outage seconds PASS
  threshold); `scripts/bluegreen-up.sh` references `gitops/bluegreen/green-root.yaml`
  (ensures the green cluster sources the right serving-tier root app);
  Makefile `dr-bluegreen` is `.PHONY` and calls `bash scripts/dr-bluegreen.sh`;
  Makefile `dr-bluegreen-down` is `.PHONY`; Makefile `dr-bluegreen-promote` is `.PHONY`.
  No Makefile changes, no script changes — tests only. `make ci` must pass. `docs/done/`
  entry required. (auto/dr-bluegreen-bats)

- [x] 🟢 **ADR-0019 amendment — add `add-default-runasnonroot` to the Initial ClusterPolicy
  set table** (CHARTER Core Values §"Decisions written down, rejected options off-limits";
  docs-only drift — ADR-0019 §"Initial ClusterPolicy set" lists 4 policies but
  `gitops/kyverno/policies/` now has 5: `add-default-runasnonroot.yaml` was added after the
  Harbor migration (`auto/harbor-application`) closed an admission gap — `goharbor` charts
  set container-level `runAsNonRoot` but not pod-level, which `require-pod-security-restricted`
  checks at the pod level; this 5th mutate policy injects the missing pod-level field.
  `tests/kyverno-add-default-runasnonroot.bats` correctly tests it, but the ADR table
  remains stale (only lists the original 4). **No prerequisites — executor may pick up
  immediately.**) Add a row to the ADR-0019 "Initial `ClusterPolicy` set" table:
  `| add-default-runasnonroot | mutate | Inject pod-level runAsNonRoot: true when missing
  — closes the admission gap exposed by the Harbor migration (ADR-0024): goharbor chart
  sets container-level but not pod-level runAsNonRoot; require-pod-security-restricted
  validates the pod level. See tests/kyverno-add-default-runasnonroot.bats. |`. Update the
  "All four policies" sentence after the table to "All five policies" (there are now 5).
  No code changes, no bats changes (the bats file already exists). `make ci` must pass.
  `docs/done/` entry required. (auto/adr-0019-runasnonroot-row)

- [x] 🟢 **cert-manager engine + self-signed root CA bootstrap** (CHARTER new Goal
  "automated TLS certificate lifecycle" — ADR-0028 for the binding chart values, PSA
  profile, and root-CA issuer chain. **No prerequisites — executor may pick up
  immediately; purely additive, does not touch the existing HTTP-only traffic path.**)
  Add `gitops/platform/cert-manager.yaml` (auto-synced ArgoCD `Application`, chart
  `cert-manager` from `https://charts.jetstack.io`, namespace `cert-manager`; pin a
  specific 1.20.x patch at executor pickup — confirm the tag exists via
  `git ls-remote --tags https://github.com/cert-manager/cert-manager.git` since
  `charts.jetstack.io`'s index is proxy-blocked in this environment). `valuesObject`
  per ADR-0028 §"Chart + version": `crds.enabled: true`; §"Footprint controls" memory
  caps (controller 128Mi, webhook 64Mi, cainjector 64Mi). Add
  `gitops/cert-manager/namespace.yaml` with all four PSA labels at `restricted`
  (ADR-0028 confirms the chart's default securityContext is fully
  `restricted`-compatible — no carve-out needed, verify this against the actual pinned
  chart's `values.yaml` at executor pickup per ADR-0028's verification method). Default-deny
  NetworkPolicy overlay at `gitops/cert-manager/networkpolicy/kustomization.yaml`
  referencing the shared baseline templates + ingress TCP 10250 from the
  kube-apiserver (webhook callback — cert-manager's webhook `securePort` default,
  confirmed against the pinned chart's `values.yaml`; mirror the existing apiserver
  `ipBlock` pattern) + ingress TCP 9402 from `observability` (metrics scrape, all
  three components expose on this port). New auto-synced
  `Application` `gitops/platform/cert-manager-networkpolicy.yaml` (sync-wave 4,
  `LoadRestrictionsNone`). Root CA bootstrap at `gitops/cert-manager/root-ca/`: a
  `selfSigned`-type `ClusterIssuer` (bootstrap-only), a `Certificate` requesting
  `isCA: true` from it, and a `ca`-type `ClusterIssuer` referencing the resulting
  Secret — exact shape per ADR-0028 §"Certificate strategy". New `cert-manager` scrape
  job in `gitops/platform/observability-alloy.yaml` targeting
  `cert-manager.cert-manager.svc.cluster.local:9402`. New
  `grafana/dashboards/lab-cert-manager.json` ("Lab — cert-manager (TLS Lifecycle)")
  modelled on `lab-kyverno.json` stat-row: pod running per component
  (controller/webhook/cainjector from KSM), ArgoCD sync state, certificate count by
  `Ready` condition (real `certmanager_certificate_ready_status`), certificate expiry
  timestamps (`certmanager_certificate_expiration_timestamp_seconds`). No HTTPRoute —
  cert-manager has no web UI; document in the PR body. Update
  `docs/dependency-tree.md` with a CERT-MANAGER subgraph + Alloy scrape edge. New
  `tests/cert-manager.bats`: Application shape, chart source + version pin,
  `crds.enabled: true`, namespace PSA labels, NetworkPolicy overlay structure,
  the two-`ClusterIssuer` root-CA chain shape, scrape job target, dashboard file +
  required panels. Add a `cert-manager: restricted` row to ADR-0017's per-namespace
  profile table in the same PR (small, directly caused by this item — unlike other
  items' separate "ADR-0017 amendment" follow-ups, this one ships with zero carve-out
  so there's nothing to amend later). **Executor note:** if the PR crosses ~400 lines
  per WAYS-OF-WORKING.md §3, split the chart Application + namespace + NetworkPolicy
  from the root-CA bootstrap + dashboard + Alloy scrape. The Gateway HTTPS listener +
  wildcard Certificate + frontdoor `:8443` port mapping is a separate follow-up item
  (ADR-0028 §"Scope & exceptions" — deliberately not bundled here).
  (auto/cert-manager-engine)

- [x] 🟢 **Gateway HTTPS listener + wildcard Certificate + frontdoor `:8443` port
  mapping** (follow-up to the cert-manager engine item above, scoped in ADR-0028
  §"Scope & exceptions" — depends on `k8s-lab-ca` ClusterIssuer, sync-wave 5,
  already shipped). Added an `https`/443 listener to the shared `Gateway`
  (`gitops/network/gateway.yaml`) alongside (never replacing) the existing `http`/80
  one — HTTPRoutes with no `sectionName` (all of them today) attach to both, so every
  existing HTTP URL keeps working unchanged and HTTPS becomes available, not
  mandatory. New wildcard `Certificate` for `*.127.0.0.1.nip.io` +
  `127.0.0.1.nip.io` at `gitops/network/certificates/wildcard-certificate.yaml`,
  issued by `k8s-lab-ca`, in the `lab-gateway` namespace (same namespace as the
  Gateway, so its Secret needs no `ReferenceGrant`). New auto-synced `Application`
  `gitops/platform/lab-gateway-certificate.yaml` at sync-wave 6 (one after
  `cert-manager-root-ca`, wave 5, whose `ClusterIssuer` this Certificate
  references) — until that Secret exists the HTTPS listener simply stays
  not-Programmed and self-heals once it lands, same eventual-consistency pattern
  the root-CA chain itself already relies on. Extended
  `scripts/bluegreen-frontdoor.sh`'s `gen_conf`/`apply_conf` with an nginx `stream {}`
  TCP-passthrough block: host `:8443` (new `FRONTDOOR_HTTPS_PORT`, default `8443` —
  matches the k3d `https_port` Terraform variable's existing host-port convention) →
  the active cluster's serverlb container port `443` directly (TLS terminates inside
  Envoy at the Gateway, not at the frontdoor — passthrough, not a second
  termination), so the DR front door's HTTPS entry point survives a blue/green
  cutover exactly like its existing `:8000` HTTP one. `up` now also publishes
  `-p $HTTPS_PORT:$HTTPS_PORT` and recreates a leftover container that predates
  this change (detected via `docker port … 8443/tcp`) so the new mapping actually
  takes effect. New `tests/frontdoor-https.bats` covering the generated nginx conf's
  `stream`/`listen 8443`/`proxy_pass $1:443` shape and the port-republish/recreate
  logic; extended `tests/cert-manager.bats` with the wildcard Certificate + new
  Application's shape. `tests/networkpolicy-lab-gateway.bats` is unaffected
  (`lab-gateway` holds no pods — Certificates are API objects, not network
  endpoints). Updated `docs/dependency-tree.md` and flipped CHARTER's "TLS
  certificate lifecycle" target entry from "(planned)" to built. `make ci` must
  pass. `docs/done/` entry required. (auto/cert-manager-gateway-https)

- [x] 🟢 **KEDA event-driven autoscaling engine** (CHARTER new Goal "event-driven
  autoscaling" — ADR-0029 for the binding chart values, PSA profile, and footprint
  controls. **No prerequisites — executor may pick up immediately; purely additive,
  no existing workload is touched.**) Found during a coverage/hardening fallback pass
  (ROADMAP rule #9) after every gated `Now / next` item and every doc-drift/coverage
  gap turned up empty — re-read CHARTER's Vision/Goals for a genuinely uncovered CNCF
  pattern rather than defaulting to smaller filler, same discipline that found
  cert-manager. Added `gitops/platform/keda.yaml` (auto-synced ArgoCD `Application`,
  chart `keda` v2.18.0 from `https://kedacore.github.io/charts`, namespace `keda`;
  version confirmed via the chart source repo's `release/v2.18` branch since the
  chart index itself is proxy-blocked in this environment, same class of limitation as
  `charts.jetstack.io`). `valuesObject` per ADR-0029 §"Footprint controls": tightened
  memory limits (operator/metricServer 128Mi, webhooks 64Mi) below the chart's
  generous 1000Mi-per-component default. Added `gitops/keda/namespace.yaml` with all
  four PSA labels at `restricted` (verified zero carve-out needed against the pinned
  chart's `values.yaml`, second component after cert-manager to land at `restricted`
  out of the box). Default-deny NetworkPolicy overlay at
  `gitops/keda/networkpolicy/kustomization.yaml` referencing the shared baseline
  templates + ingress TCP 9443 from kube-apiserver (admission webhook callback,
  confirmed against the pinned chart's `values.yaml`) + ingress TCP 8080 from
  `observability` (metrics scrape). New auto-synced `Application`
  `gitops/platform/keda-networkpolicy.yaml` (sync-wave 4, `LoadRestrictionsNone`). New
  `keda` scrape job in `gitops/platform/observability-alloy.yaml` targeting the
  operator Service (`keda-operator.keda.svc.cluster.local:8080` — where
  `keda_scaler_active`/`keda_scaled_object_paused`/`keda_scaler_metrics_value` are
  actually emitted, verified against the pinned tag's Go source, not guessed from
  docs). New `grafana/dashboards/lab-keda.json` ("Lab — KEDA (Event-Driven
  Autoscaling)") modelled on `lab-cert-manager.json`'s stat-row: pod running per
  component (KSM), ArgoCD sync state, active-scaler count, ScaledObject error rate —
  panels show "No data" naturally until the follow-up `ScaledObject` demo exists
  (ADR-0004). No HTTPRoute — KEDA has no web UI; document in the PR body. Updated
  `docs/dependency-tree.md` with a KEDA subgraph + Alloy scrape edge and
  `tests/dashboard-coverage.bats` with the O5 sweep entry in the same PR (closing the
  gap #442 fixed for cert-manager immediately, not as a follow-up this time). New
  `tests/keda.bats`: Application shape, chart source + version pin, `crds.install:
  true`, namespace PSA labels, NetworkPolicy overlay structure, scrape job target,
  dashboard file + required panels, and an additive-only proof (no `ScaledObject`/
  `ScaledJob` references any workload yet). Added a `keda: restricted` row to
  ADR-0017's per-namespace profile table in the same PR (zero carve-out, nothing to
  amend later — same reasoning as the cert-manager row). **Two explicit follow-up
  items, not bundled here** (ADR-0029 §"Scope & exceptions"): wiring the admission
  webhook's TLS to cert-manager's `k8s-lab-ca` ClusterIssuer (the chart supports this
  natively via `certificates.certManager`), and a real `ScaledObject` demo scaling a
  workload on the `data` namespace's RabbitMQ queue depth. `make ci` must pass.
  `docs/done/` entry required. (auto/keda-engine)

- [x] 🟢 **KEDA admission webhook TLS — wire to cert-manager's `k8s-lab-ca`** (CHARTER
  new Goal "event-driven autoscaling" follow-up; ADR-0029 §"Scope & exceptions" — the
  ADR itself is the binding spec for this follow-up, no new RFC needed. **Prerequisite
  already met:** `cert-manager-root-ca` (sync-wave 5, `gitops/platform/cert-manager-root-ca.yaml`)
  is merged and live-synced, so the `k8s-lab-ca` `ClusterIssuer` it creates already exists
  ahead of this item's new wave-6 KEDA placement.) Patch `gitops/platform/keda.yaml`'s
  `valuesObject` to add the `certificates.certManager` block per ADR-0029 §"Out of
  scope... explicit follow-ups": `enabled: true`, `issuer.generate: false`,
  `issuer.name: k8s-lab-ca`, `issuer.kind: ClusterIssuer` — replacing the chart's default
  `certificates.autoGenerated: true` self-signed cert generation. Per the ADR's own
  wave-ordering analysis: enabling `certManager` flips the webhook cert volume from
  optional to required (confirmed against the chart's `templates/manager/deployment.yaml`
  conditional), which would deadlock at the current wave placement — `k8s-lab-ca` doesn't
  exist until `cert-manager-root-ca` reconciles at wave 5, but `keda` (wave 1) /
  `keda-extras` (wave 0) / `keda-networkpolicy` (wave 4) are all gated to sync *before*
  wave 5 completes. Move all three KEDA Applications' `argocd.argoproj.io/sync-wave`
  annotation to `"6"` (alongside `gitops/platform/lab-gateway-certificate.yaml`, which
  depends on the same `ClusterIssuer` for the same reason). Update `tests/keda.bats`'s
  three existing wave assertions (`keda-extras` 0→6, `keda` 1→6, `keda-networkpolicy`
  4→6) and add a new assertion that the chart `valuesObject` carries the
  `certificates.certManager` block with the documented issuer fields. `make ci` must
  pass. `docs/done/` entry required. (auto/keda-webhook-cert-manager-tls)

- [x] 🟢 **KEDA `ScaledObject` demo — scale `rabbitmq-load` on RabbitMQ queue depth**
  (CHARTER new Goal "event-driven autoscaling" — the actual pedagogical payoff (scaling
  *demonstrated*, not just installed); ADR-0029 §"Scope & exceptions" — the ADR is the
  binding spec, no new RFC needed. **No prerequisites — independent of the webhook-TLS
  item above; the executor may pick up either first.**) Add a `TriggerAuthentication`
  named `rabbitmq-trigger-auth` and a `ScaledObject` named `rabbitmq-load-scaler`, both
  in namespace `data` (co-located with the `rabbitmq-load` Deployment they target — see
  `gitops/data/demo/rabbitmq-load.yaml` and its `data-demo-creds` Secret from
  `gitops/data/demo/externalsecret.yaml`, keys `rabbitmq-username`/`rabbitmq-password`
  sourced from Vault `rabbitmq/default` — note this is the correct existing Secret; ADR-0029's
  text calls it "the existing `rabbitmq-creds` ExternalSecret" but the actual manifest is
  named `data-demo-creds`). `TriggerAuthentication.spec.secretTargetRef` reads the
  `rabbitmq-username`/`rabbitmq-password` keys from `data-demo-creds` (verify the exact
  field name the pinned KEDA version's `rabbitmq` scaler expects — `host` vs
  `hostFromEnv` — against the chart's scaler docs/source at pickup, not guessed).
  `ScaledObject` targets the `rabbitmq-load` Deployment, `minReplicaCount: 1`,
  `maxReplicaCount: 5` (small bound — a demo, not a capacity plan), trigger type
  `rabbitmq`, `queueName: demo` (the queue `rabbitmq-load` itself declares via the
  management API — see its startup script), connection host
  `http://rabbitmq.data.svc.cluster.local:15672` (management HTTP API, `protocol: http`),
  a `queueLength` threshold tuned low enough that the demo's own publish/consume loop
  visibly moves the replica count — document the exact metadata block and the expected
  observable behavior in the PR body (ADR-0004: no fabricated claims — this must actually
  produce a scale event visible in `lab-keda.json`'s existing `keda_scaler_active` panel,
  which currently shows "No data" pending exactly this item). NetworkPolicy: the KEDA
  operator pod (namespace `keda`) is what polls the RabbitMQ management API, not
  `rabbitmq-load` itself, so add `allow-keda-egress-rabbitmq.yaml` to
  `gitops/keda/networkpolicy/kustomization.yaml` (egress TCP 15672 to
  `namespaceSelector: kubernetes.io/metadata.name: data`); on the `data` side, verify
  whether `gitops/data/networkpolicy/allow-rabbitmq-ingress.yaml`'s existing
  `from: - podSelector: {}` peer (no `namespaceSelector`) actually covers cross-namespace
  traffic — per NetworkPolicy semantics a bare `podSelector` peer only matches pods in the
  *same* namespace as the policy, so it likely does NOT yet permit the `keda` namespace;
  add a `namespaceSelector: kubernetes.io/metadata.name: keda` ingress peer to that file
  if so. Extend `tests/keda.bats` (or a new `tests/keda-scaledobject.bats`):
  `TriggerAuthentication` + `ScaledObject` manifests exist; `ScaledObject` references the
  `rabbitmq-load` Deployment and `queueName: demo`; the new NetworkPolicy egress allow is
  present; the `data` namespace ingress allow now covers the `keda` namespace. `make ci`
  must pass. `docs/done/` entry required. **Executor note:** if this crosses ~400 lines
  per WAYS-OF-WORKING.md §3, split the `ScaledObject`/`TriggerAuthentication` manifests
  from the NetworkPolicy egress/ingress changes. (auto/keda-scaledobject-demo)

- [x] 🟢 **`disallow-latest-tag` ClusterPolicy — exclude the `capstone` namespace**
  (RFC/issue #498 — architect decision 2026-07-18, implementing in the same PR as the
  RFC issue, mirrors the inkless ADR-0017 audit pattern from issue #494 / PR #495.
  **No prerequisites — executor may pick up immediately.**)
  `gitops/kyverno/policies/disallow-latest-tag.yaml` is a hard, unconditional
  `Enforce` rejection of any Pod whose image ends in `:latest` or carries no tag, with
  no `exclude:` block. `gitops/apps/capstone/deployment.yaml` and `rollout.yaml` both
  hardcode `image: artifactory.127.0.0.1.nip.io/docker-local/hello:latest` — on a
  from-scratch `make up`, `capstone` syncs at wave 4, before `kyverno-policies` at
  wave 5, so the initial Pod admits fine, but any *subsequent* Pod creation
  (crash/restart, node evict, a Rollout scale event, or the exact "CI builds a new
  image, roll the workload" flow capstone exists to demonstrate) is rejected — and
  `capstone`'s `selfHeal: true` means ArgoCD keeps retrying and failing the same
  reconcile. Add a narrow, explicitly-commented `exclude:` block to
  `disallow-latest-tag.yaml` scoped to the `capstone` namespace only (mirror the exact
  `exclude: any: - resources: namespaces: [...]` shape
  `require-pod-security-restricted.yaml` already uses), with a comment stating the
  flip condition: remove the exclusion once
  `gitops/apps/capstone/{deployment,rollout}.yaml` reference a real, CI-pinned tag
  instead of the floating `:latest` placeholder (depends on wiring Kargo's promotion
  pipeline to capstone's image ref — a separate, larger item this issue's flip
  condition points at, not built here). Do **not** hardcode a guessed "real" tag
  instead (ADR-0004 — this remote clusterless session cannot know what tags actually
  exist in the live Artifactory registry). Update ADR-0019's policy table row for
  `disallow-latest-tag` to document the carve-out + flip condition (mirroring how the
  `verify-image-signatures` Audit-mode carve-out is already documented there). Extend
  `tests/kyverno.bats` (or `tests/kyverno-policies.bats`): exclude block present,
  scoped to the `capstone` namespace only (not a blanket exclusion). `make ci` must
  pass. `docs/done/` entry required. Closes #498. (auto/capstone-latest-tag-exclude)

- [x] 🟢 **Bump RabbitMQ `3.13` → `4.3.x`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; RFC #522 — architect decision 2026-07-18. **No
  prerequisites — executor may pick up immediately.**) RabbitMQ's community-support
  policy now covers only the current + previous minor series (`4.3.x` / `4.2.x`);
  this lab's pinned `rabbitmq:3.13-management` (four minor series back) no longer
  receives free security patches — a version-currency gap, not a single named CVE.
  Per RFC #522's acceptance criteria the executor MUST independently re-verify the
  direct 3.13 → 4.3 upgrade path (Mnesia → Khepri automatic migration) against
  RabbitMQ's own current upgrade docs at pickup time before landing — do not assume
  the RFC's summary is still accurate. Bump
  `gitops/data/rabbitmq/statefulset.yaml`'s image tag to `rabbitmq:4.3.2-management`
  (or the latest `4.3.x` patch at pickup time). Update
  `docs/decisions/adr-0009-rabbitmq-message-broker.md` with the new pin + a
  `## Re-evaluation log` entry (trigger: support-window lapse, not a CVE — mirror
  the ADR-0017/ADR-0020 log pattern). Add new bats coverage pinning the RabbitMQ
  image tag (none exists today — checked `tests/data-layer.bats`). `make ci` must
  pass. PR body must document the executor's own upgrade-path re-verification and
  the ADR-0004 caveat that this remote clusterless session cannot confirm the
  Mnesia→Khepri migration completes cleanly against this lab's live persisted
  queue data on a real cluster — call out the rollback path prominently (revert
  the image tag; note a stateful-format downgrade may not be clean, so recovery
  may require `make dr-restore`/reseed rather than a clean revert, per ADR-0005's
  already-accepted single-node recreate-over-HA risk posture). `docs/done/` entry
  required. Closes #522. (auto/rabbitmq-bump-4x)

- [x] 🟢 **Bump Longhorn `1.7.3` → `1.11.x`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; RFC #528 — architect decision 2026-07-18). Longhorn's
  `1.7.x` line reached end-of-life 2025-09-04 (one year after its first stable
  release, under the pre-1.8 12-month support policy); this lab's pinned
  `targetRevision: 1.7.3` (`gitops/platform/longhorn.yaml`) has received no security
  patches for roughly a year — a version-currency gap, not a single named CVE.
  Lower urgency than a typical bump since Longhorn is **on-demand** (ADR-0013,
  never auto-synced) — zero exposure unless the maintainer runs `make longhorn-up`.
  **No prerequisites — executor may pick up immediately**, but per RFC #528's
  acceptance criteria the executor MUST independently re-verify the exact target
  version at pickup time (Longhorn ships on a fast 4-month cadence; "latest stable
  one line behind newest" may have moved) rather than assume this RFC's `1.11.x`
  pin is still current. Bump `gitops/platform/longhorn.yaml`'s `targetRevision`;
  diff the chart's `values.yaml` between old and new pins for every key this repo
  sets (mirror the Velero bump's verification method); confirm the V2 Data Engine
  stays opt-in, not default, at the new pin. Update
  `docs/decisions/adr-0013-longhorn-block-storage.md` with the new pin + a
  `## Re-evaluation log` entry (trigger: 1.7.x EOL, not a CVE). Update or add a
  chart-pin assertion in `tests/longhorn.bats`. Fix `docs/dependency-tree.md`'s
  stale "v1.7.2" Longhorn reference to the new pin while touching that doc. `make
  ci` must pass. PR body must document the EOL trigger, the version chosen and why,
  the values.yaml diff performed, and the ADR-0004 caveat that this remote
  clusterless session cannot verify Longhorn's CSI driver/UI start cleanly on a
  live cluster post-bump — call out the rollback path (revert `targetRevision`;
  on-demand and not currently synced, so no live-cluster risk unless the
  maintainer already has it running with real volumes — note that caveat
  explicitly). `docs/done/` entry required. Closes #528.
  (auto/longhorn-bump-1-11)

- [x] 🟢 **Bump KRO chart `0.4.1` → `0.9.x` — verify CRD/instance-scope compatibility
  first** (CHARTER **Core Values** §"Everything as code" + general hardening; RFC #534
  — architect decision 2026-07-18). KRO's latest stable release is `v0.9.2` — five minor
  versions ahead of this lab's `0.4.1` chart pin (`gitops/platform/kro.yaml`). KRO is
  pre-1.0 (`0.x` semver — every minor version is allowed to be breaking), and the
  `v0.9.0` release notes specifically flag "cluster-scoped instance CRDs" — a change
  that may affect the exact mechanism this lab depends on (the `ResourceGraphDefinition`
  in `gitops/kro/rgd-s3bucketclaim.yaml` that generates the `S3BucketClaim` CRD
  `gitops/platform/kro-resources.yaml` instantiates into the `ack-system` namespace).
  **No prerequisites — executor may pick up immediately**, but per RFC #534's
  acceptance criteria the executor MUST fetch the actual KRO CRD definitions at the
  target tag and directly verify whether the generated instance CRD's scope changed
  from `Namespaced` to `Cluster` before bumping — do not assume a clean drop-in, same
  bar the Kargo `1.2.3 → 1.6.4` bump already applied to its own multi-minor jump. If
  the scope did change, update `gitops/platform/kro-resources.yaml`'s
  `destination.namespace` (and any other namespace-scoped assumption) accordingly and
  document exactly what changed. If verification finds the breaking change is real and
  non-trivial to accommodate cleanly, split the actual version bump into a smaller
  documented item rather than force a risky bump in one PR (ROADMAP rule #9). Diff the
  chart's `values.yaml` for any key this repo's Application sets; add/extend bats
  coverage pinning the chart version. `make ci` must pass. PR body must document the
  specific CRD/scope verification performed and the ADR-0004 caveat that this remote
  clusterless session cannot verify the `S3BucketClaim` instance actually reconciles
  cleanly against a live ACK S3 Bucket + moto backend post-bump — call out the
  rollback path (revert the chart pin; note a scope-related `kro-resources.yaml` edit
  must revert in lockstep if one was needed). `docs/done/` entry required. Closes #534.
  (auto/kro-bump-0-9)

- [x] 🟢 **Migrate Grafana chart source off the deprecated `grafana.github.io/helm-charts`
  repo** (RFC #544 — architect decision 2026-07-18. **No prerequisites — executor may
  pick up immediately.**) `gitops/platform/observability-grafana.yaml`'s chart source
  (`repoURL: https://grafana.github.io/helm-charts`, `targetRevision: 10.5.15`) is
  deprecated: the chart's own `Chart.yaml` at that exact pinned tag carries
  `deprecated: true`, and its README states migration to
  `grafana-community/helm-charts` completed 2026-01-30. Migrate to
  `repoURL: https://grafana-community.github.io/helm-charts`,
  `targetRevision: 12.7.2` (verified current at the new source,
  `appVersion: 13.1.0`, no deprecation flag). Do **not** bump the running Grafana
  image itself in the same PR — `valuesObject.image.tag` stays pinned at `"13.0.1"`
  per the file's own documented history (ADR-0006's Git Sync provider + a known
  13.0.0 unified-storage migration bug for Git Sync users); the chart-source
  migration only picks up newer Helm templates/schema, not a newer running binary.
  Diff the old (chart 10.5.15) vs new (chart 12.7.2) chart's `values.yaml` /
  `templates/_pod.tpl` for every key the `valuesObject` sets (`securityContext`,
  `containerSecurityContext`, `initChownData`, `persistence`, `deploymentStrategy`,
  `extraConfigmapMounts`, `extraEmptyDirMounts`, `extraInitContainers`, `grafana.ini`
  — especially the `provisioning`/`unified_storage` feature-toggle keys ADR-0006
  depends on — `datasources`, `dashboardProviders`, `dashboards.community`,
  `extraObjects`) and confirm none were renamed/removed; document the verification
  in the `docs/done/` entry per ADR-0004. Update in-file comments referencing
  "grafana-10.5.15" as the verified chart tag to "grafana-12.7.2". Update any bats
  assertion pinning the `grafana` chart's `targetRevision`/`repoURL`, and
  `docs/dependency-tree.md` if it references either. `observability-alloy.yaml` and
  `observability-pyroscope.yaml` also use the old repoURL but showed no deprecation
  signal at their own dedicated source repos when checked — out of scope here.
  `make ci` must pass. `docs/done/` entry required. Closes #544.
  (auto/grafana-chart-source-migration)

- [x] 🟢 **Pin Vault's server image tag explicitly** (CHARTER **Core Values**
  §"Everything as code" + §"Recreate-from-code" + general hardening; planner
  gap-analysis finding, 2026-07-24 — **no prerequisites, executor may pick up
  immediately; no ADR change needed**, same reasoning as the Grafana image-tag
  override item above: no ADR governs Vault as a technology/version choice, only
  the delivery mechanism). Verified directly against the repo (not assumed, per
  ADR-0004): `gitops/platform/vault.yaml` pins the `vault` chart at
  `targetRevision: 0.34.0` but never sets an explicit `server.image.tag` —
  unlike every other version-sensitive component in this repo (Grafana, Argo
  Rollouts, Valkey, Envoy Gateway, Kiali, k3s/ADR-0030), the actual Vault
  **binary** version running in this lab is only ever recorded in a prose
  comment ("chart v0.34.0 defaults to a Vault 2.0.3 image", line 49) — not a
  field a `bats` test or a future architect ADR-audit sweep can check
  mechanically. This is the same class of gap RFC #558 (ADR-0030) fixed for
  k3s: an implicitly-inherited version with no recorded pin means "what
  version are we actually running" is unanswerable from the repo alone, and a
  future unrelated chart-patch bump (still `0.34.0` → `0.34.x`) could silently
  change the running Vault major version with nobody noticing.

  Verified live upstream (not training-data recall, ADR-0004): fetched
  `raw.githubusercontent.com/hashicorp/vault-helm/v0.34.0/values.yaml` directly
  — confirms the chart's actual default is `server.image: {repository:
  hashicorp/vault, tag: "2.0.3"}` (the `injector`/`agentImage` defaults are
  irrelevant here since this Application sets `injector.enabled: false`).
  Cross-checked `2.0.3` against every Vault CVE/security-bulletin disclosed in
  2026 findable from this sandbox (`CVE-2026-3605` KVv2 wildcard-delete DoS,
  `CVE-2026-5807` unauthenticated root-token/rekey DoS, `CVE-2026-5052` ACME
  SSRF, `HCSEC-2026-07` token-exposure-to-auth-plugins, `HCSEC-2026-16` audit
  device directory-guard bypass): every one of these is fixed in Vault CE
  `2.0.0` or `2.0.1` at the latest — `2.0.3` (our chart's current default)
  already ships every fix. This is a pin-what's-already-running change, not a
  version bump — the running Vault does not change.

  Add `image: {repository: "hashicorp/vault", tag: "2.0.3"}` under the existing
  `server:` block in `gitops/platform/vault.yaml`'s `valuesObject` (sibling to
  `standalone`/`dataStorage`/`resources`/`statefulSet`), matching the chart's
  own default exactly so this is a no-op for the running cluster. Update the
  existing line-49 comment to note the version is now an explicit pin, not an
  inherited default. Add a `## Re-evaluation log`-style dated note (a comment
  block above the `server:` key is fine — no dedicated Vault ADR exists to host
  a real `## Re-evaluation log` section) recording this pin, citing the five
  CVE/bulletin IDs above and their fixed versions, with a flip condition for
  the next audit (e.g. "revisit when a bulletin names a version above `2.0.3`
  as affected, or when bumping the chart `targetRevision` past `0.34.0`").
  Extend `tests/securitycontext-vault.bats` with a new assertion alongside the
  existing `"vault Application chart bumped to 0.34.0"` test —
  `"vault Application server image pinned to 2.0.3"` via `yqs
  '.spec.source.helm.valuesObject.server.image.tag' "$APP"` equals `"2.0.3"` —
  a recurrence guard mirroring this repo's other per-component image-tag pin
  assertions (Grafana, Argo Rollouts, Valkey). No topology change and the
  running image is identical to today's chart-default, so no
  README/`docs/dependency-tree.md` update is expected — note that explicitly in
  the PR body. `make ci` must pass. `docs/done/` entry required.
  (auto/vault-server-image-tag-pin)

- [x] 🟢 **`argo-cd` Helm chart major bump — `9.7.1` → `10.2.1`** (RFC #785 — architect
  decision 2026-07-28: **Approve**, with a required `global.networkPolicy.create: false`
  companion override. **No prerequisites — executor may pick up immediately.**) Bump
  `infra/modules/argocd/variables.tf`'s `chart_version` default `"9.7.1"` → `"10.2.1"`
  (`appVersion v3.4.4` → `v3.4.5`); update the variable's description comment to match.
  Add `global.networkPolicy.create: false` to `infra/modules/argocd/values.yaml` with a
  comment citing RFC #785: this repo already hand-manages its own default-deny +
  allow-list `NetworkPolicy` set for the `argocd` namespace via GitOps
  (`gitops/argocd/networkpolicy/`, ADR-0016 pattern), and chart `10.x` flips the
  upstream default for this key from `false` to `true` — the override preserves current
  behavior (RFC #785 verified this is the only functionally relevant key in the
  `9.7.1`→`10.2.1` values-schema diff; everything else is irrelevant to this repo's
  values or purely additive). Re-verify at pickup time that chart `10.2.1` actually
  resolves from `https://argoproj.github.io/argo-helm` before merging (RFC #785's
  authoring session could not reach that host directly — confirm the live Helm-repo
  `index.yaml` entry exists, same due-diligence pattern as the `auto/pyroscope-*`/
  `auto/grafana-chart-*` bumps). Extend the relevant `tests/*.bats` chart-pin coverage
  to assert both the new `chart_version` default and the `global.networkPolicy.create:
  false` override are present (recurrence guard). `make ci` must pass. `docs/done/`
  entry required. Closes #785. (auto/argocd-chart-10x-bump or upgrade/argocd-chart-10x-bump)

- [x] 🟢 **`tests/frozen-monolith-lib.bats` — direct unit coverage for
  `scripts/lib/frozen-monolith-check.sh` + `frozen-monolith-sync-hook.sh`**
  (CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
  recurrence rule; planner gap-analysis sweep 2026-07-31 — all three standing
  "Now / next" items are still gated on unconfirmed maintainer-confirmation
  issues #631/#633 (checked directly this run: neither issue has a comment
  confirming its ask; `gitops/kyverno/policies/verify-image-signatures.yaml`
  still reads `validationFailureAction: Audit` / `failurePolicy: Ignore`, so
  the gate is accurate, not stale), so this is rule #9 coverage/hardening
  filler, not CHARTER-objective progress — call this out explicitly in the PR
  body. **No prerequisites — executor may pick up immediately.**) Verified
  directly (not assumed, ADR-0004): every other shared `scripts/lib/*.sh`
  helper extracted from repeated copy-paste (`colors.sh`, `hook-payload.sh`,
  `yq-variant.sh`, `budget-check.sh`) has its own dedicated
  `tests/<name>-lib.bats` asserting the shared function's behavior directly
  (`colors-lib.bats`, `hook-payload-lib.bats`, `lib-yq-variant.bats`,
  `budget-check-lib.bats`) — `frozen-monolith-check.sh` and
  `frozen-monolith-sync-hook.sh` are the only two `scripts/lib/*.sh` files with
  no bats file exercising them directly (`grep -rl "lib/frozen-monolith-check"
  tests/*.bats` and the `-sync-hook` equivalent both return nothing); they are
  only exercised transitively through the four wrapper scripts they back
  (`securitycontext-tests-check.sh`, `observability-tests-check.sh`,
  `drift-detectors-tests-check.sh`, `hook-scripts-coverage-tests-check.sh`) via
  `tests/drift-frozen-monolith-checks.bats`. Not a functional bug — behavior is
  covered indirectly — but it's the one lib extraction that skipped the
  pattern's own direct-unit-test half, and per CLAUDE.md every extracted
  helper should carry its own recurrence guard rather than relying solely on
  transitive coverage through callers.

  New `tests/frozen-monolith-lib.bats` mirroring `hook-payload-lib.bats`'s
  shape exactly: (1) both lib files exist; (2) both are valid, sourceable bash
  (`bash -n`); (3) `frozen-monolith-check.sh` defines `frozen_monolith_check()`
  and `frozen-monolith-sync-hook.sh` defines `frozen_monolith_sync_hook()`;
  (4) exercise `frozen_monolith_check()` directly against two small fixture
  files under a temp dir — one case where the live `@test` title set matches
  the snapshot (expect success, drift=0) and one where it's been edited to
  differ (expect the function to report drift and print the
  "put NEW tests in <scope_hint>" guidance) — no need for `bats`-style fixture
  files beyond plain heredocs written to `$BATS_TEST_TMPDIR`; (5) exercise
  `frozen_monolith_sync_hook()` directly with a synthetic JSON hook payload
  (via `hook_file_path`'s existing stdin contract) targeting the monolith path
  vs. a non-monolith path, asserting it only fires (exit 2) on the former;
  (6) a recurrence guard: assert every `scripts/lib/*.sh` file has at least one
  `tests/*.bats` file whose content references its basename by name (the same
  structural check this item is fixing, turned into a permanent gate so a
  future fifth lib extraction can't silently skip its own direct-unit-test
  half again). `make ci` must pass. No topology change, so no
  README/`docs/dependency-tree.md` update is expected — note that explicitly
  in the PR body. `docs/done/` entry required.
  (auto/frozen-monolith-lib-test-coverage)

- [x] 🟢 **Name O3's RPO target explicitly in CHARTER.md** (CHARTER **Objective O3**;
  planner gap-analysis 2026-08-07, reached via `executor.prompt.md` STEP 6b after
  every standing "Now / next" item was found gated (unchanged) on unconfirmed
  maintainer-confirmation issues #631/#633, with no ungroomed intake issues and no
  un-RFC'd 🟡 items to promote instead — `docs/dora-audit-readiness.md` Q3 ("What are
  the recovery targets (RTO/RPO) for critical functions?") already answers "RPO ≤ 24
  hours (Velero daily schedules, 168h retention) — true today but never labeled 'RPO'
  anywhere in the docs before this file" and names the fix directly: "Cheap fix: add
  an explicit RPO line to O3 in CHARTER.md." **No prerequisites — executor may pick
  up immediately.**) Verified directly (not assumed, ADR-0004): all six
  `gitops/velero/schedules/*.yaml` Schedules (`data`, `tidb`, `capstone`, `vault`,
  `observability`, `inkless`) run once daily (staggered 01:00–04:00,
  `schedule: "<min> <hour> * * *"`) each with `ttl: 168h` (7-day retention) — the
  worst-case gap between a change and its next backup is the ≤24h window this item
  names, not a guessed number.

  Add an explicit RPO line to CHARTER.md's O3 bullet, immediately after its existing
  RTO sentence ("...under 10 minutes wall-clock on the maintainer's hardware."):
  state RPO ≤ 24 hours, citing Velero's daily schedules across all six stateful
  namespaces and their 168h/7-day retention (`gitops/velero/schedules/*.yaml`).
  Update `docs/dora-audit-readiness.md`'s Q3 "Gap" line to record that CHARTER now
  states the RPO explicitly (closing the "never labeled 'RPO' anywhere" gap) — correct
  the row honestly rather than deleting it, matching this doc's existing pattern for
  gaps closed elsewhere in the file. No manifest/code change — CHARTER.md plus one doc
  line only, so no README/`docs/dependency-tree.md` drift is expected; note that
  explicitly in the PR body. `make ci` must pass. `docs/done/` entry required.
  (auto/charter-o3-rpo-target)

- [x] 🟢 **Pin `gitlab-ce`/`gitlab-runner` to explicit versions (currently `:latest`)**
  (CHARTER **Core Values** §"Everything as code" + general hardening, mirroring
  [ADR-0030](docs/decisions/adr-0030-pin-k3s-version-explicitly.md)'s explicit-pin
  precedent; architect-fallback finding 2026-08-07, surfaced while researching
  [ADR-0033](docs/decisions/adr-0033-gitlab-git-source-and-ci.md) — RFC #1073. **No
  prerequisites — executor may pick up immediately.**) Verified directly (not assumed,
  ADR-0004): `gitlab/docker-compose.yml` pins both the `gitlab` service
  (`image: gitlab/gitlab-ce:latest`) and the `gitlab-runner` service
  (`image: gitlab/gitlab-runner:latest`) to the floating `:latest` tag — the only two
  always-on lab components still doing this; every other pinned dependency in this repo
  (RabbitMQ, Valkey, Grafana, Tempo, Mimir, Loki, k3s itself per ADR-0030, etc.) uses an
  explicit version tag. Un-pinned `:latest` means a routine `docker compose pull` +
  `make gitlab-up` cycle can silently jump GitLab CE major versions with no PR, no
  changelog review, and no rollback path recorded anywhere — the exact failure mode
  ADR-0030 exists to prevent for k3s.

  Pin `gitlab/docker-compose.yml`'s `gitlab` service to the current GitLab CE release at
  time of the PR (check `https://gitlab.com/gitlab-org/omnibus-gitlab/-/releases` or
  `docker manifest inspect gitlab/gitlab-ce:latest` for the concrete tag actually
  running, since this remote clusterless session cannot itself run `docker compose pull`
  against a live daemon — ADR-0004 caveat, note this explicitly in the PR body) and the
  `gitlab-runner` service similarly. Add a `tests/gitlab-compose.bats` (or extend
  `tests/gitlab-push.bats` if more natural) assertion that neither image reference in
  `gitlab/docker-compose.yml` is `:latest` — a recurrence guard per CLAUDE.md's
  bug-fix-prevents-recurrence rule, mirroring `tests/argocd-chart-pin.bats`'s exact-pin
  assertion pattern. Update `docs/dependency-register.md`'s eventual GitLab row (or this
  item's own follow-up) to cite the pinned version. `make ci` must pass — this is a
  docker-compose/test-only change, no cluster needed. PR body must note the rollback
  path (revert the pin; `make gitlab-up` re-pulls the prior tag) and that this remote
  session cannot verify the pinned tag actually starts healthy end-to-end (that's the
  next `make gitlab-up` run's job, same caveat pattern as every other currency-bump PR
  in this repo). `docs/done/` entry required. (auto/gitlab-version-pin)

- [x] 🟢 **`docs/dependency-register.md` — add rows for ADR-0033 (GitLab) and ADR-0034
  (LGTMP observability internals)** (CHARTER **Core Values** §"Decisions written down";
  architect-fallback follow-up 2026-08-07, RFC #1073 acceptance criteria's remaining
  unchecked box. **No prerequisites — executor may pick up immediately.**) Add a
  `GitLab` row (criticality `always-on-core`, source `about.gitlab.com`,
  `gitlab.com/gitlab-org/gitlab`, citing [ADR-0033](docs/decisions/adr-0033-gitlab-git-source-and-ci.md))
  and seven new rows — one each for Mimir, Loki, Tempo, Pyroscope, Alloy,
  kube-state-metrics, node-exporter (criticality `always-on-core`, each citing
  [ADR-0034](docs/decisions/adr-0034-lgtmp-observability-stack.md)) — to
  `docs/dependency-register.md`'s table, in the same row shape as every existing entry
  (Tool / Criticality / Upstream source / ADR / Last reviewed, the last column dated
  today with a one-line note "ADR-0033/ADR-0034 authored"). Edit the "Real gap, distinct
  from the policy-ADR exclusions above" paragraph to say the gap is closed (both ADRs
  now exist) rather than leaving it describing a now-stale state. Update the "Keeping
  this in sync" summary line's date if this PR lands on a later date than its current
  "as of" citation. Doc-only change — no code, no `gitops/` touch. `make ci` must pass
  (`readme-check`/link-check cover markdown; no drift-check currently enforces this
  register's content per its own "no mechanical drift guard yet" note). `docs/done/`
  entry required. (auto/dependency-register-adr-0033-0034-rows)

- [x] 🟢 **Bump External Secrets Operator chart `2.8.0` → `2.9.0` (real CVE fixes)**
  (CHARTER **Core Values** §"Everything as code" + general hardening; executor-fallback
  currency sweep 2026-08-10, reached via `executor.prompt.md` STEP 6b — the only three
  unchecked items anywhere in ROADMAP.md (the standing Now/next trio) remain gated on
  unconfirmed maintainer-confirmation issues #631/#633/#1034 (re-checked this cycle:
  all three issues' full comment threads read directly, latest comments 2026-08-07,
  still reporting live-cluster host-capacity/Harbor-stability blockers, no confirmation).
  PLANNER-fallback intake pass found nothing to groom — `gh issue list` equivalent (GitHub
  MCP tools, no `gh` CLI in this remote session) shows exactly the same three standing
  `[Action required]` issues, already correctly labeled; `docs/roadmap/incoming/` holds
  only its README; no un-RFC'd 🟡 item exists anywhere in ROADMAP.md (all prior 🟡 entries
  are struck through/resolved, confirmed by grepping the file). This cycle's fresh angle
  (3 days after the prior sweep on 2026-08-07, which had already checked ArgoCD, Trivy
  Operator, Grafana, Tempo, Loki, kube-state-metrics, Harbor, Kiali, kro, envoy-gateway,
  pyroscope, node-exporter, velero, ack-s3, cilium): a fresh `git ls-remote --tags` sweep
  of chart repos not re-checked in that pass — cilium (current), argo-rollouts (current),
  harbor (current), istio (current), kro (current), longhorn (a `v1.11.4` tag exists but
  is a `-dev-*` prerelease only, no real release past `1.11.3`, false-positive ruled out
  by checking the raw tag) — surfaced External Secrets Operator one minor version behind.
  **No prerequisites — executor may pick up immediately.**) Verified directly (not
  assumed, ADR-0004): `git ls-remote --tags external-secrets/external-secrets` shows
  `helm-chart-2.9.0` as the newest tag on the chart's own tagging scheme, one release
  past the pinned `2.8.0` (both `version` and `appVersion` move together in `Chart.yaml`,
  confirming this is a real upstream app release, not a same-appVersion repackage). A full
  clone diff (`git diff helm-chart-2.8.0 helm-chart-2.9.0 -- deploy/charts/external-secrets/`)
  is purely additive: two new optional pod-scheduling fields (`schedulerName`,
  `runtimeClassName`, each `{{- if .Values.X }}`-gated, default empty — no behavior change
  unless explicitly set) across all three Deployments; a new `certController.enablePartialCache`
  toggle (defaults `true`, scopes the cert-controller's informer cache to CRDs/
  ValidatingWebhookConfigurations carrying the `external-secrets.io/component` label — a
  narrowing, not a widening, of watch scope); the CRD bundle diff is schema-field
  reordering only, nothing removed. The upstream release notes name two real CVE fixes:
  `grpc-go` bumped addressing GHSA-hrxh-6v49-42gf, and `golang.org/x/text` bumped to
  `v0.40` addressing CVE-2026-56852 — the same "ships with a real security fix" bar this
  repo's other non-major currency bumps use, not a blind patch assumption. Also plus
  real bug fixes (Akeyless provider error-handling + a data-race fix, AWS Secrets Manager
  replicated-region detach-before-delete, webhook event-format standardization, an
  ExternalSecret strategy-field over-defaulting fix) — none of which touch this lab's own
  `valuesObject` keys (`installCRDs`, `podSecurityContext`, `securityContext`, `webhook.*`,
  `certController.*`, `resources`), all of which are present and unchanged in the new
  schema.

  Bump `gitops/platform/external-secrets.yaml`'s `targetRevision: 2.8.0` → `2.9.0`. New
  `tests/external-secrets-chart-pin.bats` (clusterless structural, mirrors this repo's
  other exact-version-pin test pairs, e.g. `tests/observability-loki.bats`): asserts the
  Application pins `targetRevision: 2.9.0`; asserts it does NOT pin the stale `2.8.0`
  (recurrence guard). No `docs/dependency-tree.md` or `docs/decisions/context.md` update
  needed — neither cites this chart's specific version (checked directly). **Honest note
  for a future planner/architect cycle:** External Secrets Operator has no row in
  `docs/dependency-register.md` and no dedicated ADR of its own (unlike RabbitMQ/Valkey/
  Kyverno/etc., each with a decision ADR) — the register's own construction rule
  ("every row cites the ADR that decided it") structurally excludes it, the same gap
  shape GitLab/LGTMP had before RFC #1073 closed it with ADR-0033/ADR-0034. Not fixed in
  this PR (out of scope — one item per cycle, and authoring a new ADR is architect-role
  work per WAYS-OF-WORKING.md), but flagged here so it isn't lost. `make ci` must pass.
  PR body must document the CVE findings above and the ADR-0004 caveat that this remote
  clusterless session cannot verify the ESO controller/webhook/cert-controller start
  cleanly and continue syncing secrets post-bump on a live cluster — call out the
  rollback path (revert `targetRevision`; ArgoCD re-syncs the prior chart version on its
  next reconciliation; ESO holds no persistent state of its own — secrets it manages
  live as native k8s Secrets, untouched by a chart-version revert). `docs/done/` entry
  required. (auto/external-secrets-chart-2-9-0)

- [x] 🟢 **Bump Pyroscope chart `2.2.0` → `2.2.1` (upstream security release)**
  (CHARTER **Core Values** §"Everything as code" + general hardening; executor-fallback
  currency sweep 2026-08-10, second pass this run, reached via `executor.prompt.md`
  STEP 6b — the same three standing Now/next items remain gated on unconfirmed
  maintainer-confirmation issues #631/#633/#1034 (re-checked this cycle, #1034
  unchanged since 2026-08-07). This cycle's fresh angle (continuing the prior cycle's
  `git ls-remote --tags` sweep to charts not yet checked this run): cert-manager, keda,
  vault, ack-s3, kargo, envoy-gateway, node-exporter, and alloy all confirmed current
  against their real chart-publishing repos; Pyroscope's chart (published from
  `grafana/pyroscope`'s own `operations/pyroscope/helm/pyroscope`, not the
  `grafana/helm-charts` monorepo — the source moved out of that repo, though release
  tags still land there too) turned up one minor version behind. **No prerequisites —
  executor may pick up immediately.**) Verified directly (not assumed, ADR-0004):
  `git ls-remote --tags grafana/pyroscope` shows `pyroscope-2.2.1` as the newest tag,
  one release past the pinned `2.2.0`; both `version` and `appVersion` move together in
  `Chart.yaml`. A full source diff (`git diff pyroscope-2.2.0 pyroscope-2.2.1 --
  operations/pyroscope/helm/pyroscope/`) shows `values.yaml` and every template
  byte-identical — only version-label churn in the rendered manifests (`helm.sh/chart`,
  `app.kubernetes.io/version`). The upstream chart-bump PR (grafana/pyroscope#5474)
  states this explicitly: "updates the Helm chart to align with the v2.2.1 **security
  release** of Pyroscope." The v2.2.1 app release fixes: `github.com/getkin/kin-openapi`
  (**GHSA-r277-6w6q-xmqw**, critical), `google.golang.org/grpc` (**GHSA-hrxh-6v49-42gf**),
  `golang.org/x/text` (**CVE-2026-56852**), `golang.org/x/net` (**CVE-2026-46600**), plus
  a `klauspost/compress` bump and UI-dependency fixes (tar/js-yaml/brace-expansion/
  ip-address) — well past this repo's "ships with a real security fix" bar. This repo's
  existing `readOnlyRootFilesystem: true` verification (checked against the pinned chart
  source, cited inline in `observability-pyroscope.yaml`) carries forward unchanged
  since the template is byte-identical.

  Bump `gitops/platform/observability-pyroscope.yaml`'s `targetRevision: 2.2.0` →
  `2.2.1`; update its inline comment citing the verified chart tag. New
  `tests/observability-pyroscope.bats` (clusterless structural, mirrors
  `tests/observability-loki.bats`'s per-scope pattern): asserts the Application pins
  `targetRevision: 2.2.1`; asserts it does NOT pin the stale `2.2.0` (recurrence guard).
  Update `docs/decisions/context.md`'s "Pyroscope (chart 2.2.0" citation to `2.2.1`
  (required — `make context-doc-version-sync-check` mechanically enforces this). Update
  `docs/dependency-register.md`'s Pyroscope row "Last reviewed" cell. Add a new dated
  entry to [ADR-0034](docs/decisions/adr-0034-lgtmp-observability-stack.md)'s
  `## Re-evaluation log` (its first, alongside updating its own "What's actually
  running" table's Pyroscope row to `2.2.1`) documenting the security findings above —
  **Keep**, no reason to reconsider the component itself. No `docs/dependency-tree.md`
  update needed — it doesn't cite Pyroscope's specific chart version (checked directly).
  `make ci` must pass. PR body must document the security findings above and the
  ADR-0004 caveat that this remote clusterless session cannot verify Pyroscope starts
  cleanly and continues ingesting profiles post-bump on a live cluster — call out the
  rollback path (revert `targetRevision`; ArgoCD re-syncs the prior chart version on its
  next reconciliation; Pyroscope's profile data lives on Garage S3 + its PVC, untouched
  by a chart-version revert). `docs/done/` entry required.
  (auto/pyroscope-chart-2-2-1)

- [x] 🟢 **Grafana Unified Alerting — four rules for known failure conditions** (RFC
  #1084 — architect decision 2026-08-10; closes `docs/dora-audit-readiness.md` Q7's
  "no alerting" gap; planner-groomed 2026-08-10 — the RFC's own Acceptance criteria
  is the spec below, no further sizing needed. **No prerequisites — executor may
  pick up immediately.**) Add an alerting-provisioning ConfigMap to
  `gitops/platform/observability-grafana.yaml`'s `valuesObject` (Grafana's chart
  supports mounting extra provisioning files the same way dashboards/datasources
  are already provisioned — check the chart's own `extraConfigmapMounts` or
  equivalent `valuesObject` key, mirroring whatever mechanism the existing
  datasource provisioning in this same file already uses) defining exactly these
  four rules, each `for:` the duration below, in Grafana's file-based alerting
  provisioning YAML format (`apiVersion: 1`, a `groups:` list under the
  provisioning `alerting` kind):
  1. **ArgoCDAppUnhealthy** — `argocd_app_info{health_status!="Healthy"} == 1`,
     `for: 10m`.
  2. **ArgoCDAppOutOfSync** — `argocd_app_info{sync_status="OutOfSync"} == 1`,
     `for: 30m`.
  3. **DeploymentReplicasUnavailable** —
     `kube_deployment_status_replicas_available < kube_deployment_spec_replicas`,
     `for: 10m`.
  4. **PVCStuckPendingOrLost** —
     `kube_persistentvolumeclaim_status_phase{phase=~"Pending|Lost"} == 1`,
     `for: 10m`.
  All four query the existing Mimir datasource (already configured with
  `X-Scope-OrgID: lab`) — no new datasource, no new scrape target. Do **not** add
  any `receivers:`/contact-point/notification config — per the RFC, this is
  visual-only (Grafana's Alerting UI shows firing state; no external channel
  exists in this lab to wire one to). New `tests/observability-alerting.bats`
  (clusterless structural, mirrors the `tests/observability-<scope>.bats`
  per-component pattern): asserts all four rule names + their exact PromQL
  expressions + `for:` durations are present in the provisioning config; asserts
  no `receivers:`/webhook/SMTP/contact-point key exists anywhere in the same
  block (recurrence guard — per the RFC, adding a notification channel later
  needs its own fresh decision, not a silent addition). Update
  `docs/dependency-tree.md` with a short note that Grafana Unified Alerting is
  wired, querying Mimir, visual-only, four rules. Update
  `docs/dora-audit-readiness.md`'s Q7 answer to record this closes the "no
  alerting" half of the gap (the escalation/paging half stays an explicit
  non-goal per the RFC — state that plainly, don't silently drop it). `make ci`
  must pass — this is config-only and clusterless-verifiable (structural
  assertions on the provisioning YAML; no live Grafana instance needed to
  confirm the rules are well-formed and present). PR body must document the
  ADR-0004 caveat that this remote clusterless session cannot verify the rules
  actually evaluate correctly or fire on a live cluster — call out the rollback
  path (revert the provisioning block; Grafana re-syncs via ArgoCD on next
  reconciliation; no other component depends on these rules existing). Closes
  #1084. `docs/done/` entry required. (auto/grafana-alerting-rules)

- [ ] 🟢 **verifyImages ClusterPolicy — Audit → Enforce flip** (CHARTER **Objective O4**,
  RFC #214 Item 3; **only pick up after `auto/cosign-ci-sign-step` has merged AND the
  maintainer confirms at least one CI run pushed a signed image to the registry** — the
  registry moved from Artifactory to Harbor (`auto/harbor-capstone-rewire` /
  `auto/harbor-artifactory-decommission`, ADR-0024, 2026-07-29) after this item's original
  Artifactory-specific verification command was written; check for a `<digest>.sig` tag in
  Harbor's `library/hello` repository (e.g. `crane ls harbor.127.0.0.1.nip.io/library/hello`
  or the Harbor UI/API), confirming the `sign-image` CI job actually ran and pushed a
  signature — do not reuse the old `artifactory.../docker-local/hello/.sig` path, that host
  no longer exists). Edit `gitops/kyverno/policies/verify-image-signatures.yaml`:
  `validationFailureAction: Audit` → `validationFailureAction: Enforce`;
  `failurePolicy: Ignore` → `failurePolicy: Fail`. Extend `tests/kyverno-policies.bats`
  (or `tests/kyverno.bats`) asserting `Enforce` and `Fail` values are present in the
  policy file. PR body must document the flip condition and the rollback path (revert
  both fields to `Audit` + `Ignore`, push → ArgoCD syncs within 30 s, no cluster
  downtime per RFC #214 §"Rollback path"). `make ci` must pass. **Executor note:** this
  item has a maintainer-confirmation prerequisite, tracked as a **standing**
  `[Action required]` issue (#631, stays open until confirmed — unlike the self-merging
  `[Action needed]` PR fallback) — check it for a confirmation comment before treating
  this as satisfied; skip to the next item if unconfirmed this run; close #631 in this
  item's PR once it merges. (auto/cosign-enforce-flip)

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

- [x] 🟢 **Harbor day-0 credential seam — admin + CI registry secrets** (RFC #297
  / ADR-0024 — architect decision 2026-06-30; **no prerequisites — executor may
  pick up immediately**; **unblocks `auto/harbor-capstone-rewire`**). The Harbor
  ArgoCD Application (`gitops/platform/harbor.yaml`) currently uses the
  hard-coded default password `Harbor12345` with no `existingSecretAdminPassword`
  reference, and `vault-bootstrap.sh` seeds no Harbor credential path (only
  `secret/artifactory/registry` exists). This item adds the missing day-0 seam,
  parallel to the velero-key + inkless-key pattern already in
  `garage-bootstrap.sh`: (1) extend `scripts/vault-bootstrap.sh` to seed
  `secret/harbor/admin` (`admin-user=admin`, `admin-password=<rand-hex-16>`) and
  `secret/harbor/registry` (`username=admin`, `password=<rand-hex-16>`) — both
  idempotent (`kv get ... || kv put ...`), exact parallel to the existing
  `secret/artifactory/registry` block at line 79; (2) add
  `gitops/secrets/harbor-admin-externalsecret.yaml` (namespace `harbor`, target
  Secret `harbor-admin-creds`, keys `HARBOR_ADMIN_PASSWORD` + `HARBOR_ADMIN_USER`
  from `secret/harbor/admin`); (3) patch `gitops/platform/harbor.yaml` to set
  `existingSecretAdminPassword: harbor-admin-creds` and
  `existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD`; (4) add
  `tests/harbor-bootstrap.bats` (clusterless structural: `vault-bootstrap.sh`
  seeds both paths, `harbor-admin-externalsecret.yaml` exists, `harbor.yaml`
  references `existingSecretAdminPassword`); (5) note `secret/harbor/registry`
  in the `docs/dependency-tree.md` Day-0 bootstrap section. `docs/done/` entry
  required. `make ci` must pass. (auto/harbor-bootstrap-credentials)

- [x] 🟢 **Harbor registry ExternalSecret — capstone imagePullSecret prep**
  (CHARTER **Objective O4** + capstone RFC #62, RFC #297 / ADR-0024; split-the-gate
  slice of `auto/harbor-capstone-rewire`, ROADMAP.md rule #9 — landed ahead of the
  live-cluster footprint confirmation because it is purely additive and mutates no
  live-synced state). Added `gitops/secrets/harbor-registry-externalsecret.yaml`
  rendering the already-seeded `secret/harbor/registry` Vault path (from
  `auto/harbor-bootstrap-credentials`) into a `kubernetes.io/dockerconfigjson`
  Secret named `harbor-registry` in the `capstone` namespace, mirroring the
  existing registry-credential ExternalSecret's shape. **Not** referenced by any
  `imagePullSecrets` yet — capstone keeps pulling via its current registry Secret
  until the still-gated cutover item below flips it; this Secret existing early
  only shrinks that later PR. New bats coverage in `tests/harbor-bootstrap.bats`
  (7 cases, including one asserting it is *not* yet wired into any
  `imagePullSecrets`). `docs/dependency-tree.md` updated. `make ci` passes.
  `docs/done/` entry required. (auto/harbor-registry-secret-prep)

- [x] 🟢 **Kargo egress NetworkPolicy Harbor prep** (split-the-gate slice of the
  still-gated cutover item below, per ROADMAP rule #9 — purely additive, mutates
  no live-synced *behavior*: widens `gitops/kargo/networkpolicy/allow-kargo-egress-registry.yaml`
  to also permit egress to the `harbor` namespace on TCP 443/80, alongside the
  existing legacy-registry rule it does not remove. `harbor` already exists live
  — `harbor-extras` pre-creates it at sync-wave 0 — so the selector resolves
  correctly today; nothing in gitops points Kargo's Warehouse at Harbor yet, so
  this rule has zero effect on current traffic, same "widen ahead of the flip"
  reasoning as `cert-manager-root-ca`, wave 5). Extended
  `tests/networkpolicy-kargo.bats` with two cases: the legacy selector is kept
  (not replaced), and the new harbor selector is present. `make ci` must pass.
  `docs/done/` entry required. (auto/harbor-kargo-egress-prep)

- [x] 🟢 **Capstone pipeline re-wire — Artifactory → Harbor registry host**
  (CHARTER **Objective O4** + capstone RFC #62, RFC #297 / ADR-0024 — architect
  decision 2026-06-30; **CI / security-adjacent changes pre-approved by ADR-0024
  per WAYS-OF-WORKING.md §2**; **maintainer-confirmation prerequisite: pick up
  ONLY after the maintainer confirms on #297 that the minimal Harbor profile was
  measured on the live cluster and fits the 12 GB budget on-demand — the
  ADR-0024 go/no-go gate, tracked as a standing `[Action required]` issue (#632,
  stays open until confirmed); check it for a confirmation comment before
  treating this as satisfied; skip to the next item if it cannot be verified this
  run**). The registry-credential Secret (`auto/harbor-registry-secret-prep`)
  and the Kargo egress NetworkPolicy widen (`auto/harbor-kargo-egress-prep`) are
  already prepped, both above — this item is now scoped to the actual
  live-state-mutating cutover only: `.gitlab-ci.yml` (registry host +
  login — note the GitLab CI/CD variables it reads must be repointed at Harbor
  creds by the maintainer outside this repo, since they're not GitOps-managed),
  `gitops/kargo-project/project.yaml` (Warehouse `repoURL` — this is what
  triggers Kargo's `argocd-update` promotion step against the live capstone
  Application, so it stays gated alongside the image refs below, not split out),
  `gitops/apps/capstone/rollout.yaml` + `deployment.yaml` (image refs +
  `imagePullSecrets: harbor-registry`, now that the Secret exists),
  `gitops/kyverno/policies/verify-image-signatures.yaml` (verifyImages scope
  `artifactory.127.0.0.1.nip.io/**` → `harbor.127.0.0.1.nip.io/**` — independent
  of the separate Audit→Enforce flip item, coordinate if both are open), and the
  README / `docs/dependency-tree.md` references (and, once this lands, removing
  the now-unused legacy-registry `namespaceSelector` from the NetworkPolicy the
  prep item above widened). Update the relevant bats (capstone / kargo / kyverno)
  for the new host. `make ci` must pass. `docs/done/` entry required.
  **Executor note:** if this crosses ~400 lines, split the CI/registry-credential
  cutover from the GitOps app/image-ref cutover. (auto/harbor-capstone-rewire)

- [x] 🟢 **Decommission Artifactory manifests** (RFC #297 / ADR-0024 — architect
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

- [x] 🟢 **Harbor governance LimitRange** (CHARTER **Core Values** §"Fits the
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

- [x] 🟢 **NetworkPolicy bats fan-out — Tier-1 wave overlays** (CHARTER
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

- [x] 🟢 **Lab — TiDB on-demand Alloy scrape + dashboard** (CHARTER **Core
  Values** §"Real observability only"; O5 gap-fill for on-demand components —
  follows the `lab-kargo.json` / `lab-inkless.json` precedent; **no
  prerequisites — executor may pick up immediately**). The TiDB namespace
  NetworkPolicy already permits ingress TCP 10080 from `observability`
  (`gitops/tidb/networkpolicy/allow-tidb-from-observability.yaml`) but the
  corresponding Alloy scrape job and dashboard were never added; the NP comment
  references a scrape job that does not yet exist. Add
  `prometheus.scrape "tidb"` block to
  `gitops/platform/observability-alloy.yaml` (static target
  `tidb.tidb.svc.cluster.local:10080`; `scrape_interval = "30s"`; add an
  inline comment explaining this target is idle unless `make tidb-up` is active
  — mirror the `kargo` scrape block comment). New
  `grafana/dashboards/lab-tidb.json` ("Lab — TiDB (Distributed Database)")
  modelled on `lab-kargo.json` stat-row: TiDB server pod running (KSM
  `kube_deployment_status_replicas_available{namespace="tidb"}`); TiDB operator
  pod running (`kube_deployment_status_replicas_available{namespace="tidb-admin"}`);
  ArgoCD sync state (`argocd_app_info{name="tidb-cluster"}`); TiDB query
  execution rate timeseries (`rate(tidb_executor_statement_total[5m])` by
  `type`); TiDB connection count (`tidb_server_connections`); TiDB server memory
  (cAdvisor `container_memory_working_set_bytes{namespace="tidb",container=~"tidb.*"}`).
  **Executor note:** the exact deployment name and TiDB metric names depend on
  the chart version pinned in `gitops/platform/tidb-cluster.yaml` — verify with
  `grep -r "tidb_executor\|tidb_server_connections" gitops/` or the TiDB docs
  before writing the dashboard; if a metric is not available, substitute the
  nearest equivalent (keep ADR-0004: no fabricated fallbacks). All panels real
  Mimir data with `X-Scope-OrgID: lab` (panels show "No data" naturally when
  TiDB is not running — it is on-demand). No new NP changes needed (TCP 10080
  allow is pre-wired). No new HTTPRoute row needed (`tidb-demo` row already in
  Lab UIs panel). Extend `tests/observability.bats` with four assertions:
  scrape block `"tidb"` present in `observability-alloy.yaml`; `lab-tidb.json`
  exists; dashboard references `tidb` namespace in at least one KSM query; no
  fabricated/placeholder data. Update `docs/dependency-tree.md` with TiDB
  observability note (parallel to the Kargo observability note added in
  `auto/kargo-observability-dashboard`). `docs/done/` entry required. `make ci`
  must pass. (auto/tidb-dashboard)

- [x] 🟢 **Lab — Longhorn on-demand Alloy scrape + dashboard** (CHARTER **Core
  Values** §"Real observability only"; O5 gap-fill for on-demand components —
  follows the `lab-kargo.json` / `lab-inkless.json` precedent; **no
  prerequisites — executor may pick up immediately**). The Longhorn namespace
  NetworkPolicy already permits ingress TCP 9500 from `observability`
  (`gitops/longhorn/networkpolicy/allow-longhorn-metrics-ingress.yaml`) but no
  Alloy scrape job or Grafana dashboard has been added yet. Add
  `prometheus.scrape "longhorn"` block to
  `gitops/platform/observability-alloy.yaml` (static target
  `longhorn-manager.longhorn-system.svc.cluster.local:9500`;
  `scrape_interval = "30s"`; add an inline comment explaining this target is
  idle unless `make longhorn-up` is active — mirror the `kargo` scrape block
  comment). New `grafana/dashboards/lab-longhorn.json` ("Lab — Longhorn (Block
  Storage)") modelled on `lab-kargo.json` stat-row: longhorn-manager DaemonSet
  ready (KSM
  `kube_daemonset_status_number_ready{namespace="longhorn-system",daemonset=~"longhorn-manager.*"}`);
  ArgoCD sync state (`argocd_app_info{name="longhorn-extras"}`); attached volume
  count (`count(longhorn_volume_state{state="attached"})` or
  `longhorn_volume_state` aggregated — executor must verify exact label values
  at pickup against Longhorn docs); volume robustness healthy count
  (`count(longhorn_volume_robustness{robustness="Healthy"})`); total volume
  capacity (`sum(longhorn_volume_capacity_bytes)`) gauge. All panels real Mimir
  data with `X-Scope-OrgID: lab` (panels show "No data" naturally when Longhorn
  is not running — it is on-demand per ADR-0004). No new NP changes needed (TCP
  9500 allow is pre-wired). No new HTTPRoute row needed (Longhorn UI row at
  `longhorn.127.0.0.1.nip.io:8000` is in the Lab UIs panel; `make
  lab-ui-check` unaffected). Extend `tests/longhorn.bats` with four assertions:
  scrape block `"longhorn"` present in `observability-alloy.yaml`;
  `lab-longhorn.json` exists; dashboard references `longhorn-system` namespace
  in at least one KSM query; no fabricated/placeholder data. Update
  `docs/dependency-tree.md` with Longhorn observability note. `docs/done/`
  entry required. `make ci` must pass. (auto/longhorn-dashboard)

- [x] 🟢 **O2 measurement — per-scope PSS bats for 5 Tier-1 wave namespaces**
  (CHARTER **Objective O2**, due **2026-09-30**; O2 PSS coverage gap — five
  namespaces (`argo-rollouts`, `velero`, `harbor`, `trivy-system`,
  `node-exporter`) each have a `namespace.yaml` with all four PSA labels in
  place, but their component bats files (`tests/argo-rollouts.bats`,
  `tests/velero.bats`, `tests/harbor.bats`, `tests/trivy-operator.bats`,
  `tests/node-exporter.bats`) only assert two of the four labels. O2's
  measurement criterion requires `tests/securitycontext.bats` + per-scope
  files to cover every namespace. Per `scripts/securitycontext-tests-check.sh`,
  new per-scope tests must go in their own `tests/securitycontext-<scope>.bats`
  file, not the frozen monolith. **No prerequisites — executor may pick up
  immediately.** Create five new files following the
  `tests/securitycontext-kargo.bats` / `tests/securitycontext-longhorn.bats`
  pattern (namespace PSA labels: all 4 + safety checks + extras Application
  exists):
  `tests/securitycontext-argo-rollouts.bats` — PSA `restricted` (enforce:
  restricted, enforce-version: latest, warn: restricted, audit: restricted) +
  safety checks (NOT baseline, NOT privileged) + extras Application
  `gitops/platform/argo-rollouts-extras.yaml` exists;
  `tests/securitycontext-velero.bats` — PSA `restricted` (all 4 labels) +
  safety checks (NOT baseline, NOT privileged) + extras Application
  `gitops/platform/velero-extras.yaml` exists;
  `tests/securitycontext-harbor.bats` — PSA `restricted` (all 4 labels) +
  safety checks (NOT baseline, NOT privileged) + extras Application
  `gitops/platform/harbor-extras.yaml` exists (harbor is on-demand but the
  namespace PSA floor is always-on via the extras Application; test the
  namespace manifest as committed);
  `tests/securitycontext-trivy-system.bats` — PSA `baseline` (enforce:
  baseline, enforce-version: latest, warn: baseline, audit: baseline) +
  safety checks (NOT restricted, NOT privileged) + extras Application
  `gitops/platform/trivy-extras.yaml` exists;
  `tests/securitycontext-node-exporter.bats` — PSA `privileged` (enforce:
  privileged, enforce-version: latest, warn: privileged, audit: privileged)
  + safety checks (NOT restricted, NOT baseline) + extras Application
  `gitops/platform/node-exporter-extras.yaml` exists.
  All 5 new files are additive — the partial checks in the component bats
  files remain untouched. `make ci` must pass. `docs/done/` entry required.
  (auto/securitycontext-tier1-bats)

- [x] 🟢 **O2 measurement — per-scope NP bats for 3 late-addition namespaces**
  (CHARTER **Objective O2**, due **2026-09-30**; O2 NP coverage gap — three
  namespaces (`harbor`, `kargo`, `node-exporter`) have NetworkPolicy overlays
  in `gitops/*/networkpolicy/` and are wired into the appset or a dedicated NP
  Application, but lack dedicated `tests/networkpolicy-<ns>.bats` files; the NP
  drift guard only blocks per-namespace tests creeping back into the shared
  baseline monolith — it does not require every overlay to have a per-scope
  file. O2 says "per-scope files cover every namespace in gitops/". **No
  prerequisites — executor may pick up immediately; pick up after
  `auto/securitycontext-tier1-bats` if both are available.** Create three new
  files following `tests/networkpolicy-kro.bats` as the template (`load
  lib/networkpolicy-paths`; section header; assertions for: overlay
  `kustomization.yaml` exists; references `default-deny.yaml`; references
  `allow-dns-and-apiserver.yaml`; references `zz-dns-clusterip-bridge`; each
  namespace's specific allow files by name). Also add three path vars to
  `tests/lib/networkpolicy-paths.bash`:
  `HARBOR_NP="$REPO/gitops/harbor/networkpolicy"`,
  `KARGO_NP="$REPO/gitops/kargo/networkpolicy"`,
  `NODE_EXPORTER_NP="$REPO/gitops/node-exporter/networkpolicy"`.
  Per-namespace specific allows to assert (verify exact files at executor
  pickup):
  `harbor` — `allow-harbor-ingress.yaml`, `allow-harbor-garage-egress.yaml`,
  `allow-harbor-valkey-egress.yaml`, `allow-harbor-intra-namespace.yaml`,
  `allow-harbor-metrics-ingress.yaml` (all 5 files in overlay);
  `kargo` — `allow-kargo-api-from-gateway.yaml`,
  `allow-kargo-webhook-from-apiserver.yaml`, `allow-kargo-egress-argocd.yaml`,
  `allow-kargo-egress-registry.yaml`, `allow-kargo-metrics-ingress.yaml`;
  `node-exporter` — `allow-node-exporter-metrics-ingress.yaml`.
  These tests are additive — they do NOT remove the existing NP checks from the
  component bats files. `make ci` must pass. `docs/done/` entry required.
  (auto/networkpolicy-tier1-bats-wave2)

- [x] 🟢 **`docs/00-architecture.md` — Harbor registry update** (CHARTER
  **Core Values** §"Docs & dashboards don't drift"; docs-only; **no
  prerequisites — executor may pick up immediately**). The architecture doc
  was last fully rewritten in `auto/architecture-doc-rewrite` (prior to
  ADR-0024). ADR-0024 (Harbor over Artifactory, architect decision
  2026-06-30) replaced ADR-0011, but the architecture doc still cites
  Artifactory with an ADR-0011 reference and does not mention Harbor. Three
  targeted edits (all three within `docs/00-architecture.md`):
  (a) In the "Heavy / on-demand" table update the **Artifactory OSS** row to
  read **Harbor** as the primary registry, citing ADR-0024; add a parenthetical
  noting `gitops/platform/artifactory.yaml` remains pending the decommission
  item (`auto/harbor-artifactory-decommission`) and the capstone re-wire
  (`auto/harbor-capstone-rewire`).
  (b) In the capstone pipeline section update "push to Artifactory" text to
  reflect that the target registry is Harbor (`make harbor-up`;
  `harbor.127.0.0.1.nip.io`) per ADR-0024, noting the cutover is in progress.
  (c) Correct any remaining ADR-0011 mentions to ADR-0024. All edits must
  reflect actual repo state — no fabricated claims (ADR-0004). `make ci`
  must pass. `docs/done/` entry required.
  (auto/architecture-doc-harbor-update)

- [x] 🟢 **O2 NP per-scope coverage loop bats** (CHARTER **Objective O2**,
  due **2026-09-30**; O2 recurrence guard — prevents a future namespace from
  gaining an NP overlay without a corresponding per-scope bats file; mirrors
  the `zz-dns-clusterip-bridge` presence loop added in
  `auto/gitops-clusterip-bridge`. **No prerequisites — executor may pick up
  immediately.** Add a new `@test` to `tests/networkpolicy.bats` (NOT the
  frozen monolith — `tests/networkpolicy.bats` is the shared NP file and
  accepts new tests): title `"every NP overlay dir has a per-scope
  networkpolicy-<ns>.bats file"`; the body iterates all
  `gitops/*/networkpolicy/kustomization.yaml` and
  `gitops/apps/*/networkpolicy/kustomization.yaml` paths; for each path
  derives the namespace name from the parent directory name (e.g.
  `gitops/harbor/networkpolicy/kustomization.yaml` → namespace `harbor`,
  expected bats `tests/networkpolicy-harbor.bats`; for `apps/` paths the
  namespace comes from the grandparent directory — e.g.
  `gitops/apps/capstone/networkpolicy/` → `capstone`); asserts
  `tests/networkpolicy-<ns>.bats` exists; fails with a clear message naming
  the missing file. This bats loop is the O2 NP completeness gate: it fails
  `make ci` if a future NP-fan-out PR skips the per-scope bats. Verify at
  executor pickup that the assertion passes for every existing overlay before
  committing (all per-scope files are present after #336 merges). `make ci`
  must pass. `docs/done/` entry required. (auto/o2-np-coverage-loop)

- [x] 🟢 **O2 PSS per-scope coverage loop bats** (CHARTER **Objective O2**,
  due **2026-09-30**; O2 PSS recurrence guard — prevents a future namespace
  from gaining PSA enforce labels without coverage in either
  `tests/securitycontext.bats` (the frozen monolith) or a
  `tests/securitycontext-<scope>.bats` per-scope file. **No prerequisites —
  executor may pick up immediately (pick up after `auto/o2-np-coverage-loop`
  if both are available).** Add a new `@test` to `tests/drift-detectors.bats`
  (NOT the frozen monolith): title `"every PSA-labelled namespace has
  securitycontext test coverage"`; the body iterates all `namespace.yaml`
  files under `gitops/` that contain `pod-security.kubernetes.io/enforce:`
  using `grep -rl`; for each file derives the namespace name from the
  directory path; asserts that EITHER `grep -q "<ns>" tests/securitycontext.bats`
  finds a `@test` referencing that namespace OR a
  `tests/securitycontext-<ns>.bats` file exists (check file existence with
  `-f`); fails with a clear message naming the uncovered namespace. Handle
  the `apps/` sub-path (`apps/capstone/namespace.yaml` → namespace `capstone`)
  and the `data/rabbitmq/namespace.yaml` sub-path (namespace `data` — covered
  by `securitycontext-data.bats`) correctly. Verify at executor pickup that
  the assertion passes for every existing namespace.yaml before committing.
  `make ci` must pass. `docs/done/` entry required.
  (auto/o2-pss-coverage-loop)

- [x] 🟢 **PSA `restricted` labels — `capstone-pipeline` namespace** (CHARTER
  **Objective O2**, due **2026-09-30**; O2 hardening gap — the `capstone-pipeline`
  namespace (created by Kargo's Project CRD per ADR-0023) has no `namespace.yaml`
  in `gitops/kargo-project/` carrying PSA `restricted` labels; the O2 PSS coverage
  loop added in `auto/o2-pss-coverage-loop` only flags namespaces whose
  `namespace.yaml` already exists, so this gap is silent but real; no workloads
  currently run in `capstone-pipeline` but the floor is defense-in-depth.
  **No prerequisites — executor may pick up immediately.**) Add
  `gitops/kargo-project/namespace.yaml` with four PSA `restricted` labels
  (`pod-security.kubernetes.io/enforce: restricted`,
  `pod-security.kubernetes.io/enforce-version: latest`,
  `pod-security.kubernetes.io/warn: restricted`,
  `pod-security.kubernetes.io/audit: restricted`; `metadata.name: capstone-pipeline`)
  — mirrors the `gitops/apps/capstone/namespace.yaml` pattern. The kargo-project
  ArgoCD Application sources the `gitops/kargo-project/` path in directory mode
  (see `gitops/platform/kargo-project.yaml`); ArgoCD applies the new
  `namespace.yaml` via SSA against the namespace the Kargo Project CRD already
  created. Add a `capstone-pipeline → restricted` row to ADR-0017's
  per-namespace profile table noting no workloads run there (defense-in-depth
  floor; Kargo itself runs in the `kargo` namespace). Extend `tests/kargo.bats`
  with two assertions: `gitops/kargo-project/namespace.yaml` exists; it carries
  all four PSA `restricted` labels. `make ci` must pass. `docs/done/` entry
  required. (auto/capstone-pipeline-psa)

- [ ] 🟢 **Remove legacy capstone `Deployment` — Rollout is now the sole workload
  owner** (CHARTER **Core Values** §"Production-shaped designs"; promised follow-up
  from `auto/capstone-rollout` (2026-06-13) per `docs/done/2026-06-13-capstone-rollout.md`:
  "A follow-up planner item will delete the Deployment once the Rollout is verified
  end-to-end"; **maintainer-confirmation prerequisite: pick up ONLY after the
  maintainer confirms the Argo Rollouts canary pipeline has been exercised end-to-end
  on the live cluster — at least one successful Kargo promotion seen — the done-promise
  gate, tracked as a standing `[Action required]` issue (#633, stays open until
  confirmed); check it for a confirmation comment before treating this as satisfied;
  skip to the next item if not verifiable this run**). Three deliverables:
  (1) delete `gitops/apps/capstone/deployment.yaml` and remove `deployment.yaml`
  from the `resources:` list in `gitops/apps/capstone/kustomization.yaml` (the
  Rollout in `rollout.yaml` is the sole workload owner after this change; image-ref
  and imagePullSecret are already on `rollout.yaml`); (2) update
  `tests/capstone.bats` — replace the `"capstone Deployment exists"` assertion
  with a `"capstone Deployment yaml is absent"` assertion (asserting
  `gitops/apps/capstone/deployment.yaml` does NOT exist) and add a
  `"capstone kustomization does not reference deployment.yaml"` assertion checking
  `kustomization.yaml` does not list `deployment.yaml` — both act as
  recurrence guards per CLAUDE.md's bug-fix-prevents-recurrence rule; (3) update
  `docs/dependency-tree.md` capstone sub-graph to remove the Deployment node and
  note the Rollout is the sole workload. `make ci` must pass. `docs/done/` entry
  required. (auto/capstone-deployment-removal)

- [x] 🟢 **Chaos / fault-injection drill — `make dr-chaos`** (CHARTER **Goals**
  §"operational-resilience discipline" + §"DR / blue-green on a single host" — DORA's
  Pillar 3 "digital operational resilience testing" (TLPT — threat-led penetration
  testing — concept); planner-fallback gap analysis 2026-08-04, reached via
  `executor.prompt.md` STEP 6b after all three standing "Now / next" items were found
  gated on unconfirmed maintainer-confirmation issues #631/#633 (unchanged since the
  prior planner-fallback pass this same run — re-checked both issues' comments, no new
  confirmation) with no live-state-safe slice to split off. **No prerequisites —
  executor may pick up immediately.**) Verified directly (not assumed, ADR-0004):
  `docs/dora-audit-readiness.md`'s Q12 ("Is there an adversarial/penetration-style test
  (DORA's TLPT concept)?") answers "No fault-injection or chaos-engineering scenario
  exists... the closest analog — blue/green cutover — tests *planned* failover, not an
  *injected* failure" and its own "Gap" line names the exact scoped fix: "a `make
  dr-chaos` that kills a random capstone pod during `make capstone-demo` and asserts
  the Rollout/ArgoCD self-heals within budget." Grepping ROADMAP.md for "chaos"/
  "fault-inject" turns up nothing already tracking this (the only hit is this same
  gap's own PR #973 follow-up note). This is real gap-analysis output the audit doc
  itself flags as "a reasonable, scoped future ROADMAP item if you want to close it" —
  not manufactured filler.

  Add `scripts/dr-chaos.sh` mirroring `scripts/dr-restore.sh`'s style (sources
  `lib/colors.sh` + `lib/budget-check.sh`; a `BUDGET_S` constant — pick one consistent
  with the Rollout's own canary/self-heal timing, e.g. 300s, and justify the number in
  the PR body against `gitops/apps/capstone/rollout.yaml`'s actual canary steps/
  `progressDeadlineSeconds`, not a guessed value): picks one running capstone pod at
  random (`kubectl get pods -n capstone -l <rollout label> -o name | shuf -n1`, or the
  active ReplicaSet's pod if `shuf` isn't guaranteed available — check), deletes it
  (`kubectl delete pod`), then polls until either (a) a replacement pod reaches Ready
  and the Rollout/Deployment's available-replica count is back to its pre-injection
  value within budget (self-heal confirmed, exit 0) or (b) the budget is exceeded
  (exit 1, mirroring `dr-restore.sh`'s `budget_warn_if_exceeded`/`budget_final_line`
  pattern). Follow `dr-destroy.sh`'s confirmation-prompt precedent for a destructive
  action — since this deletes a live capstone pod, gate it the same way (`DR_ASSUME_YES=1`
  bypass for non-interactive/scripted use, an explicit typed confirmation otherwise).
  Add `dr-chaos: ## Chaos drill: kill a random capstone pod, assert self-heal within
  budget (DORA Pillar 3 TLPT concept)` to the Makefile's DR section (on-demand only —
  do NOT wire into `make up`, `make dr-test`, or `make ci`, same on-demand pattern as
  `dr-bluegreen`). New `tests/dr-chaos.bats` (clusterless structural, mirrors
  `tests/dr-bluegreen.bats`'s shape exactly — no live cluster required): script exists
  + is executable; sources both shared libs; declares a `BUDGET_S` constant; has a
  `DR_ASSUME_YES`-style non-interactive guard (grep for the same pattern
  `dr-destroy.sh` uses); Makefile declares the `dr-chaos` target; the target is NOT
  invoked from `up`, `ci`, or `dr-test`'s own block (mirrors the existing "target is
  NOT invoked from X (on-demand only)" assertions in `tests/dora-metrics.bats`).
  Update `docs/DR.md` with a new "Chaos / fault-injection drill" subsection under the
  existing DR sections explaining what it does, why (TLPT concept, distinct from
  blue/green's *planned* failover), and its budget. Update
  `docs/dora-audit-readiness.md`'s Q12 answer from "No fault-injection... exists" to
  describe the new drill (cite `docs/DR.md` + the script), updating its "Gap" line
  accordingly — do not overclaim a live-cluster run happened; this remote clusterless
  session can author and structurally verify the script but cannot execute it against
  a real cluster (ADR-0004 caveat, same pattern as every other DR-script PR). PR body
  must state the chosen `BUDGET_S` value's justification and the rollback/safety story
  (worst case: the deleted pod's ReplicaSet/Rollout recreates it exactly as ArgoCD/
  Kubernetes already guarantee for any pod deletion — this script only *observes and
  times* that self-heal, it doesn't change cluster behavior itself, so there is no
  new failure mode beyond "one capstone pod restarts," an event the lab already
  tolerates routinely). `make ci` must pass. `docs/done/` entry required.
  (auto/dr-chaos-fault-injection)

- [x] 🟢 **Third-party dependency register — `docs/dependency-register.md`** (CHARTER
  **Goals** §"operational-resilience discipline" — DORA Pillar 4 (ICT third-party risk
  management); planner-fallback gap analysis 2026-08-04, reached via
  `executor.prompt.md` STEP 6b after all three standing "Now / next" items were found
  gated on unconfirmed maintainer-confirmation issues #631/#633 (re-checked, no new
  confirmation) with no live-state-safe slice to split off. **No prerequisites —
  executor may pick up immediately.**) Verified directly (not assumed, ADR-0004):
  `docs/dora-audit-readiness.md`'s Q14 ("Is there a register of ICT third-party
  dependencies?") answers "Not as a single consolidated register — but the information
  exists, scattered across the ADRs in `docs/decisions/`" and its own "Gap" line calls
  this "real but cheap to close — a `docs/dependency-register.md` tabulating (tool,
  criticality, upstream source, ADR, last-reviewed date) would turn the existing ADR
  content into a queryable register **without gathering new information**." Grepping
  ROADMAP.md for "dependency-register"/"dependency register" turns up nothing already
  tracking this (distinct from the existing `docs/dependency-tree.md`, which maps
  GitOps sync topology/namespaces, not third-party risk fields like criticality or
  license tier). This is real gap-analysis output the audit doc itself names as the
  cheapest-to-close gap in the whole document — a pure re-indexing task, not new
  investigation, so it fits a single clusterless PR cleanly.

  Add `docs/dependency-register.md`: one row per ADR-backed dependency in
  `docs/decisions/README.md`'s index (skip **Superseded** ADRs — ADR-0010, ADR-0011 —
  list only their superseding replacement, per that index's own convention), columns
  **Tool | Criticality | Upstream source | ADR | Last reviewed**. Populate purely from
  each ADR's existing content (per Q14's own framing — "without gathering new
  information"): *Criticality* — always-on core vs. next-wave vs. heavy/on-demand
  (already a documented distinction in ROADMAP.md's "Target end-state" section and
  CHARTER's own "Always-on core"/"Always-on next wave"/"Heavy / on-demand" initiative
  groupings — reuse that existing categorization, don't invent a new scheme);
  *Upstream source* — the project's real repo/chart source as cited in its own ADR
  (e.g. Kyverno → `github.com/kyverno/kyverno`); *ADR* — a link to the deciding ADR
  file; *Last reviewed* — the most recent dated entry in that ADR's own
  "Re-evaluation log" section if it has one, else the ADR's own decision date. Add a
  short intro paragraph explaining the register's purpose (Q14) and its two companion
  artifacts (`docs/decisions/` for the *why*, `docs/dependency-tree.md` for the GitOps
  *topology*, this file for the third-party-risk *rollup*) so the three don't read as
  redundant. Update `docs/dora-audit-readiness.md`'s Q14 answer from "Not as a single
  consolidated register" to "Yes" (cite the new file), updating its "Gap" line
  accordingly. New `tests/dependency-register.bats` (clusterless structural, mirrors
  the shape of `tests/incident-log.bats`): file exists; has the five-column header row;
  contains at least N rows (pick N ≥ 20, sized to the real non-superseded ADR count at
  pickup time — count `docs/decisions/adr-*.md` files minus superseded ones, don't
  guess); spot-checks a couple of specific, stable entries (e.g. a row citing ADR-0002/
  Garage, a row citing ADR-0018/Valkey); no fabricated/placeholder content (ADR-0004
  grep guard). `make ci` must pass. PR body must note this is a pure re-indexing task
  (no new dependency-risk judgment made, no new criticality tier invented) and that
  keeping it in sync with future ADRs is a manual/best-effort convention for now (note
  in the PR body whether a drift-guard mechanical check is worth a follow-up item, per
  CLAUDE.md's bugfix-recurrence-guard spirit — though this is a new-doc gap-fill, not a
  bugfix, so a follow-up guard is a judgment call for the PR body to make, not a hard
  requirement). `docs/done/` entry required. (auto/dependency-register)

- [x] 🟢 **Incident classification (severity) scheme + incident log** (CHARTER
  **Goals** §"operational-resilience discipline" — DORA's incident-management pillar
  mapped onto concrete practice; planner-fallback gap analysis 2026-08-04, reached via
  `executor.prompt.md` STEP 6b after all three standing "Now / next" items were found
  gated on unconfirmed maintainer-confirmation issues #631/#633 with no live-state-safe
  slice to split off. **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`'s Q6
  ("Is there a documented incident classification (severity) scheme?") answers "No...
  Gap: real" and Q7 notes the same absence; the file's closing summary (¶ after
  "## Overall summary") names this the one *structural* (non-cadence) DORA gap left —
  "neither [`make dora-metrics`'s MTTR row nor its change-failure-rate row] is a
  substitute for a severity scheme or a root-cause incident log for live-cluster
  events." `docs/dora-resilience-mapping.md`'s Pillar 2 section cites only the
  CI-health MTTR metric, nothing about classification or a log. Grepping ROADMAP.md
  and `docs/` for "incident classification"/"incident log" turns up nothing already
  tracking this. This is genuine, real gap-analysis output (Core Value/Goal not
  covered), not manufactured filler — and unlike the three gated items above it, it
  mutates no live-synced cluster state at all (pure docs), so it carries zero blast
  radius risk.

  Add `docs/incident-log.md`: (1) a severity scheme sized for this lab's actual
  solo-operator, clusterless-by-default shape — explicitly name "no paging, no
  escalation path" as an intentional non-goal (mirroring Q7's own gap note) rather
  than a silent absence, e.g. P0 (whole-lab-down / data-loss risk — fix same session),
  P1 (single always-on component down or a security-relevant gap — fix same session
  or next), P2 (on-demand/heavy component or non-blocking defect — backlog item), P3
  (cosmetic/doc drift — filler-lane item); (2) a "How to log a new incident" template
  row shape (mirror the existing `| Field | Content |` template already used in
  `docs/dora-audit-readiness.md`'s own "Template for a new question" — Date,
  Severity, Component(s), Detection, Root cause, Fix, Time to resolve, Follow-up);
  (3) backfill the real, already-observed incidents narrated in issue #631/#633's own
  comment history (verified directly against those comments, not fabricated,
  ADR-0004) — at minimum: Cilium agents losing apiserver connectivity after a k3d
  node IP reshuffle (fixed live via `make cilium-up`, #631 comment 2026-07-29);
  `artifactory` namespace's default-deny NetworkPolicy missing an intra-namespace
  allow so `artifactory-oss` could never reach its own bundled `postgresql` (fixed in
  PR #884, `allow-artifactory-intra-namespace.yaml`); Harbor's HTTPRoute unreachable
  because `allow-envoy-proxy-backend-egress` never allowlisted the `harbor` backend
  namespace (fixed in PR #968); Harbor's Vault-held admin credential never matching
  Harbor's real password so CI `docker login` could never succeed (fixed live,
  Vault/GitLab-CI-variable data, not GitOps-managed, no PR); and the still-open
  finding that no GitLab Runner has ever been registered against this lab's GitLab
  instance, so no `.gitlab-ci.yml` pipeline has ever executed here (#631/#633,
  2026-08-04 comments — log this one with no "Fix"/"Time to resolve" yet, an
  explicitly unresolved row, not a fabricated resolution).

  Update `docs/dora-audit-readiness.md`'s Q6 answer from "No" to describe the new
  scheme (cite `docs/incident-log.md`), updating its "Gap" line accordingly; leave
  Q7's alerting/escalation gap language intact (this item adds classification +
  logging, not automated paging — don't overclaim). Update the closing summary
  paragraph to reflect that classification + a real incident log now exist, while
  keeping the honest residual gap (no automated detection/alerting) explicit. Add one
  sentence to `docs/dora-resilience-mapping.md`'s Pillar 2 section pointing to the new
  doc alongside the existing MTTR metric citation. Add a one-line pointer to
  `docs/incident-log.md` from `docs/DR.md`'s "Recovery cookbook" section for
  severity triage. New `tests/incident-log.bats` (clusterless structural,
  mirrors the shape of other doc-presence bats files): `docs/incident-log.md`
  exists; contains a severity scheme referencing `P0`/`P1`/`P2`/`P3`; contains at
  least the five backfilled incidents above (grep for `#884`, `#968`, `cilium`,
  `GitLab Runner`); `dora-audit-readiness.md`'s Q6 answer no longer contains the
  literal string "**Answer:** No" for Q6 specifically; no fabricated/placeholder
  content (ADR-0004 grep guard: `grep -iE '"(fake|mock|placeholder|dummy)"'`).
  `make ci` must pass (in particular `markdown-links-check.sh` for the new
  cross-references). PR body must note this only closes Q6, not Q7 (alerting/
  escalation remains a real, separately-scoped gap — Q12's chaos-testing idea
  already named in the audit doc is a reasonable follow-up planner item if wanted,
  not bundled into this one to stay within WAYS-OF-WORKING.md §3's size cap).
  `docs/done/` entry required. (auto/incident-severity-scheme-log)

- [x] 🟢 **Standardize scripts/*.sh's `bad()` failure-flag variable to `drift`**
  (janitor finding, issue #957 — a duplication sweep found `ok()`/`bad()` printf
  helpers redefined inline in ~35 `scripts/*.sh` files, but unlike the `yqs()`
  dedup in PR #956 the `bad()` body isn't byte-identical everywhere: it sets a
  different failure-flag variable per script — `drift`, `rc`, or `FAILED` — each
  read later via that script's own `exit "$<var>"`. **No prerequisites — executor
  may pick up immediately.** Pure rename, no logic change: in every
  `scripts/*.sh` that defines its own `bad()` setting `rc=1` or `FAILED=1`,
  rename that variable (and every read of it, typically just the trailing
  `exit "$rc"`/`exit "$FAILED"`) to `drift`, matching the majority convention
  already used by most of these scripts. Do NOT touch scripts whose `bad()` sets
  no variable at all (informational-only) or extract the shared helper yet —
  this item is rename-only prep, split from the extraction to stay within
  WAYS-OF-WORKING.md §3's ~400-line PR cap; the follow-up extraction item below
  depends on this one merging first. `make ci` must pass (every renamed script's
  actual pass/fail behavior is unchanged — verify each one still exits the same
  way before/after). `docs/done/` entry required. (auto/scripts-drift-var-rename)

- [x] 🟢 **Extract shared `ok()`/`bad()` helpers to `scripts/lib/colors.sh`; add a
  recurrence guard** (janitor finding, issue #957; **pick up ONLY after
  `auto/scripts-drift-var-rename` merges** — every `scripts/*.sh` defining its
  own `bad()` must already use `drift` as the failure-flag variable name before
  this extraction is safe, since the shared version below writes to the
  sourcing script's own `drift` variable). Add `ok()`/`bad()` function
  definitions to `scripts/lib/colors.sh` (which already centralizes the
  `$G`/`$R`/`$Z` color codes these two functions use); remove each script's own
  inline `ok()`/`bad()` copy, replacing with (or confirming) a
  `source .../lib/colors.sh` line. New `scripts/ok-bad-lib-check.sh` (+ `make
  ok-bad-lib-check`, wired into `make ci` and the GitHub Actions `drift` job,
  plus a PostToolUse sync hook) mirroring `scripts/yqs-lib-check.sh`'s pattern
  (PR #956): fails if any `scripts/*.sh` still defines its own local
  `ok()`/`bad()` instead of sourcing the shared copy. Add matching bats coverage
  (`tests/drift-<scope>.bats` + `tests/hook-scripts-<scope>.bats` conventions —
  the relevant monoliths are frozen). `make ci` must pass. `docs/done/` entry
  required. (auto/ok-bad-lib-extract)

- [x] 🟢 **`capstone-pipeline` governance LimitRange — RFC #294 fan-out completion**
  (CHARTER **Core Values** §"Fits the 16 GB reality" + §"Everything as code; GitOps
  deploys it"; RFC #294 mapping-table completion gap — discovered via a systematic
  cross-reference of every PSA-labeled namespace against
  `gitops/platform/governance-appset.yaml`'s coverage list, same technique that found
  the `auto/remove-dead-kiali-governance` cleanup. **No prerequisites — executor may
  pick up immediately.**) The `capstone-pipeline` namespace
  (`gitops/kargo-project/namespace.yaml`, PSA `restricted` — ADR-0017's own row calls
  it "a defense-in-depth floor ensuring any future pod admitted here is hardened by
  default") is the only PSA-labeled, non-excluded namespace still missing a
  governance LimitRange entry: every other standard-tier namespace already has one,
  and `capstone-pipeline` is not in the documented on-demand-heavy exclusion list
  (`tidb`, `tidb-admin`, `longhorn-system`, `istio-system`, `inkless`) or the
  ADR-0024 `artifactory` exclusion. Add
  `gitops/governance/capstone-pipeline/kustomization.yaml` (standard tier, mirrors
  every other leaf overlay: `resources: [../base/limitrange-standard.yaml]`). Add a
  `capstone-pipeline-governance` entry to `governance-appset.yaml`'s list generator
  (`gitPath: gitops/governance/capstone-pipeline`, `destNamespace:
  capstone-pipeline`). Add `capstone-pipeline` to `tests/governance.bats`'s
  `STANDARD_NS`. Update `docs/dependency-tree.md`'s wave-4 governance list to include
  `capstone-pipeline`. **Executor note:** unlike most governance items, this creates
  one new piece of always-on auto-synced cluster state (a `capstone-pipeline`
  namespace + LimitRange, pre-created ahead of `make kargo-up`) — the same
  pre-creation pattern already used for the `kargo` namespace itself via
  `kargo-extras`, not a new pattern. PR body must call this out explicitly and note
  the rollback path (revert the appset entry; ArgoCD prunes the LimitRange +
  namespace within its sync interval — `capstone-pipeline` hosts no other workload
  today, so pruning is lossless). `make ci` must pass. `docs/done/` entry required.
  (auto/governance-capstone-pipeline)

- [x] 🟢 **O5 bats gap — `lab-argocd.json` + `lab-gitsync.json` in
  `tests/dashboard-coverage.bats`** (CHARTER **Core Values** §"Docs &
  dashboards don't drift" + **Objective O5**, due **2026-09-30**; O5 drift
  gap — both dashboards exist in `grafana/dashboards/` with real Mimir
  datasource panels (`"uid": "mimir"`) but are absent from the O5 coverage
  sweep in `tests/dashboard-coverage.bats`. `lab-argocd.json` (32 panels)
  covers ArgoCD operational metrics already scraped by Alloy (four scrape
  targets in `observability-alloy.yaml`: application-controller-metrics:8082,
  server-metrics:8083, repo-server-metrics:8084,
  applicationset-controller-metrics:8080). `lab-gitsync.json` (4 panels,
  "Lab — Git Sync") monitors Grafana native Git Sync health and proves
  ADR-0006 works in the lab. **No prerequisites — executor may pick up
  immediately.** Add two section blocks to `tests/dashboard-coverage.bats`
  following the existing 2-assertion-per-section pattern (see `# argo-rollouts`
  section for the exact style): block headed `# argocd` with
  `@test "lab-argocd.json exists (argocd coverage)"` asserting
  `[ -f "$DASHBOARDS/lab-argocd.json" ]` and
  `@test "lab-argocd.json has real Mimir datasource panel (ADR-0004)"`
  asserting `run grep -q '"uid": "mimir"' "$DASHBOARDS/lab-argocd.json"`;
  block headed `# gitsync` with the same two assertions for `lab-gitsync.json`.
  Verify both JSON files exist and contain `"uid": "mimir"` before committing.
  `make ci` must pass. `docs/done/` entry required.
  (auto/o5-argocd-gitsync-coverage-bats)

- [x] 🟢 **Governance gap — add `envoy-gateway-system` and `node-exporter`
  to the platform governance ApplicationSet** (CHARTER **Core Values** §"Resource
  limits everywhere"; RFC #294 execution gap — both namespaces are always-on,
  carry PSA labels, and have full NP overlays, but neither appears in
  `gitops/platform/governance-appset.yaml` and no explicit exclusion for them
  exists in RFC #294's rationale; no LimitRange is applied to either namespace
  today. **No prerequisites — executor may pick up immediately.**) Three
  deliverables: (1) add two entries in the `# standard tier` block of
  `gitops/platform/governance-appset.yaml` matching the existing format
  (`appName: envoy-gateway-system-governance`, `gitPath:
  gitops/governance/envoy-gateway-system`, `destNamespace:
  envoy-gateway-system`) and the same for `node-exporter`; (2) create
  `gitops/governance/envoy-gateway-system/kustomization.yaml` and
  `gitops/governance/node-exporter/kustomization.yaml`, each containing
  `namespace: <ns>` + `resources: - ../base/limitrange-standard.yaml` (same
  pattern as `gitops/governance/argocd/kustomization.yaml`); (3) extend
  `tests/governance.bats` with two assertions per new namespace:
  `envoy-gateway-system governance leaf dir has kustomization.yaml` (asserting
  `[ -f "$GOV/envoy-gateway-system/kustomization.yaml" ]`) and
  `envoy-gateway-system kustomization references the shared base limitrange`
  (asserting `run grep -q 'base/limitrange-standard.yaml'`), and the same two
  for `node-exporter`. `make ci` must pass. `docs/done/` entry required.
  (auto/governance-envoy-node-exporter)

- [x] 🟢 **NetworkPolicy overlay — `capstone-pipeline` namespace** (**blocked
  on PR #354 `auto/capstone-pipeline-psa` merging first** — the
  `capstone-pipeline` `namespace.yaml` must exist before this NP overlay is
  applied; skip to the next item until #354 merges; CHARTER **Objective O2**,
  due **2026-09-30**; ADR-0016 defense-in-depth gap — the `capstone-pipeline`
  namespace created by Kargo's Project CRD (ADR-0023) currently has no
  default-deny NetworkPolicy overlay; Kargo promotion-step pods run in this
  namespace during pipeline executions). Add
  `gitops/kargo-project/networkpolicy/kustomization.yaml` referencing the
  shared baseline templates (`default-deny.yaml` + `allow-dns-and-apiserver.yaml`
  + `zz-dns-clusterip-bridge.yaml`) plus the allow rules needed by promotion
  jobs (verify at executor pickup against actual Kargo promotion-pod egress
  requirements — at minimum: DNS, apiserver, and egress to the `kargo`
  namespace for the Kargo controller callback). Add a new Application
  `gitops/platform/kargo-project-networkpolicy.yaml` (non-auto-synced, wave
  4, `LoadRestrictionsNone`; pairs with `kargo-project.yaml`). Add
  `tests/networkpolicy-capstone-pipeline.bats` covering the three shared
  baseline template references (mirrors the pattern of any existing per-scope
  bats file). The O2 NP coverage loop in `tests/networkpolicy.bats` will
  guard this namespace automatically once the overlay exists. `make ci` must
  pass. `docs/done/` entry required.
  (auto/capstone-pipeline-networkpolicy)

- [x] 🟢 **Cilium agent Prometheus metrics + O5 CNI dashboard** (CHARTER **Objective O5**,
  RFC #358 — architect decision 2026-07-11). Enable `prometheus.enabled: true` and
  `prometheus.port: 9962` in `gitops/platform/cilium.yaml` `valuesObject` (Hubble stays
  disabled; `hubble.enabled: false` unchanged — 250-400 MB cost excluded from the 12 GB
  budget). Add `discovery.kubernetes "cilium_agent"` + `discovery.relabel "cilium_agent"`
  + `prometheus.scrape "cilium_agent"` blocks to `gitops/platform/observability-alloy.yaml`
  (Cilium DaemonSet uses `hostNetwork: true` in `kube-system`; kubernetes_sd pod discovery
  with `k8s-app=cilium` selector + relabel `__address__` to port 9962; scrape_interval
  30s; inline comment noting target is idle until `make cilium-up` has run at least once).
  Extend `gitops/observability/networkpolicy/allow-alloy-egress-external.yaml` with TCP
  9962 egress to `ipBlock: cidr: 0.0.0.0/0` (mirrors the existing TCP 9100 node-exporter
  and TCP 10250 kubelet/cAdvisor ipBlock rules). New `grafana/dashboards/lab-cilium.json`
  ("Lab — Cilium (CNI)") with five real Mimir-datasource panels: (1) Cilium agent DaemonSet
  ready replicas (`kube_daemonset_status_number_ready{namespace="kube-system",daemonset="cilium"}`);
  (2) ArgoCD sync state (`argocd_app_info{name="cilium"}`); (3) total endpoint count
  (`sum(cilium_endpoint_state)`); (4) policy count stat (`cilium_policy_count`); (5) packet
  drop rate timeseries (`rate(cilium_drop_count_total[5m])` by `reason`). All panels use
  `X-Scope-OrgID: lab` (ADR-0004 — no fabricated data). Extend `tests/dashboard-coverage.bats`
  with Cilium assertion (`lab-cilium.json` exists; `"uid": "mimir"` present). Add bats
  assertions to `tests/observability.bats` or a new `tests/cilium.bats`: `cilium_agent`
  scrape block present in `observability-alloy.yaml`; `lab-cilium.json` exists; dashboard
  references `cilium_policy_count`; no placeholder data. Update `docs/dependency-tree.md`
  with a one-line Cilium metrics scrape note. `docs/done/` entry required. `make ci` must
  pass. Single-PR preferred; split only if PR exceeds ~400 lines.
  (auto/cilium-agent-metrics)

- [x] 🟢 **`docs/00-architecture.md` — add learning-path steps for DR/blue-green and GitOps promotion (Kargo)** (CHARTER **Goals** gap — "DR / blue-green on a single host" is an explicit Goal that does not appear in the current learning-path steps 0–9; Kargo promotion pipelines are deployed and documented in the Who-does-what table but are absent from the learning-path narrative; **no prerequisites — executor may pick up immediately**; docs-only). Two small additions to the `## Suggested learning path` section in `docs/00-architecture.md`:
  (a) **Step 10 — DR / blue-green**: after step 8 (Velero backup & restore), add a step explaining `make dr-bluegreen` — it stands up a second k3d 'green' cluster that sources the *same* `gitops/` repo via `gitops/bluegreen/green-root.yaml`, cuts Envoy Gateway traffic over to green, and verifies service continuity before retiring blue with `make dr-bluegreen-promote`. `make dr-bluegreen-down` reclaims the green cluster's RAM when the exercise is done. Cross-reference `docs/DR.md §Zero-downtime blue/green` for the full runbook. Explain that steps 8 and 10 test *two distinct recovery modes*: Velero restores data from backup on the same cluster; blue-green rebuilds the platform on a fresh cluster with live traffic cut over, proving the "recreate-from-code" CHARTER Core Value under real traffic.
  (b) **Step 11 — GitOps promotion pipelines**: describe Kargo's role — a `Warehouse` CRD watches Harbor for new image digests pushed by GitLab CI; a `dev` `Stage` auto-promotes; a `prod` `Stage` requires a manual gate approval in the Kargo UI (`kargo.127.0.0.1.nip.io`, `make kargo-up`). The promotion history is visible in the Grafana Kargo dashboard (`lab-kargo.json`). Cite ADR-0023. Note `make kargo-down` when done. Explain how this layer adds *multi-stage, Warehouse-gated* promotion on top of the Argo Rollouts canary at step 7 — the two complement each other: Argo Rollouts controls in-cluster traffic shaping; Kargo controls which image digest is promoted across environment stages.
  No code changes. `make ci` must pass (readme-check and lab-ui-check unaffected — no new HTTPRoute row, no new Application). `docs/done/` entry required.
  (auto/architecture-doc-learning-path-update)

- [x] 🟢 **`docs/00-architecture.md` — add learning-path step 12 for cloud-agnostic infrastructure design** (CHARTER **Goals** gap, self-caught: the "cloud-agnostic infrastructure design" learning outcome added to CHARTER.md's Goals alongside ADR-0026 was never reflected in the learning-path narrative, including in the very PR that added steps 10–11 above — docs-only). Adds step 12 explaining that `argocd`/`gitlab` Terragrunt units depend only on `cluster`'s `kube_context`/`cluster_name`/`api_endpoint` outputs, which is why steps 1–11 run identically on `local/` (k3d) or `oracle/` (Oracle Cloud Always Free + k3s), citing `infra/live/README.md`, ADR-0026, and ADR-0027. No code changes. `docs/done/` entry required.
  (auto/architecture-doc-cloud-agnostic-step)

- [x] 🟢 **Hook-scripts negative-path coverage — `argocd-crd-ssa-sync-hook.sh` +
  `helm-chart-pin-sync-hook.sh`** (CLAUDE.md's "every bugfix/gap prevents recurrence"
  ethos + ROADMAP rule #9's coverage/hardening sweep; follow-up flagged by
  `docs/done/2026-07-16-hook-scripts-bats-coverage.md`, which closed bats coverage for
  13 previously-untested hook scripts but left these two with only filter + real-repo
  happy-path coverage, noting their underlying checks are "network-tolerant with no
  hook-level file-scoped override for injecting a broken fixture." That note is
  incomplete: both underlying `*-check.sh` scripts already have offline test seams used
  by `tests/drift-detectors.bats` — `helm-chart-pin-check.sh` supports
  `CHARTPINCHECK_ROOT` + a `CHARTPIN_RESOLVER` stub (fixtures already exist at
  `tests/fixtures/helm-chart-pin/{drift,in-sync}/`); `argocd-crd-ssa-check.sh` supports
  `CRDSSA_CHECK_ROOT` + a `CRDSSA_RENDERER` stub (fixtures already exist at
  `tests/fixtures/argocd-crd-ssa/{drift,in-sync}/`). Since each hook simply
  `bash`-invokes its check script in the same shell (no `env -i`), exported
  `CHARTPIN_RESOLVER`/`CRDSSA_RENDERER` env vars propagate straight through — no new
  fixtures need to be built, just two more `@test` cases in
  `tests/hook-scripts-coverage.bats`: (1) for `argocd-crd-ssa-sync-hook.sh`, run with
  `CRDSSA_RENDERER="$REPO/tests/fixtures/argocd-crd-ssa/renderer-stub.sh"` and a payload
  pointing at `tests/fixtures/argocd-crd-ssa/drift/big-app.yaml` (oversized CRD, no
  `ServerSideApply=true`) — assert exit 2 and that stderr names the offending
  Application; (2) for `helm-chart-pin-sync-hook.sh`, run with
  `CHARTPIN_RESOLVER="$REPO/tests/fixtures/helm-chart-pin/resolver-stub.sh"` and a
  payload pointing at `tests/fixtures/helm-chart-pin/drift/gitops/apps.yaml` (a
  `*-missing` pinned version) — assert exit 2 and that stderr names the bad pin. No
  script changes — tests only. `make ci` must pass. `docs/done/` entry required.
  **No prerequisites — executor may pick up immediately.**
  (auto/hook-scripts-negative-path-coverage)

- [x] 🟢 **Fix stale `(follow-up item)` markers in ADR-0028/ADR-0029 + widen
  `scripts/adr-followup-check.sh` to catch the parenthetical form** (CHARTER
  **Core Values** §"Docs & dashboards don't drift"; planner gap-analysis finding,
  2026-07-19 — **no prerequisites, executor may pick up immediately**). Verified
  directly against the actual repo state (not assumed, per ADR-0004): five table
  rows across two ADRs still carry a `(follow-up item)` annotation for work that
  has already shipped and is already tested:
  - `docs/decisions/adr-0028-cert-manager-tls-lifecycle.md` lines 192-194: the
    HTTPS `:443` listener (`gitops/network/gateway.yaml:32-34`), the wildcard
    `Certificate` (`gitops/network/certificates/wildcard-certificate.yaml`), and
    the `:8443` frontdoor port mapping (`scripts/bluegreen-frontdoor.sh`,
    `scripts/frontdoor-ensure.sh`) all exist and are covered by
    `tests/frontdoor-https.bats`.
  - `docs/decisions/adr-0029-keda-event-driven-autoscaling.md` lines 184-185: the
    cert-manager webhook TLS wiring (`gitops/platform/keda.yaml`'s
    `certManager.enabled: true` block referencing the `k8s-lab-ca` issuer) and the
    `ScaledObject`/`TriggerAuthentication` demo
    (`gitops/data/demo/keda-scaling/{scaledobject,triggerauthentication}.yaml`)
    both exist and are covered by `tests/keda.bats` /
    `tests/keda-scaledobject.bats`.

  `scripts/adr-followup-check.sh` (the existing mechanical guard for exactly this
  drift class — its own header comment cites the ADR-0006/CHARTER precedent) only
  greps for the capitalized literal `Follow-up:` and does not catch this
  parenthetical `(follow-up item)` form, so it stayed green through both of these
  going stale — the same undetected-drift failure mode the script exists to
  prevent, recurring in a second syntactic shape.

  Two changes: (1) edit the five table cells in ADR-0028/ADR-0029 above to drop
  the stale `(follow-up item)` annotation now that each is verified shipped and
  tested (cite the concrete file/test in the cell or an adjacent note, mirroring
  how other ADRs' "Files touched"-style tables read once implemented); (2) widen
  `scripts/adr-followup-check.sh`'s `grep` pattern (currently `'Follow-up:'`) to
  an alternation also matching the literal string `(follow-up item)` — extend the
  existing `hits=` grep line, keep the same exit-2/CI/hook wiring, no other
  script structure change. Add fixtures/cases mirroring the existing
  `tests/fixtures/adr-followup-check/{in-sync,drift-adr}` pattern: a new
  drift fixture carrying `(follow-up item)` in a table cell should fail the
  check the same way the existing `Follow-up:` drift fixture does. Extend
  `tests/drift-detectors.bats` with one new `@test` asserting the check fails on
  the new fixture, and confirm the existing "passes on the real repo" test
  (`tests/drift-detectors.bats:87`) still passes once the stale markers are
  removed. `make ci` must pass. `docs/done/` entry required.
  (auto/adr-followup-parenthetical-form)

- [x] 🟢 **GitHub Actions major-version bumps — `actions/checkout` v4.3.0→v7.0.0,
  `actions/cache` v4.3.0→v6.1.0, `actions/github-script` v7.0.1→v9.0.0,
  `hashicorp/setup-terraform` v3.1.2→v4.0.1** (CHARTER **Core Values**
  §"Clusterless gates stay green" + general CI hardening; RFC #611 — architect
  decision 2026-07-20, resolving issue #608's open Node-runtime question.
  **No prerequisites — executor may pick up immediately.**) RFC #611's binding
  decision, verified against real sources (ADR-0004): GitHub-hosted
  `ubuntu-latest` runners cache both Node.js 22.23.1 and 24.18.0 today
  (`actions/runner-images`' `Ubuntu2404-Readme.md`, fetched directly), and
  GitHub now requires actions to run on Node ≥24 (`github.blog` changelog,
  2025-09-19 Node 20 deprecation). None of this repo's workflows use the
  `pull_request_target`/`workflow_run` triggers checkout v7.0.0 restricts
  (confirmed by grep across `.github/workflows/`), and the repo's one
  github-script step (`auto-update-prs.yml`) uses only the injected
  `github`/`context` globals and `require('child_process')`, never
  `require('@actions/github')` or a `getOctokit` redeclaration — so v9.0.0's
  ESM migration is a non-issue.

  Update all 15 `uses:` lines across `.github/workflows/*.yml` to the exact
  commit SHAs below (verified directly via `git ls-remote --tags`, not
  inferred): **note the github-script SHA is the annotated tag's *peeled*
  commit, not the tag-object SHA `git ls-remote` lists first** — a real
  footgun, since the other three are lightweight tags where the listed SHA
  already is the commit:
  - `actions/checkout` → `9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` # v7.0.0
  - `actions/cache` → `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` # v6.1.0
  - `actions/github-script` → `3a2844b7e9c422d3c10d287c895573f7108da1b3` # v9.0.0
    (peeled commit — do NOT use `d746ffe35508b1917358783b479e04febd2b8f71`,
    the tag object itself)
  - `hashicorp/setup-terraform` → `dfe3c3f87815947d99a8997f908cb6525fc44e9e` # v4.0.1

  Mirror the exact `# vX.Y.Z` comment format `chore/github-actions-sha-pinning`
  (#609) established. Extend or add a bats file (check for existing
  GitHub-Actions-pin coverage first, else add `tests/github-actions-pins.bats`)
  asserting the four new SHAs/version comments are present — a recurrence
  guard mirroring this repo's other per-component pin-assertion pattern.
  `make ci` must pass — and per RFC #611, the PR's own GitHub Actions run
  (lint/unit/drift/manifests/terraform/kustomize/up-to-date, all executing on
  the bumped actions) IS the live verification here; call that out explicitly
  in the PR body instead of the usual clusterless-caveat framing. `docs/done/`
  entry required. Closes #611. (auto/github-actions-node24-bump)

- [x] 🟢 **Velero chart major bump `8.7.2` → `12.1.0`** (RFC #617 — architect
  decision 2026-07-20, actioning ADR-0021's 2026-07-18 Re-evaluation log flip
  condition. **No prerequisites — executor may pick up immediately.**)
  Implement RFC #617's binding spec exactly: bump
  `gitops/platform/velero.yaml`'s `targetRevision` from `8.7.2` to `12.1.0`
  (`appVersion` `1.15.2` → `1.18.1`). RFC #617 already verified, field-for-field
  against the real chart source at that tag, that every key this repo's
  `valuesObject` sets (`credentials.{useSecret,existingSecret}`,
  `configuration.{defaultVolumesToFsBackup,features,uploaderType,
  backupStorageLocation}`, `deployNodeAgent`, `resources`,
  `nodeAgent.resources`) is unchanged across the `8.x` → `12.x` jump — no
  `valuesObject` schema change is required, this is a version-number-only bump.
  Update `gitops/platform/velero.yaml`'s own in-file comment (documents the
  prior `8.4.0`→`8.7.2` bump) with the new bump's rationale. Extend
  `tests/velero.bats`'s chart-pin assertion (add one if none exists — check
  first) to the new version. Append the RFC #617 acceptance-criteria's required
  dated entry to ADR-0021's `## Re-evaluation log` (the architect PR already
  added the 2026-07-20 "actioned as RFC #617" entry; add one more recording the
  bump itself landing, mirroring the two-entry pattern ADR-0020 used for its
  Argo Rollouts chart bump). PR body must document the ADR-0004 caveat: this
  remote clusterless session cannot verify Velero actually starts cleanly or
  that a real backup+restore cycle succeeds post-bump on a live cluster — call
  out the rollback path (revert `targetRevision`; ArgoCD self-heals; Velero
  backups are content-addressed in Garage so a revert doesn't lose existing
  backup data). `make ci` must pass. `docs/done/` entry required. Closes #617.
  (auto/velero-chart-bump-12-1-0)

- [x] 🟢 **Bump Cilium chart `1.17.18` → `1.18.12`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC #917 — architect decision
  2026-07-30, ADR-0014 audit #916 resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) Cilium's `SECURITY.md` support table now
  marks every version `< 1.18.0` as unsupported (verified directly, not
  training knowledge — ADR-0004); this lab's `1.17.18` pin
  (`gitops/platform/cilium.yaml`) is on that unsupported line. This is the
  exact flip condition ADR-0014's 2026-07-28 Re-evaluation log entry (audit
  #772) recorded in advance. Cilium's own upgrade path is sequential
  minor-by-minor, so this item is deliberately one step (`1.17.18` →
  `1.18.12`, the latest `1.18.x` patch per `git ls-remote --tags
  https://github.com/cilium/cilium.git`), not the full jump to the current
  `1.20.0` — a future item covers the next step once this one has landed.

  Bump `gitops/platform/cilium.yaml`'s `targetRevision: 1.17.18` →
  `1.18.12`. Re-verify at pickup time (not just this RFC's cached read) that
  the `1.18.12` chart's `values.yaml` still contains every key this
  Application's `valuesObject` sets (`kubeProxyReplacement`,
  `prometheus.enabled`/`port`, `hubble.enabled`, `operator.replicas`/
  `resources`, `resources`) — same due-diligence pattern as the
  Grafana/Pyroscope/ArgoCD chart bumps. Add a new dated entry to ADR-0014's
  `## Re-evaluation log` (after the 2026-07-30 audit #916 entry) recording
  this bump landing, with a new flip condition for the next step (e.g.
  "revisit when `1.18.x` itself reaches end-of-support, or a CVE lands against
  `1.18.12` specifically"). Extend or add a `tests/*.bats` chart-pin assertion
  for Cilium (check for an existing one first) asserting `1.18.12` is present
  in `cilium.yaml` — a recurrence guard mirroring this repo's other
  per-component exact-version pin assertions. Update
  `docs/dependency-tree.md` only if it cites the pinned Cilium version
  explicitly (verify first). PR body must document: the EOL trigger, why
  `1.18.12` (smallest safe delta / sequential-upgrade step), and the
  ADR-0004 caveat that this remote clusterless session cannot verify Cilium
  continues routing pod traffic cleanly post-bump on a live cluster — call
  out the rollback path (revert `targetRevision`; ArgoCD self-heals; Cilium
  is a DaemonSet, so a revert re-rolls the same way the bump did, per the
  existing rollback note already in `cilium.yaml`'s header comment). `make ci`
  must pass. `docs/done/` entry required. Closes #917.
  (auto/cilium-1-18-12-bump)

- [x] 🟢 **DR/capstone-demo results-history log — track pass/fail + elapsed
  time per run over time** (CHARTER **Goals** §"operational-resilience
  discipline" — DORA Pillar 3 concept, testing-results tracking;
  planner-fallback gap analysis 2026-08-11, reached via
  `executor.prompt.md` STEP 6b PLANNER role after all six standing Now/next
  items were re-confirmed gated (the three GitLab→Forgejo migration items
  need live verification; the `verifyImages` Enforce flip / O4 CI gate /
  capstone `Deployment` removal are all gated on unconfirmed
  maintainer-confirmation issues #631/#633, re-checked this run — both still
  open, no new confirmation comment), the architect lane held no un-RFC'd 🟡
  item, and this run's own external chart-currency sweep (Vault, KEDA,
  TiDB Operator, kube-state-metrics, Envoy Gateway all confirmed already at
  latest stable via direct upstream release checks) and a janitor-style
  dead-code/duplication sweep (no orphaned scripts — every `scripts/*.sh` is
  referenced by the Makefile/CI/tests; every script has bats coverage) both
  came up clean. **No prerequisites — executor may pick up immediately.**)

  Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`'s
  Q13 ("Are test results tracked with remediation deadlines?") answers
  "Pass/fail is enforced by exit codes... but there's no historical log of
  *past* run results over time — only the current pass/fail, not a trend"
  and names the exact gap this item closes: "a results log would let you see
  if the 10-minute RTO is trending up as the lab grows, not just whether it
  passed today." Grepping ROADMAP.md and `docs/` for "results log"/"RTO
  trend" finds nothing already tracking this.

  Add `scripts/lib/dr-results-log.sh` (new shared lib, mirrors the existing
  `budget-check.sh` extraction precedent — same header-comment convention
  crediting why it's shared): one function
  `dr_log_result <script_name> <status> <elapsed_s> <budget_s> <objective_tag>`
  that appends one row to `docs/dr-results-log.md` — creating the file with
  a header (`| Date (UTC) | Script | Status | Elapsed (s) | Budget (s) |
  Objective |`) on first write if it doesn't exist yet. `status` is the
  literal string `PASS` or `FAIL`; the date is `date -u
  +%Y-%m-%dT%H:%M:%SZ`. Wire the call into every DR/capstone script's pass
  AND fail exit path — `scripts/dr-restore.sh` (Objective O3),
  `scripts/dr-bluegreen.sh` (blue/green), `scripts/dr-chaos.sh` (chaos),
  `scripts/capstone-demo.sh` (Objective O6) — so a real invocation (this
  remote session cannot trigger one, ADR-0004) appends exactly one row per
  run, pass or fail; never fabricate a row.

  Update `docs/DR.md` linking to the new log; update
  `docs/dora-audit-readiness.md` Q13's Gap line to note the mechanism now
  exists (pending real data — an empty/near-empty log is truthful, not a
  placeholder). New `tests/dr-results-log.bats` (clusterless, structural):
  the lib file exists and defines `dr_log_result`; each of the four scripts
  sources the lib and calls `dr_log_result` on both its pass and fail paths
  (grep-based assertions, mirroring `tests/hook-scripts-*.bats`'s style); a
  scratch-dir integration test that sources the lib, calls it twice, and
  asserts the file grows by exactly two well-formed rows under a single
  header (recurrence guard: the header must not be re-written on subsequent
  appends). `make ci` must pass. PR body must document the ADR-0004 caveat:
  this remote clusterless session cannot generate a real logged run (no
  cluster), so `docs/dr-results-log.md` ships as an empty table (header
  only) — real rows only accumulate once a maintainer or a live-cluster
  session actually runs one of the four scripts. `docs/done/` entry
  required. (auto/dr-results-log)

- [x] 🟢 **Vault internal telemetry — `sys/metrics` scrape + dashboard depth**
  (CHARTER **Goals** §"operational-resilience discipline" + **Objective O5** "every
  always-on component has a real-metric dashboard"; planner gap analysis 2026-08-11,
  reached via `executor.prompt.md` STEP 6b PLANNER role after all six standing
  Now/next items were re-confirmed gated (the three GitLab→Forgejo migration items
  need live verification; the `verifyImages` Enforce flip / O4 CI gate / capstone
  `Deployment` removal are all gated on unconfirmed maintainer-confirmation issues
  #631/#633, re-checked this run — both still open, no new confirmation comment),
  no open GitHub issue needed grooming, and `docs/roadmap/incoming/` held nothing
  pending. **No prerequisites — executor may pick up immediately.**)
  `docs/dora-audit-readiness.md` Q7's own gap line names this exact hole, left open
  by the earlier `auto/vault-pod-readiness-alert` item (which added a pod-readiness
  alert rule from the already-scraped KSM job, not a Vault-internals scrape): "Vault's
  own internal metrics — seal state, token/lease counts, storage backend health —
  still have no Alloy scrape job at all... A future item could add a full Vault
  telemetry scrape job (`telemetry` stanza + `unauthenticated_metrics_access`) if
  finer-grained Vault metrics are worth the added config surface." Verified directly
  (not assumed, ADR-0004): `gitops/platform/vault.yaml`'s `server.standalone.config`
  HCL block has no top-level `telemetry` stanza and its `listener "tcp"` block has no
  nested `telemetry { unauthenticated_metrics_access = true }` (grepped both strings
  directly — neither appears anywhere in the file); `grafana/dashboards/lab-vault.json`'s
  panels (`Vault Pod Running`, `Vault Memory (MiB)`, `Vault Restarts`, `Vault ArgoCD
  Synced`, plus the shared ESO/secrets-layer panels) are all KSM/cAdvisor-derived
  proxies — none reads a metric Vault itself emits.

  Add to `gitops/platform/vault.yaml`'s `server.standalone.config` HCL: a top-level
  `telemetry { prometheus_retention_time = "24h", disable_hostname = true }` stanza
  (enables Vault's built-in Prometheus-format metrics sink) and
  `unauthenticated_metrics_access = true` nested inside the existing
  `listener "tcp" { ... }` block (Vault's documented mechanism for exposing
  `GET /v1/sys/metrics?format=prometheus` without a token — cheaper than an
  ESO-managed scrape token for a lab whose TLS is already disabled and whose UI is
  already open cluster-internally). Add a `prometheus.scrape "vault"` block to
  `gitops/platform/observability-alloy.yaml` (mirrors the static-target
  `kyverno`/`velero`/`trivy_operator` blocks' shape): target
  `vault.vault.svc.cluster.local:8200`, `metrics_path = "/v1/sys/metrics"`,
  `params = {format = ["prometheus"]}`, `scrape_interval = "30s"`,
  `forward_to = [prometheus.remote_write.mimir.receiver]`. Add
  `gitops/vault/networkpolicy/allow-vault-metrics-from-observability.yaml` (mirrors
  `gitops/velero/networkpolicy/allow-velero-metrics-from-observability.yaml`'s exact
  shape): ingress TCP 8200 from `namespaceSelector: kubernetes.io/metadata.name:
  observability`, `podSelector: app.kubernetes.io/name: alloy`; add it to
  `gitops/vault/networkpolicy/kustomization.yaml`'s `resources:` list.

  Extend `grafana/dashboards/lab-vault.json` with a new row of real-metric panels
  sourced from Vault's own documented telemetry (verify exact metric names against
  HashiCorp's telemetry reference before committing the panel queries, not assumed
  from memory): seal status (`vault_core_unsealed`), active-vs-standby
  (`vault_core_active`), in-flight request count (`vault_core_in_flight_requests`),
  and lease count (`vault_expire_num_leases`) — each panel real Mimir data with
  `X-Scope-OrgID: lab` (ADR-0004: this remote clusterless session cannot confirm
  which of these actually emit a series without a live scrape target; any that don't
  show "No data" naturally, never a fabricated value — state this explicitly in the
  PR body rather than silently dropping a panel that turns out to read nothing). New
  `tests/observability-vault.bats` (`tests/observability.bats` is frozen — new scopes
  go in their own file, same convention `observability-alerting.bats`/
  `observability-loki.bats`/etc. already follow): scrape block `"vault"` exists in
  `observability-alloy.yaml` with the `/v1/sys/metrics` path and
  `unauthenticated_metrics_access = true` is present in `vault.yaml`; the new
  NetworkPolicy allow-rule exists on port 8200 and is wired into the kustomization;
  `lab-vault.json` references at least one of the four new metric names; no
  fabricated data. Update `docs/dependency-tree.md`'s Vault sub-graph noting the new
  scrape target. Update `docs/dora-audit-readiness.md` Q7's Gap paragraph to reflect
  this closing (the escalation non-goal and the CI-scoped-only MTTR caveat both
  remain, unchanged). `make ci` must pass. PR body must document the ADR-0004
  caveat above and the rollback path (revert the `telemetry`/
  `unauthenticated_metrics_access` config, the scrape block, and the NetworkPolicy
  rule; ArgoCD syncs the revert within 30s same as any other `vault.yaml` edit —
  note the StatefulSet also needs a pod restart to drop the removed listener
  stanza, the same operational cost the 2026-08-05 Vault image-tag bump already
  carried). `docs/done/` entry required. (auto/vault-telemetry-scrape)

- [x] 🟢 **Loki / Tempo / Pyroscope operational-health dashboards — O5 gap**
  (CHARTER **Objective O5** "every Application in `gitops/bootstrap/root-app.yaml`'s
  auto-synced set has a matching `grafana/dashboards/lab-<name>.json` with at least
  one panel backed by a real (auto-discovered) data source"; planner gap analysis
  2026-08-11, reached via `executor.prompt.md` STEP 6b PLANNER role, this session's
  6th cycle, after cycles 4 and 5 each independently confirmed the standing
  Now/next lane and CHARTER Objective O2 both fully exhausted/met, per STEP 8's
  "widen the lens" guidance. **No prerequisites — executor may pick up
  immediately.**) Verified directly (not assumed, ADR-0004): `gitops/platform/
  observability-alloy.yaml`'s `prometheus.scrape "lgtmp"` block already scrapes
  `loki.observability.svc.cluster.local:3100`, `tempo.observability.svc.cluster.
  local:3200`, and `pyroscope.observability.svc.cluster.local:4040` with
  `job="loki"`/`job="tempo"`/`job="pyroscope"` labels (same block that already
  feeds `lab-mimir.json` and `lab-grafana.json` for their sibling components) —
  but grepping every `grafana/dashboards/*.json` file for any `loki_`/`tempo_`/
  `pyroscope_`-prefixed Prometheus expression, or any panel selecting
  `deployment=~"loki.*"`/`"tempo.*"`/`"pyroscope.*"`, found zero hits anywhere.
  `lab-logs.json`/`lab-traces.json`/`lab-profiles.json` exist, but they're
  **data-browsing** dashboards (a log-search panel, a TraceQL search + trace
  view, a profile flamegraph) — none has a single pod-running/ArgoCD-sync/
  component-health panel, unlike every sibling LGTMP-stack dashboard (`lab-
  mimir.json`, `lab-alloy.json`, `lab-ksm.json`, `lab-node-exporter.json`,
  `lab-grafana.json`, all of which pair KSM/cAdvisor health panels with
  component-specific metrics). This is the one remaining O5 gap: the scrape
  infrastructure already exists, only the dashboards are missing.

  Real metric names verified directly against each project's own Go source
  (shallow-cloned `grafana/loki`, `grafana/tempo`, `grafana/pyroscope` and
  grepped each `promauto`/`prometheus.New*` metric declaration's `Namespace`
  + `Name` fields — not assumed from memory or community dashboards):
  - **Loki** (`pkg/ingester/metrics.go`, `pkg/distributor/distributor.go`):
    `loki_ingester_memory_chunks` (gauge, total chunks held in memory) and
    `loki_distributor_ingester_appends_total` (counter, ingester append calls —
    rate this for a write-throughput panel).
  - **Tempo** (`modules/distributor/distributor.go`):
    `tempo_distributor_spans_received_total` (counter, labeled `tenant`) and
    `tempo_distributor_bytes_received_total` (counter, labeled `tenant` — rate
    both for ingest-throughput panels).
  - **Pyroscope** (`pkg/distributor/metrics.go`):
    `pyroscope_distributor_profiles_received_total` (counter, labeled
    `tenant`/`scope_name`/`scope_version` — rate for an ingest-throughput panel).
  - All three: the standard Prometheus self-instrumentation gauge
    `up{job="loki"}` / `up{job="tempo"}` / `up{job="pyroscope"}` for a "component
    up" stat panel — mirrors `lab-mimir.json`'s own "Mimir up" panel
    (`max(up{job="mimir"})`) exactly, same scrape block, same pattern.

  Add three new dashboard files (mirror `lab-mimir.json`'s exact panel shape —
  stat row: up / a gauge metric / a throughput metric; a timeseries row for
  the throughput metric over time; `uid`/`tags`/`refresh`/`time` fields
  identical to `lab-mimir.json`'s): `grafana/dashboards/lab-loki.json` ("Lab —
  Loki"), `grafana/dashboards/lab-tempo.json` ("Lab — Tempo"),
  `grafana/dashboards/lab-pyroscope.json` ("Lab — Pyroscope"). These are
  **additive**, distinct from the existing `lab-logs.json`/`lab-traces.json`/
  `lab-profiles.json` data-browsing dashboards — do not merge or remove those,
  they serve a different purpose (exploring the log/trace/profile data itself,
  not monitoring the store's own health). All panels real Mimir data with
  `X-Scope-OrgID: lab` (ADR-0004 caveat: this remote clusterless session cannot
  confirm live which metrics actually emit a series without a real scrape
  target — any that don't will show "No data" naturally, never a fabricated
  value; state this explicitly in the PR body).

  Extend the existing per-component bats files (do **not** create new
  `tests/observability-<scope>.bats` files — `tests/observability-loki.bats`,
  `tests/observability-tempo.bats`, and `tests/observability-pyroscope.bats`
  already exist, currently covering only each component's image-tag pin; add
  assertions there instead, matching this repo's "extend the existing per-scope
  file" convention): each new dashboard is valid JSON, references its real
  metric name(s), and has no fabricated/placeholder data. Update
  `docs/dependency-tree.md`'s observability sub-section noting the three new
  dashboards (no scrape-job change needed — the `lgtmp` block already covers
  all three). `make ci` must pass. PR body must document the ADR-0004 caveat
  above and the rollback path (delete the three new dashboard files; Grafana's
  native Git Sync — ADR-0006 — picks up the removal on its next sync, no other
  component affected since nothing else reads these files). `docs/done/` entry
  required. (auto/lgtmp-health-dashboards)

- [x] 🟢 **Stateless-surface criticality tiering — closes DORA audit Q2's named gap**
  (CHARTER **Core Values** §"Everything as code" / operational-resilience discipline;
  planner-fallback gap analysis 2026-08-12, reached via `executor.prompt.md` STEP 6b
  PLANNER role after this run's Now/next lane was found fully gated — all six
  remaining items are either an explicit live-cluster-only flip (`auto/
  forgejo-argocd-repo-secret`'s successor) or gated on the still-unconfirmed standing
  `[Action required]` issues #631/#633 (re-checked this cycle: both still open, most
  recent comments 2026-08-11, neither confirms the gate). A currency sweep this same
  cycle (ArgoCD, Trivy Operator, Grafana, Loki/Tempo/Pyroscope, Kargo, RabbitMQ,
  Cilium, cert-manager, Velero, KEDA all checked directly against upstream tags —
  Longhorn deliberately held at `1.11.3` per ADR-0013's own binding flip condition,
  re-confirmed unfired) found nothing stale enough to bump. **No prerequisites —
  executor may pick up immediately.**) Verified directly (not assumed, ADR-0004):
  `docs/dora-audit-readiness.md` Q2 ("Are critical functions/assets identified and
  mapped to supporting ICT systems?") answers yes for the *stateful* surface only —
  CHARTER Objective O3 names the six stateful namespaces (`data`, `tidb`, `capstone`,
  `vault`, `observability`, `inkless`) as critical — and its own "Gap" line states
  plainly: "no equivalent criticality tiering for the *stateless* surface (e.g., is
  Envoy Gateway more critical than Kiali? Implicit from always-on/on-demand split,
  never stated as a tier)." `docs/incident-log.md` already has a binding P0–P3
  severity scheme (whole-lab-down/data-loss; single always-on component down/
  security gap; on-demand component broken; cosmetic) used for every real incident
  logged there — grepped directly, confirmed no existing doc maps each *component*
  to which tier its own outage would trigger, only individual past incidents.

  Add a new "Stateless component criticality tiers" section to
  `docs/dora-audit-readiness.md` directly under Q2 (or a new `docs/criticality-
  tiers.md` if the table grows unwieldy inline — executor's call, cite whichever in
  Q2's Evidence line), reusing `docs/incident-log.md`'s existing P0–P3 scheme rather
  than inventing a new one (avoids two competing severity taxonomies). One row per
  always-on stateless component from CHARTER's "Target end-state" section (Envoy
  Gateway, Cilium, ArgoCD, Vault, External Secrets, GitLab, Garage, the LGTMP stack
  components individually — Alloy/Grafana/Mimir/Loki/Tempo/Pyroscope/KSM/
  node-exporter, moto/ACK/KRO, RabbitMQ, Valkey, Kyverno, Argo Rollouts, Velero,
  Trivy Operator, cert-manager, KEDA — cross-reference `docs/dependency-tree.md` for
  the authoritative list, don't hand-enumerate from memory) plus a one-line
  justification per row grounded in what the component's outage actually breaks
  (e.g. Cilium → P0, cites the real 2026-07-29 `docs/incident-log.md` entry where a
  Cilium apiserver-connectivity loss was cluster-wide; Vault/External Secrets → P0,
  cites the real repeated "ExternalSecrets break cluster-wide" incidents already in
  that same log; Kiali/on-demand components are explicitly out of scope for this
  table — they're already covered by O3's on-demand P2 tier, this item is additive
  for the always-on set only). Update Q2's "Gap" line to point at the new
  section/file instead of stating the gap as open. New `tests/dora-audit-
  readiness.bats` (verified directly: no file by this name exists yet — only the
  unrelated `tests/dora-metrics.bats`, which covers CHARTER O7's `make dora-metrics`
  delivery-metrics feature, a different doc — do not append there) asserting the new
  section/file exists and names at minimum Envoy Gateway, Cilium,
  ArgoCD, and Vault (the four components with a real documented P0 incident already
  in `docs/incident-log.md`, so this is a recurrence guard against the tiering
  silently omitting a component that has already caused a real outage). `make ci`
  must pass. `docs/done/` entry required. PR body must document which components got
  which tier and why, per-row, not just assert the table exists (ADR-0004 — a table
  of unjustified tier labels would itself be a form of fabricated/unverified
  content). (auto/stateless-criticality-tiers)

- [x] 🟢 **Third-party dependency concentration-risk rollup — closes DORA audit Q16's
  named gap** (CHARTER **Core Values** §"Everything as code; GitOps deploys it" /
  operational-resilience discipline; planner-fallback gap analysis 2026-08-12, reached
  via `executor.prompt.md` STEP 6b PLANNER role after this run's Now/next lane was
  re-confirmed fully gated — the same six standing items (three sequential Forgejo-
  migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631;
  capstone `Deployment` removal on unconfirmed issue #633, both re-checked this cycle,
  most recent comment 2026-08-11 on each, neither confirms the gate) — and this
  cycle's own sweep found no groomable intake (the only two open issues are those same
  standing `[Action required]` trackers), no un-RFC'd 🟡 item anywhere in ROADMAP.md
  (zero `- [ ] 🟡` lines), and no `docs/roadmap/incoming/` file to absorb. **No
  prerequisites — executor may pick up immediately.**) Verified directly (not assumed,
  ADR-0004): `docs/dora-audit-readiness.md` Q16 ("Is concentration risk assessed —
  reliance on a single upstream provider?") answers that concentration is "assessed
  per-decision... but never rolled up into a single cross-cutting view of *which*
  single upstream repo, registry, or chart source, if it disappeared, would break the
  most components at once," and its own Gap line calls this "real; a genuinely new
  artifact, not just re-indexing" (distinct from Q14's `docs/dependency-register.md`,
  which the register's own header explicitly scopes as pure re-indexing with "no new
  dependency-risk judgment"). Grepping `docs/` for "concentration" turns up only this
  Q16 answer itself — nothing already tracks this.

  Add `docs/dependency-concentration.md`: group every row of
  `docs/dependency-register.md`'s 32-tool table by **upstream GitHub org** (the
  register's own "Upstream source" column — reuse those exact org strings, don't
  re-derive from memory) and surface any org backing more than one tool as a
  concentration point, one short paragraph each, worst-first. Verify the count
  directly against the live register table before writing it (the table has grown
  since Q14 first answered "24 ADRs" — re-count from the file, don't reuse a stale
  number). At minimum, `github.com/grafana` backs six always-on-core rows at once
  (Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy) — the entire observability pane
  shares one upstream governance/maintenance entity, the largest single concentration
  in the table; `github.com/argoproj` backs two (ArgoCD, Argo Rollouts); `github.com/
  pingcap` backs two (TiDB Operator, TiDB, both heavy-on-demand only, so lower blast
  radius than the always-on Grafana-org cluster). Every other row is a distinct org —
  state that plainly rather than padding the doc with single-tool "groups." Close by
  naming the lab's actual mitigation, already true today per ADR-0001's own design
  (don't invent a new one): every workload is a GitOps `Application` pointing at a
  pinned chart/image ref, so a disappeared upstream is a fork-the-source-and-repoint
  operation, not a rebuild — cite the real, already-executed ADR-0011→ADR-0024
  Artifactory→Harbor migration as the existence proof (same precedent Q17 already
  cites). Update Q16's "Gap" line in `docs/dora-audit-readiness.md` to point at the
  new file instead of stating the gap as open, and add the file to the "Evidence" line
  of both Q16 and Q14 (Q14's own "Keeping this in sync" section should note this new
  file is a downstream consumer of its table, so a future register edit that removes
  or renames a row should prompt a look here too). New assertions in a `dora-audit-
  readiness.bats`-style file (extend the existing one if `auto/stateless-criticality-
  tiers` already created `tests/dora-audit-readiness.bats` — check first, don't create
  a second file for the same doc, matching this section's own `tests/observability.bats`
  frozen-file precedent) asserting the new file exists and names at minimum
  `github.com/grafana` with a count. `make ci` must pass. `docs/done/` entry required.
  PR body must state the actual computed per-org counts, not just assert the file
  exists (ADR-0004 — an unverified rollup would itself be a form of fabricated
  content). (auto/dependency-concentration-rollup)

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
>
> **Two upgrade-drafter major-bump findings parked 2026-07-24** (issues #704, #705)
> — both need an architect go/no-go call, not a mechanical bump, per
> `routines/upgrade-drafter.prompt.md`'s "skip major bumps, open an issue" rule.

- ~~🟡 **`argo-cd` Helm chart major bump — `9.7.1` → `10.x`**~~ (issue #781; RFC #785 —
  architect decision 2026-07-28: **Approve**, chart `10.2.1`, with a required
  `global.networkPolicy.create: false` companion override.) **Groomed ↗** into a 🟢
  item in *Now / next* above (`auto/argocd-chart-10x-bump`), planner run 2026-07-28.

- [x] 🟢 **`kube-state-metrics` chart major bump — `7.8.1` → `8.0.0`** (issue #704;
  RFC #707 — architect decision 2026-07-24: **Approve.** appVersion unchanged at
  `2.19.1` — chart-packaging-only major bump, the entire breaking surface is the
  chart dropping its own bundled `CiliumNetworkPolicy` template +
  `networkPolicy.flavor: cilium` values key, which
  `gitops/platform/observability-ksm.yaml` never sets (verified directly: a `git
  diff` between the `kube-state-metrics-7.8.1` and `kube-state-metrics-8.0.0`
  chart tags touches only `Chart.yaml`, `README.md`, the removed
  `ciliumnetworkpolicy.yaml` template, and a combined 14-line
  `networkpolicy.yaml`/`values.yaml` trim — nothing this Application's
  `valuesObject` references). **No prerequisites — executor may pick up
  immediately.** Bump `targetRevision: 7.8.1` → `8.0.0` in
  `gitops/platform/observability-ksm.yaml`. Re-verify the chart's `values.yaml`
  still matches this Application's `valuesObject` at pickup time before merging
  (don't just trust this RFC's cached read — same due-diligence pattern as the
  `auto/pyroscope-*`/`auto/grafana-chart-*` bumps). `make ci` must pass.
  `docs/done/` entry required. Closes #707. (auto/ksm-chart-8-0-0 or
  upgrade/ksm-chart-8-0-0)

- ~~🟡 **`apache/kafka` client image major bump — `3.9.2` → `4.3.1`**~~ (issue
  #705; RFC #708 — architect decision 2026-07-24: **Hold.** `gitops/inkless/
  kafka-load.yaml`'s producer/consumer CLI containers stay pinned to
  `apache/kafka:3.9.2` — Kafka 4.x is a real behavioral major version (drops
  ZooKeeper mode, changes client/protocol-negotiation defaults) and this remote
  clusterless session cannot verify Inkless's Kafka-protocol compatibility with a
  4.x client (mirrors ADR-0013's Longhorn `1.12.0` hold). Resolved directly —
  no executor fan-out needed. Decision + flip condition recorded in
  [ADR-0015](docs/decisions/adr-0015-inkless-diskless-kafka.md)'s new
  `## Re-evaluation log` section. Closed via RFC #708.

- ~~🟡 **GitHub Actions major-version bumps — `actions/checkout` v4→v7,
  `actions/cache` v4→v6, `actions/github-script` v7→v9,
  `hashicorp/setup-terraform` v3→v4**~~ (RFC #611) **Groomed ↗** into a 🟢 item
  in *Now / next* above (`auto/github-actions-node24-bump`), planner run
  2026-07-20. Decision: bump to v7.0.0/v6.1.0/v9.0.0/v4.0.1 — GitHub-hosted
  `ubuntu-latest` runners already cache Node.js 24 today, confirmed directly
  against `actions/runner-images`' `Ubuntu2404-Readme.md`.

- ~~🟡 **DORA-metrics compliance for k8s-lab**~~ (RFC #580) **Groomed ↗** into a 🟢
  item in *Now / next* above (`auto/dora-metrics`), planner run 2026-07-19. Decision:
  all four metrics re-grounded in git/CI history (never live-cluster state); a new
  `scripts/dora-metrics.sh` + `make dora-metrics` on-demand target (not a new
  scheduled routine); new CHARTER Objective O7.

- ~~🟡 **DORA = Digital Operational Resilience Act alignment for k8s-lab**~~ (RFC
  #586) **Groomed ↗** into a 🟢 item in *Now / next* above (`auto/dora-resilience-
  mapping`), planner run 2026-07-19. Decision: no compliance claim (this lab isn't
  an EU-regulated financial entity); a new `docs/dora-resilience-mapping.md` maps
  four of DORA's five pillars onto real, already-existing lab mechanisms, with
  Pillar 5 (information-sharing) explicitly marked out of scope. CHARTER Goals
  sentence already landed in the RFC's own architect PR (#587).

- ~~🟡 **PSS-restricted hardening — `argocd` namespace**~~ (RFC #205)
  **Groomed ↗** into two 🟢 Phase items in *Now / next* above
  (`auto/argocd-pss-warn-audit` + `auto/argocd-pss-enforce`),
  planner run 2026-06-15.

- ~~🟡 **NetworkPolicy fan-out — `envoy-gateway-system` namespace**~~
  (RFC #206) **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/envoy-gateway-system-networkpolicy`), planner run 2026-06-15.

- ~~🟡 **`vault` PSA `baseline` → `restricted` flip**~~ (RFC #478)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/vault-psa-restricted`), planner run 2026-07-17.

- ~~🟡 **Cilium Grafana dashboard**~~ (RFC #358) **Groomed ↗** into a 🟢 item
  in *Now / next* above (`auto/cilium-agent-metrics`), planner run 2026-07-12.
  Decision: `prometheus.enabled: true` at port 9962 (Hubble stays disabled);
  Alloy pod-discovery + relabel; `lab-cilium.json` with five real Mimir panels.

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

- ~~🟡 **`kyverno` PSA `baseline` → `restricted` flip**~~ (RFC #483)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/kyverno-psa-restricted`), planner run 2026-07-17.

- ~~🟡 **Platform Governance layer — `gitops/governance/` structure**~~ (RFC #293)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/platform-governance-appset`), planner run 2026-06-30.

- ~~🟡 **Namespace Resource Profiles — standardized ResourceQuota tiers**~~ (RFC #294)
  **Groomed ↗** into a 🟢 item in *Now / next* above
  (`auto/namespace-resource-profiles`), planner run 2026-06-30.

- ~~🟡 **First cloud backend — pick a provider + implement `infra/live/<backend>/`**~~
  (RFC #377 — see [ADR-0027](docs/decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md):
  Oracle Cloud Always Free (Ampere A1 ARM) + self-managed k3s, chosen over AKS/GKE
  Autopilot because it's the only option where both control plane and compute are
  free indefinitely, not on a trial/credit mechanism — see the ADR for the full
  comparison.) **Groomed ↗** into the five 🟢 items below, per RFC #377's
  Acceptance criteria. Items 2–5 depend on item 1 merging first (module must exist
  before it can be wired in / tested).

- [x] 🟢 **`infra/modules/oracle-k3s-cluster` Terraform module** (RFC #377 item 1 —
  ADR-0027 is the binding spec). OCI Terraform provider setup; an Ampere A1
  compute instance resource sized to the Always Free shape (2 OCPU / 12 GB per
  ADR-0027 — use `required` variables for compartment/tenancy/availability-domain,
  no live-account defaults, so `terraform validate`/`fmt` pass in clusterless
  `make ci` without real OCI credentials); cloud-init installing k3s
  (`curl -sfL https://get.k3s.io | sh -`); a `local-exec` provisioner that `scp`s
  `/etc/rancher/k3s/k3s.yaml` off the instance and merges it into `~/.kube/config`
  under a distinct context name (must not collide with `k3d-k8s-lab` — see
  ADR-0027 §"Contract compliance"). Outputs: `cluster_name`, `kube_context`,
  `api_endpoint`, matching `infra/live/README.md`'s contract exactly (same names
  as `k3d-cluster`'s outputs). `make ci` (terraform fmt/validate) must pass.
  (auto/oracle-k3s-cluster-module)

- [x] 🟢 **`infra/live/oracle/{cluster,argocd,gitlab}/terragrunt.hcl`** (RFC #377
  item 2 — depends on the module above merging first). New `oracle/` backend
  directory mirroring `local/`'s three-unit structure: `cluster/` points
  `source` at `infra/modules/oracle-k3s-cluster`; `argocd/` and `gitlab/` are
  copied from `local/`'s units **unchanged** (per the contract, only the
  `cluster` unit differs per backend) — same `dependency "cluster"` block, same
  generated provider blocks. New `root.hcl` for the `oracle/` backend if its
  Terraform-state backend (item 3) needs different backend-block config than
  `local/`'s. (auto/oracle-live-units)

- [x] 🟢 **Second off-cluster Garage state store for the `oracle` backend, on a
  separate Always Free AMD Micro instance** (RFC #377 item 3 — corrected in
  ADR-0027 2026-07-13: the state backend cannot live on the same VM the
  `oracle-k3s-cluster` module creates, since that Terraform apply needs the
  state backend to already exist — same causal-ordering constraint
  [ADR-0007](docs/decisions/adr-0007-off-cluster-garage-tfstate-backend.md)
  already solved for `local/`. Uses the *separate* Always Free AMD Micro
  allocation, 1/8 OCPU / 1 GB — distinct quota from the Ampere A1 shape the
  k3s cluster uses). `infra/tfstate-oracle/` (garage.toml template, no
  hardcoded secrets — unlike `infra/tfstate/garage.toml`'s throwaway
  localhost-only secrets, this instance has a public IP) + a bootstrap
  script using the OCI CLI (not Terraform — matching ADR-0007's precedent
  that the state backend is imperative, never managed by the Terraform it
  backs) to launch the Micro instance via cloud-init, generating the Garage
  RPC secret + admin token at launch time and never committing them + a
  `make tfstate-oracle-up` target, matching the existing `tfstate-up` shape.
  (auto/oracle-tfstate)

- [x] 🟢 **`tests/oracle-cluster.bats`** (RFC #377 item 4 — depends on items 1–2).
  Module shape assertions (required variables present, no hardcoded
  credentials/secrets anywhere in `infra/modules/oracle-k3s-cluster` or
  `infra/live/oracle/`), output names match the `k3d-cluster` contract exactly,
  `argocd`/`gitlab` units under `oracle/` are byte-identical to `local/`'s
  (mechanical drift guard — mirrors the repo's existing drift-detector pattern).
  (auto/oracle-cluster-bats)

- [x] ~~🟡~~ **Author retroactive ADR(s) for GitLab and the LGTMP observability-stack
  internals** (RFC #1073 — architect decision 2026-08-07: two ADRs, GitLab standalone
  + one combined LGTMP ADR, both authored in the RFC's own PR; see
  `docs/decisions/adr-0033-gitlab-git-source-and-ci.md` and
  `docs/decisions/adr-0034-lgtmp-observability-stack.md`. **Resolved 2026-08-07** — the
  follow-up `docs/dependency-register.md` rows this item's own body called out also
  landed the same day (`auto/dependency-register-adr-0033-0034-rows`, #1076), so every
  part of this item is now built, not just RFC'd. Planner pass 2026-08-07 checked this
  off directly (STEP 3's "prune items already done") rather than leaving a
  fully-resolved item permanently unchecked.)
  (CHARTER **Core Values** §"Decisions written down, rejected options
  off-limits" — "every meaningful technical choice lands as an ADR"; planner
  gap-analysis 2026-08-07, reached via `executor.prompt.md` STEP 6b after
  Now/next's three standing items were re-checked and found still gated
  (unchanged) on unconfirmed maintainer-confirmation issues #631/#633, plus a
  fresh #1034 (disk-pressure precondition on retrying either) — and this run's
  own sweep found no un-RFC'd 🟡 item and no other green-able item anywhere in
  the backlog to promote into *Now / next* (every other item in this file is
  already `[x]`). At the time this item was written it needed an architect RFC
  before the executor could build it — RFC #1073 (below) resolved that the same
  day this item was filed.) `docs/dependency-register.md`'s
  own "Real gap, distinct from the policy-ADR exclusions above" paragraph
  already names this directly: **GitLab** (the git source of truth + CI runner,
  referenced by name across many ADRs — e.g. ADR-0001's GitOps framing — but
  never itself the *subject* of one) and the observability pipeline's internals
  — **Mimir, Loki, Tempo, Pyroscope, Alloy, kube-state-metrics, and
  node-exporter** — have no dedicated ADR; only Grafana, the pane-of-glass on
  top of them, has one (ADR-0006). Verified directly (not assumed, ADR-0004):
  grepped `docs/decisions/*.md` (all 32 existing ADRs, ADR-0001–ADR-0032) for
  each of these eight names — none is the subject of its own ADR file, and the
  register's table construction rule (every row cites the ADR that decided it)
  means they structurally cannot appear in it until one exists.

  The register's own text already flags closing this as "architect-scoped work
  (deciding whether each warrants its own retroactive ADR, or a combined one for
  the LGTMP stack), not a mechanical doc-sync fix" — this item exists so that
  observation has a place to be picked up rather than sitting as an unlinked
  prose note nobody actions. **RFC scope for the architect:** decide (a)
  whether GitLab gets its own ADR or is folded into an existing one (e.g.
  ADR-0001's GitOps-source-of-truth framing) as a documented extension; (b)
  whether the seven observability-internals tools get one combined "LGTMP
  stack" ADR — mirroring ADR-0012's existing precedent of one ADR deciding two
  related tools (Istio + Kiali) — or per-tool ADRs; (c) for each, whether the
  retroactive ADR's Decision is simply "ratify the tool already running" (the
  likely outcome, since all eight are already deployed and battle-tested in
  this lab) or whether re-litigating the choice surfaces a real alternative
  worth naming for the record. Acceptance criteria for the resulting RFC(s):
  the new ADR file(s) land under `docs/decisions/`; `docs/dependency-register.md`
  gains a row per newly-ADR'd tool (closing its own "cannot appear in this
  table" gap) in the same or a prompt follow-up executor PR; and the register's
  "Real gap" paragraph is edited to say the gap is closed (or narrowed, if the
  architect scopes it down) rather than silently deleted. (This acceptance
  criteria described what the RFC needed to deliver at the time this item was
  written; RFC #1073 delivered all of it the same day, per the "Resolved
  2026-08-07" note above.)

- [x] 🟢 **`infra/live/README.md` + `docs/dependency-tree.md` — document the
  `oracle/` backend** (RFC #377 item 5 — depends on items 1–2 existing). Added an
  `oracle/` row to `infra/live/README.md`'s "Status" section, explicitly marked
  "unverified against a real account" (per ADR-0004 — reviewed code isn't the
  same as exercised code). Skipped `docs/dependency-tree.md`: that doc reflects
  the *actual running* localhost lab's integration/bootstrap graph — the `oracle`
  backend has never been deployed, so adding it there would misrepresent
  never-run code as live system state.

- ~~🟡 **Grafana/Mimir alerting rules for known failure conditions**~~ (RFC #1084 —
  architect decision 2026-08-10: **Grafana Unified Alerting** querying Mimir, not
  Mimir's own ruler; file-based provisioning; visual-only, no external notification
  receiver; four starting rules on already-scraped metrics.) **Groomed ↗** into a 🟢
  item in *Now / next* above (`auto/grafana-alerting-rules`), planner run 2026-08-10.

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
