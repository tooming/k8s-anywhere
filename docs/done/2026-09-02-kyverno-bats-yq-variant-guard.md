# Guard `tests/kyverno.bats`'s two `-o=json`-comparison tests against the wrong yq variant

(JANITOR-fallback cleanup, executor.prompt.md STEP 6b, reached after the "Now / next"
lane was re-confirmed fully gated this cycle — both standing GitLab→Forgejo migration
items and the capstone-`Deployment`-removal item remain blocked on the same live-cluster
prerequisites as the prior cycle this same run; no ungroomed intake issue, no un-RFC'd
🟡 item, no `make ci` drift signal (doc-drift-author's lane came up clean), and no
untriaged issue (all three open issues already carry full `domain:*`/`readiness:*`/
`priority:*` labels, so triager's lane is also a genuine no-op). Fresh angle this cycle:
a full local `make ci`/`bats` run (done to validate the prior cycle's PR) surfaced two
real `not ok` results in `tests/kyverno.bats` — investigated rather than dismissed as
environment noise, and confirmed to be a real, fixable test-robustness gap, not a repo
bug.)

## What was found

Running the full bats suite locally (this sandbox ships `apt`'s `yq` —
`kislyuk/python-yq`, a jq wrapper, reporting `yq 0.0.0` — not `mikefarah/yq`) produced
two failures:

```
not ok N disallow-latest-tag's initContainers and ephemeralContainers foreach entries
  deny the same ':latest'/no-tag conditions as containers
not ok M add-default-seccomp excludes the same kube-system/baseline/privileged
  namespaces as its sibling PSS policies
```

Root-caused directly (not assumed): both tests call `yqs -o=json ...` to compare two
serialized structures for equality. Confirmed live that apt's `yq` doesn't even accept
the `-o=json` flag (`jq: Unknown option -o=json`) — every `yqs()` call in these two
tests silently returned an error/empty result instead of a real comparison, which
`tests/lib/yq.bash`'s own header comment already documents as exactly the risk
`require_mikefarah_yq_or_skip()` exists to guard against ("mikefarah-only operators",
"syntax/semantics `yqs()`'s quote-stripping can't normalise across variants") — these
two tests just never adopted it. Confirmed this is real and narrow, not systemic: only
`tests/kyverno.bats` uses `-o=json` anywhere in the suite (`grep -rl "yqs -o=json"
tests/*.bats` — one file, two call sites). This doesn't affect GitHub Actions CI
(`.github/workflows/ci.yml` installs real `mikefarah/yq`), only local runs — but a false
`not ok` on an unrelated PR's `make ci` output is exactly the kind of noise that erodes
trust in the gate, matching this repo's own precedent finding (the `cpu_millis`
regression `tests/lib/yq.bash`'s header comment cites for why `yqs()` exists at all).

## Fix

Added `require_mikefarah_yq_or_skip` (already-shared, already-established helper from
`tests/lib/yq.bash`, used elsewhere by `tests/argo-rollouts.bats`,
`tests/drift-gitops-manifest-checks.bats`, `tests/hook-scripts-coverage.bats`,
`tests/kargo.bats`) to the two specific `@test` bodies, not the whole file's `setup()`
— matching the helper's own documented convention ("never blanket-applied, so a test
whose `yqs()` call IS variant-safe still runs"). Every other test in `kyverno.bats`
still runs and still catches a real regression under any yq variant; only these two
`-o=json` comparisons now skip cleanly under the wrong variant instead of reporting a
false failure.

Verified directly, both ways:
- Under apt's `yq`: both tests now report `# skip requires mikefarah/yq on PATH`
  instead of `not ok`.
- Under a freshly-installed real `mikefarah/yq` (`v4.53.6`): both tests still run for
  real and pass (`ok 48 disallow-latest-tag's initContainers...`, `ok 57
  add-default-seccomp excludes...`) — confirming the guard didn't paper over the
  check, it only skips under the wrong tool.

Behavior-preserving: no test outcome changed under the correct yq variant (the one
GitHub Actions CI always installs); the only change is what a local run reports when
the wrong yq is on `PATH` (a clean skip instead of a misleading failure).

`make ci` / full local bats suite: green (aside from this fix's own two now-passing
assertions).

## PR

https://github.com/tooming/k8s-anywhere/pull/1376
