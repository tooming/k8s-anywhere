# Extract shared KCTX-aware kubectl() wrapper into scripts/lib/kctx.sh

(CLAUDE.md's mechanical-guard/dedup ethos; janitor fallback role, invoked via
`executor.prompt.md` STEP 6b — the executor's own Now/next lane was fully
gated this run (all three remaining 🟢 items blocked on the standing
maintainer-confirmation issues #631/#633), and the planner/architect/
upgrade-drafter*/doc-drift-author/triager fallback roles above janitor in the
chain each yielded no further real deliverable this run before this cycle.

*this run's upgrade-drafter pass already delivered one `upgrade/*` PR
(#981) earlier — capped at one per run per STEP 6b's own scope note.

Fourth janitor cleanup this run, after
[docs/done/2026-08-04-confirm-lib-dedup.md](2026-08-04-confirm-lib-dedup.md)
(PR #982),
[docs/done/2026-08-04-phase-canary-probe-lib-dedup.md](2026-08-04-phase-canary-probe-lib-dedup.md)
(PR #983), and
[docs/done/2026-08-04-skip-lib-dedup.md](2026-08-04-skip-lib-dedup.md)
(PR #984). This is the `kubectl()` context-wrapper duplication the same
whole-`scripts/*.sh` sweep found alongside `skip()`, deliberately deferred
to its own cycle/PR at the time since it's a distinct duplication class — a
live command wrapper, not just an output printer — from `skip()`.)

`scripts/cosign-bootstrap.sh`, `scripts/dr-verify.sh`,
`scripts/garage-bootstrap.sh`, `scripts/grafana-gitsync-bootstrap.sh`,
`scripts/lab-health-check.sh`, and `scripts/vault-bootstrap.sh` each
hand-rolled a byte-identical two-line pair: `KCTX="${KCTX:-}"` (optional
cluster-context override, unset = current context) followed by a `kubectl()`
shell function wrapping `command kubectl` to inject `--context "$KCTX"`
when set.

## What changed

- New `scripts/lib/kctx.sh`: the same two lines, sourced instead of
  copy-pasted.
- The 6 scripts: replaced their inline `KCTX=`/`kubectl()` pair with a
  single `source .../lib/kctx.sh` line. Left each script's own explanatory
  comment above the source line in place (some are generic, some carry
  script-specific reasoning, e.g. `vault-bootstrap.sh`'s note that unset
  KCTX keeps blue's `make up` path unchanged) — reconciliation only, no
  comment content changed.
- New `tests/kctx-lib.bats`: structural + functional coverage. The
  functional tests needed a real executable on `PATH` (not a shadowing
  shell function) as the fake `kubectl`, since the wrapper calls `command
  kubectl` — `command` explicitly bypasses shell functions/aliases and does
  a real `PATH` lookup, so a naive function-shadow mock would never
  actually be invoked. Caught this while first drafting the test (a
  function-based mock passed for the wrong reason — bash silently fell
  through to it despite `command`, revealing the test wasn't actually
  exercising `command`'s PATH-lookup semantics — corrected before shipping).

Behavior-preserving: both lines are unchanged, copy-pasted verbatim into the
shared location.

Verified: `bats` + `shellcheck` already installed in-sandbox (from earlier
janitor cleanups this run). Ran the full suite and diffed against unmodified
`main` via `git stash`: identical 13 pre-existing environment-tool failures
before and after (broken local `yq` variant, no network access), zero new
failures — only line numbers shifted (net +7 tests added).
`shellcheck -S warning scripts/*.sh` (the exact invocation `scripts/lint.sh`
uses) is clean. `make ci`'s tool-independent checks (lint, test) pass; the
manifest/kustomize/terraform validators remain sandbox-skipped
(kubeconform/kustomize/terraform/mikefarah-yq/helm aren't installed here —
the full suite runs in GitHub Actions per `CLAUDE.md`).

## PR

[#985](https://github.com/tooming/k8s-anywhere/pull/985)
