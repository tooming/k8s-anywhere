# [Action needed] Now/next still gated; CI-tooling + remaining-chart sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments.

## What this run already shipped this cycle-chain (2 PRs, not idle)

- **PR #690** (`upgrade/argocd-9-5-20-to-9-7-1`): bumped the Terraform-bootstrapped
  ArgoCD chart pin `9.5.20` → `9.7.1`, found via a check outside this
  routine's previously-defined scope (`infra/`, not `gitops/`).
- **PR #691** (`chore/upgrade-drafter-infra-chart-scope`): closed the scope gap
  that let #690's staleness go undetected across multiple prior sweeps —
  extended `routines/upgrade-drafter.prompt.md` STEP 2 to also walk
  `infra/modules/**/*.tf` + `infra/live/**/*.hcl` for Terraform-pinned Helm
  charts.

## This cycle's fresh angle: CI-tooling + remaining chart candidates

With the `infra/` blind spot now closed, swept everything the newly-widened
scope should catch plus the two remaining chart candidates from the earlier
grafana/helm-charts lookup that hadn't been individually cleared yet:

| Component | Pinned | Latest | Verdict |
|---|---|---|---|
| `.github/workflows/ci.yml`: `actions/checkout` | `v7.0.1` | `v7.0.1` | current |
| `.github/workflows/ci.yml`: `actions/cache` | `v6.1.0` | `v6.1.0` | current |
| `.github/workflows/ci.yml`: `hashicorp/setup-terraform` | `v4.0.1` | `v4.0.1` | current |
| `.github/workflows/ci.yml`: `terraform_version` | `1.15.8` | `1.15.8` | current |
| `.github/workflows/ci.yml`: kubeconform | `v0.8.0` | `v0.8.0` | current |
| `.github/workflows/ci.yml`: kustomize | `v5.8.1` | `v5.8.1` | current |
| `infra/modules/` (Terraform Helm charts, new scope) | ArgoCD only | — | only source; already bumped in #690 |
| Pyroscope chart (`gitops/platform/observability-pyroscope.yaml`) | `2.1.2` (appVersion `2.1.1`) | `2.2.0` (appVersion `2.2.0`) | **held — see below** |

### Pyroscope `2.2.0` — held

Unlike the ArgoCD bump (chart-templating only; the deployed binary is
separately pinned to `global.image.tag: latest`, so the chart version has no
behavioral effect), Pyroscope's chart version tracks its `appVersion` 1:1 —
this bump is a real `2.1.1` → `2.2.0` application minor, not just a
templating refresh. `github.com`/`api.github.com` releases pages are
proxy-blocked in this environment, and the repo's own `CHANGELOG.md` is
stale (frozen at the pre-rename `Grafana Phlare` 0.x era, unmaintained since
the project renamed to Pyroscope), so no changelog evidence either way could
be directly verified (ADR-0004 — no claim of "no breaking changes" without
being able to check). No CVE signal found anywhere reachable. This matches
the exact fact pattern this session already established a precedent for with
Valkey `8.1.0` (ADR-0018 audit #627), Alloy `1.11.0` (this run, held earlier
this cycle-chain), and Longhorn `1.12.0`/kube-state-metrics `8.0.0`
(`2026-07-22-action-needed-chart-sweep-jul22.md`): "a newer minor exists"
alone, with no security/critical-bug rationale AND no ability to positively
rule out breaking changes, is not sufficient justification on an always-on
component with real blast radius (continuous profiling receiver for the
whole LGTMP stack). Held the pin at `2.1.2`.

## Other lenses (also swept this cycle-chain, came up empty)

- **Planner:** no ungroomed issues beyond the three standing trackers,
  `docs/roadmap/incoming/` empty.
- **Architect:** re-walked every ADR's `## Re-evaluation log` flip condition —
  none newly fired.
- **Triager:** all three open issues (#631/#632/#633) already fully labeled.
- **Doc-drift:** `make ci` clean (readme-check, lab-ui-check, markdown-links,
  routines-sync all pass with no warnings).

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked flip
condition on Pyroscope, Alloy, Longhorn, or kube-state-metrics; (c) a new
GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
