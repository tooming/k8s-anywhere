# ADR-0039 — s3manager as the lab's Garage (S3) browser UI

**Status.** Adopted (retroactive record). Already live in `gitops/storage/s3manager/`
— this ADR closes a documentation gap, not a new technical choice. No binding ADR
is contradicted or superseded; self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2, same precedent as
[ADR-0036](adr-0036-external-secrets-vault-sync.md),
[ADR-0037](adr-0037-vault-secrets-management.md), and
[ADR-0038](adr-0038-ack-kro-moto-cloud-control-plane.md): a real,
already-implemented, already-live mechanism that predated having any ADR of its
own. Always-on component.

---

## Context

The lab's Garage S3 store ([ADR-0002](adr-0002-garage-not-minio.md)) has no
built-in web UI of its own — every object today is only inspectable via the CLI
(`mc`/`aws s3` against Garage's S3 API) or by an application reading it
programmatically. A lightweight, read-focused browser UI closes that gap for
demo/debugging purposes: seeing what's actually in a bucket without a shell.
This is a real, live component (`gitops/storage/s3manager/`, reachable at
`http://s3.127.0.0.1.nip.io:8080`) with its own real version-bump history that,
like ACK-S3 before ADR-0038, lived only as inline YAML comments — never
formally governed by an ADR.

---

## Decision

Adopt **s3manager** (`cloudlena/s3manager`, MIT-licensed, ~1k GitHub stars) as
the lab's Garage browser UI: a lightweight Go web app, single binary, no
persistence of its own (stateless — every view is a live read against Garage).

- **Image:** `cloudlena/s3manager@sha256:cc4b81ea29fb59610e29df6707ab6646e36e32744bbb700cffd5d2d6bf60c03f`
  (`v0.9.0`; bumped from `v0.8.0` in this same cycle — see §Re-evaluation log).
  Pinned **by digest, not tag** — deliberate, per this repo's no-floating-tag
  hardening (2026-07-28) and the Kyverno `disallow-latest-tag` `ClusterPolicy`
  this pin already satisfies; the version tag is cited in-comment for
  provenance only.
- **Namespace:** `storage` (shared with Garage itself).
- **Credentials:** the `garage-s3` Secret's `access-key-id`/`secret-access-key`
  (the same Garage key other in-cluster consumers use), via env vars —
  path-style, plain HTTP (`USE_SSL: "false"`, matching Garage's own in-cluster
  listener).
- **Ingress:** Envoy Gateway `HTTPRoute` (`s3.127.0.0.1.nip.io`), same shared
  Gateway pattern as every other lab UI ([ADR-0008](adr-0008-envoy-gateway-not-traefik.md)).

### NetworkPolicy

`gitops/storage/networkpolicy/allow-s3manager-ingress.yaml`: ingress from
`envoy-gateway-system` only (the shared Gateway proxying
`s3.127.0.0.1.nip.io` to this pod on TCP 8080) — added specifically because,
per that file's own header comment, none of `storage`'s existing NetworkPolicy
rules (`allow-garage-s3-from-observability`/`-inkless`) covered s3manager at
all until this rule was added.

## Test coverage

`tests/image-pin-demo-storage.bats` (digest-pin shape, no floating tag),
`tests/networkpolicy-storage.bats` (the ingress rule above),
`tests/dashboard-coverage.bats` / `tests/observability.bats` (dashboard
presence — s3manager itself has no dedicated real-metric dashboard beyond
Garage's own, since it exposes no Prometheus metrics of its own; it's a thin
UI over Garage's data, not an independently-monitored service).

---

## Files

| Path | Role |
|------|------|
| `docs/decisions/adr-0039-s3manager-garage-browser-ui.md` | This ADR |
| `gitops/platform/s3manager.yaml` | Auto-synced ArgoCD `Application` (in-repo manifest source) |
| `gitops/storage/s3manager/*.yaml` | Deployment, Service, HTTPRoute |
| `gitops/storage/networkpolicy/allow-s3manager-ingress.yaml` | NetworkPolicy allowing Gateway ingress |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Lands as an ArgoCD `Application`, sourcing this repo's own manifests directly (same shape as moto — see ADR-0038). |
| [ADR-0002](adr-0002-garage-not-minio.md) | s3manager is a pure consumer of Garage's S3 API — no independent storage decision here, just a browser on top. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Every view is a live read against Garage — no stub/sample data. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Reached via the shared Gateway `HTTPRoute`, same pattern as every other lab UI. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `storage` namespace's default-deny needed an explicit rule added for this pod specifically (see §NetworkPolicy above). |

---

## Re-evaluation log

### 2026-07-28 — pinned by digest (recreate-from-code / no-floating-tag hardening)

**Migrated from `gitops/storage/s3manager/deployment.yaml`'s own inline
comment** (this ADR didn't exist yet). Original pin's digest
(`sha256:f666e6fc...`) predated any matching version tag — Docker Hub's tags
API at the time showed `latest` one build ahead of `v0.7.0`.

### 2026-08-18 — bumped to `v0.8.0` (upgrade-drafter fallback currency sweep)

**Migrated from `gitops/storage/s3manager/deployment.yaml`'s own inline
comment.** Upstream had since tagged the build the prior pin was on and moved
past it: `v0.8.0` (published 2026-08-11) was the newest tag, and its digest
matched `latest`'s digest at the time — verified directly against a full
clone of `github.com/cloudlena/s3manager` (ADR-0004): `git log v0.7.0..v0.8.0`
contains three real features (per-object version listing, per-object metadata
display, local-timezone Last-Modified rendering) plus two "Update
dependencies" commits bumping the Go toolchain `1.26.2`→`1.26.5` (the same
stdlib-CVE-fixing release this repo's own Tempo `2.10.8` bump already cited:
CVE-2026-39822, CVE-2026-27145, CVE-2026-42504, CVE-2026-42505,
CVE-2026-42507) and `golang.org/x/{crypto,net,sys,text}` +
this app's S3-client SDK dependency (`v7.1.0`→`v7.2.1`).

### 2026-09-03 — ADR authored (retroactive record); bumped to `v0.9.0`

**Trigger.** This run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) found s3manager — a real, live, always-on component with a genuine
version-bump history — had no governing ADR and no `docs/dependency-register.md`
row at all, unlike every other component in the lab. Same shape as the
ADR-0036/0037/0038 gaps closed earlier this run.

**Checked directly against live sources (ADR-0004):** Docker Hub's tags API
(`hub.docker.com/v2/repositories/cloudlena/s3manager/tags`) confirms `v0.9.0`
(pushed 2026-09-02) is the newest tag, one ahead of the current `v0.8.0` pin;
zero published GHSA advisories exist for `cloudlena/s3manager`. Diffed the
real commit history (`github.com/cloudlena/s3manager/compare/v0.8.0...v0.9.0`)
rather than assuming from the release title alone: four commits — "Update
dependencies," "Add open action" (a new feature), "Migrate from Materialize
CSS to BeerCSS" (a real front-end framework swap — explains the release's own
"Redesign 🎉" title), and "Simplify code."

**Decision: bump to `v0.9.0`.** No CVE urgency (none exists either way), but
this is the newest stable tag and the diff is small and legible enough to
accept. **ADR-0004 caveat:** this remote clusterless session cannot visually
verify the CSS-framework migration renders correctly in a browser — s3manager
is stateless (no data at risk) and pinned by digest, so the rollback path is a
one-line digest revert with zero data-loss risk if the new UI renders badly.

**Flip condition (next re-evaluation).** Re-check s3manager currency and GHSA
status on the next full-sweep pass.
