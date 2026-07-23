- [ ] 🟢 **Bump kiali-server chart `1.89.8` → `2.29.0`** (CHARTER **Core Values**
  §"Everything as code" + §"Docs & dashboards don't drift"; RFC #668 — architect
  decision 2026-07-23, ADR-0012 audit resolved as **Convert**. **No
  prerequisites — executor may pick up immediately.**) `gitops/platform/kiali.yaml`'s
  pinned `kiali-server` chart `targetRevision: 1.89.8` no longer resolves in the
  live `https://kiali.org/helm-charts` index — verified directly (not a network
  blip; `main`'s own CI passed this exact check 4.5 hours before the break was
  found) that `1.89.8` was the last pre-2.0 release and the chart repo's served
  index no longer lists it. RFC #668 verified the Kiali 2.0 breaking changes
  (Discovery Selectors replacing namespace config, `kubernetes_config.cache_*`
  removal, `istio_namespace`/`external_services.istio.root_namespace` removal)
  do not touch this lab's `valuesObject` keys (`auth.strategy`, `external_services.
  prometheus.{url,custom_headers}`, `external_services.tracing.enabled`,
  `deployment.resources`) — all confirmed still valid in Kiali 2.x via current
  (2026) docs/community examples.

  Bump `gitops/platform/kiali.yaml`'s `spec.source.targetRevision` from
  `1.89.8` to `2.29.0` (newest verified-real tag, 2026-07-13) — do NOT change
  `valuesObject`, compatibility already verified in RFC #668/ADR-0012's
  Re-evaluation log entry. Update `docs/dependency-tree.md`'s two `v1.89.8`
  references (chart-pin note lines) to `2.29.0`. Add or extend a bats
  assertion pinning the `kiali-server` chart version (check `tests/platform.bats`
  first for an existing assertion to extend before adding a new one). `make ci`
  must pass — including `helm-chart-pin-check.sh` actually resolving `2.29.0`
  against the live index in the PR's own GitHub Actions run (this tool isn't
  installed in every local/sandboxed environment, so the real signal is the
  PR's CI, not a local skip). PR body must state the ADR-0004 caveat: this
  remote clusterless session cannot verify Kiali actually starts cleanly
  against real Istio/Mimir on a live `make kiali-up` post-bump, and that the
  usual "trivial revert" rollback story doesn't fully apply here since
  `1.89.8` no longer resolves either — call out that a rollback would need
  whatever `2.x` patch was last verified-working, not literally the prior pin.
  Kiali is on-demand/non-auto-synced (ADR-0012) — zero live-cluster blast
  radius; ArgoCD only reconciles this on `make kiali-up`. `docs/done/` entry
  required. Closes #668. (auto/kiali-chart-2-29-0)
