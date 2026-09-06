# `scripts/ensure-lint-tools-hook.sh` — auto-install `shellcheck`/`yamllint` at session start so `make ci`'s lint gate can't silently self-skip either

CLAUDE.md's bugfix-recurrence-prevention rule; JANITOR-fallback cleanup 2026-09-06,
a direct follow-up to `auto/ensure-bats-hook` (#1448) earlier this same run — same
footgun class, a different pair of tools. Found live checking whether the ArgoCD
chart-bump candidate an earlier cycle's `[Action needed]` note (#1450) mentioned
could be attempted more safely with `kustomize`/`helm` installed locally: neither
was installed either, and neither is `shellcheck`/`yamllint` — `scripts/lint.sh`'s
own local/CI skip (`command -v shellcheck`/`yamllint`, soft-skip locally, hard-fail
under `CI=true`) meant this session's own `make ci` had been silently skipping the
entire `lint` gate the whole run, on every one of this run's prior PRs, exactly the
same self-review blind spot the bats fix closed for the `unit` gate.

## What was done

Added `scripts/ensure-lint-tools-hook.sh`, a best-effort `SessionStart` hook
(installs `shellcheck`/`yamllint` via `apt-get` if missing, silently no-ops if
`apt-get`/network/permission isn't available — never blocks the session) wired
into `.claude/settings.json`. Once both are on `PATH`, `scripts/lint.sh`'s own
existing local/CI branch naturally takes the "run the real check" path for the
rest of the session — no change needed to `lint.sh` itself.

Verified live: running `bash scripts/lint.sh` after installing both tools found
**zero pre-existing lint findings** across the whole repo — the GitHub Actions
backstop had genuinely been keeping this clean the whole time; installing the
tools locally didn't surface a hidden violation this PR would otherwise need to
fix. This confirms the gap was purely a local self-review blind spot, not a sign
of accumulated drift.

Added `tests/hook-scripts-ensure-lint-tools.bats` (its own file per
`tests/hook-scripts-coverage.bats`'s frozen-monolith rule, mirroring
`tests/hook-scripts-ensure-bats.bats`'s structure for the sibling hook) covering:

- the script exists and is executable;
- it exits 0 and reports "already installed" for both `shellcheck` and `yamllint`
  when present (the actual path this very bats run itself exercises —
  self-verifying);
- it exits 0 even with no `apt-get`/tools on `PATH` (a minimal `PATH` containing
  only a symlinked `bash` binary, same technique as the bats hook's own test, so
  the never-blocks branch is exercised without breaking `env`'s own ability to
  resolve `bash`);
- it is actually wired into `.claude/settings.json`, and that file is still valid
  JSON after the edit.

## Why this is in scope for a JANITOR cycle

Direct continuation of the same mechanical-guard principle CLAUDE.md requires:
having found and fixed one instance of "a required `make ci` tool is silently
missing in this remote sandbox," checking for sibling instances of the exact same
class is the obvious next step, not a new investigation. `kustomize`/`helm`/
`kubeconform`/`terraform`/`tflint` (used by `validate-kustomize.sh`,
`validate-manifests.sh`, `validate-terraform.sh`) have the identical soft-skip
shape but are out of scope for this specific PR — they aren't `apt-get`-installable
Ubuntu packages the way `shellcheck`/`yamllint` are, and would need binary-download
installation (version pinning, architecture detection, checksum verification) that
deserves its own separate, more carefully-scoped PR rather than being folded into
this one.

## Result

`make ci` passes green (2929+ bats assertions, including the 5 new
`tests/hook-scripts-ensure-lint-tools.bats` assertions, 0 failures).
`.claude/settings.json` remains valid JSON. No `gitops/` change — this is
tooling/session-config only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1451
