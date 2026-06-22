# routines/ — the scheduled remote agents, as code

The version-controlled **source of truth** for the scheduled remote Claude Code
agents that develop this repo. The claude.ai routines backend holds the *running*
state; the files here are the *desired* state.

### Remote scheduled routines (cloud, clusterless)

These fire on cron from claude.ai; they only see what's in git, never the live cluster.

| File | What |
|------|------|
| [`routines.yaml`](routines.yaml) | per-routine metadata: `trigger_id`, `cron`, `model`, env, tools, `prompt_file` |
| [`executor.prompt.md`](executor.prompt.md) | the executor's prompt (nightly implementer, 21–23:00 + 00:00 UTC, `auto/*` PRs) |
| [`planner.prompt.md`](planner.prompt.md) | the planner's prompt (Mon + Thu groomer, `plan/*` PRs) |
| [`architect.prompt.md`](architect.prompt.md) | the architect's prompt (weekly Tue RFC opener, `arch/*` PRs) |
| [`triager.prompt.md`](triager.prompt.md) | the triager's prompt (Wed + Sat issue labeller — labels only, never PRs) |
| [`upgrade-drafter.prompt.md`](upgrade-drafter.prompt.md) | the upgrade drafter's prompt (weekly Thu version-bump PR, `upgrade/*`) |
| [`doc-drift-author.prompt.md`](doc-drift-author.prompt.md) | the doc-drift author's prompt (weekly Fri README/dependency-tree/lab-UI reconciliation, `sync/*`) |
| [`janitor.prompt.md`](janitor.prompt.md) | the janitor's prompt (executor STEP 6b fallback — one bounded, behavior-preserving codebase-health cleanup, `chore/*`; no separate trigger) |
| [`industry-news-writer.prompt.md`](industry-news-writer.prompt.md) | the industry-news writer's prompt (weekly Sun digest in `docs/industry/`, `digest/*` — feeds the architect's ADR audit) |

> **Retired routines:** the **reviewer** (daily first-pass PR review) was retired
> 2026-06-10 — cron-based review kept lagging PR-open, so the first-pass review now
> happens *inside* each PR-producing run (the `[self-review]` step at the end of the
> executor / planner / architect / upgrade-drafter prompts); its backend trigger is kept
> disabled. The **learning-post writer** ([`learning-post-writer.prompt.md`](learning-post-writer.prompt.md))
> lost its Sun quota slot to the industry-news writer and is not scheduled.

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
