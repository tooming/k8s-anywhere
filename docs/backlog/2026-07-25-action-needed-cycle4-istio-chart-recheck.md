# [Action needed] Now/next still gated; Istio chart pin re-verified current, other blocked hosts re-confirmed

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (fourth cycle of 2026-07-25, a new scheduled run): all three still
open, zero comments, `updated_at` unchanged since 2026-07-21T05:34 UTC. No
new GitHub issues exist beyond these three standing trackers, and
`docs/roadmap/incoming/` is empty (no pending architect items to absorb).

## This cycle's fresh angle

Earlier cycles today (see
[`2026-07-25-action-needed-cycle3-dependency-sweep-exhausted.md`](2026-07-25-action-needed-cycle3-dependency-sweep-exhausted.md))
and yesterday's platform chart-pin sweep (cycle 9) already re-verified most
`gitops/platform/*.yaml` chart pins directly against upstream. Of the
remaining unswept pins — `ack-s3` (1.8.1, `public.ecr.aws`), `kro` (0.9.2,
`ghcr.io`), `keda` (2.20.1, `kedacore.github.io`), `external-secrets` (2.8.0,
`charts.external-secrets.io`), `trivy-operator` (0.34.0,
`aquasecurity.github.io`), `vault` chart (0.34.0,
`helm.releases.hashicorp.com`), and `istio` (1.30.3,
`istio-release.storage.googleapis.com`) — this cycle checked connectivity to
each host directly (`curl -sS -o /dev/null -w "HTTP %{http_code}"`), since
prior cycles established some Helm index hosts are proxy-blocked in this
sandbox while others aren't:

- `charts.external-secrets.io`, `helm.releases.hashicorp.com`,
  `kedacore.github.io`, `aquasecurity.github.io` — all `CONNECT tunnel
  failed, response 403` (proxy policy denial), consistent with cycle 9's
  `*.github.io` finding and cycle "dependency-sweep-exhausted"'s finding for
  similar Pages hosts. `public.ecr.aws` (ack-s3) and `ghcr.io` (kro) were not
  re-tested this cycle — already confirmed blocked/covered by name in
  cycle 9's and earlier sweeps' notes.
- `istio-release.storage.googleapis.com` — **reachable (HTTP 200)**, a host
  no prior dated cycle had tried. Fetched `charts/index.yaml` directly and
  parsed every `base` chart entry's `version` field: newest is
  `1.31.0-alpha.0` (pre-release, unqualified as a stable pin per this repo's
  own precedent of skipping alpha/rc/beta lines), and `1.30.3` — this repo's
  current pin — is the newest **stable** entry, one ahead of `1.30.2` and
  `1.30.1`. Confirms `gitops/platform/istio-base.yaml` /
  `istio-cni.yaml` / `istiod.yaml` / `ztunnel.yaml`'s shared `1.30.3` pin is
  still current. (Istio is on-demand per ADR-0012 — zero live-cluster
  blast radius either way, and this specific host+version combination was
  already checked once before, in `2026-07-22-action-needed-chart-sweep-jul22.md`,
  so this is a re-confirmation rather than a first-time finding — noted
  honestly rather than overstated as new ground.)

No actionable version gap found on any of the seven pins checked or
re-checked this cycle.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size; (d) proxy access to `*.github.io` Pages hosts, `public.ecr.aws`,
and `charts.external-secrets.io`/`helm.releases.hashicorp.com`, which would
let `ack-s3`, `kro`, `keda`, `external-secrets`, `trivy-operator`, and
`vault` chart pins be verified directly instead of relying on the last
sweep that could reach them.

This note is this cycle's honest record — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
