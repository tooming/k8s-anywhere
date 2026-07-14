# Ways of Working — Agent Governance & Review

> **Scope.** The team operating model for k8s-lab: how autonomous agents operate in this
> repo, how *all* changes (human and agent) are reviewed and merged (§0–§6), and the team
> process around them — backlog, planning, ownership (§7).
>
> **Status.** Target operating model for scaling k8s-lab to a team. Controls that still
> need repo configuration are marked _⚙ to wire_. Today the repo runs two routines (see the
> registry) under a single maintainer; this is what "good" looks like as that grows.

## 0. Principles (non-negotiable)

1. **Agents have full merge authority — no human merge gate, on any tier.**
   *(Adopted 2026-07-13, superseding both the original "merge button is the
   maintainer's only touchpoint" rule and #371's Green/Yellow-only, governance-excluded
   version of self-merge: the maintainer explicitly directed "AI should fully control
   the repo from now on," merging PRs itself or, where it's the better tool for the
   job, committing straight to `main` — no waiting required.)* The architect makes
   binding technical decisions (RFCs, ADRs); the planner sequences them; the executor
   implements; **any agent may merge its own PR, including one that edits this file,
   `CHARTER.md`, or a `docs/decisions/*.md` ADR**, once required CI is green, its
   `[self-review]` comment is posted, and conversations are resolved. Branch protection
   on `main` has been removed (§4) precisely to make this possible — GitHub no longer
   blocks a merge or a direct push on any of that, which means **the CI-green /
   self-review / resolved-conversations bar is now enforced by agent discipline alone,
   not the platform.** Treat it as load-bearing for that reason, not less binding.
   The maintainer does not work issues or click merge buttons. An agent must never
   assign the maintainer an action item it can perform itself with the tools it has —
   "maintainer: please do X" is now a routine bug for anything on this repo, full stop.
   If a tool call fails, fall back to `gh` before escalating.
   > **Scope of this grant.** "Fully control the repo" covers this repo's git/GitHub
   > surface: merging, pushing to `main`, and (in principle, though no current tool
   > grants agents this capability) repo settings. It does **not** extend to three
   > categories the maintainer's instruction didn't address and that carry a different,
   > harder-to-reverse risk profile — these stay 🔴 Red per §2 until told otherwise:
   > **secrets/credentials**, **live-cluster or production infrastructure mutation**,
   > and **destructive git history operations** (force-push, branch/data deletion,
   > history rewrite) — a bad merge is one `git revert` away from fixed; a force-pushed
   > history or a wiped PVC is not. Disabling or altering another agent also stays Red —
   > it protects the kill-switch (§5) an operator relies on if a routine misbehaves, and
   > that's an orthogonal concern to *who* can merge.
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

| Routine | Trigger ID | Owner | Purpose | Cadence · Model | Branch | Max tier |
|---|---|---|---|---|---|---|
| Executor | `trig_01CRtpmaS1scBQL74xKqmfvS` | @tooming | implements one ROADMAP item / run; empty lane ⇒ escalates through the blocking role's work (planner → architect → upgrade-drafter → doc-drift → triager → janitor) so no slot is wasted | 21:00/22:00/23:00/00:00/01:00 UTC, every day (5/day) · Sonnet 4.6 | `auto/*` (fallback roles keep their own prefixes) | 🟢 Green |

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
> diff against the four review checks (gate integrity, ADR compliance, tier discipline,
> ADR-0004 fabricated content — plus the adversarial design review for `arch/*`) and
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

## 2. Autonomy tiers (what an agent may do unsupervised)

Every agent action falls in a tier. An agent that hits work above its registered tier must
**stop and open an issue for a human** — never proceed.

| Tier | Who acts | Examples (non-exhaustive) |
|---|---|---|
| 🟢 **Green** | Agent, unsupervised → PR (or direct commit to `main` for trivial changes) → **self-merge once CI is green** | Docs, comments, tests; non-auto-synced manifests; dashboards from real metrics; README / `dependency-tree.md` sync; ROADMAP grooming |
| 🟡 **Yellow** | Architect authors a binding RFC → planner grooms it → executor implements → **self-merge once CI is green** (no human-approval step) | New platform component; anything growing the always-on footprint; new deps / Helm sources; CI, gate, or `Makefile` changes; security-adjacent (auth, RBAC, network exposure); ADR-authoring; editing CHARTER.md / this file (goals & governance); `infra/` bootstrap changes |
| 🔴 **Red** | Humans only — agent must refuse & escalate | Secrets/credentials; any live-cluster or production infrastructure mutation; destructive git history operations (force-push, branch/data deletion, history rewrite); disabling or altering another agent |

Full definitions:

**🟢 Green — autonomous (PR or direct commit, self-merge).** Docs, comments, tests;
clusterless manifests that are *not* auto-synced (per the 12 GB budget rule); Grafana
dashboards built from real metrics; `docs/dependency-tree.md` and README sync; ROADMAP
grooming. This is the executor's and planner's day-to-day lane. Once required CI is
green, `[self-review]` is posted, and conversations are resolved, the routine merges its
own PR — no human-approval step, no human merge-click (§0.1).

**🟡 Yellow — architect-decided, no human-approval step, self-merge including
governance.** A new platform component; anything that grows the always-on footprint;
new third-party dependencies or Helm chart sources; changes to CI, the quality gates, or
`Makefile` targets; security-adjacent changes (auth, RBAC, network exposure); authoring
new ADRs; editing `CHARTER.md` (goals) or *this file* (governance); `infra/` bootstrap
changes. The architect routine makes the binding decision and files it as an
`rfc`-labeled GitHub issue (and, where the decision requires it, an accompanying
`arch/*` PR that lands the ADR, the `CHARTER.md` update, and any `infra/` change). The
planner grooms the RFC into 🟢 executor items on its next run without waiting for a
human to approve the RFC — the architect's decision *is* the approval. **As of
2026-07-13 (§0.1), a PR editing `WAYS-OF-WORKING.md`, `CHARTER.md`, or an ADR self-merges
like any other Yellow PR** — the prior rule requiring a human for governance-touching
merges is superseded; the maintainer's explicit "AI should fully control the repo"
instruction *is* that approval, the same way an architect RFC is approval for a new
component.

**🔴 Red — humans only; an agent must refuse and escalate.** Secrets/credentials of any
kind; any live-cluster or production infrastructure mutation; destructive git history
operations (force-push, branch/data deletion, history rewrite); disabling or altering
another agent. These four are unchanged by the 2026-07-13 full-control grant (§0.1) —
they're a different risk category (credential exposure, real infrastructure damage, or
unrecoverable data loss) than "who can merge a PR," which the grant *was* about.

**Always, regardless of tier:** never weaken or skip a gate; never merge with a red CI
check or an unresolved conversation — CI no longer *blocks* this at the platform level
(§4), so it is enforced by agent discipline alone; never touch the four Red-tier
categories above without an explicit, specific human instruction covering that exact
action.

## 3. Agent PR contract (definition of done)

- **One item per PR**, focused and bounded (target < ~400 changed lines; larger work is
  split by the planner first). Reviewers may reject oversized PRs on sight.
- **Branch prefix signals origin:** `auto/*` (executor), `plan/*` (planner), `arch/*`
  (architect), `upgrade/*` (upgrade drafter), `sync/*` (doc-drift author), `digest/*`
  (industry-news writer); `feat/*` / `fix/*` / `chore/*` (humans). Agent prefixes are
  reserved — humans don't use them.
- **PR body must state:** what changed + why, the ROADMAP item / issue it addresses, and
  that it's an agent run plus which routine produced it.
- **Green before review:** `make ci` passes; ADRs honored; heavy components stay
  non-auto-synced; docs/dashboards in sync.
- **Self-merge (any tier, including governance):** once every required status check is
  green, the `[self-review]` comment is posted, and all conversations are resolved, the
  authoring routine merges its own PR (squash, matching `main`'s linear-history
  convention) and updates the ROADMAP checkbox / closes the issue it addressed. It must
  **not** merge if any required check is red or a conversation is unresolved — those
  hold regardless of tier. It must never touch the four 🔴 Red-tier categories (§2) at
  all, merge or otherwise (§0.1).

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
  `[self-review]` posted, conversations resolved, never touching the four Red-tier
  categories) is now the *only* thing standing between a broken change and `main` —
  GitHub will no longer catch a violation of it.** Every routine and every human working
  this repo must treat those rules as load-bearing, not advisory, precisely because
  nothing else enforces them anymore. This doc still says "never merge with a red CI
  check" and "never touch a Red-tier category without explicit instruction" (§2) — those
  are no longer *technically* prevented for CI, only *behaviorally* required. If a
  routine misbehaves, the backstop is the kill-switch (§5: disable the routine) and
  reverting the bad commit, not a rejected API call.

  **Optional hardening the maintainer could still add later:** re-enable required status
  checks + linear history (without reintroducing "PR required" or CODEOWNERS-approval,
  which would reinstate a human gate the maintainer has explicitly removed). Noted here
  as an available knob, not a recommendation to act on — the maintainer's 2026-07-13
  direction was unambiguous and this doc shouldn't second-guess it.

- **`CODEOWNERS` owners** — file exists but all domain owners are `@tbd` (see §7
  ownership map). As the team grows, replace `@tbd` entries with real owners. Even with
  the CODEOWNERS *requirement* gone from branch protection, an agent PR is still **never**
  approved by an agent — self-merge is not self-*approval*; the CI-green + self-review +
  tier check together stand in for approval, they don't forge one.

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
  merging — combined with green required CI, this **is** the self-merge trigger for any
  tier (§0.1, §3), including PRs that touch governance files. It never substitutes for
  a human's ability to review after the fact, comment, or revert — self-merge removes
  the pre-merge gate, not post-merge accountability.
- **Staleness SLA:** an agent PR with no review in N working days is flagged or auto-closed,
  not left to rot. Closing is cheap — the item simply returns to the backlog.

## 5. Cost & kill-switch

- **Free quota: 5 routine runs per rolling 24h.** Beyond that, runs use usage credits *only
  if* the "additional runs" toggle is on (otherwise they're skipped — a hard free cap).
  Current allocation runs at the cap every day — all slots filled, none wasted (reviewer
  retired 2026-06-10; a second executor trigger adds a 4th run on non-Thursday days,
  since one cron expression can't encode "4/day except Thu"):
  - **Mon:** executor (4) + planner (1) = 5
  - **Tue:** executor (4) + architect (1) = 5
  - **Wed:** executor (4) + triager (1) = 5
  - **Thu:** executor (3) + planner (1) + upgrade-drafter (1) = 5
  - **Fri:** executor (4) + doc-drift-author (1) = 5
  - **Sat:** executor (4) + triager (1) = 5
  - **Sun:** executor (4) + industry-news-writer (1) = 5

  No headroom — adding any new routine or raising any cadence requires cutting an
  executor slot or enabling the paid "additional runs" toggle. (The local verifier and
  operator are invoked by hand on the maintainer's machine; they have no cron and no
  quota cost.)
- **Night-time window + rolling-24h credit safety.** All runs fire in a fixed nightly
  window at **five fixed clock-times every day — 21:00, 22:00, 23:00, 00:00, 01:00 UTC**
  (~23:00–04:00 in the maintainer's Europe/Tallinn TZ, night in both EET and EEST so no
  DST flip drifts a slot into the working day). The times are *fixed* deliberately: the
  free cap is per **rolling** 24h, not per calendar day, so because the set of fire-times
  is identical every day (only which routine fills each slot changes), every rolling 24h
  window holds exactly 5 runs and the schedule can never spill into paid "additional runs"
  credits. Clustering at night *without* fixing the times would let two nights' runs land
  in one 24h window (6+ runs) and burn credits. Slots: 21/22/23:00 = executor base;
  00:00 = executor slot-filler (or upgrade-drafter on Thu); 01:00 = routine-of-the-day.
- Spend scales with **cadence × model × routine count**; the registry records all three, and
  the routine's owner is accountable for it.
- **Scale-out rule:** add agents or raise cadence only when there is review capacity to
  absorb the extra output. Generation is cheap; safe review is not.
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
  acceptance criteria stated; tier known (🟢/🟡/🔴) and any 🟡 RFC linked; owning domain /
  CODEOWNER identified; clusterless-deliverable.
- **Definition of Done**: the agent PR contract (§3), merged through the gate (§4).

### Intake & triage

- Work enters as a **GitHub issue** — already the planner's intake queue.
- **Triage** (2–3×/week, rotating owner): label new issues (domain, tier, priority), close
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
