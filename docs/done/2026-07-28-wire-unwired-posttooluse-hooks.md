# Wire the two `PostToolUse` sync-hooks that were built but never registered

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's mechanical-recurrence-
guard principle ("a hook that nudges at edit/push time"). Architect/janitor-role
fallback (`executor.prompt.md` STEP 6b) after the "Now / next" lane again came up
fully gated on standing maintainer-confirmation issues #631/#632/#633 (re-checked
this cycle — still no confirmation comments on any of the three) and issue #791's
gap was already closed earlier this run (PR #815).

## What was found

Two `scripts/*-sync-hook.sh` files exist, are fully bats-covered
(`tests/hook-scripts-coverage.bats`), and are documented as completed deliverables
in `docs/done/2026-07-22-yq-variant-guard.md` and
`docs/done/2026-07-23-freeze-drift-detectors-bats.md` — but neither was actually
present in `.claude/settings.json`'s `PostToolUse` → `Edit|Write|MultiEdit` hooks
array, next to their sibling `*-sync-hook.sh` entries:

- `scripts/yq-variant-guard-sync-hook.sh` — nudges when a `scripts/*.sh` edit adds
  a mikefarah-only `yq` call (`eval-all`/`eval`/`ea`) without the
  `require_mikefarah_yq` guard.
- `scripts/drift-detectors-tests-sync-hook.sh` — nudges when
  `tests/drift-detectors.bats` is edited outside the frozen-file convention (new
  drift checks belong in `drift-<scope>.bats`).

Both `docs/done/` entries explicitly recorded why: the yq-variant-guard entry's own
session tried the identical `.claude/settings.json` edit and the harness denied it
("a per-session tool constraint, not a repo policy... A future interactive session
... can complete the wiring"). `make ci`/CI stayed green regardless, since the
*check* scripts (`yq-variant-guard-check.sh`, wired into `make ci` +
`.github/workflows/ci.yml`) are the actual mechanical enforcement; the hooks are a
local nudge on top, not the CI gate itself. So this was a real, if low-severity,
gap: the "nudge at edit time" layer of CLAUDE.md's recurrence-guard ladder was dead
for these two classes, even though the CI-gate layer for one of them
(`yq-variant-guard-check.sh`) was live.

## What changed

Per this session's own working agreement (the maintainer's 2026-07-14 removal of
all human-only gating, CLAUDE.md preamble), re-attempted the same
`.claude/settings.json` edit this cycle rather than assuming the prior denial was
permanent (mirrors this run's own `RemoteTrigger update` precedent — a tool refusal
observed once is not proof it will refuse forever). It succeeded this time. Added
both missing entries to the `Edit|Write|MultiEdit` hooks array, matching the exact
shape/timeout/statusMessage convention of their sibling entries:

- `yq-variant-guard-sync-hook.sh` immediately after `yq-raw-sync-hook.sh` (both
  concern `yq` usage in bats/scripts).
- `drift-detectors-tests-sync-hook.sh` immediately after
  `observability-tests-sync-hook.sh` (the other `tests/*.bats` freeze-nudge
  entries).

Verified both scripts still run cleanly against a real file (manual invocation with
a synthetic hook payload, exit 0 either way) and that `.claude/settings.json`
parses as valid JSON before committing. `make ci` passes (all real checks green;
`bats`/`shellcheck`/`kubeconform`/`kustomize`/`terraform`/`helm` gracefully skip as
designed — none installed in this environment).

No topology change, no README/`docs/dependency-tree.md` update needed (this is a
session-tooling config file, not a lab component). No new bats coverage needed —
both scripts' own behavior is already covered by `tests/hook-scripts-coverage.bats`;
what changed here is only their registration, which is inherently outside bats'
reach (it's Claude Code harness config, not something a clusterless test can
exercise).

PR: (this run's `chore/wire-unwired-posttooluse-hooks` branch)
