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

    **Never close a standing `[Action required]` issue except via the real
    confirmation it names — not as a side effect of merging a PR that only shrinks the
    gap toward it.** Found live 2026-09-04: a cycle merged PR #1403 (the RBAC half of
    issue #1229's ask) and, in the same breath as posting a comment that itself said
    "Still open per the `[Action required]` convention," made a direct API call
    closing the issue anyway — no `Closes #1229`/`Fixes #1229` keyword anywhere in the
    PR, so this wasn't GitHub's own auto-close; it was the executor's own mistake,
    caught and reopened the same day. `[Action required]` issues have no code-level
    guard against this (unlike a bats assertion, a wrong `issue_write` call can't be
    caught by `make ci`) — the mechanical discipline is procedural: after any cycle
    that touches a gated item's issue, re-read the issue's own state before ending the
    turn, and never call `issue_write`/`gh issue close` on one except when the
    confirmation comment it's actually waiting for has just been posted (by a human,
    or by a live-cluster session that performed the real check).

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
> **Status (updated 2026-08-18): O1, O2, and now O4 are all substantially done.**
> All four Tier 1 next-wave components (Kyverno, Argo Rollouts, Velero, Trivy
> Operator) are long since auto-synced with their own ADR, dashboard, and bats
> coverage — CHARTER.md records O1 as met ahead of its 2026-12-31 date. The O2
> tail this section used to track (PSS-restricted for `moto`/`ack-system`/
> `lab-gateway`, NP for `tidb`/`tidb-admin`, both coverage-loop recurrence
> guards) is fully checked off below; O2's own `argocd` PSS and
> `envoy-gateway-system` NP gaps closed earlier still. The cloud-control-plane
> dashboard (O5) shipped too (`lab-cloud-control-plane.json`, covering
> kro+moto+ack-s3). **Objective O4** (due 2026-12-31, "every image is signed
> and verified") landed both of its measurement criteria 2026-08-18: the
> `verifyImages` ClusterPolicy flipped Audit → Enforce (`auto/cosign-enforce-flip`,
> PR #1223, gated on issue #631's maintainer confirmation — a real signed image
> observed landing in Harbor) and the CI step that proves an *unsigned* image
> gets rejected (`auto/o4-ci-rejection-gate`, PR #1224) both merged. Both still
> carry an ADR-0004 caveat this remote clusterless session cannot resolve: a
> live Forgejo Actions run has not yet executed either job end-to-end (the
> rejection-gate job also needs a `KUBECONFIG` secret the maintainer hasn't set
> up yet, tracked as a standing `[Action required]` issue, #1229) — a
> live-cluster/interactive session verifying that closes the loop, but no
> further executor-buildable work remains for O4 itself.
>
> The remaining unchecked items in this section are now the two sequentially-
> blocked GitLab→Forgejo migration items (script/Makefile rename, full
> decommission — both deliberately deferred pending live verification per their
> own investigation notes) and the legacy capstone `Deployment` removal, gated
> on issue #633 (still unconfirmed as of this update). When every item here is
> gated, use rule #9's split-the-gate judgment before falling back to
> coverage/hardening filler — don't assume there's nothing left just because
> the checkboxes are gated.
>
> **WIP / size discipline reminder.** Per WAYS-OF-WORKING.md §3, target ≤ 400
> changed lines per PR. Items below that risk crossing the cap carry a
> "split if oversized" executor note matching the RFC's own split guidance.
>
> _Per-run planner narrative (what was groomed/filed/unblocked each run) lives in
> [`docs/backlog/`](docs/backlog/), one dated file per run — never inline here (see
> the **Conflict-free editing** binding rule above). History through 2026-06-20:
> [`docs/backlog/2026-06-20-planner-note-migration.md`](docs/backlog/2026-06-20-planner-note-migration.md)._
>
> **Investigation-note discipline (added 2026-08-25, JANITOR-fallback cleanup).**
> When picking up an item and finding it still blocked, write the full
> investigation (what was checked, what was found, the recommendation) to
> [`docs/roadmap/investigations/`](docs/roadmap/investigations/)
> (`YYYY-MM-DD-<slug>.md`, one file per investigation) instead of appending it
> inline here. Keep only a short "Investigated YYYY-MM-DD — <one-line reason
> still blocked>, full findings: <link>" pointer in the item body. A completed
> item's writeup is already mirrored verbatim into `docs/done/` (rule #7 below),
> so trimming its ROADMAP.md copy loses nothing there — but a *blocked* item's
> investigation prose had no such mirror anywhere, so every re-investigation
> across every cycle kept accreting new paragraphs onto the same item with
> nothing ever pruned. This is a real contributor to ROADMAP.md's size (>500 KB,
> 2026-08-25) exceeding what standard tooling can load in a single pass — same
> fix pattern this repo already applies elsewhere (`## Done` → `docs/done/`,
> per-run narrative → `docs/backlog/`, an oversized bats file →
> `tests/<scope>-<name>.bats`). Applied retroactively to the one item that had
> already grown a multi-paragraph inline investigation
> (the GitLab→Forgejo rename item below); the ~180 already-completed `[x]`
> items' own inline writeups are a separate, larger cleanup (each needs
> verifying against its `docs/done/` mirror before trimming) intentionally left
> for a future bounded cycle, not attempted in this one. **Pilot batch done
> 2026-09-04** (see the ROADMAP items immediately below) — trimmed 4 RFC #377
> Oracle items, then 4 more (batch 2), then 5 more (batch 3), then 5 more
> (batch 4), then 5 more (batch 5), then 3 more (batch 6); ~154 legacy
> items remain for future bounded cycles to continue against.

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 6** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md).
  (auto/roadmap-legacy-item-trim-batch6)
  (CHARTER **Core Values** §"Everything as code" (tooling stays usable at
  scale); JANITOR-fallback cleanup 2026-09-04, this run's fifth cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated (issues #633 and #1229 both re-checked, no new
  confirmation comment on either since cycle 2) and PLANNER/TRIAGER
  re-confirmed empty (zero new/ungroomed issues; no new open PRs).
  Continues the legacy-item-trim JANITOR fallback from batch 5. **No
  prerequisites — executor may pick up immediately.**)
  Trimmed 3 more legacy items (a smaller batch — the easy-to-verify
  candidate lens is thinning), each verified against its real
  `docs/done/` mirror before touching the ROADMAP text; deliberately left
  2 other candidates untouched (one has no `docs/done/` mirror to point
  to at all, the other is a planner resolution note spanning multiple
  PRs/ADRs, not a single-mirror executor spec — see the `docs/done/`
  writeup for the full reasoning). No information lost, 45 lines saved.
  `ROADMAP.md` 6944→6899 lines. `make ci` must pass. `docs/done/` entry
  required.

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 5** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md).
  (auto/roadmap-legacy-item-trim-batch5)
  (CHARTER **Core Values** §"Everything as code" (tooling stays usable at
  scale); JANITOR-fallback cleanup 2026-09-04, this run's fourth cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated (unchanged since cycle 2/3 — issues #633 and
  #1229 both re-checked, no new confirmation) and PLANNER/TRIAGER
  re-confirmed empty (zero new/ungroomed issues; no new open PRs).
  Continues the legacy-item-trim JANITOR fallback from batch 4.
  **No prerequisites — executor may pick up immediately.**)
  Trimmed 5 more legacy items — the cloud-control-plane dashboard,
  PSS/NetworkPolicy fan-out, and cosign CI-signing sequence — each
  verified against its real `docs/done/` mirror before touching the
  ROADMAP text; added a proper `## PR` section (with the real merged-PR
  link, found via GitHub search) to 4 of those 5 mirrors that had none.
  No information lost, 111 lines saved. `ROADMAP.md` 7055→6944 lines.
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 4** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md).
  (auto/roadmap-legacy-item-trim-batch4)
  (CHARTER **Core Values** §"Everything as code" (tooling stays usable at
  scale); JANITOR-fallback cleanup 2026-09-04, this run's third cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated (unchanged since cycle 2 — issues #633 and
  #1229 both re-checked, no new confirmation) and PLANNER/TRIAGER
  re-confirmed empty (zero new/ungroomed issues; `make ci` zero drift).
  Continues the legacy-item-trim JANITOR fallback from batch 3.
  **No prerequisites — executor may pick up immediately.**)
  Trimmed 5 more legacy items — the Kyverno + cosign + Trivy Operator +
  ADR-0017 sequence — each verified against its real `docs/done/` mirror
  before touching the ROADMAP text; backfilled 4 of those 5 mirrors' own
  missing/placeholder `## PR` sections with the real merged-PR link first
  (#170, #177, #178, #183 — one still carried a literal `PR #TBD`). No
  information lost, 153 lines saved. `ROADMAP.md` 7187→7034 lines.
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 3** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md).
  (auto/roadmap-legacy-item-trim-batch3)
  (CHARTER **Core Values** §"Everything as code" (tooling stays usable at
  scale); JANITOR-fallback cleanup 2026-09-04, this run's second cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  found fully gated (all three unchecked items re-confirmed still blocked —
  issues #633 and #1229 both re-checked, neither has a new confirmation
  comment) and PLANNER (zero ungroomed intake, zero un-RFC'd 🟡 items, zero
  `docs/roadmap/incoming/` files)/ARCHITECT (zero open `adr-audit` issues,
  no 🟡 items to RFC)/DOC-DRIFT-AUTHOR (`make ci` had zero drift warnings)
  all came up empty. TRIAGER found and labeled one genuinely untriaged issue
  (#1385, missing domain/readiness/priority) as this run's first cycle —
  a real, complete labels-only deliverable in its own right, not a PR. This
  cycle continues the legacy-item-trim JANITOR fallback from batch 2.
  **No prerequisites — executor may pick up immediately.**)
  Trimmed 5 more legacy items, each verified against its real `docs/done/`
  mirror before touching the ROADMAP text — no information lost, 156 lines
  saved. Also fixed each mirror's own placeholder PR link
  (`(see GitHub)`/`(autonomous scheduled run — executor routine)`) with the
  real merged-PR URL found via GitHub search, verifying `merged: true`
  since two of the five components had an earlier closed-unmerged attempt
  under the same title. `ROADMAP.md` 7297→7141 lines. `make ci` must pass.
  `docs/done/` entry required.

- [x] 🟢 **docs/done/ PR-link integrity fix — 80 files + mechanical guard
  hardened** — full verification writeup:
  [docs/done/2026-09-04-docs-done-pr-link-integrity-fix.md](docs/done/2026-09-04-docs-done-pr-link-integrity-fix.md).
  (auto/docs-done-pr-link-integrity-fix)
  (CHARTER "Everything as code; GitOps deploys it" + the repo's own docs/done/
  convention; JANITOR-fallback finding 2026-09-04, this run's thirtieth cycle,
  surfaced while verifying trimmed ROADMAP items' `docs/done/` mirrors during
  the batch-2 trim below. **No prerequisites — executor may pick up
  immediately.**)
  `scripts/docs-done-pr-link-check.sh`'s existing placeholder-wording
  allowlist missed dozens of other unresolved `## PR` shapes (bare branch
  names, unnamed-PR prose, un-substituted `PR #NNN`/`pull/TBD` templates).
  Backfilled all 80 with real, GitHub-API-verified PR links found via
  `git log --diff-filter=A` + last-`#NNN`-in-subject extraction. Hardened the
  guard with a second, broader pass: any file with a `## PR` heading must now
  contain a real `github.com/.../pull/NNN` URL or bare `#NNN` — not an
  allowlist of known-bad wordings. 3 new bats fixtures/cases cover the new
  logic (bare-branch-name failure, no-heading skip, README.md exclusion).
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 2** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md).
  (auto/roadmap-legacy-item-trim-batch2)
  (CHARTER **Core Values** §"Everything as code" (tooling stays usable at
  scale); JANITOR-fallback cleanup 2026-09-04, this run's twenty-ninth cycle,
  continuing the pilot batch from the previous cycle. **No prerequisites —
  executor may pick up immediately.**)
  Trimmed 4 more legacy items, each verified against its real `docs/done/`
  mirror before touching the ROADMAP text — no information lost, 54 lines
  saved. `ROADMAP.md` 7351→7297 lines. `make ci` must pass. `docs/done/`
  entry required.

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — pilot batch (RFC #377 Oracle
  items)** — full verification writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md).
  (auto/roadmap-legacy-item-trim-pilot)
  (CHARTER **Core Values** §"Everything as code" (tooling stays usable at
  scale); JANITOR-fallback pilot cleanup 2026-09-04, this run's twenty-eighth
  cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next" lane
  was re-confirmed fully gated and PLANNER/ARCHITECT/TRIAGER all came up
  empty, and the dependency-currency lens (cycles 24-27) was found exhausted.
  Fresh angle: this ROADMAP's own 2026-08-25 note explicitly named the
  ~180-item legacy-writeup trim as deferred future work — picked up a small,
  fully-verified pilot batch rather than the whole backlog at once.
  **No prerequisites — executor may pick up immediately.**)
  Trimmed 4 RFC #377 (Oracle backend) items, each verified against its real
  `docs/done/` mirror before touching the ROADMAP text — no information
  lost, ~31 lines saved. `ROADMAP.md` 7382→7351 lines. `make ci` must pass
  (2976/2976 bats tests this cycle, with shellcheck/yamllint also installed
  and run clean). `docs/done/` entry required.

- [x] 🟢 **Oldest dependency-register rows re-swept — Garage, RabbitMQ, Tempo
  confirmed clean; Forgejo unreachable** — full verification writeup:
  [docs/done/2026-09-04-oldest-register-rows-resweep-clean.md](docs/done/2026-09-04-oldest-register-rows-resweep-clean.md).
  (auto/oldest-register-rows-resweep-clean)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004;
  JANITOR-fallback coverage sweep 2026-09-04, this run's twenty-sixth
  cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next"
  lane was re-confirmed fully gated and PLANNER/ARCHITECT/TRIAGER all came
  up empty. Fresh angle: continuing the prior cycle's "rank by
  Last-reviewed date" lens to the next three oldest untouched rows.
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): Garage, RabbitMQ, Tempo all
  confirmed still current via direct tag/advisory checks; Forgejo attempted
  but `codeberg.org` is egress-blocked from this sandbox, noted explicitly
  rather than assumed current. `docs/decisions/adr-0002-garage-not-minio.md`,
  `adr-0009-rabbitmq-message-broker.md`, `adr-0006-grafana-native-git-sync.md`
  and `docs/dependency-register.md` updated. No `gitops/` change. `make ci`
  must pass. `docs/done/` entry required.

- [x] 🟢 **Pyroscope currency re-check — app `v2.3.0` exists, no matching
  chart release yet, kept at `2.2.1`** — full verification writeup:
  [docs/done/2026-09-04-pyroscope-currency-recheck-kept.md](docs/done/2026-09-04-pyroscope-currency-recheck-kept.md).
  (auto/pyroscope-currency-recheck-kept)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004;
  JANITOR-fallback coverage sweep 2026-09-04, this run's twenty-fifth
  cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next"
  lane was re-confirmed fully gated (unchanged from cycle 24's exhaustive
  re-check) and PLANNER/ARCHITECT/TRIAGER all came up empty. Fresh angle:
  ranked every dependency-register row by "Last reviewed" date and checked
  the oldest untouched one (Pyroscope, 2026-08-10) rather than re-checking
  an already-recently-verified component. **No prerequisites — executor
  may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): app `v2.3.0` confirmed real
  with genuine security content, but the chart release (what this repo
  actually pins) hasn't caught up yet — confirmed via a direct tag-404
  check, not assumed from a release-list summary. `docs/decisions/
  adr-0034-lgtmp-observability-stack.md`'s Re-evaluation log and
  `docs/dependency-register.md`'s row updated. No `gitops/` change.
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Issue #1229 wrongly closed alongside PR #1403 — reopened, ROADMAP
  rule #11 hardened** — full verification writeup:
  [docs/done/2026-09-04-issue-1229-wrongly-closed-reopened.md](docs/done/2026-09-04-issue-1229-wrongly-closed-reopened.md).
  (auto/issue-1229-reopen-rule-11-hardened)
  (CHARTER **Core Values** §"Dashboards/outputs show real, auto-discovered
  state" (ADR-0004); self-caught correction 2026-09-04, this run's
  twenty-third cycle, found on session resume while re-orienting on
  open issues per STEP 1/2 — a prior cycle's PR #1403 closed issue #1229
  despite its own comment saying it should stay open, with no closing
  keyword anywhere in the PR to explain it. **No prerequisites — this is a
  correction, not a gated item.**)
  Reopened #1229 via the GitHub API, posted a comment naming the exact
  mistake and re-confirming what's still needed, and hardened ROADMAP rule
  #11 with an explicit procedural guard against recurrence (no code-level
  guard is possible for a wrong `issue_write` call — see the docs/done
  entry's own "why procedural, not mechanical" section, per CLAUDE.md's
  escape hatch for genuinely unguardable classes). No `gitops/` or code
  change. `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Restore the silently-dropped `verify-rejection` CI job (O4 gate) +
  mechanical recurrence guard** — full verification writeup:
  [docs/done/2026-09-03-forgejo-ci-verify-rejection-restored.md](docs/done/2026-09-03-forgejo-ci-verify-rejection-restored.md).
  (auto/forgejo-ci-verify-rejection-restored)
  (CHARTER **Objective O4** ("every image is signed and verified") /
  **Core Values** §"Clusterless gates stay green"; JANITOR-fallback
  coverage sweep 2026-09-03, this run's twenty-first cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed
  fully gated and PLANNER/ARCHITECT/TRIAGER all came up empty. Fresh angle:
  re-reading issue #1229's own comment history (not just its title) found it
  had already root-caused something deeper than a missing secret — the
  entire `verify-rejection` job was silently dropped by a rewrite (#1238)
  with no test pinning its presence, and the issue's own comment explicitly
  named the executor-buildable slice ("the job restored... a
  `tests/forgejo-ci.bats` regression pinning its presence... *then* the
  KUBECONFIG secret") per ROADMAP rule #9's "split the gate" guidance.
  **No prerequisites for the restoration — executor may pick up
  immediately; the KUBECONFIG secret + live run stay gated on #1229, left
  open.**)
  Restored the job re-adapted to the file's post-rewrite conventions
  (retry_cmd wrapping, shared host-resolution step, its own checkout);
  restored + extended `tests/forgejo-ci.bats`'s coverage (12 original + 3
  new assertions). Full local bats run: 2970/2970 pass. `make ci` must
  pass. `docs/done/` entry required. Issue #1229 stays open.

- [x] 🟢 **Inkless kafka-exporter sidecar — document in ADR-0015,
  currency-check clean** — full verification writeup:
  [docs/done/2026-09-03-inkless-kafka-exporter-documented.md](docs/done/2026-09-03-inkless-kafka-exporter-documented.md).
  (auto/inkless-kafka-exporter-documented)
  (CHARTER **Core Values** §"Everything as code" (governance completeness);
  JANITOR-fallback coverage sweep 2026-09-03, this run's twentieth cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated and PLANNER/ARCHITECT/TRIAGER all came up empty.
  Fresh angle: a full `gitops/`-wide image inventory (distinct from the
  per-ADR sweeps done so far) found `danielqsj/kafka-exporter:v1.9.0` — live
  in the Inkless broker's StatefulSet since Inkless first landed — had zero
  mention in ADR-0015, unlike Valkey's equivalent `redis_exporter` sidecar in
  ADR-0018. Small enough to close as a section addition rather than a new
  ADR (an observability sidecar, not an independent architectural choice).
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): `v1.9.0` reconfirmed the newest
  real tag via Docker Hub's tags API; zero GHSA advisories exist. No
  `gitops/` change. `docs/dependency-register.md`'s Inkless row updated.
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Author ADR-0039 — s3manager as the lab's Garage (S3) browser UI
  (retroactive record); bump `v0.8.0` → `v0.9.0`** — full verification
  writeup:
  [docs/done/2026-09-03-adr-0039-s3manager-retroactive-record.md](docs/done/2026-09-03-adr-0039-s3manager-retroactive-record.md).
  (auto/adr-0039-s3manager-retroactive-record)
  (CHARTER **Core Values** §"Everything as code" (governance completeness);
  ARCHITECT-fallback gap analysis 2026-09-03, this run's nineteenth cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated and PLANNER/ARCHITECT/TRIAGER all came up empty.
  Fresh angle: continuing this run's retroactive-ADR-authorship pattern
  (ADR-0036 ESO, ADR-0037 Vault, ADR-0038 moto+ACK+KRO) found s3manager — a
  real, live, always-on Garage-browser UI with a genuine version-bump
  history — also had zero governing ADR and zero dependency-register row.
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): `v0.9.0` confirmed real via
  Docker Hub's tags API and a real commit-history diff; zero GHSA advisories
  exist. ADR-0004 caveat noted explicitly (cannot visually verify the
  CSS-framework migration renders correctly; stateless + digest-pinned, so
  rollback is a one-line revert with zero data-loss risk).
  `docs/decisions/README.md` and `docs/dependency-register.md` (1 new row +
  fixed scope-note arithmetic) updated. `make ci` must pass. `docs/done/`
  entry required.

- [x] 🟢 **Author ADR-0038 — moto + ACK (S3) + KRO for the cloud-control-plane
  demo pattern (retroactive record); bump moto `5.2.2` → `5.2.3`** — full
  verification writeup:
  [docs/done/2026-09-03-adr-0038-ack-kro-moto-retroactive-record.md](docs/done/2026-09-03-adr-0038-ack-kro-moto-retroactive-record.md).
  (auto/adr-0038-ack-kro-moto-retroactive-record)
  (CHARTER **Core Values** §"Everything as code" (governance completeness);
  ARCHITECT-fallback gap analysis 2026-09-03, this run's eighteenth cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated and PLANNER/ARCHITECT/TRIAGER all came up empty.
  Fresh angle: extending this run's retroactive-ADR-authorship pattern
  (ADR-0036 ESO, ADR-0037 Vault) to moto/ACK-S3/KRO — three real, live,
  already-hardened always-on components (KRO currently suspended) with their
  own dashboard and bats coverage, yet zero governing ADR and zero
  dependency-register row, unlike every other component in the lab.
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): moto bumped to a confirmed-real
  newer patch (Docker Hub tags API); ACK-S3 (`1.11.0`) and KRO (`0.9.3`) both
  reconfirmed already current via direct tag/release checks; zero GHSA
  advisories exist for any of the three. `docs/decisions/README.md` and
  `docs/dependency-register.md` (3 new rows + fixed scope-note arithmetic)
  updated. `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Longhorn currency re-check — `v1.12.1` now stable, ADR's own flip
  condition still not triggered, kept at `1.11.3`** — full verification
  writeup:
  [docs/done/2026-09-03-longhorn-currency-recheck-kept.md](docs/done/2026-09-03-longhorn-currency-recheck-kept.md).
  (auto/longhorn-currency-recheck-kept)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004;
  JANITOR-fallback coverage sweep 2026-09-03, this run's seventeenth cycle,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated again and PLANNER/ARCHITECT/TRIAGER all came up
  empty. Fresh angle: a pinned-chart currency sweep (distinct from the
  GHSA-advisory-sweep lens already used heavily this run) found Longhorn's
  `1.12.x` line — the line ADR-0013's own 2026-07-18 entry deliberately
  stayed one minor line behind — went stable (`v1.12.1`, 2026-08-14) since
  the last check. Verified this is an ADR-guarded case, not an unswept
  currency gap: CLAUDE.md's "never silently violate an ADR" rule applies —
  neither of ADR-0013's own named flip conditions (EOL window, a filed CVE)
  has fired, so the pin correctly stays put; the check itself, with its
  fresh verification, is the deliverable. **No prerequisites — executor may
  pick up immediately.**)
  Verified directly (not assumed, ADR-0004): `v1.12.1`'s existence confirmed
  via two independent sources (the release page and a real, resolving raw
  image-list file at that tag); ADR-0013's Re-evaluation log and
  `docs/dependency-register.md`'s row updated with the fresh check. No
  `gitops/` change. `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **dependency-concentration-sync-check: close the reverse-direction gap
  + fix a stale comment** — full verification writeup:
  [docs/done/2026-09-03-dependency-concentration-reverse-check.md](docs/done/2026-09-03-dependency-concentration-reverse-check.md).
  (auto/dependency-concentration-reverse-check)
  (CHARTER **Core Values** §"Clusterless gates stay green" / DORA audit readiness
  Q14/Q16/Q17; JANITOR-fallback coverage sweep 2026-09-03, this run's sixteenth
  cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated (3 items, all still blocked on live-cluster
  verification or maintainer confirmation — issues #633/#1229/#1345 re-checked,
  none confirmed) and PLANNER/ARCHITECT/TRIAGER all came up empty (zero
  ungroomed intake/rfc issues, zero un-RFC'd 🟡 items, zero untriaged open
  issues). Fresh angle: a coverage/hardening sweep of the mechanical drift
  guards themselves (not their subjects) found `scripts/
  dependency-concentration-sync-check.sh`'s own header comment claiming an
  already-closed gap (docs/dependency-exit-runbooks.md's downstream sync,
  actually closed by #1380 the same day #1379 landed) was still open, plus a
  genuinely still-open gap (the reverse direction: a concentration.md group
  whose stated data has drifted from the register) named in the same comment.
  **No prerequisites — executor may pick up immediately.**)
  Fixed the stale comment; added a second check pass verifying every
  concentration.md group still backs 2+ register rows and its stated count
  still matches. New bats fixtures + tests exercise both new failure modes.
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **KEDA + Velero full GHSA sweep — confirm both pins security-clean** —
  full verification writeup:
  [docs/done/2026-09-03-keda-velero-full-ghsa-sweep-clean.md](docs/done/2026-09-03-keda-velero-full-ghsa-sweep-clean.md).
  (auto/keda-velero-full-ghsa-sweep-clean)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  security sweep 2026-09-03, this run's fifteenth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again. Fresh angle: extending this run's full-advisory-sweep technique
  (Envoy Gateway, Cilium, ArgoCD, cert-manager) to KEDA (3 advisories) and Velero
  (2 advisories) — both small enough to sweep exhaustively in one PR, after an
  attempted RabbitMQ sweep (~80-90 advisories across 9 pages) was abandoned as
  disproportionate. **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): all 3 KEDA advisories and both
  Velero advisories checked; one previously-unchecked advisory found per
  project (KEDA's CI-workflow-only GHSA-w92x-gx4w-j5f2, not applicable to the
  deployed operator; Velero's GHSA-72xg-3mcq-52v4, current pin many majors
  past the fixed floor). No code change; `docs/decisions/
  adr-0029-keda-event-driven-autoscaling.md` and `docs/decisions/
  adr-0021-velero-backup-restore.md`'s Re-evaluation logs and
  `docs/dependency-register.md`'s rows updated. `make ci` must pass. `docs/done/`
  entry required.

- [x] 🟢 **cert-manager full GHSA sweep — confirm `1.21.1` pin security-clean** —
  full verification writeup:
  [docs/done/2026-09-03-cert-manager-full-ghsa-sweep-clean.md](docs/done/2026-09-03-cert-manager-full-ghsa-sweep-clean.md).
  (auto/cert-manager-full-ghsa-sweep-clean)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  security sweep 2026-09-03, this run's fourteenth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again. Fresh angle: extending this run's full-advisory-sweep technique
  (Envoy Gateway, Cilium, ArgoCD) to cert-manager — only 3 advisories total, a
  small enough set to sweep exhaustively and confirm two already-tracked findings
  plus one previously-unchecked Low advisory. **No prerequisites — executor may
  pick up immediately.**)
  Verified directly (not assumed, ADR-0004): all 3 published advisories checked;
  current pin `1.21.1` is past every floor including the newly-checked
  GHSA-r4pg-vg54-wxx4. No code change; `docs/decisions/
  adr-0028-cert-manager-tls-lifecycle.md`'s Re-evaluation log and
  `docs/dependency-register.md`'s row updated. `make ci` must pass. `docs/done/`
  entry required.

- [x] 🟢 **Author ADR-0037 — HashiCorp Vault for secrets management (retroactive
  record); bump server image `2.0.4` → `2.1.0`** — full verification writeup:
  [docs/done/2026-09-03-vault-adr-0037-retroactive-record.md](docs/done/2026-09-03-vault-adr-0037-retroactive-record.md).
  (auto/vault-adr-0037-retroactive-record)
  (CHARTER **Core Values** §"Everything as code" / CHARTER **Goals** §"the secrets
  flow (Vault → External Secrets → workload)"; architect-fallback gap analysis
  2026-09-03, this run's thirteenth cycle, reached via `executor.prompt.md`
  STEP 6b after the "Now / next" lane was re-confirmed fully gated again. Fresh
  angle: extending this run's GHSA-sweep pass (Envoy Gateway, Cilium, ArgoCD) to
  Vault surfaced a much bigger gap than "is the pin current" — Vault had no ADR
  at all and no register row, exactly the same class of gap ADR-0036 (External
  Secrets Operator) closed on 2026-08-19, and worse: its version-audit trail
  lived only as inline YAML comments in `vault.yaml`, the sole component in this
  repo doing that instead of pointing at its own ADR. **No prerequisites —
  executor may pick up immediately.**)
  Mirrors ADR-0036's established retroactive-record structure and migrates all
  four pre-existing Re-evaluation log entries verbatim from `vault.yaml`'s inline
  comments. While authoring it, re-checked currency and found `v2.1.0`
  (2026-09-01) fixes two real Go-vulnerability-database dependency issues;
  bumped the server image and its `vault-unsealer` lockstep image together.
  Caught and corrected a WebFetch ambiguity mid-research (a `main`-branch
  CHANGELOG.md fetch resolved to an unrelated section) by cross-checking against
  the real releases list instead of trusting the first result. `docs/dependency-
  register.md`'s Scope-note arithmetic updated and verified via
  `make dependency-register-check`, not hand-counted. `make ci` must pass.
  `docs/done/` entry required.

- [x] 🟢 **ArgoCD full GHSA sweep — confirm `v3.5.2` pin security-clean** — full
  verification writeup:
  [docs/done/2026-09-03-argocd-full-ghsa-sweep-clean.md](docs/done/2026-09-03-argocd-full-ghsa-sweep-clean.md).
  (auto/argocd-full-ghsa-sweep-clean)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  security sweep 2026-09-03, this run's twelfth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again. Fresh angle: extending the same full-advisory-sweep technique
  (Envoy Gateway, Cilium) to ArgoCD itself — this lab's actual GitOps deployment
  mechanism and, per `docs/dependency-exit-runbooks.md`, its single largest
  possible dependency exit — completing all 8 published advisories this time
  (a small enough total to sweep exhaustively, unlike Cilium's multi-page
  history). Complements this run's earlier chart-currency check (10.5.0→10.7.0
  exists, template-only, no appVersion change, judged not worth the risk for
  zero functional gain) by confirming that decision wasn't hiding an unpatched
  security gap. **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): every advisory's affected range
  tops out at `3.4.2` or lower; current pin's appVersion `v3.5.2` is past every
  floor, including the highest severity (Critical, a `ServerSideDiff` secret
  extraction this lab's own `Application` manifests don't trigger the
  precondition for anyway). No code change; `docs/dependency-register.md`'s
  ArgoCD row updated (no dedicated ADR/Re-evaluation log exists for ArgoCD
  specifically — its register row cites ADR-0001, which has no such section —
  so the finding is recorded in the register row itself). `make ci` must pass.
  `docs/done/` entry required.

- [x] 🟢 **Cilium: Critical advisory GHSA-3fcv-jvfp-m4q9 found unaudited, confirmed
  not applicable** — full verification writeup:
  [docs/done/2026-09-03-cilium-critical-ghsa-gap-closed.md](docs/done/2026-09-03-cilium-critical-ghsa-gap-closed.md).
  (auto/cilium-critical-ghsa-gap-closed)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  security sweep 2026-09-03, this run's eleventh cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again. Fresh angle: extending the same "full advisory listing, not just
  currency" technique from this run's Envoy Gateway sweep to Cilium — the other
  highest-blast-radius always-on-core component per `docs/dependency-exit-runbooks.md`
  — and finding a real gap this time: a Critical advisory ADR-0014's own prior
  audit (scoped only to advisories published on one specific date) never recorded.
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): the advisory's affected/patched
  ranges confirm this lab's pin (`1.18.13`) is five patches past the `1.18.x`
  fix floor (`1.18.8`) — not affected. Explicitly scoped as a targeted
  Critical-advisory check plus a partial spot-check (one of several advisory
  pages), not an exhaustive full-history re-audit — said plainly rather than
  overclaiming completeness. No code change; `docs/decisions/
  adr-0014-cilium-not-flannel-policy.md`'s Re-evaluation log and
  `docs/dependency-register.md`'s row updated. `make ci` must pass. `docs/done/`
  entry required.

- [x] 🟢 **Envoy Gateway full GHSA sweep — confirm `v1.8.3` pin security-clean** —
  full verification writeup:
  [docs/done/2026-09-03-envoy-gateway-ghsa-sweep-clean.md](docs/done/2026-09-03-envoy-gateway-ghsa-sweep-clean.md).
  (auto/envoy-gateway-ghsa-sweep-clean)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  security sweep 2026-09-03, this run's tenth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again and every remaining register row's version-currency was already
  re-confirmed exhausted this run. Fresh angle: rather than "is a newer version
  available" (already asked twice this run), asked a different question —
  "does any published advisory affect the version we're deliberately holding at" —
  for ADR-0008's Envoy Gateway hold specifically, since that ADR's own log had
  only ever answered the first question, never the second. **No prerequisites —
  executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): fetched all 10 published GitHub
  security advisories for `envoyproxy/gateway` and their affected/patched
  version ranges. Every affected range tops out at `1.8.1` or lower — current
  pin `v1.8.3` is past every floor, including the lone Critical. No code
  change; `docs/decisions/adr-0008-envoy-gateway-not-traefik.md`'s
  Re-evaluation log and `docs/dependency-register.md`'s row updated to record
  the sweep. `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Refresh `docs/dora-metrics.md` (stale since 2026-07-30)** — full
  verification writeup:
  [docs/done/2026-09-03-dora-metrics-refresh.md](docs/done/2026-09-03-dora-metrics-refresh.md).
  (auto/dora-metrics-refresh)
  (CHARTER **Objective O7**; planner-fallback gap analysis 2026-09-03, this run's
  ninth cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next"
  lane was re-confirmed fully gated again, no ungroomed intake/`rfc` issue existed
  to groom, and a second full currency sweep across every remaining register row
  (Istio, Argo Rollouts, Trivy Operator, Kargo, Valkey, ACK-S3, TiDB, Mimir) found
  nothing further to bump — all already at their newest stable version. Fresh
  angle: `docs/dora-metrics.md` itself was over a month stale (2026-07-30) and
  this run alone had already landed 8 merged PRs, meaningfully changing the real
  trailing-90-day numbers a stale snapshot was misreporting. **No prerequisites —
  executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): confirmed this session's clone is
  not shallow before trusting `make dora-metrics`' output — the script's own
  header comment documents a real prior bug where a shallow clone silently
  undercounted with no warning. Deployment frequency and change failure rate
  both updated with real, freshly computed numbers; lead time / restore time
  remain honestly "insufficient data" (this session lacks `gh` CLI, same
  limitation as whichever prior session computed the stale snapshot — not a
  script bug). `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **De-duplicate `scripts/dependency-register-check.sh`'s row-parsing logic
  into `scripts/lib/dependency-register.sh`** — full verification writeup:
  [docs/done/2026-09-03-dependency-register-check-lib-dedup.md](docs/done/2026-09-03-dependency-register-check-lib-dedup.md).
  (auto/dependency-register-check-lib-dedup)
  (CHARTER **Core Values** §"Everything as code" (CLAUDE.md de-duplication
  principle); JANITOR-fallback codebase-health sweep 2026-09-03, this run's eighth
  cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated again (issues #633/#1229 unchanged), no ungroomed
  intake/`rfc` issue existed to groom, and this run's currency sweep had checked
  every remaining register row with no further bump found (RabbitMQ, cert-manager,
  Cilium, Velero, Harbor, KEDA, Longhorn all already current; ArgoCD's chart has a
  newer template-only release with no appVersion/CVE change, judged not worth the
  risk to the repo's highest-blast-radius component for zero functional gain).
  Delegated a broad codebase-health scan (untested scripts, Makefile/script
  orphans, stale TODOs, broken doc cross-refs, oversized files, duplicate bats
  assertions) to a sub-agent — six of seven categories came back clean (this repo
  has already been heavily janitor-swept), but found one real gap: `scripts/lib/
  dependency-register.sh`'s own extraction (2026-09-02) missed a third pre-existing
  copy of the same row-parser in `dependency-register-check.sh`, exactly the
  duplication class it was extracted to stop. **No prerequisites — executor may
  pick up immediately.**)
  Verified behavior-preserving (not just structurally similar): ran the refactored
  script directly against all 8 existing fixture scenarios in
  `tests/fixtures/dependency-register-check/` — every one produced the identical
  exit code as before the refactor (bats isn't installed in this clusterless
  session, so fixtures were exercised directly rather than assumed unaffected).
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Bump Kyverno chart `3.8.2` → `3.9.0` (2 CVEs, 2 GHSAs, minor bump)** —
  full verification writeup:
  [docs/done/2026-09-03-kyverno-3-8-2-to-3-9-0-cve-bump.md](docs/done/2026-09-03-kyverno-3-8-2-to-3-9-0-cve-bump.md).
  (auto/kyverno-3-8-2-to-3-9-0)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  currency sweep 2026-09-03, this run's seventh cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again (issues #633/#1229 unchanged) and no ungroomed intake/`rfc` issue
  existed to groom. Fresh angle: continuing the currency-sweep pattern (Loki,
  Grafana, Inkless, k3s), this cycle found Kyverno's chart had real fixes
  available only on a minor bump (no 3.8.x patch backport exists) — a bigger,
  riskier change than the patch bumps so far this run, so extra verification was
  done: fetched the real chart values.yaml at the target tag directly to confirm
  this Application's specific override keys and PSA-restricted-critical
  securityContext defaults are unchanged before proceeding. **No prerequisites —
  executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): GitHub's release notes for
  `v1.19.0` cite CVE-2026-32280, CVE-2026-39836, GHSA-79gf-7frw-68m9, and
  GHSA-gcjh-h69q-9w9g under a Security heading. `raw.githubusercontent.com`'s
  real `values.yaml` at `kyverno-chart-3.9.0` confirmed unchanged
  override-key shape and identical PSA-restricted securityContext defaults.
  Noted (not acted on): four new policy CRDs this lab doesn't use, and a
  deprecation warning on the legacy `kyverno.io` policy types this lab's
  `ClusterPolicy` resources actually use (still functional, just warns).
  `gitops/platform/kyverno.yaml`, `tests/kyverno.bats`, a new ADR-0019
  Re-evaluation log entry, and `docs/dependency-register.md`'s row all
  updated. `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Bump k3s `v1.36.3+k3s1` → `v1.36.4+k3s1` on both backends** — full
  verification writeup:
  [docs/done/2026-09-03-k3s-1-36-3-to-1-36-4-currency-bump.md](docs/done/2026-09-03-k3s-1-36-3-to-1-36-4-currency-bump.md).
  (auto/k3s-1-36-3-to-1-36-4)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  currency sweep 2026-09-03, this run's sixth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again (issues #633/#1229 unchanged) and no ungroomed intake/`rfc` issue
  existed to groom. Fresh angle: continuing the currency-sweep pattern (Loki,
  Grafana, Inkless), this cycle checked RabbitMQ/cert-manager/Cilium/Velero/Harbor
  (all confirmed already current, no bump needed) before finding k3s genuinely due.
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): GitHub's release notes for `v1.36.4+k3s1`
  confirmed; a release-list summary's CVE-2025-54410 claim was independently
  checked and found unconfirmed by the release's own detailed notes and unlikely
  to apply to k3s's actual runtime (containerd, not Docker Engine) — flagged as
  such rather than asserted. Docker Hub confirms `rancher/k3s:v1.36.4-k3s1` is
  real and published. Both backends (`k3d-config.yaml.tftpl`,
  `oracle-k3s-cluster/cloud-init.yaml`) bumped together per ADR-0030's own
  discipline; `tests/k3s-version-pin.bats`, `docs/decisions/context.md`, a new
  ADR-0030 Re-evaluation log entry, and `docs/dependency-register.md`'s row all
  updated. `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **Bump Aiven Inkless broker `4.2.1-0.46` → `4.2.1-0.47`** — full
  verification writeup:
  [docs/done/2026-09-03-inkless-4-2-1-0-46-to-0-47-bump.md](docs/done/2026-09-03-inkless-4-2-1-0-46-to-0-47-bump.md).
  (auto/inkless-4-2-1-0-46-to-0-47)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  currency sweep 2026-09-03, this run's fifth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again (issues #633/#1229 unchanged) and no ungroomed intake/`rfc` issue
  existed to groom. Fresh angle: continuing the currency-sweep pattern (Loki,
  Grafana), this cycle re-checked Aiven Inkless, the oldest-reviewed row not yet
  covered this run (2026-08-18). **No prerequisites — executor may pick up
  immediately.**)
  Verified directly (not assumed, ADR-0004): GitHub's release list confirms
  `inkless-release-0.47`; the exact image tag confirmed real and pullable via an
  anonymous-token GHCR manifest query (with the correct multi-arch `Accept`
  header — a first attempt with the wrong header returned a misleading 404).
  No named CVE this release, but real bug fixes. **Flagged, not silently
  absorbed:** the release includes PostgreSQL migrations (two requiring
  table-level locks) whose execution mechanism (automatic on startup vs.
  human-triggered) this session could not confirm — filed as a `[Manual step]`
  issue for the next live `make inkless-up`. `gitops/inkless/inkless-statefulset.yaml`,
  `tests/inkless.bats`, ADR-0015's Re-evaluation log, and
  `docs/dependency-register.md`'s row all updated. `make ci` must pass.
  `docs/done/` entry required.

- [x] 🟢 **Bump Grafana image tag `13.0.7` → `13.0.8` (3 named CVEs:
  CVE-2026-12704, CVE-2026-14199, CVE-2026-19475)** — full verification writeup:
  [docs/done/2026-09-03-grafana-13-0-7-to-13-0-8-cve-bump.md](docs/done/2026-09-03-grafana-13-0-7-to-13-0-8-cve-bump.md).
  (auto/grafana-13-0-7-to-13-0-8)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  currency sweep 2026-09-03, this run's fourth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again (issues #633/#1229 unchanged) and no ungroomed intake/`rfc` issue
  existed to groom. Fresh angle: continuing the currency-sweep pattern from this
  run's third cycle (Loki), this cycle re-checked Grafana specifically — its own
  last real check (2026-08-19) was due per ADR-0006's own flip condition — and
  found a genuine security release with three named CVEs, a stronger priority
  than a routine patch per upgrade-drafter's own priority rule (CVE-mentioning
  release > patch > minor). **No prerequisites — executor may pick up
  immediately.**)
  Verified directly (not assumed, ADR-0004): GitHub's release notes for `v13.0.8`
  cite three named CVEs under a `Security` heading; Docker Hub confirms
  `grafana/grafana:13.0.8` is a real published multi-arch image. Per-CVE
  applicability to this lab's specific configuration analyzed and documented
  (Auth Proxy not used, no PostgreSQL datasource, Enterprise-only CVE likely N/A)
  — patched regardless since the binary ships the fix either way.
  `gitops/platform/observability-grafana.yaml` (both image references),
  `tests/observability-grafana.bats`, `docs/decisions/context.md`'s version
  citation, a new ADR-0006 Re-evaluation log entry, and
  `docs/dependency-register.md`'s Grafana row all updated. `make ci` must pass.
  `docs/done/` entry required.

- [x] 🟢 **Bump Loki image tag `3.7.6` → `3.7.7` (security-relevant dependency
  bumps)** — full verification writeup:
  [docs/done/2026-09-03-loki-3-7-6-to-3-7-7-security-bump.md](docs/done/2026-09-03-loki-3-7-6-to-3-7-7-security-bump.md).
  (auto/loki-3-7-6-to-3-7-7)
  (CHARTER **Core Values** §"Clusterless gates stay green" / ADR-0004; planner-fallback
  currency sweep 2026-09-03, this run's third cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again (issues #633/#1229 unchanged) and no ungroomed intake/`rfc` issue
  existed to groom. Fresh angle: rather than a third dependency-docs-prose pass,
  this cycle re-checked `grafana/loki` specifically as the oldest-reviewed row
  (2026-08-06) across all 33 `docs/dependency-register.md` rows and found a real,
  security-relevant patch published since. **No prerequisites — executor may pick
  up immediately.**)
  Verified directly (not assumed, ADR-0004): GitHub's tags list confirms `v3.7.7`
  (2026-08-27) is the newest `3.7.x` tag; its release notes cite three
  security-relevant dependency bumps (`containerd`, `etcd` client,
  `golang.org/x/mod`); Docker Hub confirms `grafana/loki:3.7.7` is a real
  published multi-arch image. `gitops/observability/loki/deployment.yaml` and
  `tests/observability-loki.bats` updated; new ADR-0006 Re-evaluation log entry
  added; `docs/dependency-register.md`'s Loki row updated (Grafana's row also
  collaterally date-bumped, honestly worded, per `dependency-register-check.sh`'s
  documented shared-ADR global-latest limitation). `make ci` must pass. `docs/done/`
  entry required.

- [x] 🟢 **Extend `docs/dependency-exit-runbooks.md` to the remaining seven
  single-tool rows (Terraform/Terragrunt, RabbitMQ, Valkey, KEDA, Forgejo,
  kube-state-metrics, node-exporter)** — full verification writeup:
  [docs/done/2026-09-03-dependency-exit-runbooks-remaining-seven.md](docs/done/2026-09-03-dependency-exit-runbooks-remaining-seven.md).
  (auto/dependency-exit-runbooks-remaining-seven)
  (CHARTER **Core Values** §"Docs & dashboards don't drift" (ADR-0004,
  `docs/dora-audit-readiness.md` Q17); planner-fallback gap analysis 2026-09-03, this
  run's second cycle, reached via `executor.prompt.md` STEP 6b after the "Now / next"
  lane was re-confirmed fully gated again this cycle (issues #633/#1229 unchanged,
  no new comments) and no ungroomed intake/`rfc` issue existed to groom. Fresh angle:
  `docs/dependency-exit-runbooks.md`'s own "Scope of this slice" note already named
  this exact remaining work as real, separately-scoped, deferred only for PR-size
  discipline — this cycle picked it up directly rather than re-mining
  `docs/dora-audit-readiness.md` for a new gap. **No prerequisites — executor may pick
  up immediately.**)
  Verified directly (not assumed, ADR-0004): confirmed each of the seven tools' real
  `gitops/` manifest path, owning ADR, and register criticality row before writing its
  runbook paragraph (no invented claims about what depends on what). `make ci` must
  pass — the `dependency-exit-runbooks-sync-check.sh` concentration-group check is
  unaffected (it only checks concentration-group coverage, not single-tool-row
  coverage). `docs/done/` entry required.

- [x] 🟢 **Fix stale "Keeping this in sync" claims in `docs/dependency-register.md`,
  `docs/dependency-concentration.md`, and `docs/dependency-exit-runbooks.md`** — full
  verification writeup:
  [docs/done/2026-09-03-dependency-docs-sync-check-drift-fix.md](docs/done/2026-09-03-dependency-docs-sync-check-drift-fix.md).
  (auto/dependency-docs-sync-check-drift-fix)
  (CHARTER **Core Values** §"Real observability only" / §"Docs & dashboards don't
  drift" (ADR-0004); planner-fallback gap analysis 2026-09-03, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated this cycle (both standing GitLab→Forgejo migration items and the
  capstone-Deployment-removal item, still blocked on unconfirmed issues #633/#1229 —
  re-checked, no new comments since 2026-08-25) and no ungroomed intake/`rfc` issue
  existed to groom (only the three standing `[Action required]` issues, none new
  work). Fresh angle: the prior day's two cycles (2026-09-02) landed
  `dependency-concentration-sync-check.sh` and `dependency-exit-runbooks-sync-check.sh`
  but never circled back to update the very "Keeping this in sync" prose in
  `docs/dependency-register.md`/`docs/dependency-concentration.md`/
  `docs/dependency-exit-runbooks.md` that those scripts closed the gap named in —
  leaving three docs asserting "no mechanical drift guard yet" right next to the
  guard that had just landed, an ADR-0004 self-consistency bug this cycle closed
  instead of mining `docs/dora-audit-readiness.md` for a fourth consecutive gap.
  **No prerequisites — executor may pick up immediately.**)
  Verified directly (not assumed, ADR-0004): confirmed all three scripts
  (`scripts/dependency-register-check.sh`, `scripts/dependency-concentration-sync-check.sh`,
  `scripts/dependency-exit-runbooks-sync-check.sh`) exist, each has a `.PHONY`
  Makefile target, and all three are invoked from the `drift` job `make ci` runs
  (`Makefile` lines 263-265) — directly contradicting each file's own stale
  "no mechanical drift guard yet" / "no mechanical guard, keep by hand" prose.
  Rewrote each file's "Keeping this in sync" section to state precisely what's now
  guarded (register "Last reviewed" staleness; register→concentration.md org-count
  sync; concentration→exit-runbooks.md group-coverage sync) and what honestly still
  isn't (the reverse direction on each sync check; exit-runbooks.md's remaining
  seven uncovered single-tool rows — unchanged, deliberate scope, not drift).
  `make ci` must pass. `docs/done/` entry required.

- [x] 🟢 **GitOps-track the `harbor.127.0.0.1.nip.io`-class in-cluster DNS rewrite
  found live in PR #1323 — extend `scripts/coredns-host-alias.sh`** — full
  verification writeup:
  [docs/done/2026-08-25-coredns-nip-io-gitops-tracking.md](docs/done/2026-08-25-coredns-nip-io-gitops-tracking.md).
  (auto/coredns-nip-io-gitops-tracking; PR #1326)

- [x] 🟢 **Bump Vault Helm chart `0.34.0` → `0.34.1`** — full verification
  writeup: [docs/done/2026-08-19-vault-chart-0-34-0-to-0-34-1.md](docs/done/2026-08-19-vault-chart-0-34-0-to-0-34-1.md)
  (PR #1269). (auto/vault-chart-0-34-0-to-0-34-1)

- [x] 🟢 **Bump Oracle-workflow-pinned Terragrunt `v1.1.1` → `v1.1.3`** — full
  verification writeup: [docs/done/2026-08-19-terragrunt-1-1-1-to-1-1-3.md](docs/done/2026-08-19-terragrunt-1-1-1-to-1-1-3.md)
  (PR #1273). (auto/terragrunt-1-1-1-to-1-1-3)

- [x] 🟢 **Bump CI's pinned Terraform `1.15.8` → `1.15.9` (CVE-2026-14978)** —
  full verification writeup: [docs/done/2026-08-19-ci-terraform-1-15-8-to-1-15-9.md](docs/done/2026-08-19-ci-terraform-1-15-8-to-1-15-9.md)
  (PR #1272). (auto/ci-terraform-1-15-8-to-1-15-9)

- [x] 🟢 **Bump Grafana image `13.0.6` → `13.0.7` (CVE-2026-17183)** — full
  verification writeup: [docs/done/2026-08-19-grafana-image-13-0-6-to-13-0-7.md](docs/done/2026-08-19-grafana-image-13-0-6-to-13-0-7.md)
  (PR #1271). (auto/grafana-image-13-0-6-to-13-0-7)

- [x] 🟢 **Bump Cilium chart `1.18.12` → `1.18.13`** — full verification
  writeup: [docs/done/2026-08-19-auto-cilium-1-18-12-to-1-18-13.md](docs/done/2026-08-19-auto-cilium-1-18-12-to-1-18-13.md)
  (PR #1252). (auto/cilium-1-18-12-to-1-18-13)

- [x] 🟢 **Pin Aiven Inkless broker `ghcr.io/aiven/inkless:latest` → `:4.2.1-0.46`,
  remove the Kyverno `disallow-latest-tag` `inkless` carve-out** — full verification
  writeup: [docs/done/2026-08-18-inkless-latest-tag-pin-kyverno-exclusion-removal.md](docs/done/2026-08-18-inkless-latest-tag-pin-kyverno-exclusion-removal.md)
  (PR #1217). (auto/inkless-latest-tag-pin-kyverno-exclusion-removal)

- [x] 🟢 **Bump kube-state-metrics chart `8.3.0` → `8.3.1`** — full verification
  writeup: [docs/done/2026-08-17-ksm-chart-8-3-1.md](docs/done/2026-08-17-ksm-chart-8-3-1.md)
  (PR #1204). (auto/ksm-chart-8-3-1)

- [x] 🟢 **Fix `scripts/git-fixture-isolation-check.sh` false-positive on
  `tests/forgejo-ci.bats`, breaking `main`'s CI** — full writeup:
  [docs/done/2026-08-17-git-fixture-isolation-check-false-positive-fix.md](docs/done/2026-08-17-git-fixture-isolation-check-false-positive-fix.md)
  (PR #1211). (auto/git-fixture-isolation-check-false-positive-fix)

- [x] 🟢 **Update `docs/dependency-register.md`'s GitLab row to a Forgejo row**
  — full writeup: [docs/done/2026-08-17-dependency-register-gitlab-to-forgejo.md](docs/done/2026-08-17-dependency-register-gitlab-to-forgejo.md)
  (PR #1209). (auto/dependency-register-gitlab-to-forgejo)

- [x] 🟢 **Bump ACK (AWS Controllers for Kubernetes) S3 chart `1.9.0` → `1.10.0`**
  — full verification writeup: [docs/done/2026-08-17-ack-s3-chart-1-10-0.md](docs/done/2026-08-17-ack-s3-chart-1-10-0.md)
  (PR #1203). (auto/ack-s3-chart-1-10-0)

- [x] 🟢 **`scripts/forgejo-runner-ensure.sh` bats coverage** →
  [docs/done/2026-08-17-forgejo-runner-ensure-bats-coverage.md](docs/done/2026-08-17-forgejo-runner-ensure-bats-coverage.md)
  (PR #1201)

- [x] 🟢 **`docker:29`/`docker:29-dind` CI-image exact-patch pin** →
  [docs/done/2026-08-17-docker-ci-image-explicit-pin.md](docs/done/2026-08-17-docker-ci-image-explicit-pin.md)
  (PR #1199)

- [x] 🟢 **GitLab CE `19.2.1-ce.0` → `19.2.2-ce.0` + `gitlab-runner` `v19.2.1` →
  `v19.2.2` (15 security fixes)** →
  [docs/done/2026-08-17-gitlab-19-2-2-security-bump.md](docs/done/2026-08-17-gitlab-19-2-2-security-bump.md)
  (PR #1197)

- [x] 🟢 **Valkey `8.0.10-alpine` → `8.1.9-alpine` — ADR-0018's flip condition met (two
  RCE-severity CVEs)** →
  [docs/done/2026-08-17-valkey-8-1-9-security-bump.md](docs/done/2026-08-17-valkey-8-1-9-security-bump.md)
  (PR #1195)

**GitLab → Forgejo migration (ADR-0035, 2026-08-11, superseding ADR-0033) — seven items
(originally six; item 4 split in two on 2026-08-11 per rule #9 below), work
top-to-bottom, each its own PR.** GitLab keeps running unmodified until the last item;
there is no point where the lab loses a working git source or CI path.

- [x] 🟢 **Forgejo compose stack, additive alongside GitLab** →
  [docs/done/2026-08-11-forgejo-compose-stack-roadmap-bookkeeping.md](docs/done/2026-08-11-forgejo-compose-stack-roadmap-bookkeeping.md)
  (PR #1105, bookkeeping PR #1106)
- [x] 🟢 **`infra/modules/forgejo-config` Terraform module** →
  [docs/done/2026-08-11-forgejo-config-terraform-module.md](docs/done/2026-08-11-forgejo-config-terraform-module.md)
  (PR #1107)
- [x] 🟢 **Port `.gitlab-ci.yml` → `.forgejo/workflows/build-sign-push.yml`** →
  [docs/done/2026-08-11-forgejo-ci-workflow.md](docs/done/2026-08-11-forgejo-ci-workflow.md)
  (PR #1108)
- [x] 🟢 **Wire ArgoCD's repo-credential Secret for the Forgejo remote (prep slice)** →
  [docs/done/2026-08-11-forgejo-argocd-repo-secret.md](docs/done/2026-08-11-forgejo-argocd-repo-secret.md)
  (PR #1110)
- [x] 🟢 **Flip `Application` `repoURL`s (including `root-app.yaml`) to the Forgejo
  remote, verify a real sync** — done 2026-08-17, accelerated per explicit user
  direction ("get rid of GitLab already... fix-forward") rather than waiting for
  item 3's still-outstanding live signed-push confirmation. Live-cluster session:
  flipped all 59 `repoURL:` occurrences across 58 `gitops/**/*.yaml` files plus
  `root-app.yaml` and the `argocd-repo-server` egress `NetworkPolicy` (renamed
  `allow-argocd-repo-server-egress-gitlab.yaml` →
  `-egress-forgejo.yaml`, port 8929→2223). Found and fixed a real bug blocking the
  whole cutover along the way: Forgejo's `GITEA__server__SSH_PORT` only sets the
  *advertised* clone-URL port, not what the container's sshd actually binds to —
  it was listening on 22 the whole time, so the `"2223:2223"` compose port mapping
  pointed at nothing. Fixed with an explicit `GITEA__server__SSH_LISTEN_PORT: "22"`
  + `"2223:22"` mapping; verified live via `git ls-remote` over SSH succeeding.
  Also found the Terraform-managed ArgoCD deploy key was missing from Forgejo's
  live DB (state/reality drift) and registered it directly via Forgejo's API as a
  stopgap — a `terraform plan`/`apply` for `infra/modules/forgejo-config` is still
  owed once its remote-state backend's credential issue (hit, not debugged, this
  session) is resolved. Applied live via `kubectl apply -f gitops/bootstrap/
  root-app.yaml` + `kubectl apply -f gitops/platform/ --server-side
  --force-conflicts` (ArgoCD's own sync operation stalled mid-flight under host
  load; the direct apply achieved the same end state deterministically). Verified:
  all 121 Applications' live `spec.source.repoURL` point at Forgejo; cluster health
  held at 106-107/121 Healthy throughout. (PR #1205)
- [x] 🟢 **Simulate Garage unavailability — third DR fault-injection drill
  (`make dr-garage-failure`)** →
  [docs/done/2026-08-18-dr-garage-failure-drill.md](docs/done/2026-08-18-dr-garage-failure-drill.md)
  (PR #1240)
- [x] 🟢 **Dependency exit runbooks for the lab's top concentration risks — closes
  DORA audit Q17's named gap** →
  [docs/done/2026-08-18-dependency-exit-runbooks.md](docs/done/2026-08-18-dependency-exit-runbooks.md)
  (PR #1242)
- [ ] 🟢 **Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh` + matching `Makefile`
  targets** (bootstrap, TLS bootstrap, push, force-push, `rebase-prs`' GitLab leg);
  `tests/gitlab-compose.bats`/`tests/gitlab-push.bats` → `forgejo-*` bats files with
  equivalent coverage (mechanical-guard parity, not a regression). Prerequisite item
  (repoURL flip) is now done and GitLab itself is stopped (2026-08-17, `make
  gitlab-down`) — these scripts are dead code pointing at a stopped service, so this
  is now safe/overdue, not merely unblocked.

  **Investigated 2026-08-17 (executor STEP 3 pickup, clusterless session) — NOT a
  mechanical rename; picking it up blind risks a broken `make up`. Still blocked:**
  the push auth model changes shape entirely (GitLab's HTTPS+PAT → Forgejo's SSH
  deploy key), Forgejo likely needs no TLS-bootstrap equivalent at all (plain HTTP,
  unlike GitLab), and `make up`'s bootstrap sequence still calls the GitLab targets
  outright — a live-cluster or otherwise better-verified session needs to design
  and verify the replacement end-to-end, not find-and-replace it blind. Full
  findings and recommendation:
  [docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md](docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md).
  Left unchecked rather than shipping a same-shaped-but-wrong rename (ADR-0004).
- [ ] 🟢 **Decommission `gitlab/docker-compose.yml` + `infra/modules/gitlab-config`** —
  GitLab is **stopped** as of 2026-08-17 (`make gitlab-down`, volumes kept for
  rollback) but not yet removed from the repo — deliberately kept a beat longer than
  the accelerated cutover above so there's a fast rollback path if Forgejo proves
  unstable over a real work cycle, matching how Artifactory's decommission followed
  (not preceded) Harbor's proven-live cutover
  (`docs/done/2026-07-29-harbor-artifactory-decommission.md`). Update
  `docs/dependency-register.md`'s GitLab row (currently flagged "still the live,
  running component") to a Forgejo row once this lands.

- [x] 🟢 **Add `make dependency-concentration-sync-check` — a mechanical `make ci`
  guard closing the "no mechanical drift guard yet" gap `docs/dependency-register.md`,
  `docs/dependency-concentration.md`, and `docs/dependency-exit-runbooks.md` each
  honestly flag in their own "Keeping this in sync" sections** — full verification
  writeup:
  [docs/done/2026-09-02-dependency-concentration-sync-check.md](docs/done/2026-09-02-dependency-concentration-sync-check.md).
  (auto/dependency-concentration-sync-check)
  (CHARTER **Core Values** §"Everything as code" (DORA audit readiness Q14/Q16/Q17);
  planner-fallback gap analysis 2026-09-02, this run's fifth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again this cycle and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
  TRIAGER all came up empty again. Fresh angle: rather than a fourth pass mining
  `docs/dora-audit-readiness.md` for another named prose gap, this cycle closed the
  "no mechanical drift guard yet" limitation those three docs each honestly
  self-flag — the exact CLAUDE.md bugfix-recurrence-prevention pattern (mechanical
  guard over a note to remember). **No prerequisites — executor may pick up
  immediately.**)

  Unlike `dependency-maintenance-check.sh` (network-dependent, deliberately kept
  out of `make ci`), this check is pure text-parsing over two already-committed
  docs — fast, deterministic, network-free — so it's wired directly into `make ci`
  and `.github/workflows/ci.yml`'s `drift` job. It counts how many
  `docs/dependency-register.md` rows share each `github.com` upstream org and fails
  if any org backing 2+ rows isn't named in `docs/dependency-concentration.md`.
  Extracted the shared table-parsing logic (`depreg_rows`/`depreg_github_match`)
  into `scripts/lib/dependency-register.sh` first, refactoring
  `dependency-maintenance-check.sh` to use it too, rather than let a second
  near-identical parser copy exist — the exact "two copies of a parser" class
  CLAUDE.md's de-duplication principle exists to catch, closed proactively before a
  third copy could appear. Added a matching `dependency-concentration-sync-hook.sh`
  (PostToolUse nudge, mirrors `dependency-register-sync-hook.sh`) plus bats coverage
  for the check, the shared lib, and the hook (`tests/dependency-concentration-sync-check.bats`,
  `tests/dependency-register-lib.bats`, `tests/hook-scripts-dependency-concentration-sync.bats`).
  `make ci` must pass. `docs/done/` entry required.
  (auto/dependency-concentration-sync-check)

- [x] 🟢 **Add `make dependency-exit-runbooks-sync-check` — a mechanical `make ci`
  guard closing the second half of the "no mechanical drift guard yet" gap between
  `docs/dependency-concentration.md` and `docs/dependency-exit-runbooks.md`** — full
  verification writeup:
  [docs/done/2026-09-02-dependency-exit-runbooks-sync-check.md](docs/done/2026-09-02-dependency-exit-runbooks-sync-check.md).
  (auto/dependency-exit-runbooks-sync-check)
  (CHARTER **Core Values** §"Everything as code" (DORA audit readiness Q14/Q16/Q17);
  planner-fallback gap analysis 2026-09-02, this run's sixth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated again this cycle and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
  TRIAGER all came up empty again. Fresh angle: the fifth cycle's
  `dependency-concentration-sync-check.sh` closed only half of the "no mechanical
  drift guard yet" gap (register rows -> named concentration groups); this cycle
  closes the other half (named concentration groups -> matching exit-runbook
  sections), rather than re-mining `docs/dora-audit-readiness.md` a fourth time.
  **No prerequisites — executor may pick up immediately.**)

  `scripts/dependency-exit-runbooks-sync-check.sh` parses every named
  `` `github.com/ORG` `` concentration-group header out of
  `docs/dependency-concentration.md` (currently three) and fails if
  `docs/dependency-exit-runbooks.md` has no matching section for one. Deliberately
  scoped to the three named concentration *groups* only, not the eleven-minus-four
  remaining single-tool rows the fourth cycle already documented as an intentional
  partial slice (not drift) — checking those would conflate "not yet covered by
  choice" with "out of sync by accident". Pure text-parsing, no network calls, wired
  directly into `make ci` and `.github/workflows/ci.yml`'s `drift` job. Added a
  matching `dependency-exit-runbooks-sync-hook.sh` (PostToolUse nudge, mirrors
  `dependency-concentration-sync-hook.sh`) plus bats coverage
  (`tests/dependency-exit-runbooks-sync-check.bats`,
  `tests/hook-scripts-dependency-exit-runbooks-sync.bats`). `make ci` must pass.
  `docs/done/` entry required. (auto/dependency-exit-runbooks-sync-check)

- [x] 🟢 **Extend `docs/dependency-exit-runbooks.md` (DORA audit Q17) to the four
  highest-blast-radius remaining single-tool rows — Cilium, Garage, Envoy Gateway,
  cert-manager** — full verification writeup:
  [docs/done/2026-09-02-dependency-exit-runbooks-single-tool-slice.md](docs/done/2026-09-02-dependency-exit-runbooks-single-tool-slice.md).
  (auto/dependency-exit-runbooks-single-tool-slice)
  (CHARTER **Core Values** §"Everything as code" (DORA audit readiness Q17);
  planner-fallback gap analysis 2026-09-02, this run's fourth cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated this cycle (same blockers as the three prior cycles this run) and
  PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER all came up empty
  again. Fresh angle: continued mining `docs/dora-audit-readiness.md` — this run's
  third pass over it — for another real, previously-untouched, explicitly-named
  gap. `docs/dependency-exit-runbooks.md`'s own "Scope of this slice" note already
  named the eleven remaining `always-on-core` single-tool rows as "real,
  separately-scoped future work if wanted" — picked the four highest actual
  blast-radius ones (CNI, storage, ingress, TLS) rather than all eleven, to stay
  within WAYS-OF-WORKING.md §3's size discipline, matching this file's own existing
  scoping precedent. **No prerequisites — executor may pick up immediately.**)

  Added four single-paragraph runbook entries (Cilium, Garage, Envoy Gateway,
  cert-manager) to `docs/dependency-exit-runbooks.md`, each covering the same
  ground as the existing three group entries (what a real exit changes
  mechanically, fork-and-repoint-or-a-real-migration, whether an exit-direction
  alternative has been evaluated — honestly "no" for all four, distinct from each
  ADR's own original rejected-alternative record) in a leaner one-paragraph shape
  since each is a single tool, not a multi-tool group. Verified each citation
  directly against the real gitops manifests and ADRs (not assumed): Cilium is
  Terraform-bootstrapped like ArgoCD, not a `gitops/` Application; Envoy Gateway is
  sourced via a Kustomize-vendored chart per its own header comment (the
  probe-timeout fix); cert-manager's ADR-0028 explicitly states no prior ADR
  evaluated or rejected an alternative (verified directly, not assumed). Updated
  the file's "Scope of this slice" note to name the four newly-covered rows and
  the seven still remaining. Added a bats assertion
  (`tests/dora-audit-readiness.bats`) confirming all four new entries are present.
  Updated `docs/dora-audit-readiness.md`'s own Q17 gap text (it previously listed
  all eleven remaining single-tool rows as un-covered — now stale/inaccurate for
  four of them, caught and fixed in the same pass rather than left stale,
  ADR-0004) to name the four newly-covered rows and the seven still remaining.
  `make ci` must
  pass. `docs/done/` entry required. (auto/dependency-exit-runbooks-single-tool-slice)

- [x] 🟢 **Close DORA audit Q7's named future-candidate gap — add a
  `VaultSealedDegraded` Grafana alert rule reading `vault_core_unsealed` directly** —
  full verification writeup:
  [docs/done/2026-09-02-vault-sealed-degraded-alert.md](docs/done/2026-09-02-vault-sealed-degraded-alert.md).
  (auto/vault-sealed-degraded-alert)
  (CHARTER **Core Values** §"Real observability only" (DORA audit readiness Q7);
  planner-fallback gap analysis 2026-09-02, this run's third cycle, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated this cycle (same GitLab→Forgejo/capstone-`Deployment` blockers as the two
  prior cycles this run) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
  TRIAGER all came up empty (no ungroomed intake, no un-RFC'd 🟡 item, digest already
  fresh from yesterday, register already current, `make ci` clean with no drift
  signal, all 3 open issues already fully labeled). Fresh angle this cycle: continued
  mining `docs/dora-audit-readiness.md` (the same document Q15's gap-closure came
  from two cycles ago) for another still-open, previously-untouched gap — Q7's own
  text explicitly named a concrete future candidate: "a new alert rule reading the
  now-scraped `vault_core_unsealed` directly could catch that gap if it proves worth
  closing." **No prerequisites — executor may pick up immediately.**)

  Added a sixth Grafana Unified Alerting rule (RFC #1084,
  `gitops/platform/observability-grafana.yaml`'s existing `valuesObject.alerting`
  block, immediately after `VaultPodNotReady`): `VaultSealedDegraded`, `for: 10m`,
  expr `vault_core_unsealed{job="vault"} == bool 0` (the `== bool 0` form is
  required, not just `== 0` — mirrors the file's own documented stateSet-metric
  gotcha: a plain `== 0` filter returns the matched sample's own value, which is 0,
  so a `gt 0` threshold could never fire; `bool` forces it to emit 1 on match). This
  is a direct, independent seal-state signal alongside `VaultPodNotReady`'s
  pod-readiness one — reads `vault_core_unsealed` from Vault's own telemetry
  (already scraped by `auto/vault-telemetry-scrape`, no new Alloy job needed), not
  dependent on whatever the pod's readiness probe happens to reflect about seal
  state (this remote clusterless session cannot verify that probe's exact live
  behavior either way, ADR-0004 — the new rule's value doesn't depend on it: it's a
  genuinely separate signal, not conditional on the first rule having a gap).
  Updated `tests/observability-alerting.bats` (new rule-presence assertion; the
  "five rules" `for`/datasource count assertions bumped to six) and
  `docs/dependency-tree.md`'s Grafana-alerting row. Updated
  `docs/dora-audit-readiness.md`'s Q7 answer/gap to describe six rules and cite the
  new one, narrowing (not fabricating closure of) the section's remaining gaps
  (escalation stays a non-goal; the CI-health metric still doesn't cover live-cluster
  incidents). `make ci` must pass. `docs/done/` entry required.
  (auto/vault-sealed-degraded-alert)

- [x] 🟢 **Close DORA audit Q15's named gap — add `make dependency-maintenance-check`,
  a re-checkable maintenance-health report for every `docs/dependency-register.md`
  row** — full verification writeup:
  [docs/done/2026-09-02-dependency-maintenance-check.md](docs/done/2026-09-02-dependency-maintenance-check.md).
  (auto/dependency-maintenance-check; PR #1375)

- [x] 🟢 **Bump Valkey image pin `8.1.9-alpine` → `8.1.10-alpine` — SECURITY
  release (GHSA-jcj7-v34w-v9vv), ADR-0018's own flip condition triggered** —
  full verification writeup:
  [docs/done/2026-09-01-valkey-8-1-10-security-bump.md](docs/done/2026-09-01-valkey-8-1-10-security-bump.md).
  (auto/valkey-8.1.10-security-bump; PR #1361)

- [x] 🟢 **GitHub→Forgejo pull-based, fast-forward-only sync workflow** — full
  verification writeup:
  [docs/done/2026-08-25-forgejo-github-sync-workflow.md](docs/done/2026-08-25-forgejo-github-sync-workflow.md).
  (auto/forgejo-github-sync-workflow; RFC #1340.) Closes #1340.
  (PR #1347 — the mirror's own placeholder resolved via GitHub search,
  confirmed `merged: true`.)

- [x] 🟢 **Bump Valkey's `redis_exporter` sidecar `v1.88.0-alpine` → `v1.89.0-alpine`**
  — full verification writeup:
  [docs/done/2026-08-13-redis-exporter-1-89-0.md](docs/done/2026-08-13-redis-exporter-1-89-0.md).
  (auto/redis-exporter-1-89-0; PR #1178)

- [x] 🟢 **Pin the TiDB demo's floating `nginx:alpine` tag to `nginx:1.31.3-alpine`**
  — full verification writeup:
  [docs/done/2026-08-13-tidb-demo-nginx-explicit-pin.md](docs/done/2026-08-13-tidb-demo-nginx-explicit-pin.md).
  (auto/tidb-demo-nginx-explicit-pin; PR #1180)

- [x] 🟢 **Bump Terraform-bootstrapped `argo-cd` chart `10.3.2` → `10.3.3` (appVersion
  `v3.5.0` → `v3.5.1`, real ArgoCD security/reliability fixes)** — full
  verification writeup:
  [docs/done/2026-08-13-argocd-chart-10-3-3.md](docs/done/2026-08-13-argocd-chart-10-3-3.md).
  (auto/argocd-chart-10-3-3; PR #1182)

- [x] 🟢 **Bump Tempo's pinned image `2.10.7` → `2.10.8` (real Go-stdlib + gRPC/otel
  security fixes)** — full verification writeup:
  [docs/done/2026-08-13-tempo-2-10-8.md](docs/done/2026-08-13-tempo-2-10-8.md).
  (auto/tempo-2-10-8; PR #1189)

- [x] 🟢 **Pin `gitlab/docker-compose.yml`'s `gitlab-tls` sidecar to `nginx:1.27.5-alpine`
  (currently the floating `1.27-alpine` tag)** — full verification writeup:
  [docs/done/2026-08-13-gitlab-tls-nginx-explicit-pin.md](docs/done/2026-08-13-gitlab-tls-nginx-explicit-pin.md).
  (auto/gitlab-tls-nginx-explicit-pin; PR #1191)

- [x] 🟢 **Vault pod-readiness alert rule — extend Grafana Unified Alerting (RFC #1084)**
  — full verification writeup:
  [docs/done/2026-08-11-vault-pod-readiness-alert.md](docs/done/2026-08-11-vault-pod-readiness-alert.md).
  (auto/vault-pod-readiness-alert; PR #1119)

- [x] 🟢 **Fix two Grafana Unified Alerting rules that can never fire — threshold-vs-stateSet-metric bug (RFC #1084 follow-up)**
  — full verification writeup:
  [docs/done/2026-08-13-alerting-threshold-bool-fix.md](docs/done/2026-08-13-alerting-threshold-bool-fix.md).
  (auto/alerting-threshold-bool-fix; PR #1187)

- [x] 🟢 **k3d containerd registry mirror — resolve `harbor.127.0.0.1.nip.io` in-cluster**
  — full verification writeup:
  [docs/done/2026-08-07-k3d-registry-mirror-harbor.md](docs/done/2026-08-07-k3d-registry-mirror-harbor.md).
  (auto/k3d-registry-mirror-harbor; PR #1080)

- [x] 🟢 **Bump Terraform-bootstrapped `argo-cd` chart `10.2.3` → `10.3.0`**
  — full verification writeup:
  [docs/done/2026-08-07-argocd-chart-10-3-0.md](docs/done/2026-08-07-argocd-chart-10-3-0.md).
  (auto/argocd-chart-10-3-0; PR #1056)

- [x] 🟢 **Bump Trivy Operator chart `0.34.0` → `0.35.0` (appVersion `0.32.0` →
  `0.33.0`, bundled Trivy scanner `0.72.0` → `0.73.0`)** — full verification
  writeup:
  [docs/done/2026-08-07-trivy-operator-chart-0-35-0.md](docs/done/2026-08-07-trivy-operator-chart-0-35-0.md).
  (auto/trivy-operator-chart-0-35-0; PR #1057)

- [x] 🟢 **Bump Grafana image tag `13.0.3` → `13.0.5` (security fix) + correct
  ADR-0006's stale Tempo pin citation** — full verification writeup:
  [docs/done/2026-08-06-grafana-image-13-0-5.md](docs/done/2026-08-06-grafana-image-13-0-5.md).
  (auto/grafana-image-13-0-5; PR #1044)

- [x] 🟢 **Bump Loki image `grafana/loki:3.7.5` → `3.7.6`** — full verification
  writeup:
  [docs/done/2026-08-06-loki-image-3-7-6.md](docs/done/2026-08-06-loki-image-3-7-6.md).
  (auto/loki-3-7-6; PR #1042)

- [x] 🟢 **Bump Loki image `grafana/loki:3.7.4` → `3.7.5`** — full verification
  writeup:
  [docs/done/2026-08-06-loki-image-3-7-5.md](docs/done/2026-08-06-loki-image-3-7-5.md).
  (auto/loki-image-3-7-5; PR #1033)

- [x] 🟢 **Bump `kube-state-metrics` chart `8.0.0` → `8.1.3`** — full
  verification writeup:
  [docs/done/2026-08-05-ksm-chart-8-1-3.md](docs/done/2026-08-05-ksm-chart-8-1-3.md).
  (auto/ksm-chart-8-1-3; PR #1023)

- [x] 🟢 **Pin Inkless's batch-coordinator `postgres` image explicitly —
  `postgres:17` → `postgres:17.10`** — full verification writeup:
  [docs/done/2026-08-05-inkless-postgres-explicit-pin.md](docs/done/2026-08-05-inkless-postgres-explicit-pin.md).
  (auto/inkless-postgres-explicit-pin; PR #1016)

- [x] 🟢 **Bump Vault's pinned image `hashicorp/vault:2.0.3` → `2.0.4` (server +
  unsealer)** — full verification writeup:
  [docs/done/2026-08-05-vault-image-2-0-4.md](docs/done/2026-08-05-vault-image-2-0-4.md).
  (auto/vault-image-2-0-4; PR #1011)

- [x] 🟢 **Bump `ack-s3` (AWS Controllers for Kubernetes S3 chart) `1.8.2` →
  `1.9.0`** — full verification writeup:
  [docs/done/2026-08-05-ack-s3-chart-1-9-0.md](docs/done/2026-08-05-ack-s3-chart-1-9-0.md).
  (auto/ack-s3-chart-1-9-0; PR #1009)

- [x] 🟢 **Bump k3s pin `v1.36.2+k3s1` → `v1.36.3+k3s1` on both backends** —
  full verification writeup:
  [docs/done/2026-08-05-k3s-1-36-3.md](docs/done/2026-08-05-k3s-1-36-3.md).
  (auto/k3s-1-36-3; PR #998) Closes #995.

- [x] 🟢 **Bump Terraform-bootstrapped `argo-cd` chart `10.2.2` → `10.2.3`** —
  full verification writeup:
  [docs/done/2026-08-05-argocd-chart-10-2-3.md](docs/done/2026-08-05-argocd-chart-10-2-3.md).
  (auto/argocd-chart-10-2-3; PR #993)

- [x] 🟢 **Bump `grafana` chart `12.10.2` → `12.10.3`** — full verification
  writeup:
  [docs/done/2026-08-05-grafana-chart-12-10-3.md](docs/done/2026-08-05-grafana-chart-12-10-3.md).
  (auto/grafana-chart-12-10-3; PR #991)

- [x] 🟢 **Bump `kiali-server` chart `2.29.0` → `2.30.0`** — full verification
  writeup:
  [docs/done/2026-08-04-kiali-chart-2-30-0.md](docs/done/2026-08-04-kiali-chart-2-30-0.md).
  (auto/kiali-chart-2-30-0; PR #970)

- [x] 🟢 **Bump Harbor chart `1.19.1` → `1.19.2`** — full verification writeup:
  [docs/done/2026-08-03-harbor-chart-1-19-2.md](docs/done/2026-08-03-harbor-chart-1-19-2.md).
  (auto/harbor-chart-1-19-2; PR #963)

- [x] 🟢 **Bump cert-manager chart `1.21.0` → `1.21.1`** — full verification
  writeup:
  [docs/done/2026-07-31-auto-cert-manager-chart-1-21-1.md](docs/done/2026-07-31-auto-cert-manager-chart-1-21-1.md).
  (auto/cert-manager-chart-1-21-1; PR #937) Closes #933.

- [x] 🟢 **Bump `kro` chart `0.9.2` → `0.9.3`** — full verification writeup:
  [docs/done/2026-07-30-kro-cve-bump-0-9-3.md](docs/done/2026-07-30-kro-cve-bump-0-9-3.md).
  (auto/kro-cve-bump-0-9-3; PR #901)

- [x] 🟢 **Lab — Istio ambient mesh (`istio-system`) observability wiring: Alloy
  scrape + Grafana dashboard** — full verification writeup:
  [docs/done/2026-07-28-istio-observability-dashboard.md](docs/done/2026-07-28-istio-observability-dashboard.md).
  (auto/istio-observability-dashboard; PR #824)

- [x] 🟢 **Bump Envoy Gateway chart `v1.8.2` → `v1.8.3`** — full verification
  writeup:
  [docs/done/2026-07-23-envoy-gateway-chart-1-8-3.md](docs/done/2026-07-23-envoy-gateway-chart-1-8-3.md).
  (auto/envoy-gateway-chart-1-8-3; PR #674) Closes #671.

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

- [x] 🟢 **Bump Valkey image tag `8.0-alpine` → `8.0.10-alpine`** — full
  verification writeup:
  [docs/done/2026-07-22-valkey-cve-bump-8-0-10.md](docs/done/2026-07-22-valkey-cve-bump-8-0-10.md).
  (auto/valkey-cve-bump-8-0-10; PR #658) Closes #655.

- [x] 🟢 **`docs/dora-resilience-mapping.md` — DORA (EU regulation) pillar
  mapping, explicitly not a compliance claim** — full verification writeup:
  [docs/done/2026-07-19-dora-resilience-mapping.md](docs/done/2026-07-19-dora-resilience-mapping.md).
  (auto/dora-resilience-mapping; PR #589) Closes #586.

- [x] 🟢 **`scripts/dora-metrics.sh` + `make dora-metrics` — DORA metrics from git/CI
  history** — full verification writeup:
  [docs/done/2026-07-19-dora-metrics.md](docs/done/2026-07-19-dora-metrics.md).
  (auto/dora-metrics; PR #584) Closes #580.

- [x] 🟢 **Replace the dead "idle issue" fallback across every routine prompt with a
  `[Action needed]` PR** — full verification writeup:
  [docs/done/2026-07-19-action-needed-pr-fallback.md](docs/done/2026-07-19-action-needed-pr-fallback.md).
  (auto/action-needed-pr-fallback; PR #578) Closes #569.

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

- [x] 🟢 **Bump Grafana image tag `13.0.1` → `13.0.3`** — full verification
  writeup:
  [docs/done/2026-07-19-grafana-cve-bump-13-0-3.md](docs/done/2026-07-19-grafana-cve-bump-13-0-3.md).
  (auto/grafana-cve-bump-13-0-3; PR #566) Closes #563.

- [x] 🟢 **Pin k3s to an explicit version on every backend** — full verification
  writeup:
  [docs/done/2026-07-19-k3s-version-pin.md](docs/done/2026-07-19-k3s-version-pin.md).
  (auto/k3s-version-pin; PR #561) Closes #558.

- [x] 🟢 **Bump Argo Rollouts image tag `v1.9.0` → `v1.9.1`** — full
  verification writeup:
  [docs/done/2026-07-19-argo-rollouts-cve-image-tag.md](docs/done/2026-07-19-argo-rollouts-cve-image-tag.md).
  (auto/argo-rollouts-cve-image-tag; PR #555) Closes #552.

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

- [x] 🟢 **Bump Cilium `1.16.6` → `1.17.18`** — full verification writeup:
  [docs/done/2026-07-18-cilium-cve-bump.md](docs/done/2026-07-18-cilium-cve-bump.md).
  (auto/cilium-cve-bump-1-17-18; PR #505) Closes #501.

- [x] 🟢 **Bump Kargo `1.2.3` → `1.6.4`** — full verification writeup:
  [docs/done/2026-07-18-kargo-cve-bump-and-fixes.md](docs/done/2026-07-18-kargo-cve-bump-and-fixes.md).
  (auto/kargo-cve-bump-1-6-4; PR #511) Closes #508.

- [x] 🟢 **Bump Kargo `1.6.4` → `1.10.9`** — full verification writeup:
  [docs/done/2026-07-18-kargo-cve-bump-1-10-9.md](docs/done/2026-07-18-kargo-cve-bump-1-10-9.md).
  (auto/kargo-cve-bump-1-10-9; PR #549)

- [x] 🟢 **`kyverno` PSA `baseline` → `restricted` flip** — full verification
  writeup:
  [docs/done/2026-07-17-kyverno-psa-restricted.md](docs/done/2026-07-17-kyverno-psa-restricted.md).
  (auto/kyverno-psa-restricted; PR #486) Closes #483.

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

- [x] 🟢 **Governance LimitRange fan-out — `cert-manager` + `keda`** — full
  verification writeup:
  [docs/done/2026-07-16-governance-cert-manager-keda.md](docs/done/2026-07-16-governance-cert-manager-keda.md).
  (auto/governance-cert-manager-keda; PR #451)

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

- [x] 🟢 **`observability` readOnlyRootFilesystem tighten — Pyroscope** — full
  verification writeup:
  [docs/done/2026-07-15-observability-readonlyrootfs-pyroscope.md](docs/done/2026-07-15-observability-readonlyrootfs-pyroscope.md).
  (auto/observability-readonlyrootfs-pyroscope; PR #415)

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

- [x] 🟢 **Kyverno engine + observability** — full verification writeup:
  [docs/done/auto-kyverno-engine.md](docs/done/auto-kyverno-engine.md)
  (PR #170). (auto/kyverno-engine)

- [x] 🟢 **Kyverno initial ClusterPolicies (validate + mutate +
  verifyImages)** — full verification writeup:
  [docs/done/legacy-kyverno-initial-clusterpolicies-validate-mutate-verifyimages.md](docs/done/legacy-kyverno-initial-clusterpolicies-validate-mutate-verifyimages.md)
  (PR #177). (auto/kyverno-policies)

- [x] 🟢 **cosign-bootstrap.sh day-0 seam (key generation +
  ConfigMap)** — full verification writeup:
  [docs/done/auto-cosign-bootstrap-script.md](docs/done/auto-cosign-bootstrap-script.md)
  (PR #178). (auto/cosign-bootstrap-script)

- [x] 🟢 **Velero controller + Garage S3 backend** — full verification writeup:
  [docs/done/2026-06-12-velero-controller.md](docs/done/2026-06-12-velero-controller.md)
  (PR #189). (auto/velero-controller)

- [x] 🟢 **Velero Schedules — four stateful namespaces** — full verification
  writeup:
  [docs/done/2026-06-13-velero-schedules.md](docs/done/2026-06-13-velero-schedules.md)
  (PR #198). (auto/velero-schedules)

- [x] 🟢 **make dr-restore + scripts/dr-restore.sh — Objective O3 enabler** —
  full verification writeup:
  [docs/done/2026-06-13-dr-restore-script.md](docs/done/2026-06-13-dr-restore-script.md)
  (PR #199). (auto/dr-restore-script)

- [x] 🟢 **Argo Rollouts controller** — full verification writeup:
  [docs/done/2026-06-13-argo-rollouts-controller.md](docs/done/2026-06-13-argo-rollouts-controller.md)
  (PR #190). (auto/argo-rollouts-controller)

- [x] 🟢 **Capstone Rollout overlay + success-rate AnalysisTemplate** — full
  verification writeup:
  [docs/done/2026-06-13-capstone-rollout.md](docs/done/2026-06-13-capstone-rollout.md)
  (PR #200). (auto/capstone-rollout)

- [x] 🟢 **Trivy Operator continuous scanning + SBOMs** — full
  verification writeup:
  [docs/done/auto-trivy-operator.md](docs/done/auto-trivy-operator.md)
  (PR #183). (auto/trivy-operator)

- [x] 🟢 **ADR-0017 amendment — four Tier 1 next-wave namespace
  rows** — full verification writeup:
  [docs/done/2026-06-12-auto-adr-0017-next-wave-rows.md](docs/done/2026-06-12-auto-adr-0017-next-wave-rows.md)
  (PR #184). (auto/adr-0017-next-wave-rows)

- [x] 🟢 **Lab — Cloud control-plane (moto / ACK / KRO)
  dashboard** — full verification writeup:
  [docs/done/2026-06-13-cloud-control-plane-dashboard.md](docs/done/2026-06-13-cloud-control-plane-dashboard.md)
  (PR #201). (auto/cloud-control-plane-dashboard)

- [x] 🟢 **PSS-restricted fan-out — `moto` + `ack-system`
  namespaces + `lab-gateway` labels** — full verification writeup:
  [docs/done/2026-06-14-pss-moto-ack-labgateway.md](docs/done/2026-06-14-pss-moto-ack-labgateway.md)
  (PR #202). (auto/pss-moto-ack-labgateway)

- [x] 🟢 **NetworkPolicy fan-out — `tidb` + `tidb-admin`
  namespaces** — full verification writeup:
  [docs/done/2026-06-14-networkpolicy-tidb-fanout.md](docs/done/2026-06-14-networkpolicy-tidb-fanout.md)
  (PR #203). (auto/networkpolicy-tidb-fanout)

- [x] 🟢 **Argo Rollouts dashboard + Alloy scrape job** — full verification
  writeup:
  [docs/done/2026-06-15-argo-rollouts-dashboard.md](docs/done/2026-06-15-argo-rollouts-dashboard.md).
  (auto/argo-rollouts-dashboard; PR #211)

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

- [x] 🟢 **External Secrets dashboard + Alloy scrape** — full verification
  writeup:
  [docs/done/2026-06-19-external-secrets-dashboard.md](docs/done/2026-06-19-external-secrets-dashboard.md).
  (auto/external-secrets-dashboard; PR #234)

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

- [x] 🟢 **NetworkPolicy fan-out — `envoy-gateway-system` namespace** — full
  verification writeup:
  [docs/done/2026-06-16-envoy-gateway-system-networkpolicy.md](docs/done/2026-06-16-envoy-gateway-system-networkpolicy.md).
  (auto/envoy-gateway-system-networkpolicy; PR #219)

- [x] 🟢 **cosign-bootstrap wiring into `make up`** — full verification
  writeup:
  [docs/done/2026-06-17-cosign-make-up-wiring.md](docs/done/2026-06-17-cosign-make-up-wiring.md)
  (PR #222). (auto/cosign-make-up-wiring)

- [x] 🟢 **`cosign sign` stage in `.gitlab-ci.yml`** — full verification
  writeup:
  [docs/done/2026-06-17-cosign-ci-sign-step.md](docs/done/2026-06-17-cosign-ci-sign-step.md)
  (PR #223). (auto/cosign-ci-sign-step)

- [x] 🟢 **`make capstone-demo` + `scripts/capstone-demo.sh`** — full
  verification writeup:
  [docs/done/2026-06-18-capstone-demo-target.md](docs/done/2026-06-18-capstone-demo-target.md)
  (PR #225). (auto/capstone-demo-target)

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

- [x] 🟢 **zz-dns-clusterip-bridge — bring out-of-band CNPs under GitOps** —
  full verification writeup:
  [docs/done/2026-07-02-gitops-clusterip-bridge.md](docs/done/2026-07-02-gitops-clusterip-bridge.md).
  (auto/gitops-clusterip-bridge; PR #324) Closes #315.

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

- [x] 🟢 **cert-manager engine + self-signed root CA bootstrap** — full
  verification writeup:
  [docs/done/2026-07-16-cert-manager-engine.md](docs/done/2026-07-16-cert-manager-engine.md)
  (PR #439). (auto/cert-manager-engine)

- [x] 🟢 **Gateway HTTPS listener + wildcard Certificate + frontdoor `:8443` port
  mapping** — full verification writeup:
  [docs/done/2026-07-16-cert-manager-gateway-https.md](docs/done/2026-07-16-cert-manager-gateway-https.md).
  (auto/cert-manager-gateway-https; PR #440)

- [x] 🟢 **KEDA event-driven autoscaling engine** — full verification writeup:
  [docs/done/2026-07-16-keda-engine.md](docs/done/2026-07-16-keda-engine.md).
  (auto/keda-engine; PR #444)

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

- [x] 🟢 **KEDA `ScaledObject` demo — scale `rabbitmq-load` on RabbitMQ queue
  depth** — full verification writeup:
  [docs/done/2026-07-17-keda-scaledobject-demo.md](docs/done/2026-07-17-keda-scaledobject-demo.md).
  (auto/keda-scaledobject-demo; PR #459)

- [x] 🟢 **`disallow-latest-tag` ClusterPolicy — exclude the `capstone`
  namespace** — full verification writeup:
  [docs/done/2026-07-18-capstone-latest-tag-exclude.md](docs/done/2026-07-18-capstone-latest-tag-exclude.md).
  (auto/capstone-latest-tag-exclude; PR #500) Closes #498.

- [x] 🟢 **Bump RabbitMQ `3.13` → `4.3.x`** — full verification writeup:
  [docs/done/2026-07-18-rabbitmq-bump-4x.md](docs/done/2026-07-18-rabbitmq-bump-4x.md).
  (auto/rabbitmq-bump-4x; PR #525) Closes #522.

- [x] 🟢 **Bump Longhorn `1.7.3` → `1.11.x`** — full verification writeup:
  [docs/done/2026-07-18-longhorn-bump-1-11.md](docs/done/2026-07-18-longhorn-bump-1-11.md).
  (auto/longhorn-bump-1-11; PR #531) Closes #528.

- [x] 🟢 **Bump KRO chart `0.4.1` → `0.9.x` — verify CRD/instance-scope
  compatibility first** — full verification writeup:
  [docs/done/2026-07-18-kro-bump-0-9.md](docs/done/2026-07-18-kro-bump-0-9.md).
  (auto/kro-bump-0-9; PR #537) Closes #534.

- [x] 🟢 **Migrate Grafana chart source off the deprecated
  `grafana.github.io/helm-charts` repo** — full verification writeup:
  [docs/done/2026-07-18-grafana-chart-source-migration.md](docs/done/2026-07-18-grafana-chart-source-migration.md).
  (auto/grafana-chart-source-migration; PR #547) Closes #544.

- [x] 🟢 **Pin Vault's server image tag explicitly** — full verification
  writeup:
  [docs/done/2026-07-24-vault-server-image-tag-pin.md](docs/done/2026-07-24-vault-server-image-tag-pin.md).
  (auto/vault-server-image-tag-pin; PR #699)

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
  `scripts/lib/frozen-monolith-check.sh` + `frozen-monolith-sync-hook.sh`** —
  full verification writeup:
  [docs/done/2026-07-31-auto-frozen-monolith-lib-test-coverage.md](docs/done/2026-07-31-auto-frozen-monolith-lib-test-coverage.md).
  (auto/frozen-monolith-lib-test-coverage; PR #954)

- [x] 🟢 **Name O3's RPO target explicitly in CHARTER.md** — full
  verification writeup:
  [docs/done/2026-08-07-charter-o3-rpo-target.md](docs/done/2026-08-07-charter-o3-rpo-target.md).
  (auto/charter-o3-rpo-target; PR #1060)

- [x] 🟢 **Pin `gitlab-ce`/`gitlab-runner` to explicit versions (currently
  `:latest`)** — full verification writeup:
  [docs/done/2026-08-07-gitlab-version-pin.md](docs/done/2026-08-07-gitlab-version-pin.md).
  (auto/gitlab-version-pin; PR #1075)

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
  — full verification writeup:
  [docs/done/2026-08-10-external-secrets-chart-2-9-0.md](docs/done/2026-08-10-external-secrets-chart-2-9-0.md).
  (auto/external-secrets-chart-2-9-0; PR #1081)

- [x] 🟢 **Bump Pyroscope chart `2.2.0` → `2.2.1` (upstream security release)**
  — full verification writeup:
  [docs/done/2026-08-10-pyroscope-chart-2-2-1.md](docs/done/2026-08-10-pyroscope-chart-2-2-1.md).
  (auto/pyroscope-chart-2-2-1; PR #1082)

- [x] 🟢 **Grafana Unified Alerting — four rules for known failure conditions** —
  full verification writeup:
  [docs/done/2026-08-10-grafana-alerting-rules.md](docs/done/2026-08-10-grafana-alerting-rules.md).
  (auto/grafana-alerting-rules; PR #1087) Closes #1084.

- [x] 🟢 **verifyImages ClusterPolicy — Audit → Enforce flip** — full
  verification writeup:
  [docs/done/2026-08-18-cosign-enforce-flip.md](docs/done/2026-08-18-cosign-enforce-flip.md).
  (auto/cosign-enforce-flip; PR #1223) Closes #631.

- [x] 🟢 **Lab — Grafana Alloy self-monitoring dashboard + self-scrape** —
  full verification writeup:
  [docs/done/2026-06-20-auto-alloy-self-monitoring.md](docs/done/2026-06-20-auto-alloy-self-monitoring.md).
  (auto/alloy-self-monitoring; PR #241)

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

- [x] 🟢 **PSA baseline + NetworkPolicy — `inkless` namespace** — full
  verification writeup:
  [docs/done/2026-06-23-pss-np-inkless.md](docs/done/2026-06-23-pss-np-inkless.md)
  (component later removed entirely, PR #1424, per Aiven Inkless's retirement
  — this is a historical record of completed work, not live state; kept per
  this repo's convention of leaving completed-item history accurate even
  after later removal, same as every other retired component).
  (auto/pss-np-inkless; PR #260)

- [x] 🟢 **Lab — `demo` + `data-demo` dashboards (O5 completion)** — full
  verification writeup:
  [docs/done/2026-06-24-demo-data-demo-dashboards.md](docs/done/2026-06-24-demo-data-demo-dashboards.md).
  (auto/demo-data-demo-dashboards; PR #264)

- [x] 🟢 **`docs/00-architecture.md` — current-state rewrite** — full
  verification writeup:
  [docs/done/2026-06-25-auto-architecture-doc-rewrite.md](docs/done/2026-06-25-auto-architecture-doc-rewrite.md).
  (auto/architecture-doc-rewrite; PR #273)

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

- [x] 🟢 **PSS `privileged` labels + NetworkPolicy — `longhorn-system`** — full
  verification writeup:
  [docs/done/2026-06-27-pss-np-longhorn.md](docs/done/2026-06-27-pss-np-longhorn.md).
  (auto/pss-np-longhorn; PR #284)

- [x] 🟢 **PSS `privileged` labels + NetworkPolicy — `istio-system`** — full
  verification writeup:
  [docs/done/2026-06-27-pss-np-istio-system.md](docs/done/2026-06-27-pss-np-istio-system.md).
  (auto/pss-np-istio-system; PR #285)

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

- [x] 🟢 **PSA `baseline` labels + NetworkPolicy — `artifactory` namespace** —
  full verification writeup:
  [docs/done/2026-06-29-auto-pss-np-artifactory.md](docs/done/2026-06-29-auto-pss-np-artifactory.md).
  (auto/pss-np-artifactory; PR #298)

- [x] 🟢 **NetworkPolicy extensions — Kiali allows in `istio-system`** — full
  verification writeup:
  [docs/done/2026-06-29-kiali-np-istio-system.md](docs/done/2026-06-29-kiali-np-istio-system.md).
  (auto/kiali-np-istio-system; PR #299)

- [x] 🟢 **O4 CI gate — `verify-image-rejection` job** — full verification
  writeup:
  [docs/done/2026-08-18-o4-ci-rejection-gate.md](docs/done/2026-08-18-o4-ci-rejection-gate.md).
  (auto/o4-ci-rejection-gate; PR #1224)

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

- [x] 🟢 **Harbor on-demand Application + namespace + Envoy route** — full
  verification writeup:
  [docs/done/2026-06-30-harbor-application.md](docs/done/2026-06-30-harbor-application.md).
  (auto/harbor-application; PR #306)

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

- [x] 🟢 **Lab — Harbor OCI registry dashboard + observability metrics** —
  full verification writeup:
  [docs/done/2026-07-01-auto-harbor-observability-dashboard.md](docs/done/2026-07-01-auto-harbor-observability-dashboard.md)
  (corrected 2026-09-05: that file's own `## PR` section cited the wrong
  number, #318 — the actual, real, `merged: true` PR is #316, verified via
  the GitHub API and cross-checked against #318's own body, which is a
  distinct, unrelated planner PR; the mirror file has been fixed in the same
  commit as this trim).
  (auto/harbor-observability-dashboard; PR #316)

- [x] 🟢 **Lab — Kargo promotion-pipeline dashboard + observability metrics** —
  full verification writeup:
  [docs/done/2026-07-01-auto-kargo-observability-dashboard.md](docs/done/2026-07-01-auto-kargo-observability-dashboard.md).
  (auto/kargo-observability-dashboard; PR #317)

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

- [x] 🟢 **Capstone pipeline re-wire — Artifactory → Harbor registry host** —
  full verification writeup:
  [docs/done/2026-07-29-harbor-capstone-rewire.md](docs/done/2026-07-29-harbor-capstone-rewire.md).
  (auto/harbor-capstone-rewire; PR #885)

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

- [x] 🟢 **Harbor governance LimitRange** — full verification writeup:
  [docs/done/2026-07-03-auto-harbor-governance-limitrange.md](docs/done/2026-07-03-auto-harbor-governance-limitrange.md).
  (auto/harbor-governance-limitrange; PR #327)

- [x] 🟢 **O5 dashboard-coverage bats — always-on service apps** — full
  verification writeup:
  [docs/done/2026-07-04-auto-o5-dashboard-coverage-bats.md](docs/done/2026-07-04-auto-o5-dashboard-coverage-bats.md).
  (auto/o5-dashboard-coverage-bats; PR #328)

- [x] 🟢 **NetworkPolicy bats fan-out — Tier-1 wave overlays** — full
  verification writeup:
  [docs/done/2026-07-04-networkpolicy-tier1-bats.md](docs/done/2026-07-04-networkpolicy-tier1-bats.md).
  (auto/networkpolicy-tier1-bats; PR #329)

- [x] 🟢 **Lab — TiDB on-demand Alloy scrape + dashboard** — full verification
  writeup:
  [docs/done/2026-07-05-auto-tidb-dashboard.md](docs/done/2026-07-05-auto-tidb-dashboard.md).
  (auto/tidb-dashboard; PR #332)

- [x] 🟢 **Lab — Longhorn on-demand Alloy scrape + dashboard** — full
  verification writeup:
  [docs/done/2026-07-05-auto-longhorn-dashboard.md](docs/done/2026-07-05-auto-longhorn-dashboard.md).
  (auto/longhorn-dashboard; PR #333)

- [x] 🟢 **O2 measurement — per-scope PSS bats for 5 Tier-1 wave namespaces** —
  full verification writeup:
  [docs/done/2026-07-06-auto-securitycontext-tier1-bats.md](docs/done/2026-07-06-auto-securitycontext-tier1-bats.md).
  (auto/securitycontext-tier1-bats; PR #335)

- [x] 🟢 **O2 measurement — per-scope NP bats for 3 late-addition
  namespaces** — full verification writeup:
  [docs/done/2026-07-06-auto-networkpolicy-tier1-bats-wave2.md](docs/done/2026-07-06-auto-networkpolicy-tier1-bats-wave2.md).
  (auto/networkpolicy-tier1-bats-wave2; PR #336)

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

- [x] 🟢 **PSA `restricted` labels — `capstone-pipeline` namespace** — full
  verification writeup:
  [docs/done/2026-07-09-auto-capstone-pipeline-psa.md](docs/done/2026-07-09-auto-capstone-pipeline-psa.md).
  (auto/capstone-pipeline-psa; PR #354)

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

- [x] 🟢 **Chaos / fault-injection drill — `make dr-chaos`** — full verification
  writeup:
  [docs/done/2026-08-04-dr-chaos-fault-injection.md](docs/done/2026-08-04-dr-chaos-fault-injection.md).
  (auto/dr-chaos-fault-injection; PR #975)

- [x] 🟢 **Third-party dependency register — `docs/dependency-register.md`**
  — full verification writeup:
  [docs/done/2026-08-04-dependency-register.md](docs/done/2026-08-04-dependency-register.md).
  (auto/dependency-register; PR #977)

- [x] 🟢 **Incident classification (severity) scheme + incident log** — full
  verification writeup:
  [docs/done/2026-08-04-incident-severity-scheme-log.md](docs/done/2026-08-04-incident-severity-scheme-log.md).
  (auto/incident-severity-scheme-log; PR #973)

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

- [x] 🟢 **Extract shared `ok()`/`bad()` helpers to `scripts/lib/colors.sh`;
  add a recurrence guard** (janitor finding, issue #957) — full writeup:
  [docs/done/2026-08-03-ok-bad-lib-extract.md](docs/done/2026-08-03-ok-bad-lib-extract.md).
  (auto/ok-bad-lib-extract)

- [x] 🟢 **`capstone-pipeline` governance LimitRange — RFC #294 fan-out
  completion** — full writeup:
  [docs/done/2026-07-26-governance-capstone-pipeline-limitrange.md](docs/done/2026-07-26-governance-capstone-pipeline-limitrange.md).
  (auto/governance-capstone-pipeline)

- [x] 🟢 **O5 bats gap — `lab-argocd.json` + `lab-gitsync.json` in
  `tests/dashboard-coverage.bats`** — full writeup:
  [docs/done/2026-07-11-o5-argocd-gitsync-coverage-bats.md](docs/done/2026-07-11-o5-argocd-gitsync-coverage-bats.md).
  (auto/o5-argocd-gitsync-coverage-bats)

- [x] 🟢 **Governance gap — add `envoy-gateway-system` and `node-exporter`
  to the platform governance ApplicationSet** — full writeup:
  [docs/done/2026-07-11-auto-governance-envoy-node-exporter.md](docs/done/2026-07-11-auto-governance-envoy-node-exporter.md).
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

- [x] 🟢 **Cilium agent Prometheus metrics + O5 CNI dashboard** — full
  verification writeup:
  [docs/done/2026-07-12-auto-cilium-agent-metrics.md](docs/done/2026-07-12-auto-cilium-agent-metrics.md).
  (auto/cilium-agent-metrics; PR #367)

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
  `scripts/adr-followup-check.sh` to catch the parenthetical form** — full
  verification writeup:
  [docs/done/2026-07-19-adr-followup-parenthetical-form.md](docs/done/2026-07-19-adr-followup-parenthetical-form.md).
  (auto/adr-followup-parenthetical-form; PR #601)

- [x] 🟢 **GitHub Actions major-version bumps — `actions/checkout` v4.3.0→v7.0.0,
  `actions/cache` v4.3.0→v6.1.0, `actions/github-script` v7.0.1→v9.0.0,
  `hashicorp/setup-terraform` v3.1.2→v4.0.1** — full verification writeup:
  [docs/done/2026-07-20-github-actions-node24-bump.md](docs/done/2026-07-20-github-actions-node24-bump.md).
  (auto/github-actions-node24-bump; PR #614) Closes #611.

- [x] 🟢 **Velero chart major bump `8.7.2` → `12.1.0`** — full verification
  writeup:
  [docs/done/2026-07-20-velero-chart-bump-12-1-0.md](docs/done/2026-07-20-velero-chart-bump-12-1-0.md).
  (auto/velero-chart-bump-12-1-0; PR #620) Closes #617.

- [x] 🟢 **Bump Cilium chart `1.17.18` → `1.18.12`** — full verification
  writeup:
  [docs/done/2026-07-30-cilium-1-18-12-bump.md](docs/done/2026-07-30-cilium-1-18-12-bump.md).
  (auto/cilium-1-18-12-bump; PR #920) Closes #917.

- [x] 🟢 **DR/capstone-demo results-history log — track pass/fail + elapsed
  time per run over time** — full verification writeup:
  [docs/done/2026-08-11-dr-results-log.md](docs/done/2026-08-11-dr-results-log.md).
  (auto/dr-results-log; PR #1125)

- [x] 🟢 **Vault internal telemetry — `sys/metrics` scrape + dashboard depth** —
  full verification writeup:
  [docs/done/2026-08-11-vault-telemetry-scrape.md](docs/done/2026-08-11-vault-telemetry-scrape.md).
  (auto/vault-telemetry-scrape; PR #1127)

- [x] 🟢 **Loki / Tempo / Pyroscope operational-health dashboards — O5 gap** —
  full verification writeup:
  [docs/done/2026-08-11-lgtmp-health-dashboards.md](docs/done/2026-08-11-lgtmp-health-dashboards.md).
  (auto/lgtmp-health-dashboards; PR #1131)

- [x] 🟢 **Stateless-surface criticality tiering — closes DORA audit Q2's named gap**
  — full verification writeup:
  [docs/done/2026-08-12-stateless-criticality-tiers.md](docs/done/2026-08-12-stateless-criticality-tiers.md).
  (auto/stateless-criticality-tiers; PR #1133)

- [x] 🟢 **Third-party dependency concentration-risk rollup — closes DORA audit Q16's
  named gap** — full verification writeup:
  [docs/done/2026-08-12-dependency-concentration-rollup.md](docs/done/2026-08-12-dependency-concentration-rollup.md).
  (auto/dependency-concentration-rollup; PR #1163)

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

- ~~🟡 **GitHub↔Forgejo git-history divergence — needs an architect decision on
  sync strategy**~~ (issue #1335; RFC #1340 — architect decision 2026-08-25:
  build a scheduled, pull-based, fast-forward-only Forgejo Actions sync job
  plus a CLAUDE.md working-agreement rule; no new/superseding ADR needed.)
  **Groomed ↗** into a 🟢 item in *Now / next* above (`auto/forgejo-github-sync-workflow`),
  planner-fallback run 2026-08-25 — the one-time 118-vs-38 history
  reconciliation itself stays tracked separately via standing
  `[Action required]` issue #1345 (out of scope for the sync-workflow item;
  needs a live-cluster session with real Forgejo network access).

- ~~🟡 **`argo-cd` Helm chart major bump — `9.7.1` → `10.x`**~~ (issue #781; RFC #785 —
  architect decision 2026-07-28: **Approve**, chart `10.2.1`, with a required
  `global.networkPolicy.create: false` companion override.) **Groomed ↗** into a 🟢
  item in *Now / next* above (`auto/argocd-chart-10x-bump`), planner run 2026-07-28.

- [x] 🟢 **`kube-state-metrics` chart major bump — `7.8.1` → `8.0.0`** — full
  verification writeup:
  [docs/done/2026-07-24-ksm-chart-8-0-0.md](docs/done/2026-07-24-ksm-chart-8-0-0.md).
  (issue #704; RFC #707; auto/ksm-chart-8-0-0; PR #710) Closes #707.

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

- [x] 🟢 **`infra/modules/oracle-k3s-cluster` Terraform module** (RFC #377 item 1
  — ADR-0027 is the binding spec) — full writeup:
  [docs/done/2026-07-13-oracle-k3s-cluster-module.md](docs/done/2026-07-13-oracle-k3s-cluster-module.md).
  (auto/oracle-k3s-cluster-module)

- [x] 🟢 **`infra/live/oracle/{cluster,argocd,gitlab}/terragrunt.hcl`** (RFC #377
  item 2) — full writeup:
  [docs/done/2026-07-13-oracle-live-units.md](docs/done/2026-07-13-oracle-live-units.md).
  (auto/oracle-live-units)

- [x] 🟢 **Second off-cluster Garage state store for the `oracle` backend, on a
  separate Always Free AMD Micro instance** (RFC #377 item 3) — full writeup:
  [docs/done/2026-07-13-oracle-tfstate.md](docs/done/2026-07-13-oracle-tfstate.md).
  (auto/oracle-tfstate)

- [x] 🟢 **`tests/oracle-cluster.bats`** (RFC #377 item 4) — full writeup:
  [docs/done/2026-07-13-oracle-cluster-bats.md](docs/done/2026-07-13-oracle-cluster-bats.md).
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
  `oracle/` backend** — full verification writeup:
  [docs/done/2026-07-13-oracle-backend-docs.md](docs/done/2026-07-13-oracle-backend-docs.md)
  (PR #384). (RFC #377 item 5)

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
