# bats tests skip (not false-pass/fail) under the wrong yq variant

**Date:** 2026-08-18
**Role:** JANITOR fallback (`executor.prompt.md` STEP 6b, reached after PLANNER,
ARCHITECT, and DOC-DRIFT-AUTHOR all found nothing new this cycle — the "Now / next"
lane's five items are all still gated: the two GitLab→Forgejo migration items
sequentially blocked on each other, and `verifyImages` Enforce / O4 CI gate / legacy
capstone `Deployment` removal all still gated on unconfirmed maintainer-confirmation
issues #631/#633, re-checked this cycle, unchanged since the prior cycle's check).
`upgrade-drafter`'s own one-PR-per-run cap was already spent this run
(`upgrade/s3manager-digest-to-v0-8-0`). TRIAGER found nothing to triage (both open
issues, #631/#633, already fully labeled).

## What this closes

`docs/backlog/2026-08-17-action-needed-cycle8-yq-variant-bats-gap-noted.md` (a prior
cycle this run) found four bats test failures tracing to a real yq-implementation
incompatibility (mikefarah/yq vs. a python/jq-based `yq`) and explicitly flagged
extending the guard as a "possible future JANITOR candidate" — but declined to attempt
it: "verifying such a change is *actually* correct would require testing against
**both** yq variants, and this sandbox only has the wrong one."

This cycle's sandbox has both: `go install github.com/mikefarah/yq/v4@latest` and
`go install helm.sh/helm/v3/cmd/helm@latest` (Go's own module proxy,
`proxy.golang.org`, is reachable even though this sandbox's egress proxy blocks most
Helm-chart-repo/GitHub-Pages hosts) installed the real mikefarah/yq (`v4.53.3`) and
`helm` (`v3.21`) alongside the sandbox's pre-existing wrong-variant `yq` (a
Python/jq-based wrapper, prints `yq 0.0.0`) — letting this cycle actually verify a fix
against both, closing the exact gap the prior cycle's note left open.

## Root cause (verified directly, ADR-0004 — not assumed)

Running the full local suite with the correct mikefarah/yq + helm installed: **100%
green, zero failures** — confirming this was never a real repo bug, purely a local
sandbox tool-variant gap. `scripts/lib/yq-variant.sh`'s `require_mikefarah_yq()`
already gates the three check scripts this class of failure traces to
(`helm-chart-pin-check.sh`, `argocd-crd-ssa-check.sh`, `rollouts-plugin-list-check.sh`)
— it makes each script exit 0 ("skipping") under the wrong yq variant rather than
erroring. That's correct for the scripts themselves, but the **bats tests wrapping
them** had no matching skip semantics, so the wrong variant produced two failure
modes depending on the assertion shape:

1. A test asserting `[ "$status" -eq 2 ]` (or specific drift output) hard-**fails**
   when the script silently skips instead (`not ok`) — the four failures the prior
   cycle's note already found (`argo-rollouts.bats` `| tag`, `kargo.bats`
   `selfSignedCert.generate`, kargo dev/prod "nests the image override"), plus this
   cycle found five more in the same class: `tests/drift-gitops-manifest-checks.bats`
   (all 3 `helm-chart-pin-check`/`argocd-crd-ssa-check`/`rollouts-plugin-list-check`
   "FAILS when..." assertions) and `tests/hook-scripts-coverage.bats` (the 3
   `*-sync-hook: ... exits 2 (drift)` tests).
2. **A worse, previously-unnoticed failure mode**: a test asserting only
   `[ "$status" -eq 0 ]` (e.g. "helm-chart-pin-check: passes when every chart pin
   resolves") **false-passes** under the wrong variant — the script's own
   skip-and-exit-0 path satisfies the assertion without the check's actual logic
   ever running. Silent false-pass is worse than a loud failure; this cycle's fix
   closes both directions the same way.

Two distinct root causes surfaced within the "hard-fail" class, each verified by
running the exact `yqs()` query directly against both variants:

- **Mikefarah-only operators.** `| tag` (YAML-tag introspection) has no jq/python-yq
  equivalent — the query itself is only valid under mikefarah/yq.
- **Embedded double quotes in a scalar value.** The kargo Stage `digest` field's real
  value contains literal `"..."` (`${{ imageFrom("harbor...").Digest }}`) —
  python-yq's JSON-encoded output escapes those (`\"`), and `yqs()`'s
  leading/trailing-quote strip (`tests/lib/yq.bash`) doesn't undo mid-string escaping,
  so the comparison mismatches even though the underlying query succeeds cleanly
  (verified: same query, run directly, returns the right value under both variants —
  only the escaped serialization differs).
- (The `selfSignedCert.generate` case is a third, narrower shape: chaining a field
  access through a boolean scalar is a type error under jq/python-yq semantics but
  tolerated as null under mikefarah/yq — same root class, different trigger.)

## Fix

Added `require_mikefarah_yq_or_skip()` to `tests/lib/yq.bash` — a bats-flavored
counterpart to `scripts/lib/yq-variant.sh`'s `require_mikefarah_yq()`, using bats'
own `skip` builtin instead of `exit`. Called it precisely where verified necessary
(never blanket-applied to a whole test file unless every test in it genuinely needs
it):

- `tests/argo-rollouts.bats` — 1 test (`| tag`).
- `tests/kargo.bats` — 3 tests (`selfSignedCert.generate`, dev/prod "nests the image
  override").
- `tests/drift-gitops-manifest-checks.bats` — in `setup()` (all 9 tests in this file
  directly exercise one of the three `require_mikefarah_yq()`-gated scripts).
- `tests/hook-scripts-coverage.bats` — 3 tests (the matching `*-sync-hook` drift
  assertions); this file is the frozen coverage monolith, but
  `hook-scripts-coverage-tests-check.sh`'s drift guard snapshots `@test` **titles**
  only — none changed here, confirmed clean (`make hook-scripts-coverage-tests-check`
  passes with no re-mark needed).

## Verification (both variants, this cycle)

- **Wrong yq on PATH** (this sandbox's pre-existing `yq 0.0.0`): all 17 previously
  hard-failing/false-passing assertions across the four files now report `ok ... #
  skip requires mikefarah/yq on PATH`; `bats tests/argo-rollouts.bats tests/kargo.bats
  tests/drift-gitops-manifest-checks.bats tests/hook-scripts-coverage.bats` — 0
  `not ok`.
- **Correct mikefarah/yq + helm on PATH** (installed this cycle via `go install`): the
  same four files — 0 `not ok`, 0 skips — every assertion genuinely runs and passes,
  confirming the guard changes nothing about real CI (which always has the correct
  tools) and the fix doesn't mask a real regression.
- Full `make ci` (`bash scripts/*.sh` + `bats tests/`), correct tools on PATH: clean,
  zero failures, zero warnings.

## Behavior preservation

Zero-diff to any script under `scripts/`; zero change to any test's assertion logic
or expected values — only a `skip` call added ahead of assertions that already
existed. `make ci`'s passing-assertion count is unaffected on a machine with the
right tools (which is what CI always has); only a local run missing them changes
outcome, from "wrong/misleading" to "honest skip".

## PR

https://github.com/tooming/k8s-anywhere/pull/1215
