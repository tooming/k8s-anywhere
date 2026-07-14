# routines/ — the scheduled remote agents, as code

The version-controlled **source of truth** for the scheduled remote Claude Code
agents that develop this repo. The claude.ai routines backend holds the *running*
state; the files here are the *desired* state.

### Remote scheduled routines (cloud, clusterless)

**Only one trigger is actually live.** [`routines.yaml`](routines.yaml) is the source of
truth — this section mirrors it, not the other way around. The executor fires on cron
from claude.ai (5×/day, every day) and only sees what's in git, never the live cluster.
Every other prompt file below was a separately-scheduled trigger until **2026-06-13**,
when all of them were retired and absorbed into the executor's own fallback chain
(`executor.prompt.md` STEP 6b: an empty ROADMAP lane makes the executor read and execute
the next blocked role's prompt file itself, in the same run). They stay in this
directory as fallback targets and on-demand local invocations, not as scheduled triggers.

| File | What |
|------|------|
| [`routines.yaml`](routines.yaml) | per-routine metadata: `trigger_id`, `cron`, `model`, env, tools, `prompt_file` |
| [`executor.prompt.md`](executor.prompt.md) | **the only live trigger.** Nightly implementer (21:00/22:00/23:00/00:00/01:00 UTC, every day), `auto/*` PRs; falls back through the roles below when its own lane is empty |
| [`planner.prompt.md`](planner.prompt.md) | the planner's prompt — groomer, `plan/*` PRs. Fallback-only since 2026-06-13 |
| [`architect.prompt.md`](architect.prompt.md) | the architect's prompt — RFC opener, `arch/*` PRs. Fallback-only since 2026-06-13 |
| [`triager.prompt.md`](triager.prompt.md) | the triager's prompt — issue labeller, labels only, never PRs. Fallback-only since 2026-06-13 |
| [`upgrade-drafter.prompt.md`](upgrade-drafter.prompt.md) | the upgrade drafter's prompt — version-bump PR, `upgrade/*`. Fallback-only since 2026-06-13 |
| [`doc-drift-author.prompt.md`](doc-drift-author.prompt.md) | the doc-drift author's prompt — README/dependency-tree/lab-UI reconciliation, `sync/*`. Fallback-only since 2026-06-13 |
| [`janitor.prompt.md`](janitor.prompt.md) | the janitor's prompt — one bounded, behavior-preserving codebase-health cleanup, `chore/*`. Always fallback-only, never had its own trigger |
| [`learning-post-writer.prompt.md`](learning-post-writer.prompt.md) | weekly reflection post in `docs/learnings/`, `learn/*`. Always fallback-only, never had its own trigger |

> **Retired triggers** (kept disabled as an audit trail — no delete API): the
> **reviewer** (daily first-pass PR review, retired 2026-06-10 — cron-based review kept
> lagging PR-open, so first-pass review now happens *inside* each PR-producing run, the
> `[self-review]` step); and **planner, architect, triager, upgrade-drafter,
> doc-drift-author, industry-news-writer, and the old "executor 4th slot"** (all retired
> 2026-06-13, absorbed into the executor's fallback chain above — the industry-news
> writer's digest-gathering step folded into the architect prompt's own STEP 1). Do not
> re-enable any of these without also reworking the fallback chain, or work will
> double-fire from two triggers.

### Local on-demand roles (maintainer's machine, cluster-bound)

These can't be cloud routines — they need Colima and the live cluster. The maintainer
invokes them by hand in a Claude Code session. Listed in `routines.yaml` under
`local_roles:` for discoverability; no `trigger_id`, no cron, no quota cost.

| File | What |
|------|------|
| [`verifier.prompt.md`](verifier.prompt.md) | bring up the lab on an `auto/*` PR's branch and confirm acceptance criteria pass end-to-end |
| [`operator.prompt.md`](operator.prompt.md) | on-call pulse check; run DR drills; file `incident` issues when something needs a human |

## Changing a routine

1. Edit `routines.yaml` (cadence/model/etc.) and/or the relevant `*.prompt.md`.
2. Open a PR — a prompt or cadence change reviews like any other diff.
3. After merge, **apply**: ask Claude Code *"apply the routines"*. It reads these
   files and syncs the backend — `RemoteTrigger create` when `trigger_id` is empty
   (then writes the new id back here), else `RemoteTrigger update`.

## Why "apply" is run by Claude Code, not a CI script

The routines API is reached through Claude Code's in-process `RemoteTrigger` tool with
managed OAuth — there is **no exposed token to `curl`** from CI. So Claude Code is the
"apply" tool, the way someone runs `terraform apply` by hand. If a routines CLI or API
token becomes available, wrap it as `make routines-apply` / `make routines-check` and
add the latter to the `ci` gate.

## Why the autonomous executor may not edit these files

The cloud executor runs with `allowed_tools = [Bash, Read, Write, Edit, Glob, Grep]` —
**no `RemoteTrigger`**. So it physically *cannot* apply a routine change to the live
trigger. If it edits a `*.prompt.md` and runs `make routines-mark-applied`,
`routines-check` stays green (the snapshot matches the file) while the **live trigger
silently drifts** from the repo. That is exactly how the merged JANITOR rung (#251) and
the `docs/done/` STEP 6 went missing from the live executor trigger until #263 repaired
them by hand.

`routines-check` can't catch this — CI has no claude.ai token to compare against the
live trigger. So the footgun is removed *structurally*: **`scripts/routines-author-check.sh`**
(`make routines-author-check`, wired into `make ci` and the GitHub Actions `drift` job)
**fails any executor-authored change that touches a routine file.** "Executor-authored"
= the branch matches `routines.yaml`'s `branch_prefix` (`auto/`) *or* the commit author
is the cloud identity `Claude <noreply@anthropic.com>`. The result: only interactive
Claude Code sessions — which *can* `RemoteTrigger update` + `make routines-mark-applied`
in the same session — ever change routine files. If the executor needs a routine change,
it opens an issue for a human instead (the same way it defers any other out-of-tier work).

**An interactive session's apply call can fail — verify, don't assume.** The
`update_trigger` tool is documented to only let an agent push new `prompt`/`name`
content to a trigger *it created itself* via `create_trigger`, and
`trig_01CRtpmaS1scBQL74xKqmfvS` (the executor) was created via the claude.ai UI/API
directly (`created_via: "http_api"`), not by any agent. Two sessions (PR #374, PR
#391/#396) got refused on this basis (`"Agents can only update routines they created"`,
sometimes an opaque stream-closed error instead) and concluded updates were permanently
impossible — but a later session (2026-07-14) called the *same* `update_trigger` against
the *same* trigger id and it succeeded. So treat a refusal as possibly transient: retry
in a fresh session before assuming it's permanent. If it does fail: land the repo change
anyway and say so plainly in the PR, but do **not** run `make routines-mark-applied` —
that file is a claim the live trigger matches the repo (ADR-0004), and it would be
false. `routines-check` stays red until either a later session's apply succeeds or the
maintainer applies the change by hand through the claude.ai routines UI — and a red
`routines-check` is never grounds to merge anyway (WAYS-OF-WORKING.md §2 is absolute).

## Checking running state & drift

Ask Claude Code to *"list routines"* (`RemoteTrigger list`) and compare against
`routines.yaml`. Any difference is drift to reconcile — same spirit as the repo's
existing `readme-check` / `lab-ui-check` detectors. Editing a routine in the claude.ai
UI bypasses this file, so prefer changing it here.

## How this relates to the rest of the config

- **These files** = the *deployment config of the agents* — when they run, which model,
  and the exact prompt.
- [`CHARTER.md`](../CHARTER.md) / [`ROADMAP.md`](../ROADMAP.md) / [`docs/decisions/`](../docs/decisions/)
  / [`docs/WAYS-OF-WORKING.md`](../docs/WAYS-OF-WORKING.md) = the *content and rules the
  agents follow* at runtime.
