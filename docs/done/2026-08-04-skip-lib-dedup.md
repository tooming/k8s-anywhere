# Extract shared skip() printer from 4 check scripts into scripts/lib/colors.sh

(CLAUDE.md's mechanical-guard/dedup ethos; janitor fallback role, invoked via
`executor.prompt.md` STEP 6b — the executor's own Now/next lane was fully
gated this run (all three remaining 🟢 items blocked on the standing
maintainer-confirmation issues #631/#633), and the planner/architect/
upgrade-drafter*/doc-drift-author/triager fallback roles above janitor in the
chain each yielded no further real deliverable this run before this cycle.

*this run's upgrade-drafter pass already delivered one `upgrade/*` PR
(#981) earlier — capped at one per run per STEP 6b's own scope note.

Third janitor cleanup this run, after
[docs/done/2026-08-04-confirm-lib-dedup.md](2026-08-04-confirm-lib-dedup.md)
(PR #982) and
[docs/done/2026-08-04-phase-canary-probe-lib-dedup.md](2026-08-04-phase-canary-probe-lib-dedup.md)
(PR #983). Widening the duplication sweep beyond the DR-script family this
time (`grep -hoE '^[a-zA-Z_][a-zA-Z0-9_]*\(\)\s*\{' scripts/*.sh | sort |
uniq -c | sort -rn` across ALL of `scripts/*.sh`, not just the blue/green
drill scripts) turned up two more real, byte-identical duplication classes:
this one (`skip()`, 4 occurrences) and a `kubectl()` context-wrapper (6
occurrences) — left for a later cycle per janitor's "ONE bounded cleanup"
rule, since bundling unrelated duplication classes into one PR isn't bounded.)

`scripts/argocd-crd-ssa-check.sh`, `scripts/helm-chart-pin-check.sh`,
`scripts/lint.sh`, and `scripts/validate-terraform.sh` each hand-rolled a
byte-identical `skip()` informational-notice printer — the natural
"skipped, not passed or failed" companion to the `ok()`/`bad()` pair
`scripts/lib/colors.sh` already homes.

## What changed

- `scripts/lib/colors.sh`: added `skip()`, alongside the existing shared
  `ok()`/`bad()`.
- The 4 scripts: removed their inline `skip()` definition (each already
  sources `lib/colors.sh`, so no new source line needed). Their own local,
  no-side-effect `ok()`/`bad()` pair (the documented colors.sh exception for
  scripts tracking failure via a separate `fail` variable) is untouched —
  only `skip()`, which was truly byte-identical everywhere, was in scope.
- `tests/colors-lib.bats`: added a `skip()` coverage block (definition,
  functional no-side-effect-on-drift check, a recurrence guard scanning
  `scripts/*.sh`, and a sourcing check for the 4 callers) — mirroring the
  existing `ok()`/`bad()`/`phase()` coverage blocks in the same file.

Behavior-preserving: `skip()`'s `printf` shape is unchanged, copy-pasted
verbatim into the shared location.

Verified: `bats` + `shellcheck` already installed in-sandbox (from the
earlier janitor cleanups this run). Ran the full suite and diffed against
unmodified `main` via `git stash`: identical 13 pre-existing environment-tool
failures before and after (broken local `yq` variant, no network access),
zero new failures — only line numbers shifted (net +4 tests added).
`shellcheck -S warning scripts/*.sh` (the exact invocation `scripts/lint.sh`
uses) is clean. `make ci`'s tool-independent checks (lint, test) pass; the
manifest/kustomize/terraform validators remain sandbox-skipped
(kubeconform/kustomize/terraform/mikefarah-yq/helm aren't installed here —
the full suite runs in GitHub Actions per `CLAUDE.md`).

## PR

[#984](https://github.com/tooming/k8s-anywhere/pull/984)
