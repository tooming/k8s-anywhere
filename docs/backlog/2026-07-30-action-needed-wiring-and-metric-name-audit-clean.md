# [Action needed] Now/next still gated; ExternalSecret/HTTPRoute/Velero wiring audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Two real merged PRs this run
([#903](https://github.com/tooming/k8s-anywhere/pull/903),
[#905](https://github.com/tooming/k8s-anywhere/pull/905)), plus seven honest
fallback-chain records
([#904](https://github.com/tooming/k8s-anywhere/pull/904),
[#906](https://github.com/tooming/k8s-anywhere/pull/906),
[#907](https://github.com/tooming/k8s-anywhere/pull/907),
[#909](https://github.com/tooming/k8s-anywhere/pull/909),
[#910](https://github.com/tooming/k8s-anywhere/pull/910),
[#911](https://github.com/tooming/k8s-anywhere/pull/911),
[#912](https://github.com/tooming/k8s-anywhere/pull/912)), and one independent
merge from a concurrent executor session
([#908](https://github.com/tooming/k8s-anywhere/pull/908)).

## This cycle's fresh angles (all clean)

1. **`ExternalSecret` → `secretStoreRef` wiring.** All 15 `ExternalSecret`
   resources across the repo reference `{name: vault, kind:
   ClusterSecretStore}`, matching the one real `ClusterSecretStore`
   (`gitops/secrets/clustersecretstore.yaml`). No dangling references.
2. **`HTTPRoute` → `parentRefs` wiring.** All 13 `HTTPRoute` resources
   reference `{name: eg, namespace: lab-gateway}`, matching the single real
   `Gateway` (`gitops/network/gateway.yaml`). No typos.
3. **Velero `Schedule` namespace coverage.** All six schedules use literal
   `includedNamespaces` (no selector-typo risk); every namespace name
   verified against a real `namespace.yaml`, and cross-checked against every
   namespace actually holding PVCs — full coverage, `capstone`'s
   zero-schedule-PVC-need and `storage`/Garage's documented exclusion both
   confirmed correct.
4. **Grafana dashboard PromQL metric-name typo sweep.** Extracted ~88
   distinct metric names from all 34 dashboards (`grafana/dashboards/`) and
   fuzzy-matched every pair for near-duplicate/typo'd metric names. 8 close
   pairs found, all legitimately distinct real metrics (e.g.
   `container_network_receive_bytes_total` vs `..._transmit_bytes_total`).
   No typos.

Also spot-checked two recent `docs/done/*.md` entries against current repo
state and re-ran `scripts/kustomize-orphan-check.sh` live — both still
accurate, zero orphans currently.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record — a background research pass tried
four genuinely fresh angles (cross-checked against 30+ prior sweep files to
avoid repeats), all clean. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
