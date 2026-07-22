# [Action needed] Now/next still gated; yq-variant-guard landed, fresh envoy-gateway check found an unpublished artifact

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle, all three still open, still zero comments.

## What this cycle did

Fell through the STEP 6b fallback chain to the **janitor** lens and landed a
real, merged PR: **#662** (`chore/yq-variant-guard`) — three `make ci` drift
detectors (`helm-chart-pin-check.sh`, `argocd-crd-ssa-check.sh`,
`rollouts-plugin-list-check.sh`) were silently false-passing in this remote
environment because the `yq` on `PATH` here is python-yq, not mikefarah/yq,
and all three scripts swallow that incompatibility via `2>/dev/null`. Added
`scripts/lib/yq-variant.sh` (`require_mikefarah_yq`, hard-fail in CI / honest
skip locally) plus a new recurrence-guard check
(`scripts/yq-variant-guard-check.sh`, wired into `make ci` + CI, with bats
coverage) so no future script can add the same unguarded call. Confirmed via
the PR's own CI run: `drift` and `unit` jobs both went green against real
mikefarah/yq + real bats. One documented gap: the companion PostToolUse hook
was written and bats-covered but couldn't be wired into
`.claude/settings.json` — that Edit call was denied by this session's tool
permissions (a session-level constraint, not repo policy); the CI gate is the
binding enforcement regardless. Full writeup:
`docs/done/2026-07-22-yq-variant-guard.md`.

## This cycle's fresh angle (after the PR above merged)

Re-ran STEP 1b/STEP 2/STEP 3 against the new `main` (post-#662) and confirmed
the *Now / next* lane is still fully gated. Rather than re-run the identical
janitor sweep, tried a fresh **architect** lens: real, network-verified CVE/
release checks (raw.githubusercontent.com CHANGELOG/release-notes + Docker
Hub tag-existence probes, ADR-0004) against four chart pins **not yet audited
this session**:

- **cert-manager** (`1.21.0`) — confirmed current; no `v1.21.1`/`v1.22.0` tag
  exists upstream (404 both).
- **KEDA** (`2.20.1`) — confirmed current; no `v2.20.2`/`v2.21.0` tag exists.
- **Velero** (chart `12.1.0`) — confirmed current; the chart repo's `main`
  branch `Chart.yaml` is still exactly `version: 12.1.0`.
- **Envoy Gateway** (`v1.8.2`) — **found a real candidate, correctly held
  back.** `v1.8.3`'s release notes exist upstream (dated 2026-07-20, two days
  ago) and explicitly list a `security updates` entry ("Updated distroless
  base image") plus a real TLS-handling correctness fix (a serving cert chain
  with an expired member was previously silently dropped, corrupting the
  chain; a mismatched cert/key pair could break TLS for every Gateway sharing
  a proxy under `mergeGateways`). This would normally clear this session's
  own upgrade bar (explicit security rationale, same-minor-line patch, no
  Lua-filter usage in our config so the one breaking change doesn't apply).
  **But the artifact itself isn't published yet**: both
  `docker.io/envoyproxy/gateway-helm:v1.8.3` (the Helm chart, OCI) and
  `docker.io/envoyproxy/gateway-dev:v1.8.3` (the image) return 404 on Docker
  Hub, while `v1.8.2` (current pin) returns 200. Bumping `targetRevision` to a
  chart version that doesn't exist yet is exactly the failure mode
  `scripts/helm-chart-pin-check.sh` was built to catch (`ArgoCD repo-server`
  sits `Unknown` forever) — and, per this cycle's own PR above, that check now
  actually works correctly in this environment again. Did not bump.

## What would unblock further work

- (a) the maintainer confirming a live-cluster observation on #631, #632, or
  #633;
- (b) **Envoy Gateway `v1.8.3` actually landing on Docker Hub** — re-check
  `curl -o /dev/null -w '%{http_code}' https://hub.docker.com/v2/repositories/envoyproxy/gateway-helm/tags/v1.8.3`
  on a future run; once it returns 200, this is a ready-to-build upgrade item
  (same-minor patch, explicit security rationale, no Lua-filter impact);
- (c) a new upstream CVE/release firing a tracked flip condition on another
  component;
- (d) a new GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
