# Pin the TiDB demo's floating `nginx:alpine` tag to `nginx:1.31.3-alpine`

(CHARTER **Core Values** §"Everything as code" + general hardening; planner-fallback
currency sweep 2026-08-13, second pass this run, reached via `executor.prompt.md`
STEP 6b — every Now/next item is still gated (the three standing GitLab→Forgejo
migration items plus the three items gated on maintainer-confirmation issues
#631/#633, re-checked, unchanged) and this run's first PLANNER-fallback pass
(`auto/redis-exporter-1-89-0`, merged) already claimed the one sidecar-image gap
that sweep found. This cycle's fresh angle, per STEP 8's "widen the lens" guidance
(a different pass than the one just used): rather than continuing the
version-currency sweep, checked every `image:` line under `gitops/` for a
**floating** (non-exact-patch) tag — the same class of gap the 2026-08-05
`postgres:17` → `postgres:17.10` Inkless fix (issue #1013,
`docs/done/2026-08-05-inkless-postgres-explicit-pin.md`) closed for that
component, applied here as a fresh sweep across the rest of the repo. Found one
remaining instance: `gitops/tidb-demo/deployment.yaml`'s demo web server was pinned
to the bare floating tag `nginx:alpine`, unlike every other version-sensitive pin
in this repo (Vault, Grafana, Argo Rollouts, Envoy Gateway, Kiali, k3s, and
Inkless's Postgres), which all pin an exact patch explicitly.

Verified directly (not assumed, ADR-0004): Docker Hub's tags API for
`library/nginx` shows the floating `alpine` tag's content digest
(`sha256:4a73073b...`) is byte-identical to the `mainline-alpine` tag's digest,
which in turn matches the exact-version tags `1.31.3-alpine` and `1.31-alpine`
(same digest for all four) — so `nginx:alpine` currently resolves to nginx's
**mainline** line at patch `1.31.3`, not the `stable` line (`1.30.4-alpine`, a
distinct, older digest, confirmed separately). This is a **pin-what's-already-
running** change, not a version bump — the floating tag already resolved to
`1.31.3-alpine` on any fresh pull today; explicit pinning only makes that fact
durable and inspectable, mirroring the Inkless-Postgres and 2026-07-24 Vault
server-image-pin precedents exactly.

## Fix

Bumped `gitops/tidb-demo/deployment.yaml`'s `image: nginx:alpine` → `image:
nginx:1.31.3-alpine`. Added a header comment documenting the pin-what's-running
finding above, including the mainline-vs-stable digest disambiguation. Added two
new `tests/tidb-cluster.bats` assertions: the exact pin is present, and the bare
floating `nginx:alpine` tag is NOT present — same shape as this repo's other
per-component exact-version pin recurrence guards (mirrors `tests/inkless.bats`'s
postgres pin pair).

## ADR-0004 caveat

This remote clusterless session cannot verify the demo pod starts cleanly post-pin
on a live cluster.

## Rollback path

Revert the tag. `tidb-demo` is part of the on-demand `tidb` unit, never
auto-synced, so this has zero live-cluster blast radius until the maintainer next
runs `make tidb-up`; no data-loss risk either way since `1.31.3-alpine` and the
prior floating `alpine` are the same actual image content today.

## PR

https://github.com/tooming/k8s-anywhere/pull/1180
