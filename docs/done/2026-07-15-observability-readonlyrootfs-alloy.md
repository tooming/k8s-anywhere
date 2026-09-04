# `observability` readOnlyRootFilesystem tighten — Alloy

**`observability` readOnlyRootFilesystem tighten — Alloy** (CHARTER **Objective O2**
hardening, ADR-0017 §"Per-workload field carve-outs"; split from the combined
Alloy/Grafana/Pyroscope item filed 2026-07-14). Verified against the actual `alloy`
chart source at the pinned tag (`grafana/alloy` repo, tag `helm-chart/1.8.2`,
`operations/helm/charts/alloy/templates/controllers/_pod.yaml` +
`templates/containers/_agent.yaml`, fetched via
`git clone --filter=blob:none --sparse`): contrary to this item's original inline
comment ("chart-created emptyDir"), the chart does **not** create a volume for
`--storage.path` (default `/tmp/alloy`) — there is no volume or mount matching that
path anywhere in the chart's templates, only `config` / `varlog` / `dockercontainers`
/ `extra`. Under the prior `readOnlyRootFilesystem: false` config this landed on the
container's writable root fs; flipping to `true` without a fix would have crash-looped
Alloy on its first WAL write.

Fixed by adding an explicit `alloy-storage` `emptyDir` volume via
`controller.volumes.extra`, mounting it at `/tmp/alloy` via `alloy.mounts.extra`, then
flipping `alloy.securityContext.readOnlyRootFilesystem: false` → `true` in
`gitops/platform/observability-alloy.yaml`. Extended
`tests/securitycontext-observability.bats` with two new assertions: Alloy sets
`readOnlyRootFilesystem: true`, and the `alloy-storage` emptyDir + `/tmp/alloy` mount
are present. Updated the file's header comment to reflect Alloy no longer being an
open carve-out.

Also recorded a network-access finding in ROADMAP.md for the two remaining components
(Grafana, Pyroscope): `grafana.github.io` and `api.github.com` are proxy-blocked in
this environment, but `raw.githubusercontent.com` (for known file paths) and the git
wire protocol (`git clone --filter=blob:none --sparse` + `git ls-remote --tags`)
are not — this unblocks reading a pinned chart's real `templates/` without a live
cluster, which the 2026-07-14 filing of this item assumed was unavailable.

(auto/observability-readonlyrootfs-alloy)

## PR

https://github.com/tooming/k8s-anywhere/pull/413
