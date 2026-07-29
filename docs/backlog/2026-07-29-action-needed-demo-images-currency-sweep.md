# [Action needed] Now/next still gated; demo/data-layer image currency sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#863](https://github.com/tooming/k8s-anywhere/pull/863) (KSM +
node-exporter chart currency check).

## This cycle's fresh angle

Checked the demo/data-layer workload images not yet individually verified
this run:

- **demo** (`jaegertracing/example-hotrod:2.20.0`) — latest tag, current.
- **data-demo**'s `rabbitmq-load` (`curlimages/curl:8.21.0`) — latest tag,
  current.
- **s3manager** (`cloudlena/s3manager@sha256:f666e...`, pinned by digest) —
  the pinned digest matches the current `latest` tag's digest exactly,
  same verification technique used earlier this run for the cosign image.
- `data-demo`'s `valkey-load` (`valkey/valkey:8.0.10-alpine`) — already
  verified current earlier this run (the Valkey/Redis license-recheck
  cycle).

All current, no bump available anywhere in this sweep.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
