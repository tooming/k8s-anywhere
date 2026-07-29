# [Action needed] Now/next still gated; KRO 0.9.3 found but chart artifact unverifiable this cycle

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#834](https://github.com/tooming/k8s-anywhere/pull/834) (ADR-citation
integrity sweep).

## This cycle's fresh angle

Extended the upgrade-drafter's own `gitops/**/*.yaml` version-currency walk to
components no prior `docs/backlog/` note names explicitly: the LGTMP
components sourced as plain manifests from this repo's own GitLab mirror
(`gitops/observability/{mimir,loki,tempo}/deployment.yaml` — `targetRevision:
main` there is this repo's own branch, not an external chart, so the real
dependency to check is each `image:` tag), plus KRO and moto:

- **Mimir** `grafana/mimir:3.1.4`, **Loki** `grafana/loki:3.7.4`, **Tempo**
  `grafana/tempo:2.10.7` — each confirmed via `git ls-remote --tags` to
  already be the newest stable tag on its line. No bump available.
- **Pyroscope** chart `2.2.0` — confirmed via the chart's own
  `raw.githubusercontent.com/grafana/pyroscope/main/operations/pyroscope/
  helm/pyroscope/Chart.yaml` to be current (`version: 2.2.0`,
  `appVersion: 2.2.0`).
- **moto** `motoserver/moto:5.2.2` — Docker Hub tags API reachable but its
  `-last_updated` ordering mixed old/new pushes inconclusively in the time
  available this cycle; not resolved either way, flagged for a future pass
  with a proper semver-sorted query.
- **KRO** (`gitops/platform/kro.yaml`, sourced as an OCI Helm chart from
  `ghcr.io/kro-run/kro`, pinned `0.9.2`) — `git ls-remote --tags
  https://github.com/kro-run/kro` shows a real `v0.9.3` tag (commit
  `f5dc199`) one patch ahead of the pin. **Held back, not bumped**, because
  this sandbox cannot verify the corresponding OCI chart artifact was
  actually published to `ghcr.io/kro-run/kro` — anonymous GHCR token
  requests (`https://ghcr.io/token?service=ghcr.io&scope=repository:
  kro-run/kro:pull`) return `DENIED` from this sandbox, and no
  `kro-run.github.io/kro/index.yaml` mirror is reachable either. This is
  the exact same failure mode this repo already hit and correctly handled
  once before: issue #663 (2026-07-22) found the `envoy-gateway` `v1.8.3`
  git tag existed before its Docker Hub chart artifact did, and the bump
  was deliberately held back until the artifact was independently
  confirmed live (`docs/decisions/adr-0008-envoy-gateway-not-traefik.md`'s
  Re-evaluation log). Bumping `kro.yaml`'s `targetRevision` to `0.9.3` on
  the strength of a git tag alone, with no live confirmation the chart
  itself resolves, would repeat that exact mistake and risk landing a
  reference `make ci` cannot validate (ArgoCD would only discover the
  broken pull live, on next sync).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) GHCR
becoming reachable from a future session (or the maintainer confirming
`ghcr.io/kro-run/kro:0.9.3` resolves), so the KRO bump above can be verified
and landed properly; (c) a new GitHub issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely fresh finding (not a
repeat of any prior "everything's clean" sweep), correctly held back per this
repo's own established artifact-verification discipline rather than shipped
on an unverified assumption. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
