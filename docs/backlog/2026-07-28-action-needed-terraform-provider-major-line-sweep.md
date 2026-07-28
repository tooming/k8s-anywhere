# [Action needed] Terraform provider major-version sweep — two providers behind their own constraints

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified this cycle: all
three still open, zero comments). No open GitHub issues needed grooming, and a full
`(external-secrets, cert-manager, KEDA, Alloy, Grafana chart, kube-state-metrics,
node-exporter, Pyroscope)` CVE/version sweep earlier this run already produced two real
`upgrade/*` PRs (#789 Alloy chart `1.10.1`→`1.11.0`, #790 Grafana chart `12.8.1`→`12.10.0`,
both merged).

This cycle tried a genuinely different angle: the upgrade-drafter routine's own STEP 2
explicitly requires a *separate* enumeration pass over `infra/modules/**/*.tf` (Terraform
provider constraints), distinct from the `gitops/**/*.yaml` walk — this is the exact pass
that previously caught the `argo-cd` Helm chart sitting stale across multiple sweep cycles.
Applying that same technique to `required_providers` blocks (rather than `helm_release`
`chart_version`s, which were already checked and are current) found two providers whose
`~>` pessimistic constraints have silently locked them behind a major-version line that
newer stable releases have already crossed:

- `hashicorp/helm` (`infra/modules/argocd/main.tf`): pinned `~> 2.17`, real latest is
  `v3.2.0` (2026-06-04) — a `2.x`→`3.x` line the constraint can never auto-pick-up.
- `oracle/oci` (`infra/modules/oracle-k3s-cluster/main.tf`): pinned `~> 7.0`, real latest is
  `v8.24.0` (2026-07-22) — a `7.x`→`8.x` line, same situation.

Both are architecturally significant (potential resource-schema breaking changes) and
per the upgrade-drafter's own "no major bumps" rule, not something to auto-bump. Filed
[issue #791](https://github.com/tooming/k8s-anywhere/issues/791) with the full verification
trail (real GitHub releases pages fetched live, not training-data assumptions per ADR-0004)
for the architect to pick up as an RFC, mirroring the disposition of issue #781 (the
`argo-cd` Helm chart major-line finding from earlier today, already resolved via
RFC #785 → PR #787 → PR #788).

Also checked: `gitlabhq/gitlab` provider (`~> 19.0`, real latest `v19.2.1`) and
`hashicorp/null`/`hashicorp/local` (`~> 3.2`/`~> 2.5`) are all still within their pinned
major line — no gap there.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
