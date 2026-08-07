# k3d containerd registry mirror — resolve `harbor.127.0.0.1.nip.io` in-cluster

(CHARTER **Core Values** §"Recreate-from-code" (`make up` should let the capstone demo
actually run) + §"Images are signed and verified" (O4's admission-signing chain needs a
real image to reach the pod before it's exercisable at all); planner gap-analysis
2026-08-07, reached via `executor.prompt.md` STEP 6b — Now/next's three standing items
remain gated on unconfirmed maintainer-confirmation issues #631/#633/#1034 (re-checked
this cycle, unchanged), and this run's own sweep found no un-RFC'd 🟡 item and no later
section holding an unpromoted item — this is fresh gap-analysis, not a promotion. **No
prerequisites — executor may pick up immediately** (this item is orthogonal to the
live-cluster confirmation #631/#633 need; it fixes a structural bug that *causes* part
of what's blocking them, but doesn't require the cluster to be up to write correctly).
Source: issue #633's 2026-08-07 00:11 UTC comment (a live-cluster session), which found
that once Kargo's Warehouse resource finally validated for the first time, artifact
discovery immediately failed with `dial tcp 127.0.0.1:443: connect: connection refused`
resolving `harbor.127.0.0.1.nip.io` — and separately confirmed the capstone Rollout/
Deployment pod has been stuck `ImagePullBackOff` on the identical error the entire time
(117+ minutes old at observation, pre-existing, unrelated to that session's other
fixes). Root cause, verified directly in this repo (not assumed, ADR-0004): `nip.io`
is a wildcard DNS service that resolves `<anything>.<IP>.nip.io` to the literal `<IP>`
embedded in the hostname, regardless of *where* the DNS query originates — so
`harbor.127.0.0.1.nip.io`, which correctly means "the Colima host" from *outside* the
cluster (where a human's browser or `curl` runs), means "this pod's own loopback"
from *inside* any pod. `gitops/apps/capstone/deployment.yaml` and
`gitops/apps/capstone/rollout.yaml` both pull `image:
harbor.127.0.0.1.nip.io/library/hello:latest` (grepped directly), and
`gitops/kargo-project/project.yaml`'s Warehouse subscribes to the same
`harbor.127.0.0.1.nip.io/library/hello` repoURL for digest discovery — every one of
these is an in-cluster containerd/Kargo-controller pull, not a browser request, so all
three hit this bug identically. This is a structural, environment-wide gap (any future
on-demand component whose manifests reference a `*.127.0.0.1.nip.io` image host would
hit the same wall), not a one-off capstone bug.

Fix: add a k3d **containerd registry mirror** so in-cluster pulls of
`harbor.127.0.0.1.nip.io` transparently redirect to Harbor's real in-cluster Service —
`harbor.harbor.svc.cluster.local` port 80 (confirmed directly: `gitops/harbor/route.yaml`
backendRefs the `harbor` Service in the `harbor` namespace on port 80, which
`gitops/harbor/networkpolicy/allow-harbor-ingress.yaml`'s own comment confirms
targetPorts to the `harbor-nginx` container's 8080, TLS disabled per ADR-0024 §"Minimal
profile" `expose.tls.enabled: false` — so the mirror endpoint is plain HTTP, no cert
needed). Edit `infra/modules/k3d-cluster/k3d-config.yaml.tftpl`: add a top-level
`registries:` block (k3d's Simple-config field, independent of the existing
`options:`/`ports:` blocks — no conditional needed, always include it, mirrors the
unconditional `ports:` block already in this file) with inline `config:` content
matching containerd's own `registries.yaml` mirror shape:
```yaml
registries:
  config: |
    mirrors:
      "harbor.127.0.0.1.nip.io":
        endpoint:
          - "http://harbor.harbor.svc.cluster.local"
```
Add a code comment above it explaining the nip.io loopback problem (mirrors this item's
own reasoning, so a future reader doesn't need to rediscover it) and noting that Harbor
is itself on-demand (ADR-0024) — this mirror sits inert, harmlessly, whenever Harbor
isn't running; it only matters once `make harbor-up` is used. Scope note: the Oracle
backend (`infra/modules/oracle-k3s-cluster`) is explicitly **out of scope** for this
item — per ROADMAP's own existing note (`infra/live/README.md` "Status" section), that
backend has never actually been deployed, so there is nothing live to fix there yet;
file a follow-up when it is.

New `tests/k3d-registry-mirror.bats` (clusterless, structural — mirrors
`tests/k3s-version-pin.bats`'s file-content-assertion pattern): the tftpl contains a
top-level `registries:` key; the mirror block names
`"harbor.127.0.0.1.nip.io"`; the endpoint is `http://harbor.harbor.svc.cluster.local`
(not `https://`, matching Harbor's TLS-disabled minimal profile); a recurrence guard
that the endpoint is NOT `127.0.0.1` (the exact bug this item fixes — same
"does not pin/contain the stale value" shape as this repo's other version-pin test
pairs). Update `docs/dependency-tree.md`'s Harbor/capstone sub-graph with a one-line
note that in-cluster pulls of `harbor.127.0.0.1.nip.io` resolve via a k3d containerd
mirror to the real Service, not via nip.io DNS. `make ci` must pass (this is a
`terraform validate`/`fmt`-checked template plus a new bats file — no live k3d cluster
needed to confirm the YAML is well-formed and the mirror block is present and correctly
shaped). PR body must document the root-cause finding above and the ADR-0004 caveat
that this remote clusterless session cannot verify the mirror actually redirects a real
containerd pull on a live cluster — call out the rollback path (revert the `registries:`
block; the next `k3d cluster create`/`terraform apply` for a fresh cluster reverts to
unmirrored pulls; existing clusters would need `k3d cluster delete && terraform apply`
to pick up the change, since k3d has no in-place registries-reload — note this plainly,
it is the same "cluster recreate" cost every other k3d-config.yaml.tftpl change in this
repo already carries) and a note asking the maintainer to retry #631's/#633's pipeline
run only *after* this lands and a cluster recreate has picked it up, since it removes a
root cause those issues' own comments trace their most recent blocker to. `docs/done/`
entry required. (auto/k3d-registry-mirror-harbor)

## PR

auto/k3d-registry-mirror-harbor — PR number to be filled once opened.
