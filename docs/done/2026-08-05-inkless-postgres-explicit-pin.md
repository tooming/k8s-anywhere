# Pin Inkless's batch-coordinator `postgres` image explicitly — `postgres:17` → `postgres:17.10`

(CHARTER **Core Values** §"Everything as code" + general hardening;
planner-fallback finding 2026-08-05, surfaced during this run's
ARCHITECT-fallback audit of ADR-0015 (issue #1013/PR #1014, which held
Inkless's Postgres at the `17.x` line rather than jump to the released
`18.x` major) — that audit's body flagged this as a separate,
non-architectural gap: `postgres:17` is a **floating tag**, unlike every
other version-sensitive pin in this repo (Vault, Grafana, Argo Rollouts,
Envoy Gateway, Kiali, k3s), which all pin an exact patch explicitly. **No
prerequisites — executor may pick up immediately** (Now/next's three
standing items remain gated on #631/#633, no new comment). Verified
directly (not assumed, ADR-0004): Docker Hub's tags API
(`hub.docker.com/v2/repositories/library/postgres/tags?name=17.`) shows
`17.10` as the newest patch on the `17.x` line (`17.0` through `17.10`, no
`17.11` yet), matching `postgres/postgres`'s own `REL_17_10` git tag. This
is a **pin-what's-already-running** change, not a version bump — the
floating `postgres:17` tag already resolves to `17.10` on any fresh image
pull today; explicit pinning only makes that fact durable and inspectable,
mirroring the 2026-07-24 Vault server-image-pin precedent
(`docs/done/2026-07-24-vault-server-image-tag-pin.md`) exactly.

Bump `gitops/inkless/postgres-statefulset.yaml`'s `image: postgres:17` →
`image: postgres:17.10`. Add a new recurrence-guard assertion to
`tests/inkless.bats` (currently that file only asserts the StatefulSet
manifest *exists* — `"postgres StatefulSet manifest exists"` — no test
guards the image tag at all yet): assert `image: postgres:17.10` is
present in `postgres-statefulset.yaml`, and a second assertion that the
bare floating `image: postgres:17` (no patch suffix) is NOT present, same
shape as this repo's other per-component exact-version pin recurrence
guards (mirrors `ack-s3.bats`/`envoy-gateway.bats`). No ADR-0015 edit
needed beyond what PR #1014 already added — that re-evaluation log entry
already documents the `17.x` vs `18.x` major-line decision; this item only
makes the *current* `17.x` patch explicit, it doesn't re-litigate the
major-version hold. No `docs/dependency-tree.md`/`context.md` update
needed — neither cites this image's specific version (checked directly).
`make ci` must pass. PR body must document the Docker Hub tag-currency
finding above and the ADR-0004 caveat that this remote clusterless session
cannot verify `inkless-postgres` starts cleanly post-pin on a live cluster
— call out the rollback path (revert the tag; Inkless is on-demand/never
auto-synced, so this has zero live-cluster blast radius until the
maintainer next runs `make inkless-up`; no data-loss risk either way since
`17.10` and floating `17` are the same actual image content today).

Re-verified at pickup time (this build cycle): Docker Hub's tags API still
shows `17.10` as the newest patch on the `17.x` line — no drift since the
planning cycle.

## PR

https://github.com/tooming/k8s-anywhere/pull/1016
