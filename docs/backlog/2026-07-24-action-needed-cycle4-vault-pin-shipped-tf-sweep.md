# [Action needed] Now/next still gated; shipped a real Vault hardening find this cycle, Terraform-provider sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (fourth cycle of 2026-07-24): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC. No new GitHub issues exist
beyond these three standing trackers.

## This run's real progress (not idle)

This run already shipped two real, merged PRs before this cycle's note:

- **PR #698** (`plan/vault-image-tag-pin`) — planner-fallback gap analysis
  found that `gitops/platform/vault.yaml` never pinned an explicit
  `server.image.tag`, unlike every other version-sensitive component in this
  repo — the running Vault binary version (`2.0.3`) was only ever recorded in
  a prose comment. Added the ROADMAP item.
- **PR #699** (`auto/vault-server-image-tag-pin`) — implemented it in the same
  run (STEP 8: the plan PR merging unblocked a brand-new 🟢 item with no
  prerequisites, picked up immediately). Pinned `server.image: {repository:
  hashicorp/vault, tag: "2.0.3"}` (a no-op for the running cluster — matches
  the chart's existing default). Verified live against Vault's own
  `CHANGELOG.md`: confirmed 3 of 5 cited 2026 CVEs/bulletins
  (`CVE-2026-5807`, `CVE-2026-5052`, `HCSEC-2026-07`) are fixed by name-match
  in the `## 2.0.0` section; the other 2 (`CVE-2026-3605`, `HCSEC-2026-16`)
  are flagged as secondary-source-only per ADR-0004, not asserted as
  independently confirmed. Added a `tests/securitycontext-vault.bats`
  recurrence guard.

## This cycle's fresh angle (came up empty, but real)

After shipping the above, checked whether any *other* platform component has
the same gap class (chart version fully decoupled from the running app
version, no explicit image-tag pin, no mechanical recurrence guard):

1. **Every `gitops/platform/*.yaml` Application** was grepped for an
   `image:` override block. Only `observability-grafana.yaml` (already
   pinned, pre-existing) and `vault.yaml` (just pinned, this run) have one.
   `argo-rollouts.yaml` briefly had one as a stopgap (2026-07-18/19,
   CVE-2026-35469) but it was correctly removed once the chart itself
   started tracking the fixed `appVersion` (2026-07-20, upgrade-drafter) —
   confirmed by reading the in-file comment trail. No other component shows
   the same "chart version totally decoupled from app version" pattern
   Vault had; the rest either track appVersion 1:1 with the chart (already
   covered by `make ci`'s "ADR chart-version sync" gate) or have no ADR
   tying a specific app version to a behavior, making an explicit pin lower
   value than it was for Vault (which holds every secret in the lab).
2. **Terraform/Terragrunt provider version pins** — the upgrade-drafter's own
   STEP 2 flags this as a "distinct enumeration pass" from the `gitops/`
   walk, since a miss here can go undetected for cycles (this happened once
   for real: `infra/modules/argocd/variables.tf`'s `chart_version`, fixed in
   PR #690 the day before yesterday). Enumerated every `required_providers`
   block in `infra/modules/*/main.tf` (`argocd`: `hashicorp/helm ~> 2.17`;
   `oracle-k3s-cluster`: `oracle/oci ~> 7.0`, `hashicorp/null ~> 3.2`;
   `gitlab-config`: `gitlabhq/gitlab ~> 19.0`, `hashicorp/kubernetes ~>
   2.30`; `k3d-cluster`: `hashicorp/null ~> 3.2`, `hashicorp/local ~> 2.5`).
   All use conventional Terraform `~>` pessimistic-constraint pins (the
   idiomatic, intentional "float within this minor/major" pattern for
   providers, not a moving-tag gap like `latest`/`main`/`HEAD`) — no action
   needed, these aren't meant to be hand-bumped per patch release.
3. **`infra/modules/argocd/variables.tf`'s `chart_version`** (the exact field
   PR #690 fixed two days ago) re-checked directly: `9.7.1`, matching both
   `infra/live/oracle/argocd/terragrunt.hcl` and
   `infra/live/local/argocd/terragrunt.hcl`. Still current — no drift since
   PR #690.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition (including Vault's own new
`## Re-evaluation log` flip condition just added this run: "a bulletin names
a version above `2.0.3` as affected, or the chart `targetRevision` bumps past
`0.34.0`"); (c) a new GitHub issue of any size.

This note is this cycle's honest record — a real, distinct check, on top of
two merged PRs earlier in this same run — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
