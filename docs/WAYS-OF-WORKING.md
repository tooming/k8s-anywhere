# Ways of Working — Agent Governance & Review

> **Scope.** The first half of the team operating model: how autonomous agents operate in
> this repo, and how *all* changes (human and agent) are reviewed and merged. The other
> half — backlog tooling, planning/triage cadences, the domain-ownership map — is deferred;
> see [Deferred](#deferred).
>
> **Status.** Target operating model for scaling k8s-lab to a team. Controls that still
> need repo configuration are marked _⚙ to wire_. Today the repo runs two routines (see the
> registry) under a single maintainer; this is what "good" looks like as that grows.

## 0. Principles (non-negotiable)

1. **Agents are contributors, not admins.** Every agent change lands as a PR and clears the
   *same* bar as a human change. No special merge path.
2. **Humans own priority, merge, and architecture.** Agents *propose* and *implement*
   well-scoped, low-risk work; humans decide what matters and what ships.
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

| Routine | Trigger ID | Owner | Purpose | Cadence · Model | Branch | Max tier |
|---|---|---|---|---|---|---|
| Executor | `trig_01CRtpmaS1scBQL74xKqmfvS` | @maintainer | implements one ROADMAP item / run | 5h · Sonnet 4.6 | `auto/*` | 🟢 Green |
| Planner | `trig_015uWP3Hv1LTREpKzzkMkpUE` | @maintainer | grooms CHARTER gaps + issues → ROADMAP | weekly · Opus 4.7 | `plan/*` | 🟢 Green |

_(Replace `@maintainer` with the owning engineer or team as the team grows.)_

## 2. Autonomy tiers (what an agent may do unsupervised)

Every agent action falls in a tier. An agent that hits work above its registered tier must
**stop and open an issue for a human** — never proceed.

**🟢 Green — autonomous (PR + normal review).** Docs, comments, tests; clusterless
manifests that are *not* auto-synced (per the 12 GB budget rule); Grafana dashboards built
from real metrics; `docs/dependency-tree.md` and README sync; ROADMAP grooming. This is the
executor's and planner's entire lane.

**🟡 Yellow — needs a human-authored issue/RFC first (agent may then implement).** A new
platform component; anything that grows the always-on footprint; new third-party
dependencies or Helm chart sources; changes to CI, the quality gates, or `Makefile`
targets; security-adjacent changes (auth, RBAC, network exposure).

**🔴 Red — humans only; an agent must refuse and escalate.** Secrets/credentials of any
kind; any live-cluster or prod mutation; **merging** PRs; repo settings, branch protection,
or CODEOWNERS; force-push, branch/data deletion, history rewrite; editing CHARTER.md
(goals), the ADRs (decisions), or this doc; disabling or altering another agent; `infra/`
bootstrap changes that could break recreate-from-code.

**Always, regardless of tier:** never weaken or skip a gate, never self-merge, never push to
`main`, never access credentials.

## 3. Agent PR contract (definition of done)

- **One item per PR**, focused and bounded (target < ~400 changed lines; larger work is
  split by the planner first). Reviewers may reject oversized PRs on sight.
- **Branch prefix signals origin:** `auto/*` (executor), `plan/*` (planner), `feat/*` /
  `fix/*` (humans). Prefixes are reserved — humans don't use `auto/` or `plan/`.
- **PR body must state:** what changed + why, the ROADMAP item / issue it addresses, and
  that it's an agent run plus which routine produced it.
- **Green before review:** `make ci` passes; ADRs honored; heavy components stay
  non-auto-synced; docs/dashboards in sync.

## 4. Review & merge gate (identical for humans and agents)

_⚙ to wire (GitHub repo settings):_

- **Branch protection on `main`:** no direct pushes; PR required; required status check =
  CI (`make ci`); ≥ 1 human approval (≥ 2 for Yellow-tier changes); **CODEOWNERS** review
  required; no self-approval / self-merge; linear history (which also retires the
  planner/executor rebase wrinkle).
- **`CODEOWNERS`** routes each PR to its owning humans by path (e.g.
  `gitops/observability/` → the observability owners). An agent PR is **never** approved by
  an agent.

_Process:_

- **Who reviews an agent PR:** the human CODEOWNER for the touched paths. It's a normal PR —
  reviewed for correctness, scope, **gate integrity** (did the agent quietly weaken a test
  or loosen a check?), and security. CI-green is necessary, not sufficient; don't
  rubber-stamp.
- **WIP limit:** cap concurrent open agent PRs (suggested ≤ 3 `auto/*` + ≤ 1 `plan/*`). At
  the cap, agents wait instead of piling on. (The executor already skips items with an open
  `auto/*` PR; the cap generalizes that to protect reviewer attention.)
- **Staleness SLA:** an agent PR with no review in N working days is flagged or auto-closed,
  not left to rot. Closing is cheap — the item simply returns to the backlog.

## 5. Cost & kill-switch

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

## Deferred

The team-process half is not yet written: backlog tooling (migrating `ROADMAP.md` to a
concurrent tracker once several humans edit it), planning/triage cadences, definition of
ready, per-domain charters, and the ownership / CODEOWNERS map. Tracked as a follow-up.
