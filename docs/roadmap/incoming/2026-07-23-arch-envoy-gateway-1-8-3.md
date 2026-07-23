- [ ] 🟢 **Bump Envoy Gateway chart `v1.8.2` → `v1.8.3`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC #671 — architect decision
  2026-07-23, ADR-0008 audit resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) ADR-0008's 2026-07-18 Re-evaluation log
  entry (audit #515) recorded an explicit flip condition: "revisit when a new
  Envoy Gateway security bulletin names a version above `v1.8.2` as affected."
  Issue #663 (2026-07-22T05:46 UTC) found `v1.8.3` existed as a GitHub tag but
  its chart/image weren't yet published to Docker Hub (404), so the bump was
  correctly held back. Re-verified 2026-07-23: `v1.8.3` is now live — GitHub
  release published 2026-07-22T18:59:00Z (stable, not pre-release; changelog:
  dependency updates + a fix that "rejects TLS secret when certificate and
  private key do not match"), and the Docker Hub OCI artifact
  `envoyproxy/gateway-helm:v1.8.3` resolves for real (`tag_status: active`,
  digest `sha256:cfb34ff4266c87a394cd6be5c13607a2dd47083aef771368302eaeaa99c4a0a9`,
  content-type `application/vnd.cncf.helm.config.v1+json`, `last_updated:
  2026-07-22T18:57:28Z` — confirmed via direct query against
  `https://hub.docker.com/v2/repositories/envoyproxy/gateway-helm/tags/v1.8.3`,
  not just training knowledge, per ADR-0004).

  Bump `gitops/platform/envoy-gateway.yaml`'s `targetRevision: v1.8.2` →
  `v1.8.3` (same source, same major.minor line — patch bump only). Add a new
  dated entry to ADR-0008's `## Re-evaluation log` (after the existing
  2026-07-18 audit #515 entry) recording this bump, citing the GitHub release
  + Docker Hub verification above, with a new flip condition for the next
  audit (e.g. "revisit when a bulletin names a version above `v1.8.3` as
  affected"). Add or extend a `tests/*.bats` chart-pin assertion for
  envoy-gateway (check for an existing one first) asserting `v1.8.3` is
  present in `envoy-gateway.yaml` — a recurrence guard mirroring the existing
  Argo Rollouts/Grafana/Valkey image-tag pin assertions. Update
  `docs/dependency-tree.md` only if it references the pinned chart version
  explicitly. `make ci` must pass. PR body must note the ADR-0004 caveat that
  this remote clusterless session cannot verify Envoy Gateway starts cleanly
  post-bump on a live cluster — call out the rollback path (revert
  `targetRevision`; ArgoCD self-heals within its sync interval; Envoy Gateway
  is stateless control plane, so a revert recovers immediately with no data
  loss). `docs/done/` entry required. Closes #671.
  (auto/envoy-gateway-chart-1-8-3)
