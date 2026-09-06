# ROADMAP

The backlog for **k8s-lab**, derived from [CHARTER.md](CHARTER.md) (the north-star this
is projected from) and worked by one scheduled routine: the **executor**, which fires
several times a day (see `routines/routines.yaml` for the current cadence) and
implements ROADMAP items back-to-back for as long as each run continues (STEP 8's loop
— no longer one item per run). The **planner** that proposes items here (plan-only PRs)
has no cron of its own anymore — the executor invokes it as a fallback role (STEP 6b)
whenever its own lane runs dry, which can happen more than once in a single run. CHARTER
= the goals; this file = the next steps.

The always-on stack is already built (Traefik, Vault, External Secrets, Garage,
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
  (auto/roadmap-legacy-item-trim-batch6; PR #1415)

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 5** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md).
  (auto/roadmap-legacy-item-trim-batch5; PR #1414)

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 4** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md).
  (auto/roadmap-legacy-item-trim-batch4; PR #1413)

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 3** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md).
  (auto/roadmap-legacy-item-trim-batch3; PR #1412)

- [x] 🟢 **docs/done/ PR-link integrity fix — 80 files + mechanical guard
  hardened** — full verification writeup:
  [docs/done/2026-09-04-docs-done-pr-link-integrity-fix.md](docs/done/2026-09-04-docs-done-pr-link-integrity-fix.md).
  (auto/docs-done-pr-link-integrity-fix; PR #1411)

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — batch 2** — full verification
  writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md).
  (auto/roadmap-legacy-item-trim-batch2; PR #1410)

- [x] 🟢 **ROADMAP.md legacy `[x]` item trim — pilot batch (RFC #377 Oracle
  items)** — full verification writeup:
  [docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md).
  (auto/roadmap-legacy-item-trim-pilot; PR #1409)

- [x] 🟢 **Oldest dependency-register rows re-swept — Garage, RabbitMQ, Tempo
  confirmed clean; Forgejo unreachable** — full verification writeup:
  [docs/done/2026-09-04-oldest-register-rows-resweep-clean.md](docs/done/2026-09-04-oldest-register-rows-resweep-clean.md).
  (auto/oldest-register-rows-resweep-clean; PR #1407)

- [x] 🟢 **Pyroscope currency re-check — app `v2.3.0` exists, no matching
  chart release yet, kept at `2.2.1`** — full verification writeup:
  [docs/done/2026-09-04-pyroscope-currency-recheck-kept.md](docs/done/2026-09-04-pyroscope-currency-recheck-kept.md).
  (auto/pyroscope-currency-recheck-kept; PR #1406)

- [x] 🟢 **Issue #1229 wrongly closed alongside PR #1403 — reopened, ROADMAP
  rule #11 hardened** — full verification writeup:
  [docs/done/2026-09-04-issue-1229-wrongly-closed-reopened.md](docs/done/2026-09-04-issue-1229-wrongly-closed-reopened.md).
  (auto/issue-1229-reopen-rule-11-hardened; PR #1404)

- [x] 🟢 **Restore the silently-dropped `verify-rejection` CI job (O4 gate) +
  mechanical recurrence guard** — full verification writeup:
  [docs/done/2026-09-03-forgejo-ci-verify-rejection-restored.md](docs/done/2026-09-03-forgejo-ci-verify-rejection-restored.md).
  (auto/forgejo-ci-verify-rejection-restored; PR #1402)

- [x] 🟢 **Inkless kafka-exporter sidecar — document in ADR-0015,
  currency-check clean** — full verification writeup:
  [docs/done/2026-09-03-inkless-kafka-exporter-documented.md](docs/done/2026-09-03-inkless-kafka-exporter-documented.md).
  (auto/inkless-kafka-exporter-documented; PR #1401)

- [x] 🟢 **Author ADR-0039 — s3manager as the lab's Garage (S3) browser UI
  (retroactive record); bump `v0.8.0` → `v0.9.0`** — full verification
  writeup:
  [docs/done/2026-09-03-adr-0039-s3manager-retroactive-record.md](docs/done/2026-09-03-adr-0039-s3manager-retroactive-record.md).
  (auto/adr-0039-s3manager-retroactive-record; PR #1400)

- [x] 🟢 **Author ADR-0038 — moto + ACK (S3) + KRO for the cloud-control-plane
  demo pattern (retroactive record); bump moto `5.2.2` → `5.2.3`** — full
  verification writeup:
  [docs/done/2026-09-03-adr-0038-ack-kro-moto-retroactive-record.md](docs/done/2026-09-03-adr-0038-ack-kro-moto-retroactive-record.md).
  (auto/adr-0038-ack-kro-moto-retroactive-record; PR #1399)

- [x] 🟢 **Longhorn currency re-check — `v1.12.1` now stable, ADR's own flip
  condition still not triggered, kept at `1.11.3`** — full verification
  writeup:
  [docs/done/2026-09-03-longhorn-currency-recheck-kept.md](docs/done/2026-09-03-longhorn-currency-recheck-kept.md).
  (auto/longhorn-currency-recheck-kept; PR #1398)

- [x] 🟢 **dependency-concentration-sync-check: close the reverse-direction gap
  + fix a stale comment** — full verification writeup:
  [docs/done/2026-09-03-dependency-concentration-reverse-check.md](docs/done/2026-09-03-dependency-concentration-reverse-check.md).
  (auto/dependency-concentration-reverse-check; PR #1397)

- [x] 🟢 **KEDA + Velero full GHSA sweep — confirm both pins security-clean** —
  full verification writeup:
  [docs/done/2026-09-03-keda-velero-full-ghsa-sweep-clean.md](docs/done/2026-09-03-keda-velero-full-ghsa-sweep-clean.md).
  (auto/keda-velero-full-ghsa-sweep-clean; PR #1396)

- [x] 🟢 **cert-manager full GHSA sweep — confirm `1.21.1` pin security-clean** —
  full verification writeup:
  [docs/done/2026-09-03-cert-manager-full-ghsa-sweep-clean.md](docs/done/2026-09-03-cert-manager-full-ghsa-sweep-clean.md).
  (auto/cert-manager-full-ghsa-sweep-clean; PR #1395)

- [x] 🟢 **Author ADR-0037 — HashiCorp Vault for secrets management (retroactive
  record); bump server image `2.0.4` → `2.1.0`** — full verification writeup:
  [docs/done/2026-09-03-vault-adr-0037-retroactive-record.md](docs/done/2026-09-03-vault-adr-0037-retroactive-record.md).
  (auto/vault-adr-0037-retroactive-record; PR #1394)

- [x] 🟢 **ArgoCD full GHSA sweep — confirm `v3.5.2` pin security-clean** — full
  verification writeup:
  [docs/done/2026-09-03-argocd-full-ghsa-sweep-clean.md](docs/done/2026-09-03-argocd-full-ghsa-sweep-clean.md).
  (auto/argocd-full-ghsa-sweep-clean; PR #1393)

- [x] 🟢 **Cilium: Critical advisory GHSA-3fcv-jvfp-m4q9 found unaudited, confirmed
  not applicable** — full verification writeup:
  [docs/done/2026-09-03-cilium-critical-ghsa-gap-closed.md](docs/done/2026-09-03-cilium-critical-ghsa-gap-closed.md).
  (auto/cilium-critical-ghsa-gap-closed; PR #1392)

- [x] 🟢 **Envoy Gateway full GHSA sweep — confirm `v1.8.3` pin security-clean** —
  full verification writeup:
  [docs/done/2026-09-03-envoy-gateway-ghsa-sweep-clean.md](docs/done/2026-09-03-envoy-gateway-ghsa-sweep-clean.md).
  (auto/envoy-gateway-ghsa-sweep-clean; PR #1391)

- [x] 🟢 **Refresh `docs/dora-metrics.md` (stale since 2026-07-30)** — full
  verification writeup:
  [docs/done/2026-09-03-dora-metrics-refresh.md](docs/done/2026-09-03-dora-metrics-refresh.md).
  (auto/dora-metrics-refresh; PR #1390)

- [x] 🟢 **De-duplicate `scripts/dependency-register-check.sh`'s row-parsing logic
  into `scripts/lib/dependency-register.sh`** — full verification writeup:
  [docs/done/2026-09-03-dependency-register-check-lib-dedup.md](docs/done/2026-09-03-dependency-register-check-lib-dedup.md).
  (auto/dependency-register-check-lib-dedup; PR #1389)

- [x] 🟢 **Bump Kyverno chart `3.8.2` → `3.9.0` (2 CVEs, 2 GHSAs, minor bump)** —
  full verification writeup:
  [docs/done/2026-09-03-kyverno-3-8-2-to-3-9-0-cve-bump.md](docs/done/2026-09-03-kyverno-3-8-2-to-3-9-0-cve-bump.md).
  (auto/kyverno-3-8-2-to-3-9-0; PR #1388)

- [x] 🟢 **Bump k3s `v1.36.3+k3s1` → `v1.36.4+k3s1` on both backends** — full
  verification writeup:
  [docs/done/2026-09-03-k3s-1-36-3-to-1-36-4-currency-bump.md](docs/done/2026-09-03-k3s-1-36-3-to-1-36-4-currency-bump.md).
  (auto/k3s-1-36-3-to-1-36-4; PR #1387)

- [x] 🟢 **Bump Aiven Inkless broker `4.2.1-0.46` → `4.2.1-0.47`** — full
  verification writeup:
  [docs/done/2026-09-03-inkless-4-2-1-0-46-to-0-47-bump.md](docs/done/2026-09-03-inkless-4-2-1-0-46-to-0-47-bump.md).
  (auto/inkless-4-2-1-0-46-to-0-47; PR #1386)

- [x] 🟢 **Bump Grafana image tag `13.0.7` → `13.0.8` (3 named CVEs:
  CVE-2026-12704, CVE-2026-14199, CVE-2026-19475)** — full verification writeup:
  [docs/done/2026-09-03-grafana-13-0-7-to-13-0-8-cve-bump.md](docs/done/2026-09-03-grafana-13-0-7-to-13-0-8-cve-bump.md).
  (auto/grafana-13-0-7-to-13-0-8; PR #1384)

- [x] 🟢 **Bump Loki image tag `3.7.6` → `3.7.7` (security-relevant dependency
  bumps)** — full verification writeup:
  [docs/done/2026-09-03-loki-3-7-6-to-3-7-7-security-bump.md](docs/done/2026-09-03-loki-3-7-6-to-3-7-7-security-bump.md).
  (auto/loki-3-7-6-to-3-7-7; PR #1383)

- [x] 🟢 **Extend `docs/dependency-exit-runbooks.md` to the remaining seven
  single-tool rows (Terraform/Terragrunt, RabbitMQ, Valkey, KEDA, Forgejo,
  kube-state-metrics, node-exporter)** — full verification writeup:
  [docs/done/2026-09-03-dependency-exit-runbooks-remaining-seven.md](docs/done/2026-09-03-dependency-exit-runbooks-remaining-seven.md).
  (auto/dependency-exit-runbooks-remaining-seven; PR #1382)

- [x] 🟢 **Fix stale "Keeping this in sync" claims in `docs/dependency-register.md`,
  `docs/dependency-concentration.md`, and `docs/dependency-exit-runbooks.md`** — full
  verification writeup:
  [docs/done/2026-09-03-dependency-docs-sync-check-drift-fix.md](docs/done/2026-09-03-dependency-docs-sync-check-drift-fix.md).
  (auto/dependency-docs-sync-check-drift-fix; PR #1381)

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

  **Update 2026-09-06 (live-cluster session) — the credential-wiring half of "`make
  up`'s bootstrap sequence still calls the GitLab targets outright" is now closed**,
  independently of this item: a fresh `make up` was reproduced live failing
  `root-app`'s very first sync (missing `repo-forgejo-gitops` Secret — the exact gap
  this investigation flagged). Fixed with `scripts/forgejo-repo-secret.sh` +
  `make forgejo-repo-secret`, wired into `up` right after `forgejo-up` and before
  `gitlab-up`/`root-app` — full writeup:
  [docs/done/2026-09-06-forgejo-repo-secret-bootstrap-gap.md](docs/done/2026-09-06-forgejo-repo-secret-bootstrap-gap.md).
  This item stays open: the SSH-based `forgejo-push`/`forgejo-force-push` replacement,
  the TLS-layer question, and the actual `gitlab-*.sh` → `forgejo-*.sh` rename are
  still undone — GitLab's targets still run in `up` (legacy, harmless) and no
  automated push exists yet for a genuinely empty Forgejo repo.
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
  (auto/dependency-concentration-sync-check; PR #1379)

- [x] 🟢 **Add `make dependency-exit-runbooks-sync-check` — a mechanical `make ci`
  guard closing the second half of the "no mechanical drift guard yet" gap between
  `docs/dependency-concentration.md` and `docs/dependency-exit-runbooks.md`** — full
  verification writeup:
  [docs/done/2026-09-02-dependency-exit-runbooks-sync-check.md](docs/done/2026-09-02-dependency-exit-runbooks-sync-check.md).
  (auto/dependency-exit-runbooks-sync-check; PR #1380)

- [x] 🟢 **Extend `docs/dependency-exit-runbooks.md` (DORA audit Q17) to the four
  highest-blast-radius remaining single-tool rows — Cilium, Garage, Envoy Gateway,
  cert-manager** — full verification writeup:
  [docs/done/2026-09-02-dependency-exit-runbooks-single-tool-slice.md](docs/done/2026-09-02-dependency-exit-runbooks-single-tool-slice.md).
  (auto/dependency-exit-runbooks-single-tool-slice; PR #1378)

- [x] 🟢 **Close DORA audit Q7's named future-candidate gap — add a
  `VaultSealedDegraded` Grafana alert rule reading `vault_core_unsealed` directly** —
  full verification writeup:
  [docs/done/2026-09-02-vault-sealed-degraded-alert.md](docs/done/2026-09-02-vault-sealed-degraded-alert.md).
  (auto/vault-sealed-degraded-alert; PR #1377)

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

- [x] 🟢 **Bump kiali-server chart `1.89.8` → `2.29.0`** — full verification
  writeup:
  [docs/done/2026-07-23-arch-adr-0012-kiali-chart-index-audit.md](docs/done/2026-07-23-arch-adr-0012-kiali-chart-index-audit.md).
  (arch/adr-0012-kiali-chart-index-audit; PR #669) Closes #668.

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

- [x] 🟢 **ADR-0006 — remove stale "Follow-up: wire both bootstraps into
  `make up`/DR" note** — full verification writeup:
  [docs/done/2026-07-18-adr-0006-stale-followup-note.md](docs/done/2026-07-18-adr-0006-stale-followup-note.md).
  (auto/adr-0006-stale-followup-note; PR #551)

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

- [x] 🟢 **`vault` PSA `baseline` → `restricted` flip** — full verification
  writeup:
  [docs/done/2026-07-17-vault-psa-restricted.md](docs/done/2026-07-17-vault-psa-restricted.md).
  (auto/vault-psa-restricted; PR #481) Closes #478.

- [x] 🟢 **Governance LimitRange fan-out — `cert-manager` + `keda`** — full
  verification writeup:
  [docs/done/2026-07-16-governance-cert-manager-keda.md](docs/done/2026-07-16-governance-cert-manager-keda.md).
  (auto/governance-cert-manager-keda; PR #451)

- [x] 🟢 **`observability` readOnlyRootFilesystem tighten — Alloy** — full
  verification writeup:
  [docs/done/2026-07-15-observability-readonlyrootfs-alloy.md](docs/done/2026-07-15-observability-readonlyrootfs-alloy.md).
  (auto/observability-readonlyrootfs-alloy; PR #413)

- [x] 🟢 **`observability` readOnlyRootFilesystem tighten — Grafana** — full
  verification writeup:
  [docs/done/2026-07-15-observability-readonlyrootfs-grafana.md](docs/done/2026-07-15-observability-readonlyrootfs-grafana.md).
  (auto/observability-readonlyrootfs-grafana; PR #414)

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

- [x] 🟢 **Trivy Operator dashboard** — full verification writeup:
  [docs/done/2026-06-15-trivy-dashboard.md](docs/done/2026-06-15-trivy-dashboard.md).
  (auto/trivy-dashboard; PR #212)

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

- [x] 🟢 **`tests/dr-bluegreen.bats` — structural test gate for zero-downtime
  blue/green DR scripts** — full verification writeup:
  [docs/done/2026-07-14-dr-bluegreen-bats-bookkeeping.md](docs/done/2026-07-14-dr-bluegreen-bats-bookkeeping.md).
  (chore/dr-bluegreen-bats; PR #393)

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

- [x] 🟢 **Lab — Kube State Metrics cluster-health dashboard** — full
  verification writeup:
  [docs/done/auto-ksm-cluster-health-dashboard.md](docs/done/auto-ksm-cluster-health-dashboard.md).
  (auto/ksm-cluster-health-dashboard; PR #242)

- [x] 🟢 **Lab — Node Exporter cluster-vitals dashboard** — full verification
  writeup:
  [docs/done/2026-06-21-node-exporter-vitals-dashboard.md](docs/done/2026-06-21-node-exporter-vitals-dashboard.md).
  (auto/node-exporter-vitals-dashboard; PR #245)

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

- [x] 🟢 **PSA baseline + NetworkPolicy — `lab-demo` namespace** — full
  verification writeup:
  [docs/done/2026-06-22-pss-np-lab-demo.md](docs/done/2026-06-22-pss-np-lab-demo.md).
  (auto/pss-np-lab-demo; PR #256)

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

- [x] 🟢 **ADR-0017 amendment — add `kargo` namespace row** — full
  verification writeup:
  [docs/done/2026-06-27-adr-0017-kargo-row.md](docs/done/2026-06-27-adr-0017-kargo-row.md).
  (auto/adr-0017-kargo-row; PR #291)

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

- [x] 🟢 **Harbor day-0 credential seam — admin + CI registry secrets** — full
  verification writeup:
  [docs/done/2026-07-08-harbor-bootstrap-credentials.md](docs/done/2026-07-08-harbor-bootstrap-credentials.md).
  (auto/harbor-bootstrap-credentials; PR #347)

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

- [x] 🟢 **O2 NP per-scope coverage loop bats** — full verification writeup:
  [docs/done/2026-07-07-o2-np-coverage-loop.md](docs/done/2026-07-07-o2-np-coverage-loop.md).
  (auto/o2-np-coverage-loop; PR #343)

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

- [x] 🟢 **NetworkPolicy overlay — `capstone-pipeline` namespace** — full
  verification writeup:
  [docs/done/2026-07-11-auto-capstone-pipeline-networkpolicy.md](docs/done/2026-07-11-auto-capstone-pipeline-networkpolicy.md).
  (auto/capstone-pipeline-networkpolicy; PR #363)

- [x] 🟢 **Cilium agent Prometheus metrics + O5 CNI dashboard** — full
  verification writeup:
  [docs/done/2026-07-12-auto-cilium-agent-metrics.md](docs/done/2026-07-12-auto-cilium-agent-metrics.md).
  (auto/cilium-agent-metrics; PR #367)

- [x] 🟢 **`docs/00-architecture.md` — add learning-path steps for DR/blue-green
  and GitOps promotion (Kargo)** — full verification writeup:
  [docs/done/2026-07-13-architecture-doc-learning-path-update.md](docs/done/2026-07-13-architecture-doc-learning-path-update.md).
  (auto/architecture-doc-learning-path-update; PR #385)

- [x] 🟢 **`docs/00-architecture.md` — add learning-path step 12 for
  cloud-agnostic infrastructure design** — full verification writeup:
  [docs/done/2026-07-13-architecture-doc-cloud-agnostic-step.md](docs/done/2026-07-13-architecture-doc-cloud-agnostic-step.md).
  (auto/architecture-doc-cloud-agnostic-step; PR #387)

- [x] 🟢 **Hook-scripts negative-path coverage — `argocd-crd-ssa-sync-hook.sh` +
  `helm-chart-pin-sync-hook.sh`** — full verification writeup:
  [docs/done/2026-07-16-hook-scripts-negative-path-coverage.md](docs/done/2026-07-16-hook-scripts-negative-path-coverage.md).
  (auto/hook-scripts-negative-path-coverage; PR #432)

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

- [x] 🟢 **`scripts/ensure-bats-hook.sh` — auto-install `bats` at session start so
  `make ci`'s unit-test gate can't silently self-skip in an autonomous session** —
  full verification writeup:
  [docs/done/2026-09-06-ensure-bats-session-start-hook.md](docs/done/2026-09-06-ensure-bats-session-start-hook.md).
  (auto/ensure-bats-hook)
  (CLAUDE.md's bugfix-recurrence-prevention rule; JANITOR-fallback cleanup 2026-09-06,
  reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
  re-confirmed fully gated this cycle (issues #633/#1229 unchanged) and
  PLANNER/ARCHITECT/TRIAGER/DOC-DRIFT-AUTHOR all came up empty again. Found live this
  same run: two `upgrade/*` version-bump PRs
  (`upgrade/kro-0.9.3-to-0.9.4`, `upgrade/grafana-12.10.4-to-12.11.2`) both passed a
  local `make ci` that silently skipped `tests/securitycontext-kro.bats`'s hard-coded
  exact-chart-pin assertion because `bats` wasn't installed in this remote clusterless
  sandbox — `scripts/test.sh`'s existing local-vs-CI skip is a fair convenience for a
  human contributor, but this session's *entire* self-review contract IS `make ci`
  (WAYS-OF-WORKING.md §0.1's self-merge model, no other backstop) — recurring twice in
  one run makes it a real class of bug, not a one-off, per CLAUDE.md's own
  bugfix-recurrence rule.)

  Added `scripts/ensure-bats-hook.sh`, a best-effort `SessionStart` hook (installs
  `bats` via `apt-get` if missing, silently no-ops if `apt-get`/network/permission
  isn't available — never blocks the session) wired into `.claude/settings.json`.
  Once `bats` is on `PATH`, `scripts/test.sh`'s own existing local/CI branch naturally
  takes the "run the real suite" path for the rest of the session — no change needed
  to `test.sh` itself. Added `tests/hook-scripts-ensure-bats.bats` (its own file per
  `tests/hook-scripts-coverage.bats`'s frozen-monolith rule) covering: script
  exists/executable, exits 0 + reports "already installed" when `bats` is present
  (the actual path this bats run itself exercises), exits 0 even with no `apt-get` on
  `PATH` (never blocks), and is actually wired into `.claude/settings.json` (valid
  JSON preserved). `make ci` must pass. `docs/done/` entry required.
  (auto/ensure-bats-hook)

- [x] 🟢 **Fix a stale ADR-0004 violation in `docs/dora-audit-readiness.md`'s Kyverno
  criticality-tier row** — full verification writeup:
  [docs/done/2026-09-06-dora-kyverno-failurepolicy-fix.md](docs/done/2026-09-06-dora-kyverno-failurepolicy-fix.md).
  (auto/dora-kyverno-failurepolicy-fix)
  (ADR-0004 (no fabricated content — dashboards/outputs must show real,
  auto-discovered state); JANITOR-fallback cleanup 2026-09-06, reached via
  `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
  gated this cycle (issues #633/#1229 unchanged) and PLANNER/ARCHITECT/TRIAGER/
  DOC-DRIFT-AUTHOR/UPGRADE-DRAFTER all came up empty or too risky this cycle
  (ArgoCD's chart 10.5.0 → 10.8.0 spanned multiple minor releases and this remote
  session's page-fetch tooling could not reliably diff its large `values.yaml`
  across tags — skipped rather than asserting safety it couldn't verify).)

  `docs/dora-audit-readiness.md`'s Kyverno criticality-tier row claimed "Every
  policy in `gitops/kyverno/policies/` sets `failurePolicy: Ignore` ... confirmed
  directly in `verify-image-signatures.yaml`" — verified directly against the real
  file (ADR-0004) and found this false: `verify-image-signatures.yaml` explicitly
  sets `failurePolicy: Fail` (flipped from `Ignore` 2026-08-18, per that file's own
  header comment). Corrected the row to state the real, current fact and to
  honestly flag what the other 4 `ClusterPolicy` files' unset `failurePolicy`
  actually resolves to as unverified from this clusterless session (not asserted
  either way), rather than repeating a blanket claim that was already wrong for at
  least one of the five files. `make ci` must pass. `docs/done/` entry required.
  (auto/dora-kyverno-failurepolicy-fix)

- [x] 🟢 **`scripts/ensure-lint-tools-hook.sh` — auto-install `shellcheck`/`yamllint`
  at session start so `make ci`'s lint gate can't silently self-skip either** —
  full verification writeup:
  [docs/done/2026-09-06-ensure-lint-tools-session-start-hook.md](docs/done/2026-09-06-ensure-lint-tools-session-start-hook.md).
  (auto/ensure-lint-tools-hook)
  (CLAUDE.md's bugfix-recurrence-prevention rule; JANITOR-fallback cleanup 2026-09-06,
  a direct follow-up to `auto/ensure-bats-hook` (#1448) earlier this same run — same
  footgun class, a different pair of tools. Found live checking whether the ArgoCD
  chart-bump candidate this cycle's `[Action needed]` note (#1450) mentioned could be
  attempted more safely with `kustomize`/`helm` installed locally: neither was
  installed either, and neither is `shellcheck`/`yamllint` — `scripts/lint.sh`'s own
  local/CI skip (`command -v shellcheck`/`yamllint`, soft-skip locally, hard-fail
  under `CI=true`) meant this session's own `make ci` had been silently skipping the
  entire `lint` gate the whole run, on every one of this run's prior PRs, exactly the
  same self-review blind spot the bats fix closed for the `unit` gate.)

  Added `scripts/ensure-lint-tools-hook.sh`, a best-effort `SessionStart` hook
  (installs `shellcheck`/`yamllint` via `apt-get` if missing, silently no-ops if
  `apt-get`/network/permission isn't available — never blocks the session) wired
  into `.claude/settings.json`. Once both are on `PATH`, `scripts/lint.sh`'s own
  existing local/CI branch naturally takes the "run the real check" path for the
  rest of the session — no change needed to `lint.sh` itself. Verified live: running
  `bash scripts/lint.sh` after installing both found zero pre-existing lint findings
  across the whole repo (the GitHub Actions backstop had genuinely been keeping this
  clean; installing the tools locally didn't surface a hidden violation this PR would
  otherwise need to fix). Added `tests/hook-scripts-ensure-lint-tools.bats` (its own
  file per `tests/hook-scripts-coverage.bats`'s frozen-monolith rule, mirroring
  `tests/hook-scripts-ensure-bats.bats`'s structure) covering: script
  exists/executable, exits 0 + reports "already installed" for both tools when
  present (the actual path this bats run itself exercises), exits 0 even with no
  `apt-get`/tools on `PATH` (never blocks), and is actually wired into
  `.claude/settings.json` (valid JSON preserved). `make ci` must pass. `docs/done/`
  entry required. (auto/ensure-lint-tools-hook)

- [x] 🟢 **`scripts/ensure-manifest-tools-hook.sh` — auto-install
  `kustomize`/`terraform`/`tflint`/`kubeconform` so `make ci`'s validate gates can't
  self-skip either** — full verification writeup:
  [docs/done/2026-09-06-ensure-manifest-tools-session-start-hook.md](docs/done/2026-09-06-ensure-manifest-tools-session-start-hook.md).
  (auto/ensure-manifest-tools-hook)
  (CLAUDE.md's bugfix-recurrence-prevention rule; third JANITOR-fallback follow-up
  this same run to `auto/ensure-bats-hook` (#1448) and `auto/ensure-lint-tools-hook`
  (#1456) — same footgun class, the remaining validate-*.sh tool dependencies.
  Verified live none of `kustomize`/`terraform`/`tflint`/`kubeconform` was installed
  either, meaning `make ci`'s kustomize/terraform/manifests steps had all been
  silently self-skipping the whole run too.)

  Added `scripts/ensure-manifest-tools-hook.sh`, pinning each tool's version to
  exactly match `.github/workflows/ci.yml`'s own pins (`kustomize` v5.8.1,
  `kubeconform` v0.8.0, `terraform` 1.15.9, `tflint` via CI's own install script) so
  a local pass means the same thing CI's pass means. `helm` is deliberately excluded
  and the script says why: its official binaries are hosted exclusively on
  `get.helm.sh`, which this sandbox's egress proxy blocks (verified live — the
  official `get-helm-3` install script failed with `connect_rejected`); this only
  costs `helm-chart-pin-check.sh`'s local run (that gate's own soft-skip message
  already says so) since `validate-kustomize.sh` no longer needs `helm` at all as of
  2026-09-06 (ADR-0040's Envoy Gateway removal deleted the only kustomization that
  vendored a Helm chart via the `helmCharts` inflator). Verified live: running the
  freshly-enabled `kustomize`/`terraform`/`manifests` `make ci` steps found **zero
  pre-existing failures** — the GitHub Actions backstop had genuinely been keeping
  all three clean; enabling them locally didn't surface hidden drift needing a
  separate fix. Added `tests/hook-scripts-ensure-manifest-tools.bats` (its own file
  per `tests/hook-scripts-coverage.bats`'s frozen-monolith rule): script
  exists/executable, reports "already installed" for all four tools when present
  (the actual path this bats run itself exercises), never fails even with no
  network/tools reachable (a minimal `PATH` exercising only the hook's own
  non-network coreutils calls), explicitly documents the `helm` exclusion, and is
  wired into `.claude/settings.json` with valid JSON preserved. `make ci` must pass.
  `docs/done/` entry required. (auto/ensure-manifest-tools-hook)

- [x] 🟢 **Fix a stale namespace list in `gitops/platform/velero-networkpolicy.yaml`'s
  header comment (post-TiDB-removal drift)** — full verification writeup:
  [docs/done/2026-09-06-velero-networkpolicy-tidb-comment-fix.md](docs/done/2026-09-06-velero-networkpolicy-tidb-comment-fix.md).
  (auto/velero-networkpolicy-tidb-comment-fix)
  (ADR-0004; JANITOR-fallback coverage sweep 2026-09-06, following up on PR #1452's
  TiDB/Istio/Kiali/Longhorn removal — checked every `gitops/` file for lingering
  references to the removed components and found this one stale header comment; the
  child `NetworkPolicy` file itself (`gitops/velero/networkpolicy/
  allow-velero-egress-kopia-pv.yaml`) had already been correctly updated by PR #1452,
  but the parent `Application` wrapper's own header comment, listing the same
  namespace set independently in prose, was missed.)

  `gitops/platform/velero-networkpolicy.yaml`'s header comment still listed
  "backed-up namespaces (data/tidb/capstone/vault)" — `tidb` no longer exists as a
  namespace since PR #1452. Corrected to the real, current set
  (data/capstone/vault/observability, matching the child `NetworkPolicy`'s actual
  `values:` list exactly) with an inline note on when/why it changed. No test
  depended on the stale text (checked `tests/networkpolicy-velero.bats`/
  `tests/velero.bats` directly). `make ci` must pass. `docs/done/` entry required.
  (auto/velero-networkpolicy-tidb-comment-fix)

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
