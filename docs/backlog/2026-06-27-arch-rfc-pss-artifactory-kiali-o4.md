# Architect run 2026-06-27 — three RFCs: artifactory PSS, Kiali NP, O4 rejection gate

**Trigger:** executor fallback chain — Now/next lane empty (verifyImages flip blocked on
maintainer confirmation; PRs #284 and #285 cover the two remaining PSS items). Planner
fallback blocked (plan PR #286 already carries the lane refill). Architect fallback
executed.

**Upstream release fetching:** GitHub API session scoped to `tooming/k8s-lab` only;
external repository access denied. Proceeded from training knowledge per ADR-0004
(no fabricated release entries). No ADR audit triggers identified from training knowledge
this week — existing carve-outs (vault, tidb, storage, kyverno) remain valid.

## RFCs filed this run

### RFC #287 — PSS `baseline` + NetworkPolicy — `artifactory` namespace
**Decision:** `baseline` PSA profile (Artifactory OSS JVM init containers run as root
UID 0 for `chown`; `privileged` not warranted — no `SYS_ADMIN`/`NET_ADMIN`/host paths).
NetworkPolicy: ingress TCP 8082 from `envoy-gateway-system`; egress TCP 3900 to `storage`
(Garage S3). `artifactory-extras.yaml` updated to auto-sync (mirrors longhorn-extras/
istio-system-extras pattern). Appset entry `artifactory-networkpolicy` added.
**ADR-0017 row:** `artifactory → baseline`.

### RFC #288 — Kiali NetworkPolicy extensions in `istio-system`
**Key finding:** Kiali deploys into `istio-system` (confirmed: `gitops/platform/kiali.yaml`
`destination.namespace: istio-system`). No separate `kiali` namespace. PSA covered by
`istio-system → privileged` (PR #285). No ADR-0017 `kiali` row needed.
**Decision:** extend `istio-system` NP overlay (post PR #285 merge) with two per-pod
allows: ingress TCP 20001 from `envoy-gateway-system` (Kiali UI); egress TCP 9009 to
`observability` (Mimir Prometheus query). ADR-0017 `istio-system` row updated with
parenthetical noting Kiali co-residence.

### RFC #289 — O4 CI gate: `verify-image-rejection` job in GitLab CI
**Decision:** `verify-rejection` stage + `verify-image-rejection` job using `docker:24`+DinD.
Pushes unsigned `busybox:1.37.0` retagged to `$REGISTRY/docker-local/test-unsigned:
rejection-test` without cosign signing; attempts `kubectl run` in `capstone` namespace;
asserts Kyverno blocks admission. Requires `KUBECONFIG` CI variable (type File) and
`auto/cosign-enforce-flip` merged as prerequisites.

## ROADMAP.md changes

Three targeted single-line annotations to existing 🟡 items in the Cross-cutting section:
- `O4 completion gate` → `(RFC #289)` appended
- `PSS profile decision — artifactory` → `(RFC #287)` appended
- `PSS profile decision — kiali` → `(RFC #288)` appended

No new items in `docs/roadmap/incoming/` (all items already existed in ROADMAP.md).
