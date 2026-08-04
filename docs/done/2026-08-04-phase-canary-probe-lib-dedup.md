# Extract shared phase()/probe()/stop_probe() helpers from dr-bluegreen.sh, dr-bluegreen-promote.sh, dr-test.sh

(CLAUDE.md's mechanical-guard/dedup ethos; janitor fallback role, invoked via
`executor.prompt.md` STEP 6b — the executor's own Now/next lane was fully
gated this run (all three remaining 🟢 items blocked on the standing
maintainer-confirmation issues #631/#633), and the planner/architect/
upgrade-drafter*/doc-drift-author/triager fallback roles above janitor in the
chain each yielded no further real deliverable this run before this cycle.

*this run's upgrade-drafter pass already delivered one `upgrade/*` PR
(#981) earlier — capped at one per run per STEP 6b's own scope note.

This is the second janitor cleanup this run — the first
([docs/done/2026-08-04-confirm-lib-dedup.md](2026-08-04-confirm-lib-dedup.md),
PR #982) extracted the confirmation-prompt duplication across the same
family of DR scripts. Re-scanning the same file family for a fresh angle
(not a repeat of the confirm-prompt sweep) turned up this second, distinct
duplication class.)

`scripts/dr-bluegreen.sh`, `scripts/dr-bluegreen-promote.sh`, and
`scripts/dr-test.sh` each hand-rolled a byte-identical `phase()` section-
header printer. `scripts/dr-bluegreen.sh` and `scripts/dr-bluegreen-promote.sh`
additionally each hand-rolled byte-identical `probe()` (one-shot canary HTTP
check) and `stop_probe()` (background-probe-process teardown) functions —
unsurprising since `dr-bluegreen-promote.sh` is a superset drill built on the
same primitives as `dr-bluegreen.sh`.

## What changed

- `scripts/lib/colors.sh`: added `phase()`, alongside the existing shared
  `ok()`/`bad()` printers it already homes.
- New `scripts/lib/canary-probe.sh`: `probe()` and `stop_probe()`. Deliberately
  **not** named `bluegreen-probe.sh` — that name collides with the
  pre-existing, unrelated `scripts/bluegreen-probe.sh` (the actual background
  curl-loop probe process this lib's `probe()` one-shot check complements),
  which would have made `tests/frozen-monolith-lib.bats`'s "every
  `scripts/lib/*.sh` file is referenced by name" recurrence guard pass on a
  false positive (the existing script's test references would incidentally
  satisfy the basename-substring check without ever exercising the new lib).
  Caught this collision while writing the new lib's own test file and
  renamed before it shipped.
- `scripts/dr-bluegreen.sh` / `scripts/dr-bluegreen-promote.sh`: source the
  new lib; removed their inline `probe()`/`stop_probe()` definitions.
  `scripts/dr-test.sh`: removed its inline `phase()` (already sources
  `lib/colors.sh`, so no new source line needed).
- `tests/colors-lib.bats`: added a `phase()` coverage block (definition,
  functional printf-shape check, a recurrence guard scanning `scripts/*.sh`
  — not recursively into `scripts/lib/`, which is where the shared copy
  legitimately lives — and a sourcing check for the 3 callers).
- New `tests/canary-probe-lib.bats`: structural + functional coverage for
  the new lib (existence, function definitions, syntax, `probe()`'s
  unreachable-host behavior, `stop_probe()`'s no-op-when-empty and
  actually-kills-the-process behavior) plus the matching recurrence guard
  and sourcing check.

Behavior-preserving: `phase()`'s printf shape and `probe()`/`stop_probe()`'s
bodies are unchanged, copy-pasted verbatim into the shared location. One
pre-existing quirk surfaced (not introduced by this change, and unchanged by
it): `probe()`'s `curl ... -w '%{http_code}' || echo 000` prints `000000`
(not `000`) on a total connection failure — curl's own `-w` write already
emits `000` for the http_code, and curl's simultaneous non-zero exit status
additionally triggers the `|| echo 000` fallback. Every real call site only
ever compares the output against `"200"`, so this has zero behavioral
consequence either before or after — documented in the new test's comment
rather than silently asserting the wrong expected value.

Verified: `bats` + `shellcheck` installed in-sandbox (from the prior janitor
cleanup this same run). Ran the full suite and diffed against unmodified
`main` via `git stash`: identical 13 pre-existing environment-tool failures
before and after (broken local `yq` variant, no network access), zero new
failures — only line numbers shifted (net +12 tests added).
`shellcheck -S warning scripts/*.sh` (the exact invocation `scripts/lint.sh`
uses) is clean. `make ci`'s tool-independent checks (lint, test) pass; the
manifest/kustomize/terraform validators remain sandbox-skipped
(kubeconform/kustomize/terraform/mikefarah-yq/helm aren't installed here —
the full suite runs in GitHub Actions per `CLAUDE.md`).

## PR

[#983](https://github.com/tooming/k8s-anywhere/pull/983)
