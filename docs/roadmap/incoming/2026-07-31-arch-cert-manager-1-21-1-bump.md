- [ ] 🟢 **Bump cert-manager chart `1.21.0` → `1.21.1`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC #933 — architect decision
  2026-07-31, ADR-0028 audit #931 resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) `v1.21.1` exists — confirmed directly via
  `git ls-remote --tags https://github.com/cert-manager/cert-manager.git` (not
  training knowledge, ADR-0004) and a shallow clone at that tag showing the
  commit dates to 2026-07-29, two days after ADR-0028's most recent audit
  (#763, 2026-07-27). `git log refs/tags/v1.21.0..refs/tags/v1.21.1` on that
  real clone shows: a fix for a controller panic/incorrect-renewal bug
  (`fix(renew): Do not renew a certificate if its renewPolicy=Disabled`), and
  four dependency bumps cert-manager's own renovate automation tagged
  `[security]`: `golang.org/x/text` → `v0.40.0`, `google.golang.org/grpc` →
  `v1.82.1`, `github.com/google/cel-go` → `v0.29.0`, `go.opentelemetry.io/otel`
  → `v1.44.0`.

  Bump `gitops/platform/cert-manager.yaml`'s `targetRevision: 1.21.0` →
  `1.21.1` (same source, same major.minor line — patch bump only). Re-verify
  directly at pickup time that the `1.21.1` chart's `values.yaml` still
  contains every key this Application's `valuesObject` sets unchanged in shape
  (`crds.enabled`, `resources.limits.memory`, `webhook.resources.limits.memory`,
  `cainjector.resources.limits.memory`). Add a new dated entry to ADR-0028's
  `## Re-evaluation log` (after the existing 2026-07-27 audit #763 entry)
  recording this bump, citing audit #931, the four security-tagged dependency
  bumps, and the renewal-policy panic fix, with a new flip condition for the
  next audit (e.g. "revisit when a cert-manager security advisory names a
  version at or above `1.21.1` as affected"). Extend `tests/cert-manager.bats`'s
  existing chart-pin assertion (`"cert-manager Application pins chart version
  1.21.0"`) to assert `1.21.1` instead — a recurrence guard mirroring this
  repo's other per-component exact-version pin assertions. Update
  `docs/dependency-tree.md`'s cert-manager bullet, which cites the chart
  version explicitly (`v1.21.0` → `v1.21.1`). `make ci` must pass. PR body must
  document the security-tagged dependency bumps + panic fix, why `1.21.1`
  (smallest safe delta), and the ADR-0004 caveat that this remote clusterless
  session cannot verify cert-manager issues/renews certificates cleanly
  post-bump on a live cluster — call out the rollback path (revert
  `targetRevision`; ArgoCD self-heals within its sync interval; cert-manager is
  a stateless controller Deployment, so a revert recovers immediately with no
  data loss — existing `Certificate`/`ClusterIssuer` objects and their Secrets
  are untouched by a controller-image rollback). `docs/done/` entry required.
  Closes #933. (auto/cert-manager-chart-1-21-1)
