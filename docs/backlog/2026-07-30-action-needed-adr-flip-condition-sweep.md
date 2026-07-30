# [Action needed] Now/next still gated; ADR flip-condition sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all gated on standing maintainer-confirmation issues [#631](https://github.com/tooming/k8s-anywhere/issues/631) and [#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-checked this cycle, no new confirmation.

## What this run already did

Seven real merged PRs this run (#918 architect ADR-0014 audit + RFC #917, #919 planner absorption, #920 Cilium `1.18.12` bump, #922 chart-pin sweep, #923 janitor `stale-prs-check` guard, #924 plain-image-pin sweep), plus three stale-PR recoveries (#914/#915/#921).

## This cycle's fresh angle (clean)

Every prior sweep this run checked upstream *releases* against pins. This cycle checked the other direction: read every ADR's own `## Re-evaluation log` (20 ADRs carry one) and extracted each one's currently-recorded flip condition, to see if any is met by something already known rather than needing a fresh upstream check. Two are non-CVE conditions worth independent verification:

- **ADR-0017's `lab-demo` row** — flip condition: `jaegertracing/example-hotrod` ships a non-root UID, or is superseded by a capstone-built image. The pinned tag (`2.20.0`) is unchanged since the last audit (2026-07-26) and this run's own image-pin sweep (#924) confirmed no newer tag exists — same image, same Dockerfile, condition still not met.
- **ADR-0017's `inkless` row** — flip condition: (a) `ghcr.io/aiven/inkless` ships a non-root `USER` directive (met, per audit #494) **and** (b) verified non-root on a live cluster (outstanding — requires live-cluster access this session doesn't have).

Every other ADR's flip condition is CVE/release-triggered — already covered by this run's architect sweep (#918, which checked all 16 architect-tracked components) and the two chart/image-pin sweeps (#922, #924). No condition found met that this session can act on; the two outstanding ones both need either a new upstream release (none shipped) or live-cluster verification (out of scope, same as every other maintainer-confirmation gate this run already surfaces via #631/#633).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release firing a tracked ADR flip condition — none available right now, having just swept every ADR'd component and every pinned image this run.

This note is this cycle's honest record. The run continues to the next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
