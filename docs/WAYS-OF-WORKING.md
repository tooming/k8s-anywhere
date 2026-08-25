# Ways of Working — Agent Governance & Review

> **Scope.** The team operating model for k8s-lab: how autonomous agents operate in this
> repo, how *all* changes (human and agent) are reviewed and merged (§0–§6), and the team
> process around them — backlog, planning, ownership (§7).
>
> **Status.** Target operating model for scaling k8s-lab to a team. Controls that still
> need repo configuration are marked _⚙ to wire_. Today the repo runs two routines (see the
> registry) under a single maintainer; this is what "good" looks like as that grows.

## 0. Principles (non-negotiable)

1. **Agents have full, unrestricted authority over this repo — no human merge gate,
   no reserved category, no autonomy-tier system.**
   *(Adopted 2026-07-14, superseding both the original "merge button is the
   maintainer's only touchpoint" rule and the prior Green/Yellow/Red autonomy-tier
   model — including the version of it that still reserved secrets/credentials,
   live-cluster/production mutation, destructive git history operations, and
   disabling/altering another agent for a human: the maintainer explicitly directed
   "AI should be fully responsible for this repo from now on," with no category held
   back and no tier framework left to enforce one.)* The architect makes binding
   technical decisions (RFCs, ADRs); the planner sequences them; the executor
   implements; **any agent may merge its own PR, including one that edits this file,
   `CHARTER.md`, a `docs/decisions/*.md` ADR, secrets/credentials, live-cluster or
   production infrastructure, git history, or another agent's configuration**, once
   required CI is green, its `[self-review]` comment is posted, and conversations are
   resolved. Branch protection on `main` has been removed (§4) precisely to make this
   possible — GitHub no longer blocks a merge or a direct push on any of that, which
   means **the CI-green / self-review / resolved-conversations bar is now enforced by
   agent discipline alone, not the platform.** Treat it as load-bearing for that
   reason, not less binding. The maintainer does not work issues or click merge
   buttons. An agent must never assign the maintainer an action item it can perform
   itself with the tools it has — "maintainer: please do X" is now a routine bug for
   anything on this repo, full stop. If a tool call fails, fall back to `gh` before
   escalating.
   > **Scope of this grant.** "Fully responsible for the repo" covers this repo's
   > git/GitHub surface (merging, pushing to `main`, repo settings in principle) with
   > no carve-out — the categories a prior version of this doc marked 🔴 Red
   > (secrets/credentials, live-cluster or production infrastructure mutation,
   > destructive git history operations, disabling/altering another agent) are no
   > longer reserved for a human. This grant doesn't expand what any individual agent
   > session is actually *able or willing* to do in practice — that's a property of
   > the session's own tooling and operating constraints, which this document doesn't
   > configure and can't override.
2. **The repo is the only rulebook agents obey.** Remote agents see only what's in git, so
   [CHARTER.md](../CHARTER.md), the [ROADMAP.md](../ROADMAP.md) rules, the ADRs in
   [decisions/](decisions/), and this doc are the *complete* set of rules. A governance
   change takes effect only once it's merged.
3. **Review capacity is the constraint, not generation.** Agents are throttled so they
   never out-produce the team's ability to review safely (see §4 WIP limits). Full merge
   authority raises the stakes on this, not lowers them — nothing else will catch a
   quietly-oversized or off-scope PR before it lands.

## 1. Agent registry (every routine has a human owner)

No unregistered autonomous routine may run against this repo. Each is owned by one
accountable human — for its output **and** its cost. Adding, re-scoping, or changing a
routine's model/cadence is a PR that edits this table.

**Remote routines (cloud, clusterless):** [`routines/routines.yaml`](../routines/routines.yaml)
is the source of truth for what's actually live — this table mirrors it, not the other
way around; if they disagree, trust the YAML and fix this table.

| Routine | Trigger ID | Owner | Purpose | Cadence · Model | Branch |
|---|---|---|---|---|---|
| Executor | `trig_01XxtSdkPdRNjBfAidUXTwos` | @tooming | implements ROADMAP items back-to-back for as long as the run continues (one PR per item, STEP 8 loop — no longer one-and-done); empty lane ⇒ escalates through the blocking role's work (planner → architect → upgrade-drafter → doc-drift → triager → janitor) so no cycle is wasted | 00:00/05:00/14:00 UTC, every day (3/day) · Sonnet 5 | `auto/*` (fallback roles keep their own prefixes) |

**One trigger, not eight.** Planner, architect, triager, upgrade-drafter, doc-drift-author,
industry-news-writer, and the old "executor 4th slot" each *used to* have their own
cron-scheduled trigger; all were retired 2026-06-13 and absorbed into the single executor
trigger above, which now reads their prompt files in-repo as fallback targets when its own
ROADMAP lane is empty (`executor.prompt.md` STEP 6b) — this is why they still exist under
`routines/` with no separate schedule. Their old trigger IDs are kept disabled (no delete
API) purely as an audit trail; do not re-enable them without also reworking the fallback
chain, or the same work will double-fire from two triggers. `janitor.prompt.md` and
`learning-post-writer.prompt.md` were never separately triggered — same model, fallback-only.

> **Retired — Reviewer** (`trig_01Dw7US6aZmJo8XZwDikoNkG`, daily 17:30 UTC, retired
> 2026-06-10): cron-based review structurally lagged PR-open — PRs were merged between
> slots and the routine spent runs filing idle issues (#160). First-pass review now
> happens **inside each PR-producing run**: the executor, planner, architect, and
> upgrade-drafter prompts end with a mandatory self-review step that audits the run's own
> diff against the three review checks (gate integrity, ADR compliance, ADR-0004
> fabricated content — plus the adversarial design review for `arch/*`) and
> posts a `[self-review]` comment + `self-reviewed` label on the PR before the run ends.
> The backend trigger stays disabled as an audit trail; its daily slot funded the
> executor's restoration to 3/day, and the 2026-06-13 consolidation folded the rest into
> the fallback chain above.

**Local on-demand roles (maintainer's machine, cluster-bound — not on cron, no quota cost):**

| Role | Owner | Purpose | Invoked as |
|---|---|---|---|
| Verifier | @tooming | bring up the lab on an `auto/*` PR's branch and confirm acceptance criteria pass end-to-end; comments `[verifier-routine]` + labels `verified-by-routine` | `claude --prompt routines/verifier.prompt.md "verify auto/<slug>"` |
| Operator | @tooming | on-call pulse check; run `make dr-*` drills; file `incident` issues when something needs a human | `claude --prompt routines/operator.prompt.md "check the lab"` |

_(As the team grows, replace the single-owner entries above with the owning engineer or team for each routine.)_

> The canonical, version-controlled definitions of these routines (cron, model, prompt,
> tools) live in [`routines/`](../routines/) and are applied via Claude Code — see
> [routines/README.md](../routines/README.md). This table is the human-readable summary.

## 3. Agent PR contract (definition of done)

- **One item per PR**, focused and bounded (target < ~400 changed lines; larger work is
  split by the planner first). Reviewers may reject oversized PRs on sight.
- **Branch prefix signals origin:** `auto/*` (executor), `plan/*` (planner), `arch/*`
  (architect), `upgrade/*` (upgrade drafter), `sync/*` (doc-drift author), `chore/*`
  (janitor), `digest/*` (industry-news writer, retired 2026-06-13 — folded into the
  architect, kept here as a dead-prefix reference for any stray leftover branches);
  `feat/*` / `fix/*` (humans). Agent prefixes are reserved — humans don't use them.
- **PR body must state:** what changed + why, the ROADMAP item / issue it addresses, and
  that it's an agent run plus which routine produced it.
- **Green before review:** `make ci` passes; ADRs honored; heavy components stay
  non-auto-synced; docs/dashboards in sync.
- **Self-merge (unconditional, including governance):** once every required status check
  is green, the `[self-review]` comment is posted, and all conversations are resolved,
  the authoring routine merges its own PR (squash, matching `main`'s linear-history
  convention) and updates the ROADMAP checkbox / closes the issue it addressed. It must
  **not** merge if any required check is red or a conversation is unresolved — those
  hold unconditionally, with no exception for any category of change (§0.1).

## 4. Review & merge gate

_GitHub repo settings (as of 2026-07-13):_

- **Branch protection on `main` — removed** (maintainer action, 2026-07-13, to unblock
  self-merge (§0.1)). This was the *repo-settings* half of enabling self-merge that §0.1
  originally flagged as an agent-can't-do-this-itself follow-up; it's now done, and the
  maintainer went further than the minimal fix — full removal, not just the CODEOWNERS
  requirement:
  - No PR required — **direct pushes to `main` are now technically possible.**
  - **No required status checks** — `lint`/`manifests`/`terraform`/`kustomize`/`unit`/
    `drift`/`up-to-date` still run (the `.github/workflows/ci.yml` jobs are unchanged),
    but GitHub no longer *blocks* a merge (or a direct push) on their result. A red CI
    run is now advisory, not a gate, at the platform level.
  - No CODEOWNERS review required, no linear-history enforcement, no
    conversations-must-resolve requirement.

  **What this means in practice: the self-merge contract in §0.1/§3/§4 (CI green,
  `[self-review]` posted, conversations resolved) is now the *only* thing standing
  between a broken change and `main` — GitHub will no longer catch a violation of it.**
  Every routine and every human working this repo must treat those rules as
  load-bearing, not advisory, precisely because nothing else enforces them anymore.
  This doc still says "never merge with a red CI check" — that is no longer
  *technically* prevented by GitHub, only *behaviorally* required. If a routine
  misbehaves, the backstop is the kill-switch (§5: disable the routine) and reverting
  the bad commit, not a rejected API call.

  **Optional hardening the maintainer could still add later:** re-enable required status
  checks + linear history (without reintroducing "PR required" or CODEOWNERS-approval,
  which would reinstate a human gate the maintainer has explicitly removed). Noted here
  as an available knob, not a recommendation to act on — the maintainer's 2026-07-13
  direction was unambiguous and this doc shouldn't second-guess it.

- **`CODEOWNERS` owners** — file exists but all domain owners are `@tbd` (see §7
  ownership map). As the team grows, replace `@tbd` entries with real owners. Even with
  the CODEOWNERS *requirement* gone from branch protection, an agent PR is still **never**
  approved by an agent — self-merge is not self-*approval*; the CI-green + self-review
  together stand in for approval, they don't forge one.

_Process:_

- **Who reviews an agent PR:** any human, at their discretion — self-merge means review
  is no longer a precondition, but PRs stay open to comment/revert like any other
  change. Reviewed for correctness, scope, **gate integrity** (did the agent quietly
  weaken a test or loosen a check?), and security; CI-green is necessary, not
  sufficient for a *human* reviewer's trust, even though it is sufficient to trigger
  self-merge.
- **WIP limit:** cap concurrent open agent PRs (suggested ≤ 3 `auto/*` + ≤ 1 each of
  `plan/*`, `arch/*`, `upgrade/*`, `sync/*`, `digest/*`). At the cap, agents wait instead
  of piling on. (The executor already skips items with an open `auto/*` PR; the cap
  generalizes that to protect reviewer attention.) Every PR-producing routine posts a
  first-pass `[self-review]` comment (+ `self-reviewed` label) on its own PR before
  merging — combined with green required CI, this **is** the self-merge trigger
  unconditionally (§0.1, §3), including PRs that touch governance files. It never
  substitutes for a human's ability to review after the fact, comment, or revert —
  self-merge removes the pre-merge gate, not post-merge accountability.
- **Staleness SLA:** an agent PR with no review in N working days is flagged or auto-closed,
  not left to rot. Closing is cheap — the item simply returns to the backlog.

## 5. Cost & kill-switch

- **Free quota: 5 routine runs per rolling 24h, shared across the whole account, not
  per-repo.** Beyond that, runs use usage credits *only if* the "additional runs" toggle is
  on (otherwise they're skipped — a hard free cap).
  [`routines/routines.yaml`](../routines/routines.yaml) is the **single source of truth**
  for the exact cron and slot count — don't restate the schedule here. (A day-by-day slot
  table — "Mon: executor(4)+planner(1)", etc. — lived in this section until 2026-07-14 and
  silently drifted for a month after the 2026-06-13 single-trigger consolidation described
  in §1, describing eight retired per-day-of-week triggers that no longer exist. Duplicating
  the schedule in prose is exactly what let it drift undetected; this section now only
  describes the *policy*, not the literal times.) One trigger, one cron, every slot runs
  the same executor prompt, which escalates through the in-repo fallback chain (§1,
  `executor.prompt.md` STEP 6b) whenever its own ROADMAP lane is empty — so every one of
  this trigger's daily slots stays productive without a second trigger or a per-day
  rotation to keep in sync by hand. **2026-08-18: this trigger dropped from 5→4 runs/day**
  to free one account-wide slot for a new PR-only executor trigger on
  [`tooming/easysportstream`](https://github.com/tooming/easysportstream) (see that repo's
  `routines/routines.yaml` and `docs/AGENT_WAYS_OF_WORKING.md` §5 for the other half of this
  split). **2026-08-25: dropped again, 4→3 runs/day**, at the maintainer's explicit request,
  to free a second account-wide slot for a new executor trigger on
  [`tooming/keebridge`](https://github.com/tooming/keebridge) (see that repo's own
  `routines/routines.yaml` for the other half of this split) — the account-wide
  5-runs/rolling-24h total is unchanged across both drops, just redistributed across three
  repos now. No headroom beyond that combined total — adding any further routine trigger or
  raising any repo's cadence requires enabling the paid "additional runs" toggle. (The local
  verifier and operator are invoked by hand on the maintainer's machine; they have no cron
  and no quota cost.)
- **Spread-across-the-day schedule + rolling-24h credit safety.** This trigger's daily runs
  fire at fixed clock-times (see `routines.yaml`'s `cron` for the exact current values,
  evenly spaced across the full day rather than clustered in one nightly window). The times
  are *fixed* deliberately: the free cap is per **rolling** 24h, not per calendar day, so
  because the set of fire-times is identical every day, every rolling 24h window holds the
  same fixed count of runs and the schedule can never spill into paid "additional runs"
  credits — that invariant only needs fixed clock-times, not a particular time-of-day, which
  is why spreading them across the day is safe. This was originally an
  all-night 21/22/23/0/1 UTC clustering; the maintainer asked (2026-07-16) to spread it
  across the day instead, and the `routines.yaml` cron edit landed and was applied to the
  live trigger the same day (PR #453) — `.routines-applied` records the applied hash and
  `tests/routine-schedule-spread.bats` mechanically guards against the schedule
  re-clustering. Trade-off accepted deliberately: PRs can now land and self-merge during
  the maintainer's daytime, not only overnight — consistent with WAYS-OF-WORKING.md §0.1's
  full-autonomy model, but worth knowing about.
- **A run is no longer bounded to one item's worth of spend — the maintainer's explicit
  goal is that a run works until its credit runs out.** Since 2026-07-16
  (`executor.prompt.md` STEP 8), a single run loops through as many ROADMAP items as it
  can — implement, PR, self-review, merge, repeat — with **no voluntary stopping
  point**: not an empty backlog, not an exhausted fallback chain, not even a cycle whose
  honest outcome was the idle issue. The *only* thing that ends a run is the run itself
  being cut off by its own resource limits. This does not change the **number** of runs
  (still fixed at whatever `routines.yaml`'s cron says, the free-quota unit), but it can
  substantially change **spend per run** and, more importantly, **PR volume per run** —
  potentially many self-merged PRs landing back-to-back with no run-boundary between
  them. This is in direct tension with §0.3's "review capacity is the constraint, not
  generation": more PRs per run means more merged changes for the maintainer to spot-check
  after the fact, faster. The mitigations already in place (§0.1's CI-green +
  `[self-review]` + resolved-conversations bar; WIP caps in §4; each cycle still capped at
  one item / ~400 lines) are unchanged and still apply per cycle — but this is a real
  cost/risk increase from the maintainer's explicit choice, not a side effect to ignore.
  If output ever outpaces what's reasonable to spot-check, the fix is the kill-switch
  below (pause the routine) or re-adding a per-run cycle cap in `executor.prompt.md`
  STEP 8, not silently tolerating it.
- Spend scales with **cadence × model × routine count × cycles-per-run**; the registry
  (§1) and `routines.yaml` record the first three, and the routine's owner is accountable
  for all four now that the fourth is effectively unbounded.
- **Scale-out rule:** add agents, raise cadence, or let a run cycle through more items
  only when there is review capacity to absorb the extra output. Generation is cheap;
  safe review is not.
- **Emergency stop:** disable a routine immediately from the routines page (toggle off) or
  via `RemoteTrigger {action:"update", body:{enabled:false}}`. Pausing the worst-behaving
  routine always beats merging under pressure.

## 6. When an agent gets it wrong

- Close the bad PR with a one-line reason. If the failure is systemic (a recurring rule
  violation, chronic over-sizing), fix it at the source — harden the routine prompt and/or
  this doc — and disable the routine until the fix merges if needed.
- Because agents obey only what's in-repo, **every governance fix is itself a PR.** That's
  the feedback loop: bad agent behavior → tighten the in-repo rules → agents comply on the
  next run.

## 7. Team process (backlog, planning, ownership)

### Backlog: file → tracker

While only a few people edit it, `ROADMAP.md` in git is fine. Once several humans edit
concurrently, move the backlog to a **GitHub Projects board** (Issues as cards; columns
**Inbox → Ready → In progress → In review → Done**; a WIP cap per column). `CHARTER.md`
and the ADRs stay as PR-reviewed files. The planner then writes/updates **Issues**, not a
markdown list — which also ends the file-contention wrinkle between planner, executor, and
humans.

- **Definition of Ready** (an item is executor-pickable only when): scoped to one PR;
  acceptance criteria stated; any needed RFC linked; owning domain / CODEOWNER
  identified; clusterless-deliverable.
- **Definition of Done**: the agent PR contract (§3), merged through the gate (§4).

### Intake & triage

- Work enters as a **GitHub issue** — already the planner's intake queue.
- **Triage** (2–3×/week, rotating owner): label new issues (domain, priority), close
  duplicates / out-of-scope, route to a CODEOWNER. `wontfix` / `question` are skipped by
  the planner.

### Planning cadence

- **Weekly grooming** (leads + planner): leads set *priority*; the planner proposes
  decomposition and surfaces CHARTER gaps. Humans decide order; the planner records the
  agreed items.
- **Per-cycle retro**: review what agents shipped vs. what got reverted, and tune the
  routine prompts / this doc. Governance is iterated via PR (§6) like any other code.

### Ownership map

Each domain has an owning person/team, encoded in [`.github/CODEOWNERS`](../.github/CODEOWNERS):

| Domain | Paths | Owner |
|---|---|---|
| Bootstrap / IaC | `infra/`, `gitops/bootstrap/`, `gitops/platform/` | @tbd |
| Network / ingress | `gitops/network/` | @tbd |
| Secrets | `gitops/vault/`, `gitops/secrets/` | @tbd |
| Storage / data | `gitops/storage/`, `gitops/data/` | @tbd |
| Observability | `gitops/observability/` | @tbd |
| Cloud control-plane | `gitops/ack/`, `gitops/kro/`, `gitops/moto/` | @tbd |
| Apps / demo | `gitops/apps/` | @tbd |

As the team grows, give each domain its **own executor routine** scoped to that path (own
branch prefix), so agents work in parallel without colliding and PRs route to the right
reviewers. **Per-domain charters**: `CHARTER.md` is the top-level north-star; a domain may
add a sub-charter / OKRs that its planner reads for domain-specific gap analysis.
