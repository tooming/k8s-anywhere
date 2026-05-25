# routines/ — the scheduled remote agents, as code

The version-controlled **source of truth** for the two scheduled remote Claude Code
agents that develop this repo. The claude.ai routines backend holds the *running*
state; the files here are the *desired* state.

| File | What |
|------|------|
| [`routines.yaml`](routines.yaml) | per-routine metadata: `trigger_id`, `cron`, `model`, env, tools, `prompt_file` |
| [`executor.prompt.md`](executor.prompt.md) | the executor's prompt (every-6h implementer, `auto/*` PRs) |
| [`planner.prompt.md`](planner.prompt.md) | the planner's prompt (weekly groomer, `plan/*` PRs) |

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
