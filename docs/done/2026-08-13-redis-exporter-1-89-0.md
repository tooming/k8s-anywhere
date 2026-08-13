# Bump Valkey's `redis_exporter` sidecar `v1.88.0-alpine` → `v1.89.0-alpine`

(CHARTER **Core Values** §"Everything as code" + general hardening; planner-fallback
currency sweep 2026-08-13, reached via `executor.prompt.md` STEP 6b — every unchecked
ROADMAP item (the three standing Now/next GitLab→Forgejo migration items plus the
three items gated on maintainer-confirmation issues #631/#633) was re-checked this
cycle and confirmed still gated (both issues' latest comments, 2026-08-11 13:09 UTC,
report the same live-cluster blockers, no maintainer confirmation), with no
live-state-safe slice to split off any of them. Fresh angle this cycle: a full
inventory of every plain `image:` line under `gitops/` not yet cross-checked against
its own upstream source (the always-on-stack chart/image pins in
`docs/dependency-register.md` were all re-verified current on 2026-08-12/13 by prior
cycles — Terraform, ArgoCD, Garage, Grafana, Envoy Gateway, RabbitMQ, Cilium,
Valkey itself, Kyverno, Argo Rollouts, Velero, Trivy Operator, Kargo, Harbor,
cert-manager, KEDA, GitLab, and the LGTMP internals — but sidecar/helper images that
ride alongside a tracked component, not tracked as their own register row, hadn't
been swept this run. **No prerequisites — executor may pick up immediately.**)
Verified directly (not assumed, ADR-0004): Docker Hub's tags API
(`hub.docker.com/v2/repositories/oliver006/redis_exporter/tags`) shows
`v1.89.0-alpine` (and plain `v1.89.0`) published 2026-08-09, one release ahead of
this lab's pinned `v1.88.0-alpine` (pinned 2026-07-25 per the pin's own inline
comment) — matching `github.com/oliver006/redis_exporter`'s own `v1.89.0` git tag.
A real clone's `git log v1.88.0..v1.89.0` (3 commits, not the published
`CHANGELOG.md`) shows: `fix: avoid COMMANDLOG error spam on targets without
COMMANDLOG support (#1156)` — directly relevant to this lab, since Valkey does not
implement the newer `COMMANDLOG` command this exporter started probing for, so the
prior pin was almost certainly emitting spurious error-level log noise on every
scrape; `ensure a change in label keys doesn't vanish the metric (#1151)` — a real
metric-correctness fix; and a routine dependency bump (`prometheus/client_golang`
1.23.2 → 1.24.1). This satisfies the "ships with a real fix" bar this repo's other
non-CVE currency bumps (e.g. Loki's ingester flush-race fix, this same sidecar's
prior `v1.87.0`→`v1.88.0` bump) use — not a blind patch assumption.

Bump `gitops/data/valkey/statefulset.yaml`'s `image:
oliver006/redis_exporter:v1.88.0-alpine` → `:v1.89.0-alpine`. Update the file's
existing header comment block to describe this bump instead: cite the
COMMANDLOG-spam fix (and why it's relevant to Valkey specifically), the label-key
metric fix, and that no flag/env-var surface changed (this container still sets
only `REDIS_ADDR`/`REDIS_PASSWORD`, both long-stable). Update
`tests/data-layer.bats`'s pin assertion (previously titled `"valkey's redis_exporter
sidecar is pinned to v1.88.0-alpine (patch bump from v1.87.0)"`) to assert
`v1.89.0-alpine` and retitle it to describe this bump. No `docs/dependency-tree.md`
or `docs/dependency-register.md`/ADR-0018 update needed — none of the three cites
this sidecar's specific version (checked directly; the register's Valkey row and
ADR-0018 both mention `redis_exporter` only by name, never a pinned tag). `make ci`
must pass.

## ADR-0004 caveat

This remote clusterless session cannot verify the sidecar starts cleanly and the
"Lab — Valkey" dashboard keeps populating post-bump on a live cluster.

## Rollback path

Revert the `image:` tag. Valkey's `StatefulSet` is a plain manifest, not an
ArgoCD-templated Helm release, so a revert takes effect on the next GitOps sync; the
exporter is stateless, so a rollback recovers immediately with no data loss.

## PR

https://github.com/tooming/k8s-anywhere/pull/1178
