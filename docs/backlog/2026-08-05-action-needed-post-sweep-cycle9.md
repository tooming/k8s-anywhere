# [Action needed] Now/next still gated; extensive currency + janitor sweep landed 8 PRs this run

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
recent cycle has found gated, re-verified fresh this cycle:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (confirm a real
   GitLab CI run signed and pushed an image to Harbor).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (confirm an Argo
   Rollouts canary + Kargo promotion has run end-to-end).

Both issues' comment threads re-read fresh this cycle: still open, no new
confirmation since 2026-08-04. Open PR
[#980](https://github.com/tooming/k8s-anywhere/pull/980)
(`feat/gitlab-runner-and-registry-port-fix`, human-authored, still open) is
the maintainer's own live in-progress work toward unblocking both.

## What this run already did (8 merged PRs, not idle)

This is cycle 9 of a single continuous run. Prior cycles this run landed:

- [#990](https://github.com/tooming/k8s-anywhere/pull/990) / [#991](https://github.com/tooming/k8s-anywhere/pull/991) — Grafana chart `12.10.2` → `12.10.3` (planner-found, executor-built).
- [#992](https://github.com/tooming/k8s-anywhere/pull/992) / [#993](https://github.com/tooming/k8s-anywhere/pull/993) — ArgoCD Terraform-bootstrapped chart `10.2.2` → `10.2.3`, with a full six-item breaking-change diligence pass (Helm v3→v4 migration, UI extensions, gRPC changes, impersonation, SSH, GPG — none applicable to this lab's config).
- [#996](https://github.com/tooming/k8s-anywhere/pull/996) / [#997](https://github.com/tooming/k8s-anywhere/pull/997) / [#998](https://github.com/tooming/k8s-anywhere/pull/998) — k3s `v1.36.2+k3s1` → `v1.36.3+k3s1`, a real credential-exposure fix (a `Node` annotation secret-redaction bug), taken through the full architect ADR-audit → RFC #995 → planner-absorption → executor-build chain (ADR-0030 explicitly requires this path, not a drive-by bump).
- [#1000](https://github.com/tooming/k8s-anywhere/pull/1000) — resolved a real, dated stale TODO in `infra/modules/argocd/values.yaml` (the `global.image.tag: latest` override), unblocked by this same run's own ArgoCD chart bump. Deliberately did **not** remove the matching Kyverno `argocd` namespace exclusion — that requires a live `terraform apply` first (tracked in a new standing `[Action required]` issue [#999](https://github.com/tooming/k8s-anywhere/issues/999), mirroring #631/#633's pattern) to avoid reintroducing a documented prior outage (#632 investigation).

## This cycle's sweep (components checked, all confirmed current)

Beyond the three real deltas above, this run directly verified (`git
ls-remote`/full clone diffs, not training knowledge — ADR-0004) that the
following are already at their newest stable release: tidb-operator
(`v1.6.5`), vault-helm (`v0.34.0`), kargo (`v1.11.0`), external-secrets
(`v2.8.0`), KEDA (`2.20.2`), Istio ambient mesh (`1.30.3`), Grafana Alloy
(`1.11.0`), Trivy Operator (`0.34.0`, cross-checked against the correct
`aquasecurity/helm-charts` chart repo after an initial wrong-repo comparison
was caught and corrected), Valkey (`8.0.10`), RabbitMQ (`v4.3.4`), and
`redis_exporter` (`v1.88.0`). No open `adr-audit`-labeled issues exist. No
ungroomed GitHub issues exist (only the two standing `[Action required]`
issues, both not intake).

## Assessment

Eight real, verified PRs landed this run across the full planner → architect
→ executor → janitor role chain, plus proper ADR/RFC governance for the
security-sensitive k3s bump. The remaining gated items are genuinely blocked
on live-cluster facts only the maintainer can observe — not on undiscovered
gaps in this repo.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or the new #999 — PR
#980 is the maintainer's own live in-progress work toward the first two; (b)
a new GitHub issue of any size (ungroomed intake); (c) a new upstream
CVE/release firing one of this repo's many tracked ADR flip conditions.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8 this
is not a stopping point — the run continues to the next cycle.
