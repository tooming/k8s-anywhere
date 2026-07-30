# [Action needed] Now/next still gated; bats hardcoded-path reference audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Two real merged PRs this run
([#903](https://github.com/tooming/k8s-anywhere/pull/903),
[#905](https://github.com/tooming/k8s-anywhere/pull/905)), plus several honest
fallback-chain records
([#904](https://github.com/tooming/k8s-anywhere/pull/904),
[#906](https://github.com/tooming/k8s-anywhere/pull/906),
[#907](https://github.com/tooming/k8s-anywhere/pull/907),
[#909](https://github.com/tooming/k8s-anywhere/pull/909),
[#910](https://github.com/tooming/k8s-anywhere/pull/910)). A second, concurrent
executor session independently merged
[#908](https://github.com/tooming/k8s-anywhere/pull/908) — no overlap with this
session's angles.

## This cycle's fresh angle (clean)

**Hardcoded `$REPO/<path>` reference audit across `tests/*.bats`** — extracted
every literal `$REPO/gitops/...`/`$REPO/grafana/...`/`$REPO/docs/...`/
`$REPO/scripts/...`/`$REPO/infra/...` path string (332 total) and checked each
resolves to a real on-disk file. 9 initial "missing" hits, all investigated
and confirmed false positives from the grep's own extension pattern, not real
drift:
- 5 are deliberate **negative** assertions (`[ ! -f ... ]`) confirming a
  decommissioned file's absence — `gitops/platform/artifactory{,-extras}.yaml`,
  `gitops/secrets/artifactory-registry-externalsecret.yaml`
  (`tests/no-artifactory.bats`), and `gitops/harbor/networkpolicy/
  allow-harbor-clusterip-egress.yaml` (`tests/harbor.bats`, the file this
  run's own #903 fix removed).
- 2 are intentional **fixture example** paths
  (`docs/decisions/adr-0099-widget.md`, `gitops/platform/widget.yaml` in
  `tests/hook-scripts-coverage.bats`) used to exercise a hook script's
  filtering logic, plus `gitops/README.md` in this run's own
  `tests/hook-scripts-kustomize-orphan.bats` (also a filter-exercise, not an
  expected-real-file case).
- 2 are grep-pattern truncation artifacts: the real files are
  `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` and
  `infra/tfstate-oracle/cloud-init.yaml.tpl` — my scan's extension pattern
  matched the `.yaml` substring inside `.tftpl`/`.tpl` and dropped the rest,
  not an actual dangling reference.

No real dangling test-path reference found.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
