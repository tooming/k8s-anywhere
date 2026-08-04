# Extract shared scripts/lib/confirm.sh from dr-chaos.sh, dr-destroy.sh, dr-test.sh, dr-bluegreen-promote.sh

(CLAUDE.md's mechanical-guard/dedup ethos; janitor fallback role, invoked via
`executor.prompt.md` STEP 6b — the executor's own Now/next lane was fully
gated this run (all three remaining 🟢 items blocked on the standing
maintainer-confirmation issues #631/#633), and the planner/architect/
upgrade-drafter*/doc-drift-author/triager fallback roles above janitor in the
chain each yielded no further real deliverable this cycle.

*this run's upgrade-drafter pass already delivered one `upgrade/*` PR
(#981, grafana chart 12.10.0 → 12.10.2) earlier in the same run — STEP 6b's
own scope note caps that role at one `upgrade/*` PR per run, so a second
upgrade wasn't picked up again this cycle even though it would otherwise be
the next rung up the fallback chain.)

`scripts/dr-chaos.sh`, `scripts/dr-destroy.sh`, `scripts/dr-test.sh`, and
`scripts/dr-bluegreen-promote.sh` each hand-rolled a byte-similar "type the
word back to confirm" destructive-action gate: `DR_ASSUME_YES=1` bypass check,
a warning message, a `[ -t 0 ]` TTY check, `read -r -p "Type '<word>' ...: "`
+ exact-match-or-abort, and an identical `else` branch refusing outright with
"Refusing non-interactively without DR_ASSUME_YES=1." on stderr. This is the
same class of duplication already extracted three times before in this repo —
`scripts/lib/colors.sh` (ANSI color setup), `scripts/lib/budget-check.sh`
(wall-clock budget check/report), and `scripts/lib/hook-payload.sh`
(PostToolUse payload parsing) — so this mirrors that precedent rather than
inventing a new pattern.

## What changed

- New `scripts/lib/confirm.sh`: `confirm_or_abort <message> <confirm_word>
  [prompt_verb_phrase]`. Callers pass their own pre-formatted message string
  (so each script's exact coloring/trailing-space/newline choice is
  preserved byte-for-byte) and their own confirm word + optional prompt-verb
  phrase (defaults to `"to continue"`).
- `scripts/dr-chaos.sh` / `scripts/dr-destroy.sh` / `scripts/dr-test.sh` /
  `scripts/dr-bluegreen-promote.sh`: source the new lib; replaced their
  inline confirmation blocks with a single `confirm_or_abort` call each.
  `dr-test.sh`'s and `dr-bluegreen-promote.sh`'s post-confirmation
  `export DR_ASSUME_YES=1` (so children inherit the go-ahead) is caller-side
  logic and stays unchanged in each script.
- `tests/confirm-lib.bats` (new): structural + functional coverage for the
  lib, mirroring `tests/budget-check-lib.bats` — including a recurrence
  guard asserting every script with a `Type '...' to` confirmation prompt
  also sources `lib/confirm.sh`.
- `tests/dr-chaos.bats`: the two tests that grepped the script source
  directly for the literal strings `DR_ASSUME_YES` / `Refusing
  non-interactively...` (since that logic now lives in the shared lib,
  not the script itself) replaced with tests asserting the script sources
  `lib/confirm.sh` and calls `confirm_or_abort`.
- `tests/dr-bluegreen.bats`: same swap for its one now-stale
  `Refusing non-interactively` source-grep test (its `DR_ASSUME_YES`
  source-grep test still passes as-is — `dr-bluegreen-promote.sh` still
  literally contains that string via its own `export DR_ASSUME_YES=1` line).
- `tests/dr-guards.bats`: added a new runtime test —
  `dr-chaos.sh: refuses non-interactively without DR_ASSUME_YES` — actually
  executing the script non-interactively and asserting exit 1 + the real
  stderr message, matching the existing coverage style already used there
  for `dr-destroy.sh` / `dr-test.sh` / `dr-bluegreen-promote.sh`. This is
  strictly additive coverage: `dr-chaos.sh`'s non-interactive-refusal
  behavior previously had only a source-grep test (now replaced, see above),
  never an actual runtime-execution test.

Behavior-preserving: every script's exact warning-message text, coloring,
trailing whitespace/newline, confirm word, and prompt-verb phrase are
unchanged (each is now composed by the caller via `printf`/`$(...)` and
passed straight through — `confirm_or_abort` prints the message with `%s`,
no added formatting). The `DR_ASSUME_YES=1` bypass, TTY check, and
non-interactive refusal message/exit-code are all identical to before.

Verified by installing `bats` + `shellcheck` in-sandbox (neither was
preinstalled) and running the full suite: all `confirm-lib`/`dr-chaos`/
`dr-guards`/`dr-bluegreen` cases pass (`bats tests/confirm-lib.bats
tests/dr-chaos.bats tests/dr-guards.bats tests/dr-bluegreen.bats` → 8+55
green). Confirmed via `git stash` that the sandbox's pre-existing 13
unrelated failures (broken local `yq` binary variant, no network access —
`helm-chart-pin-check`, `argocd-crd-ssa-check`, `rollouts-plugin-list-check`,
their downstream sync-hook tests, plus two unrelated Kargo/kustomize-image
assertions) are identical before and after this change — only their line
numbers shifted (net +9 tests added). `shellcheck -S warning scripts/*.sh`
(the exact invocation `scripts/lint.sh` uses) is clean. `make ci`'s
tool-independent checks (lint, test) pass; the manifest/kustomize/terraform
validators remain sandbox-skipped (kubeconform/kustomize/terraform/
mikefarah-yq/helm aren't installed here — the full suite runs in GitHub
Actions per CLAUDE.md).

## PR

[#982](https://github.com/tooming/k8s-anywhere/pull/982)
