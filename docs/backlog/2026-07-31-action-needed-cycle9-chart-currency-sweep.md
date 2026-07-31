# [Action needed] Now/next still gated; ADR/chart-currency re-audit sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle (fetched both issues' comment threads directly): both still open, no new
confirmation since the last check.

## What this run already did

Two real merged PRs so far this run:
[#941](https://github.com/tooming/k8s-anywhere/pull/941) (finished a prior run's
stale, unmerged `chore/*` self-review — STEP 1b recovery), and
[#942](https://github.com/tooming/k8s-anywhere/pull/942) (rescued an
already-implemented but never-PR'd fix sitting on an orphaned
`auto/dora-audit-readiness-adr-count-fix` branch — a stale ADR-count citation in
`docs/dora-audit-readiness.md`, landed under the janitor "stale doc reference"
mandate).

## This cycle's fresh angle

Earlier `[Action needed]` notes filed today
([argocd-todo-clean](2026-07-31-action-needed-argocd-todo-clean.md),
[cert-manager-doc-consistency-clean](2026-07-31-action-needed-cert-manager-doc-consistency-clean.md))
already used the "inline TODO/FIXME sweep" and "cross-check a specific recent bump
against every doc that cites it" lenses. This cycle instead ran a **chart-pin /
CVE-currency re-audit across ADRs whose flip conditions had NOT been re-checked
today**, verified directly against real upstream sources (git tag lists, not
training knowledge — ADR-0004), one component at a time:

- **ADR-0030 (k3s pin, `v1.36.2+k3s1`):** `git ls-remote --tags
  k3s-io/k3s` — newest `1.36.x` tag is still `v1.36.2+k3s1`; no `v1.36.3+` or
  `v1.37.x` stable tag exists. Flip condition not met.
- **ADR-0008 (Envoy Gateway, `v1.8.3`):** `git ls-remote --tags
  envoyproxy/gateway` — newest `1.8.x` tag is still `v1.8.3` (last bumped
  2026-07-23, RFC #671); no `v1.9.0` tag exists. Flip condition not met.
- **ADR-0009 (RabbitMQ image pin, `4.3.4-management`):** re-evaluation log shows
  last CVE audit 2026-07-27 (#761), already current — not yet stale enough to
  re-check meaningfully this cycle.
- **ADR-0018 (Valkey, `8.0.10`):** last audited 2026-07-29 (#829, license
  re-check) — current.
- **ADR-0029 (KEDA):** last CVE audit 2026-07-27 (#764) — current.
- **ADR-0013 (Longhorn, `1.11.3`):** last currency check 2026-07-28 (executor) —
  current.
- **ADR-0022 (Trivy Operator, `0.34.0`):** last audit 2026-07-28 (#773) —
  current.
- **Terraform-bootstrapped chart (ADR-0001 seam, `infra/modules/argocd`, ArgoCD
  chart `10.2.1` / app `v3.4.5`):** this is a *distinct* enumeration surface from
  `gitops/**/*.yaml` per `routines/upgrade-drafter.prompt.md` STEP 2 (a prior
  currency gap here went undetected for two sweep cycles, per
  `docs/done/2026-07-23-argocd-chart-bump-9-5-20-to-9-7-1.md`) — re-verified
  it's already covered by today's earlier TODO-sweep finding
  (`docs/backlog/2026-07-31-action-needed-argocd-todo-clean.md`): `v3.4.5` is
  still the newest stable tag, confirmed again via a fresh `git ls-remote`.
- **CHARTER.md's "~33 ArgoCD Applications" figure:** spot-counted `kind:
  Application` manifests directly (`grep -rl "kind: Application"
  gitops/platform/*.yaml` → 80, but that count mixes root platform Applications
  with ApplicationSet-generated leaf apps and heavy/on-demand components not in
  the "always-on core" bucket CHARTER's figure describes) — the figure already
  uses "~" (approximate), so it isn't the same exact-count-drift footgun class
  as the ADR-count/namespace-count bugs fixed earlier this run; recomputing it
  precisely needs the same namespace-bucketing methodology issue #846 used, not
  a quick recount, and a wrong "precise" replacement would itself violate
  ADR-0004. Left as-is — flagging here rather than guessing.
- **Scripts-without-bats-coverage sweep:** every `scripts/*.sh` file has at
  least one reference somewhere under `tests/*.bats` — no gap found.

Every source checked was already current or already correctly gated — a clean
result, not a missed opportunity. No open GitHub issues need grooming (only
#631/#633, both already fully triaged and tracked), and `docs/roadmap/incoming/`
holds no pending architect items.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing one of the tracked ADR flip conditions above.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
