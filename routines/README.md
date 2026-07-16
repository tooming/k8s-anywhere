# routines/ — the scheduled remote agents, as code

The version-controlled **source of truth** for the scheduled remote Claude Code
agents that develop this repo. The claude.ai routines backend holds the *running*
state; the files here are the *desired* state.

### Remote scheduled routines (cloud, clusterless)

**Only one trigger is actually live.** [`routines.yaml`](routines.yaml) is the source of
truth — this section mirrors it, not the other way around. The executor fires on cron
from claude.ai (5×/day, every day — see `routines.yaml` for the exact times) and only
sees what's in git, never the live cluster. Each run now loops through as many ROADMAP
items as it can (`executor.prompt.md` STEP 8) instead of stopping after one, so "a run"
and "one item" are no longer the same thing.
Every other prompt file below was a separately-scheduled trigger until **2026-06-13**,
when all of them were retired and absorbed into the executor's own fallback chain
(`executor.prompt.md` STEP 6b: an empty ROADMAP lane makes the executor read and execute
the next blocked role's prompt file itself, in the same run). They stay in this
directory as fallback targets and on-demand local invocations, not as scheduled triggers.

| File | What |
|------|------|
| [`routines.yaml`](routines.yaml) | per-routine metadata: `trigger_id`, `cron`, `model`, env, tools, `prompt_file`, `live_prompt` (the short pointer actually pushed to the live trigger — see "Pointer architecture" below) |
| [`executor.prompt.md`](executor.prompt.md) | **the only live trigger.** Implementer (see `routines.yaml` for cadence), `auto/*` PRs, one PR per item but many items per run (STEP 8 loop); falls back through the roles below when its own lane is empty |
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

## Pointer architecture (2026-07-15)

A live trigger's actual content is `routines.yaml`'s `live_prompt` — a short,
effectively-static instruction telling the run to read `prompt_file` (e.g.
`executor.prompt.md`) from the already-checked-out repo and follow it in full.
The real operating contract lives **only** in `prompt_file` and is read fresh
every run; it is **never baked into the trigger**. This means:

- **Editing a `*.prompt.md` file needs no apply step at all.** It's a normal PR,
  reviewed like any other diff, live the moment it merges to `main` — the next
  run reads whatever is on `main` at fetch time.
- **Editing `routines.yaml`'s structural fields** (`cron`, `model`, `enabled`,
  `allowed_tools`, `live_prompt`, `environment_id`) is the only thing that still
  needs the apply dance below, because those fields are pushed to the live API.

## Changing a routine

**A `*.prompt.md` file** (the actual instructions the executor or a fallback
role follows): just edit it and open a PR. Nothing else to do — no apply step,
because it's never baked into any trigger.

**`routines.yaml`** (cadence/model/enabled/tools/`live_prompt`/environment):

1. Edit the file.
2. Open a PR — reviews like any other diff.
3. After merge, **apply**: ask Claude Code *"apply the routines"*. It reads the
   file and syncs the backend — `RemoteTrigger create` when `trigger_id` is empty
   (then writes the new id back here), else `RemoteTrigger update`.
4. Run `make routines-mark-applied` to refresh `.routines-applied` (see below).

## Why "apply" is run by Claude Code, not a CI script

The routines API is reached through Claude Code's in-process `RemoteTrigger` tool with
managed OAuth — there is **no exposed token to `curl`** from CI. So Claude Code is the
"apply" tool, the way someone runs `terraform apply` by hand. If a routines CLI or API
token becomes available, wrap it as `make routines-apply` / `make routines-check` and
add the latter to the `ci` gate.

## Why the autonomous executor may not edit routines.yaml (but may edit *.prompt.md files)

The cloud executor runs with `allowed_tools = [Bash, Read, Write, Edit, Glob, Grep]` —
**no `RemoteTrigger`**. So it physically *cannot* apply a `routines.yaml` change to the
live trigger. If it edited `routines.yaml` (cron/model/enabled/`live_prompt`/etc.) and ran
`make routines-mark-applied`, `routines-check` would stay green (the snapshot matches the
file) while the **live trigger silently drifts** from the repo — that is exactly how the
old baked-prompt version of this footgun bit us before the 2026-07-15 pointer-architecture
change (the merged JANITOR rung #251 and the `docs/done/` STEP 6 went missing from the
live executor trigger until #263 repaired them by hand).

Since that change, `*.prompt.md` files are no longer baked into any trigger at all — they're
read live from the checked-out repo every run — so editing one carries **zero** live-drift
risk. `routines.yaml` is the only file whose content is ever pushed to the live API, so it's
the only one still protected.

`routines-check` can't catch `routines.yaml` drift by itself — CI has no claude.ai token to
compare against the live trigger. So the footgun is removed *structurally*:
**`scripts/routines-author-check.sh`** (`make routines-author-check`, wired into `make ci`
and the GitHub Actions `drift` job) **fails any executor-authored change that touches
`routines.yaml`.** "Executor-authored" = the branch matches `routines.yaml`'s
`branch_prefix` (`auto/`) *or* the commit author is the cloud identity
`Claude <noreply@anthropic.com>`. The result: only interactive Claude Code sessions —
which *can* `RemoteTrigger update` + `make routines-mark-applied` in the same session —
ever change `routines.yaml`. If the executor needs a cadence/model/`live_prompt` change,
it opens an issue instead — a hard tool-access limit (the cloud executor has no
`RemoteTrigger` tool at all), not a scope choice. It may, however, freely edit its own or
any fallback role's `*.prompt.md` directly, the same as any other repo file.

**An interactive session's apply call can fail — verify, don't assume.** The
`update_trigger` tool is documented to only let an agent push new `prompt`/`name`
content to a trigger *it created itself* via `create_trigger`. The original executor
trigger (`trig_01CRtpmaS1scBQL74xKqmfvS`, since retired for an unrelated reason — see
#423 — and superseded by `trig_01XxtSdkPdRNjBfAidUXTwos`) was created via the claude.ai
UI/API directly (`created_via: "http_api"`), not by any agent. Two sessions (PR #374, PR
#391/#396) got refused on this basis (`"Agents can only update routines they created"`,
sometimes an opaque stream-closed error instead) and concluded updates were permanently
impossible — but a later session (2026-07-14) called the *same* `update_trigger` against
the *same* trigger id and it succeeded. So treat a refusal as possibly transient: retry
in a fresh session before assuming it's permanent. If it does fail: land the repo change
anyway and say so plainly in the PR, but do **not** run `make routines-mark-applied` —
that file is a claim the live trigger matches the repo (ADR-0004), and it would be
false. `routines-check` stays red until either a later session's apply succeeds or the
maintainer applies the change by hand through the claude.ai routines UI — and a red
`routines-check` is never grounds to merge anyway (WAYS-OF-WORKING.md §4's "never merge
red CI" is absolute).

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
