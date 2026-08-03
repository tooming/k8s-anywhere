# [Action needed] Now/next still gated; fresh local shellcheck/yamllint pass clean

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items it has
held all run, all gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle (fetched both issues' comment threads directly): both still open, no
new confirmation since the last check.

## What this run already did

Five real merged PRs so far this run:
[#955](https://github.com/tooming/k8s-anywhere/pull/955) (upgrade-drafter:
argo-cd Helm chart `10.2.1` → `10.2.2`),
[#956](https://github.com/tooming/k8s-anywhere/pull/956) (janitor: dedupe the
`yqs()` scalar-read helper, `scripts/lib/yq.sh` + recurrence guard — also
filed issue #957 for a second, larger duplication finding too risky for the
same sitting),
[#958](https://github.com/tooming/k8s-anywhere/pull/958) (planner: groomed
issue #957 into two sequenced Now/next items),
[#959](https://github.com/tooming/k8s-anywhere/pull/959) (executor: renamed
`scripts/*.sh`'s inconsistent `rc`/`FAILED` failure-flag variables to
`drift`),
[#960](https://github.com/tooming/k8s-anywhere/pull/960) (executor: extracted
the now-consistent `ok()`/`bad()` pair to `scripts/lib/colors.sh` + its own
recurrence guard, closing out issue #957's full chain).

## This cycle's fresh angle

Two lenses not yet used this run, tried back-to-back:

1. **`tests/frozen-monolith-lib.bats`'s recurrence guard** (every
   `scripts/lib/*.sh` file must be referenced by name in at least one
   `tests/*.bats` file) — already green, thanks to this run's own
   `tests/lib-yq.bats` and `tests/colors-lib.bats` extension covering the two
   lib files added/extended this run. No gap.
2. **A real local `shellcheck`/`yamllint` pass** — installed both via
   `apt-get` (neither has been available in any prior cycle this run, which
   all silently skipped the lint step with "not installed — skipping").
   `shellcheck -S warning scripts/*.sh`: clean, zero findings. `yamllint -c
   .yamllint.yml gitops infra .github`: exactly one hit —
   `infra/modules/oracle-k3s-cluster/cloud-init.yaml:1:2 warning: missing
   starting space in comment`. Investigated directly: that line is
   `#cloud-config`, cloud-init's required magic header (must have **no**
   space after `#` for cloud-init to recognize the file's directive format —
   `# cloud-config` would silently stop being parsed as a cloud-config
   document). This is a correct false-positive, not a bug — fixing it would
   break real functionality, so left alone. `lint.sh` still exits 0 (this is
   `warning` severity only, not an error under `.yamllint.yml`'s rules).

Both lenses came up genuinely clean — a second consecutive empty pass after
different angles, not a repeat of the same search.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing one of the tracked ADR flip conditions.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
