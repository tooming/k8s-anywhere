# `lab-demo` actually runs the Jaeger HotROD tracing demo, not the "single static hello-world Deployment" the docs claimed

Found live 2026-09-08 (planner gap analysis, different lens: cross-checking
a docs claim repeated across 5 files against the actual manifest it
describes): `git log -S "static hello-world" -- README.md CHARTER.md
ROADMAP.md docs/00-architecture.md` showed this phrasing was introduced by
the 2026-09-06/2026-09-07 simplification commit (`319d6b2`/#1497) — the
same commit that removed the observability stack HotROD's tracing existed
to feed — but `gitops/apps/demo/deployment.yaml`'s actual image was never
swapped; it still pulled the full Jaeger HotROD demo app, whose own
`OTEL_EXPORTER_OTLP_ENDPOINT` was already removed the same commit ("hotrod
runs with its own default (no-op) exporter behavior" — its tracing
functionality was entirely dead weight). Confirmed there was no Service or
IngressRoute for `lab-demo` at all — HotROD's web UI had never actually
been reachable from outside the cluster, so replacing it lost nothing
reachable. Also confirmed `gitops/apps/demo/configmap.yaml`
(`lab-demo-hello`) was never referenced by the Deployment — a second,
independent orphan this same fix closed.

## What was done

1. **Image swap** — `gitops/apps/demo/deployment.yaml`'s image replaced
   `jaegertracing/example-hotrod:2.20.0` with
   `nginxinc/nginx-unprivileged:1.31.5-alpine` (exact tag, verified live
   against Docker Hub's tags API — the latest real `X.Y.Z-alpine` release,
   pushed 2026-09-07). Serves the `lab-demo-hello` ConfigMap's own "Hello
   from GitOps..." message as a real static page: added a new `index.html`
   key to the ConfigMap (same message text, not a fabricated copy — a bats
   test asserts both copies match) and mounted it read-only at
   `/usr/share/nginx/html`.
2. **PSS flip (`baseline` → `restricted`)** — nginx-unprivileged runs
   non-root by default, meeting the flip condition ADR-0017's `lab-demo`
   row named since the pilot. Flipped `gitops/apps/demo/namespace.yaml`'s
   four PSA labels; added explicit pod securityContext
   (`runAsNonRoot: true`, `runAsUser`/`runAsGroup`/`fsGroup: 10001` per
   ADR-0017's per-workload default, `seccompProfile.type: RuntimeDefault`)
   and container securityContext (`allowPrivilegeEscalation: false`,
   `capabilities.drop: [ALL]`, `readOnlyRootFilesystem: true`).
3. **Writable paths via emptyDir, not a relaxed root filesystem** — mounted
   `emptyDir` volumes at `/tmp` and `/var/cache/nginx`, the exact two paths
   nginx-unprivileged's own README documents as needing to be writable
   under a read-only root filesystem (pid file + all http-context temp
   paths redirect under `/tmp` by default; the default `nginx.conf`'s
   proxy/fastcgi cache dirs live under `/var/cache/nginx`) — verified
   against the image's own documentation, not guessed.
4. **ADR-0017 updated** — the `lab-demo` per-namespace table row now reads
   `restricted`; added a dated `## Re-evaluation log` entry recording the
   flip and its full history (checked 2026-07-26, 2026-09-08 not-yet-met →
   this flip).
5. **Stale comments fixed** — `gitops/apps/demo/namespace.yaml`'s own
   header comment and `tests/securitycontext-lab-demo.bats`'s own header
   comment both still said "because jaegertracing/example-hotrod runs as
   root" and cited the dead "or is replaced by the capstone-built image"
   flip condition (the same phrase already removed from ADR-0017 itself in
   #1514, but missed in these two files) — corrected. Also fixed two
   current-state claims in `docs/dependency-tree.md` (a Mermaid diagram
   node label and the `lab-demo namespace PSA` bullet) that still named
   HotROD/`baseline`.
6. **Test coverage** — `tests/securitycontext-lab-demo.bats` rewritten to
   assert `restricted` (was `baseline`), the new image pin, every new
   securityContext field, the emptyDir mounts, and the ConfigMap wiring —
   16 tests total (was 5). `tests/image-pin-demo-storage.bats`'s recurrence
   guard (no-floating-tag hardening) updated to assert the new
   `nginx-unprivileged` exact-tag pin instead of the retired
   `jaegertracing/example-hotrod:2.20.0` one.

**Not in scope** (per the ROADMAP item's own text): adding a
Service/IngressRoute for `lab-demo` — it never had one; a separate item if
ever wanted.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green) — including
`validate-manifests.sh`/kustomize re-rendering the new Deployment shape
cleanly. Diff size: 215 insertions + 40 deletions across 7 files, well
within WAYS-OF-WORKING.md §3's ~400-line cap (no split needed).

## PR

[#1529](https://github.com/tooming/k8s-anywhere/pull/1529) (autonomous
scheduled executor run, cycle 16: item picked directly from the
freshly-refilled "Now / next" lane after cycle 15's `plan/*` PR #1528).
