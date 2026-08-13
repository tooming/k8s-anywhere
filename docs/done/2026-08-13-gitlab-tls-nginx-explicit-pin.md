# Pin `gitlab/docker-compose.yml`'s `gitlab-tls` sidecar to `nginx:1.27.5-alpine` (currently the floating `1.27-alpine` tag)

(CHARTER **Core Values** §"Everything as code" + general hardening; planner-fallback
currency/hardening sweep 2026-08-13, reached via `executor.prompt.md` STEP 6b — every
Now/next item is still gated (the three standing GitLab→Forgejo migration items, plus
the `verifyImages` Enforce flip, the O4 CI-rejection-gate, and the legacy capstone
`Deployment` removal, all gated on unconfirmed maintainer-confirmation issues
#631/#633). This cycle's fresh angle: the last two currency sweeps this run covered
`gitops/**/*.yaml` image lines and the Terraform-bootstrap seam; this cycle instead
swept the two out-of-cluster `docker-compose.yml` stacks (`gitlab/`, `forgejo/`) — a
third, genuinely distinct enumeration surface neither prior sweep touched.

Verified directly (not assumed, ADR-0004): `tests/gitlab-compose.bats`'s own docstring
documents the exact bug class this repo already fixed once for this same file — the
omnibus service and its runner used to float on `:latest` until pinned to
`19.2.1-ce.0`/`v19.2.1` — but the `gitlab-tls` nginx sidecar (added later, for
ADR-0006's Grafana Git Sync HTTPS requirement) was missed: it still floated on
`nginx:1.27-alpine` (a minor-version tag, not an exact patch), unlike every other
image in this file. Docker Hub's tags API confirms `nginx:1.27-alpine`'s current
digest (`sha256:65645c7b...`) is byte-identical to the exact-patch tag
`nginx:1.27.5-alpine`'s digest (checked against `1.27.5`/`1.27.4`/`1.27.3`/`1.27.2`/
`1.27.1`/`1.27.0`-alpine individually — only `1.27.5-alpine` matches).
`forgejo/docker-compose.yml` was checked too and has no equivalent gap — both its
images are already exact-pinned. This is a pin-what's-already-running change, not a
version bump — the floating tag already resolves to `1.27.5-alpine` on any fresh pull
today; explicit pinning only makes that fact durable and inspectable, mirroring this
run's own `tidb-demo` nginx pin precedent
(`docs/done/2026-08-13-tidb-demo-nginx-explicit-pin.md`).

## Fix

Bumped `gitlab/docker-compose.yml`'s `gitlab-tls` service `image: nginx:1.27-alpine`
→ `image: nginx:1.27.5-alpine`, with a header comment documenting the digest-match
finding (mirroring the omnibus service's own adjacent comment style). Extended
`tests/gitlab-compose.bats` with two new assertions: `gitlab-tls` is pinned to
`nginx:1.27.5-alpine`; the bare floating `nginx:1.27-alpine` (no patch suffix) is NOT
present — same present/absent recurrence-guard shape as this run's own
`tidb-demo`/`tests/tidb-cluster.bats` pair. No `docs/dependency-tree.md`/
`docs/dependency-register.md`/ADR-0033 update needed — none of the three tracks this
specific sidecar's pinned patch version.

## ADR-0004 caveat

This remote clusterless session cannot verify the `gitlab-tls` container starts
cleanly and Grafana's Git Sync HTTPS path keeps working post-pin — this service runs
outside the Kubernetes cluster entirely, on the maintainer's Colima host.

## Rollback path

Revert the `image:` tag. `docker compose --profile tls up -d` on the next
`gitlab-tls-bootstrap.sh` run picks up the change; zero data-loss risk either way
since `nginx:1.27-alpine` and `1.27.5-alpine` are the same actual image content
today, and this container is stateless TLS termination with no volumes.

## PR

https://github.com/tooming/k8s-anywhere/pull/1191
