# Add explicit timeout-minutes to every .github/workflows/ci.yml job

Janitor fallback (executor routine, STEP 6b — ROADMAP `Now / next` fully
gated again this cycle: the same five `[ ]` items are blocked on the
standing maintainer-confirmation issues #631/#632/#633, all three still
open with zero comments; planner/architect/doc-drift/triager lenses came up
empty). This cycle's finding came directly from the previous cycle's own
experience landing PR #648: the `unit` and `drift` jobs sat `in_progress`
for 20+ minutes with zero progress across three separate workflow-run
attempts (two manual cancel+rerun cycles), while every other job in the
same runs (`lint`, `manifests`, `kustomize`, `terraform`, `up-to-date`)
consistently finished in seconds. The diff under test in that PR was five
lines in a test file with no plausible way to hang CI — the actual cause
was a stalled network-dependent install step (`apt-get update/install`,
a release-binary `curl`, the `helm` install script), and because no job in
`.github/workflows/ci.yml` sets an explicit `timeout-minutes`, GitHub
Actions' default 360-minute job timeout applied — a hang like that could
have blocked the PR for hours with no automatic recovery, only a human or
agent noticing and manually cancelling.

## What changed (behavior-preserving under normal conditions)

Added `timeout-minutes:` to all six jobs in `.github/workflows/ci.yml`:
10 minutes for `lint`/`manifests`/`terraform`/`kustomize` (each normally
finishes in well under a minute), 15 minutes for `unit`/`drift` (the
heavier jobs — full bats suite / full drift sweep, normally a few minutes).
Every value is generous headroom above observed normal duration and far
below the previous effective 360-minute default, so no job that completes
normally is affected — this only changes behavior for a job that's
genuinely stuck, turning a silent multi-hour stall into a fast, visible
failure that retry logic (human or agent) can act on quickly.

Added a recurrence guard in `tests/drift-detectors.bats`: two new
assertions confirm every job under `jobs:` in `ci.yml` carries its own
`timeout-minutes` (scoped to the `jobs:` section only, since `on:` and
`permissions:` also have 2-space-indented `key:` lines that would otherwise
false-positive as job names) and that the job count matches the
timeout-minutes count 1:1, so a future job added without one is caught
mechanically rather than silently falling back to the 360-minute default.
Verified both assertions' underlying `awk`/`grep` logic manually against
both the real file (passes) and an artificially-stripped copy missing two
jobs' timeouts (correctly fails, naming both missing jobs).

`bash scripts/ci-parity-check.sh` stays green — this change adds no new
`scripts/*.sh` gate invocation to either side, only job-level YAML keys, so
the make-ci/ci.yml script-set parity check is unaffected. `make ci` — fully
green locally (bats/kustomize/kubeconform/terraform/shellcheck/yamllint
aren't installed in this remote sandbox and gracefully skip; GitHub Actions
is the authoritative gate for the bats run itself).

## PR

See PR link on the branch `chore/ci-workflow-job-timeouts`.
