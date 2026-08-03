# [Action needed] Observability/data plain-image sweep clean; Now/next still gated

## What's blocked

Unchanged: ROADMAP.md's *Now / next* lane holds the same 3 items gated on
[#631](https://github.com/tooming/k8s-anywhere/issues/631)/[#633](https://github.com/tooming/k8s-anywhere/issues/633)
(re-verified, both still open). No new GitHub issues, no open PRs beyond
this run's own in-flight ones.

## What this run already did (5 real merged PRs)

[#962](https://github.com/tooming/k8s-anywhere/pull/962) (planner: Harbor
item), [#963](https://github.com/tooming/k8s-anywhere/pull/963) (executor:
Harbor bump), [#964](https://github.com/tooming/k8s-anywhere/pull/964)
(Action needed, cycle 3), [#965](https://github.com/tooming/k8s-anywhere/pull/965)
(upgrade-drafter: KEDA bump), [#966](https://github.com/tooming/k8s-anywhere/pull/966)
(Action needed, cycle 5 — full `gitops/platform/*.yaml` chart sweep).

## This cycle's fresh angle: plain (non-chart) image tags

Cycle 5 covered every Helm-chart-sourced `targetRevision:`. This cycle
covered the remaining plain `image:` tags in `gitops/observability/`,
`gitops/moto/`, `gitops/storage/`, `gitops/data/` that aren't chart-managed
— checked each against its real GitHub releases page: `grafana/loki:3.7.4`
(latest, a security release), `grafana/mimir:3.1.4` (latest, security),
`grafana/tempo:2.10.7` (latest), `motoserver/moto:5.2.2` (latest),
`oliver006/redis_exporter:v1.88.0` (latest). All five already current — no
gaps found. Also confirmed the `infra/modules/*/main.tf` Terraform provider
constraints are all `~>` pessimistic version ranges (not exact pins), so
`terraform init` already floats to the latest matching provider release on
every run — nothing to manually bump there by design (mechanically
guarded — see `tests/argocd-chart-pin.bats`'s provider-constraint
assertions).

Also spot-checked CHARTER Objective O6's measurement mechanism
(`make capstone-demo` / `scripts/capstone-demo.sh`) exists with real bats
coverage — already fully built, not a gap.

## Assessment

Between this run's architect sweep (cycle 1), full chart sweep (cycle 5),
and this cycle's plain-image sweep, the dependency-currency search space is
now very thoroughly covered for this run. Further identical re-sweeps this
run would be diminishing-returns repeats rather than fresh signal. The
next genuinely new finding is most likely to come from: (a) a maintainer
confirmation on #631/#633, (b) new intake (an issue), or (c) simple elapsed
time producing a new upstream release/CVE on a component already confirmed
current as of this run.

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8.
