# [Action needed] Now/next still gated; ack-s3/kro OCI hosts newly reachable, no version gap found

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, `updated_at` unchanged since
2026-07-21T05:34 UTC. No new ungroomed GitHub issues exist beyond these three
standing trackers (`search_issues` for open, non-`groomed`/`wontfix`/
`question` issues returns exactly #631/#632/#633), and `docs/roadmap/incoming/`
is empty (no pending architect items to absorb). Both parked upgrade-drafter
major-bump findings (#704, #705) already have architect decisions on record
(Approve / Hold — see ROADMAP.md's *Cross-cutting hardening* section), so
there is nothing left for the architect role to decide either.

## This cycle's fresh angle (upgrade-drafter chart-pin sweep)

Prior cycles today and yesterday established that several Helm-index hosts
return `CONNECT tunnel failed, response 403` through this session's outbound
proxy (`charts.external-secrets.io`, `helm.releases.hashicorp.com`,
`kedacore.github.io`, `aquasecurity.github.io`), and explicitly flagged
`public.ecr.aws` (ack-s3) and `ghcr.io` (kro) as "not re-tested this cycle."
This cycle tested those two OCI registry hosts directly:

- **`public.ecr.aws` (ack-s3, `gitops/platform/ack-s3.yaml`, pinned `1.8.1`)
  — reachable.** Fetched an anonymous pull token
  (`GET /token/?service=public.ecr.aws&scope=repository:aws-controllers-k8s/s3-chart:pull`)
  and queried `GET /v2/aws-controllers-k8s/s3-chart/tags/list` directly. The
  highest stable semver tag returned is `1.8.1` — **matches the current pin
  exactly**. No upgrade available; this repo's pin is current, confirmed by a
  real registry query (ADR-0004), not assumed from a prior sweep.
- **`ghcr.io` (kro, `gitops/platform/kro.yaml`, pinned `0.9.2`) — reachable,
  but inconclusive.** Fetched an anonymous token
  (`GET /token?service=ghcr.io&scope=repository:kro-run/kro/kro:pull`) and
  queried `GET /v2/kro-run/kro/kro/tags/list`, which returned tags only up to
  `0.4.1` — lower than the `0.9.2` already pinned in this repo. That is not a
  real downgrade signal; it means the tag-list path
  (`kro-run/kro/kro`, derived mechanically from `repoURL` + `/` + `chart`)
  does not match the actual OCI artifact path this repo's chart resolves
  against (ArgoCD's OCI resolution isn't a flat `repoURL/chart` concatenation
  for every chart layout). Recorded honestly as inconclusive rather than
  filing a bogus downgrade or guessing at the right path — no change made to
  `kro.yaml`.
- The four previously-flagged Pages hosts (`charts.external-secrets.io`,
  `helm.releases.hashicorp.com`, `kedacore.github.io`,
  `aquasecurity.github.io`) were re-tested and are still `403`-denied by the
  proxy — unchanged from prior cycles.
- `api.github.com` was tried as a fallback path to check upstream releases
  for the four blocked chart sources (`external-secrets/external-secrets`,
  `hashicorp/vault-helm`, `kedacore/charts`, `aquasecurity/trivy-operator`)
  — this session's GitHub access is scoped to `tooming/k8s-anywhere` only;
  every other repo returns "GitHub access to this repository is not enabled
  for this session." Not pursued further — widening GitHub repo scope for an
  external upstream lookup is outside what this routine should request on
  its own.

No actionable version gap found on either newly-reachable host this cycle.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size; (d) proxy access to the four still-blocked Pages hosts, or a way to
resolve the correct OCI tag-list path for the `kro` chart, to verify those
five remaining unswept pins directly instead of relying on assumption.

This note is this cycle's honest record — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
