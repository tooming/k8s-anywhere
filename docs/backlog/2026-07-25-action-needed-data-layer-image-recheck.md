# [Action needed] Now/next still gated; data-layer image pins re-verified current

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, zero comments. No new ungroomed GitHub
issues exist beyond these three standing trackers (`list_issues` sorted by
`created` descending confirms #633 is still the newest open issue), and
`docs/roadmap/incoming/` is empty.

Two PRs already merged earlier in this same run: #723 (ack-s3/kro OCI
registry chart-pin recheck) and #724 (`chore:` direct bats coverage for
`scripts/lib/yq-variant.sh`'s `require_mikefarah_yq()`, closing the one
coverage gap a fresh `scripts/*.sh` vs. `tests/*.bats` sweep turned up).

## This cycle's fresh angle

A repeat of the "scripts with no bats coverage" sweep that found #724's gap
came up empty this time (every `scripts/*.sh` and `scripts/lib/*.sh` now has
at least one direct reference in `tests/*.bats`) — expected, since #724 just
closed the one gap that sweep could find.

Widened to a different lens: Docker Hub is reachable from this sandbox
(confirmed working previously for the Envoy Gateway chart-pin bump per
ROADMAP history). Queried the tags API directly for the three data-layer
images pinned in `gitops/data/*/statefulset.yaml` that hadn't been
re-verified yet this run:

- `rabbitmq:4.3.4-management` — `4.3.4-management` is the newest tag on the
  `4.3.x` line (no `4.3.5` exists). Current.
- `valkey/valkey:8.0.10-alpine` — queried every `8.0.x` tag specifically
  (not just the most-recently-pushed page, which surfaces `9.x`/`unstable`
  first); `8.0.10-alpine` is the highest patch on the `8.0.x` line. Current.
- `oliver006/redis_exporter:v1.88.0-alpine` — `v1.88.0-alpine` is the newest
  tag overall (bumped from `v1.87.0` earlier today per
  `docs/done/2026-07-25-redis-exporter-1-87-0-to-1-88-0.md`). Current.

No actionable version gap found on any of the three.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, on top of the two PRs already
merged earlier in this run — not a stopping point in principle. Given how
many consecutive fresh-angle sweeps across chart pins, registry hosts, and
test coverage have now come up empty (this run and the many dated cycles in
`docs/backlog/` before it), the backlog genuinely has no further
clusterless, gate-passing work available until the standing
maintainer-confirmation issues receive a comment. `executor.prompt.md`
STEP 8 continues to apply if a future cycle in this same run finds a new
angle.
