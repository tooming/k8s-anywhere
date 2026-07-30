# [Action needed] Now/next still gated; plain-image-pin sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all gated on standing maintainer-confirmation issues [#631](https://github.com/tooming/k8s-anywhere/issues/631) and [#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-checked this cycle: both still open, no new confirmation.

## What this run already did

Six real merged PRs this run ([#918](https://github.com/tooming/k8s-anywhere/pull/918) architect ADR-0014 audit + RFC #917, [#919](https://github.com/tooming/k8s-anywhere/pull/919) planner absorption, [#920](https://github.com/tooming/k8s-anywhere/pull/920) Cilium `1.18.12` bump, [#922](https://github.com/tooming/k8s-anywhere/pull/922) upgrade-drafter chart sweep, [#923](https://github.com/tooming/k8s-anywhere/pull/923) janitor `stale-prs-check` guard), plus three stale-PR recoveries ([#914](https://github.com/tooming/k8s-anywhere/pull/914)/[#915](https://github.com/tooming/k8s-anywhere/pull/915)/[#921](https://github.com/tooming/k8s-anywhere/pull/921), the latter from a concurrent executor session).

## This cycle's fresh angle (clean)

The prior upgrade-drafter cycle ([#922](https://github.com/tooming/k8s-anywhere/pull/922)) swept every ArgoCD `Application` chart `targetRevision` pin in `gitops/platform/*.yaml` (~20 sources). This cycle checked the OTHER half of `routines/upgrade-drafter.prompt.md` STEP 2's scope that sweep didn't reach: plain `image:` tags on `Deployment`/`StatefulSet` manifests outside `gitops/platform/` — `gitops/data/`, `gitops/apps/`, `gitops/moto/`, `gitops/inkless/`. Checked every pinned (non-`latest`) image against its real upstream repo via `git ls-remote --tags`:

| Image | Pinned | Latest upstream | Status |
|---|---|---|---|
| `jaegertracing/example-hotrod` | 2.20.0 | 2.20.0 | current |
| `curlimages/curl` | 8.21.0 | 8.21.0 | current |
| `rabbitmq` | 4.3.4-management | 4.3.4 | current |
| `valkey/valkey` | 8.0.10-alpine | 8.0.10 | current (bumped this run's window, RFC-tracked CVE fix) |
| `oliver006/redis_exporter` | v1.88.0-alpine | 1.88.0 | current |
| `danielqsj/kafka-exporter` | v1.9.0 | 1.9.0 | current |
| `apache/kafka` | 3.9.2 | — | intentionally held (RFC #708, major-version compatibility risk) |
| `postgres` | 17 | — | intentional floating major, not a moving-tag violation (Inkless metadata store) |
| `motoserver/moto` | 5.2.2 | 5.2.2 | current |
| `harbor.../library/hello`, `ghcr.io/aiven/inkless` | `latest` | — | intentional follow-the-stream / pipeline-built images, out of scope per this role's own rule |

Every non-floating pin outside `gitops/platform/` is already at latest stable. Combined with the prior cycle's chart sweep, this is now a complete pass over every version-pinned source in `gitops/` this run.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release firing a tracked ADR flip condition.

This note is this cycle's honest record. The run continues to the next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
