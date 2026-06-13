# Ways of Working — Agent Governance & Review

> **Scope.** The team operating model for k8s-lab: how autonomous agents operate in this
> repo, how *all* changes (human and agent) are reviewed and merged (§0–§6), and the team
> process around them — backlog, planning, ownership (§7).
>
> **Status.** Target operating model for scaling k8s-lab to a team. Controls that still
> need repo configuration are marked _⚙ to wire_. Today the repo runs two routines (see the
> registry) under a single maintainer; this is what "good" looks like as that grows.

## 0. Principles (non-negotiable)

1. **Agents are contributors, not admins.** Every agent change lands as a PR and clears the
   *same* bar as a human change. No special merge path.
2. **Humans own merge; agents own design and implementation.** The architect makes
   binding technical decisions (RFCs, ADRs); the planner sequences them; the executor
   implements. The human's only gate is the merge button on the resulting PRs. Agents
   *propose* what ships; humans decide *whether* to ship it by merging or closing.
   **The merge button is the maintainer's ONLY touchpoint.** The maintainer does not work
   issues. An agent must never assign the maintainer an action item it can perform itself
   with the tools it has (creating/applying labels, re-tagging, commenting, closing its
   own issues, opening follow-up issues) — "maintainer: please do X" in an issue is a
   routine bug unless X is genuinely 🔴 Red (secrets, repo settings, branch protection,
   a CHARTER/governance decision). If a tool call fails, fall back to `gh` before
   escalating; escalate only what §2 actually reserves for humans.
3. **The repo is the only rulebook agents obey.** Remote agents see only what's in git, so
   [CHARTER.md](../CHARTER.md), the [ROADMAP.md](../ROADMAP.md) rules, the ADRs in
   [decisions/](decisions/), and this doc are the *complete* set of rules. A governance
   change takes effect only once it's merged.
4. **Review capacity is the constraint, not generation.** Agents are throttled so they
   never out-produce the team's ability to review safely (see §4 WIP limits).

## 1. Agent registry (every routine has a human owner)

No unregistered autonomous routine may run against this repo. Each is owned by one
accountable human — for its output **and** its cost. Adding, re-scoping, or changing a
routine's model/cadence is a PR that edits this table.

**Remote routines (cloud, clusterless):**

| Routine | Trigger ID | Owner | Purpose | Cadence · Model | Branch | Max tier |
|---|---|---|---|---|---|---|
| Executor | `trig_01CRtpmaS1scBQL74xKqmfvS` | @tooming | implements one ROADMAP item / run; empty lane ⇒ escalates through the blocking role's work (planner → architect → upgrade-drafter → doc-drift → triager) so no slot is wasted | 21–23:00 UTC nightly (3/day) · Sonnet 4.6 | `auto/*` (fallback roles keep their own prefixes) | 🟢 Green |
| Executor 4th slot | `trig_011X276UrgGJWLsgC9Apneok` | @tooming | same prompt as the executor (incl. the fallback chain); fills the day's 5th quota slot | 00:00 UTC daily except Thu · Sonnet 4.6 | `auto/*` | 🟢 Green |
| Planner | `trig_015uWP3Hv1LTREpKzzkMkpUE` | @tooming | grooms CHARTER gaps + issues → ROADMAP | Mon + Thu 01:00 UTC · Opus 4.7 | `plan/*` | 🟢 Green |
| Architect | `trig_01SpewghyraZDSrLoGA32nBe` | @tooming | researches best practices → opens RFC issues for 🟡 items | weekly Tue 01:00 UTC · Opus 4.7 | `arch/*` | 🟢 Green |
| Triager | `trig_01E6ugxYJY6yGzwvSHSgFaCx` | @tooming | labels open issues with domain / tier / priority | Wed + Sat 01:00 UTC · Sonnet 4.6 | — (labels) | 🟢 Green |
| Upgrade drafter | `trig_01UyN9qcTFvWD14k38tn49K1` | @tooming | bumps existing chart/image versions, one PR per run | weekly Thu 00:00 UTC · Sonnet 4.6 | `upgrade/*` | 🟢 Green |
| Doc-drift author | `trig_01AibRNtdZLqLu3a58jDxnFk` | @tooming | reconciles README + dependency-tree + lab-UI drift | weekly Fri 01:00 UTC · Sonnet 4.6 | `sync/*` | 🟢 Green |
| Industry-news writer | `trig_01GNuyixzT3TBDF7Mk4ZeSTr` | @tooming | weekly upstream-news digest under `docs/industry/` (feeds the architect's ADR audit) | weekly Sun 01:00 UTC · Sonnet 4.6 | `digest/*` | 🟢 Green |

> **Retired — Reviewer** (`trig_01Dw7US6aZmJo8XZwDikoNkG`, daily 17:30 UTC, retired
> 2026-06-10): cron-based review structurally lagged PR-open — PRs were merged between
> slots and the routine spent runs filing idle issues (#160). First-pass review now
> happens **inside each PR-producing run**: the executor, planner, architect, and
> upgrade-drafter prompts end with a mandatory self-review step that audits the run's own
> diff against the four review checks (gate integrity, ADR compliance, tier discipline,
> ADR-0004 fabricated content — plus the adversarial design review for `arch/*`) and
> posts a `[self-review]` comment + `self-reviewed` label on the PR before the run ends.
> The backend trigger stays disabled as an audit trail; its daily slot funded the
> executor's restoration to 3/day.

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
| 🟢 **Green** | Agent, unsupervised → PR + normal review | Docs, comments, tests; non-auto-synced manifests; dashboards from real metrics; README / `dependency-tree.md` sync; ROADMAP grooming |
| 🟡 **Yellow** | Architect authors a binding RFC → planner grooms it → executor implements (no human-approval step) | New platform component; anything growing the always-on footprint; new deps / Helm sources; CI, gate, or `Makefile` changes; security-adjacent (auth, RBAC, network exposure); ADR-authoring; `infra/` bootstrap changes |
| 🔴 **Red** | Humans only — agent must refuse & escalate | Secrets; any live-cluster / prod change; **merging** PRs; repo settings / branch protection / CODEOWNERS; force-push, deletion, history rewrite; disabling another agent; editing CHARTER.md (goals) or this governance doc |

Full definitions:

**🟢 Green — autonomous (PR + normal review).** Docs, comments, tests; clusterless
manifests that are *not* auto-synced (per the 12 GB budget rule); Grafana dashboards built
from real metrics; `docs/dependency-tree.md` and README sync; ROADMAP grooming. This is the
executor's and planner's day-to-day lane.

**🟡 Yellow — architect-decided, no human-approval step.** A new platform component;
anything that grows the always-on footprint; new third-party dependencies or Helm chart
sources; changes to CI, the quality gates, or `Makefile` targets; security-adjacent
changes (auth, RBAC, network exposure); authoring new ADRs; `infra/` bootstrap changes.
The architect routine makes the binding decision and files it as an `rfc`-labeled GitHub
issue (and, where the decision requires it, an accompanying `arch/*` PR that lands the ADR
and any `infra/` change). The planner grooms the RFC into 🟢 executor items on its next
run without waiting for a human to approve the RFC — the architect's decision *is* the
approval. The human gate remains the merge button on every resulting PR.

**🔴 Red — humans only; an agent must refuse and escalate.** Secrets/credentials of any
kind; any live-cluster or prod mutation; **merging** PRs; repo settings, branch protection,
or CODEOWNERS; force-push, branch/data deletion, history rewrite; editing CHARTER.md
(goals) or this governance doc; disabling or altering another agent.

**Always, regardless of tier:** never weaken or skip a gate, never self-merge, never push to
`main`, never access credentials.

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

## 4. Review & merge gate (identical for humans and agents)

_GitHub repo settings (configured 2026-06-13):_

- **Branch protection on `main`** — active. Rules enforced (no bypass, admins included):
  - PR required before merging; no direct pushes to `main`.
  - ≥ 1 approval required; stale approvals dismissed on new commits.
  - CODEOWNERS review required (routes PRs to domain owners by path).
  - Required status checks (all must pass): `lint`, `manifests`, `terraform`,
    `kustomize`, `unit`, `drift` (from the `ci` workflow) and `up-to-date`
    (from `pr-up-to-date`).
  - Branches must be up to date with `main` before merging.
  - Linear history enforced (no merge commits on `main`).
  - All conversations must be resolved before merging.

_⚙ still to wire:_

- **`CODEOWNERS`** — file exists but all domain owners are `@tbd` (see §7 ownership
  map). As the team grows, replace `@tbd` entries with real owners; until then the
  CODEOWNERS requirement is satisfied by the maintainer (@tooming) for all paths.
  An agent PR is **never** approved by an agent.

_Process:_

- **Who reviews an agent PR:** the human CODEOWNER for the touched paths. It's a normal PR —
  reviewed for correctness, scope, **gate integrity** (did the agent quietly weaken a test
  or loosen a check?), and security. CI-green is necessary, not sufficient; don't
  rubber-stamp.
- **WIP limit:** cap concurrent open agent PRs (suggested ≤ 3 `auto/*` + ≤ 1 each of
  `plan/*`, `arch/*`, `upgrade/*`, `sync/*`, `digest/*`). At the cap, agents wait instead
  of piling on. (The executor already skips items with an open `auto/*` PR; the cap
  generalizes that to protect reviewer attention.) Every PR-producing routine posts a
  first-pass `[self-review]` comment (+ `self-reviewed` label) on its own PR before its
  run ends — it does NOT replace human review, and a self-review never counts as the
  human approval the gate requires.
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
