# [Action needed] Now/next still gated; chart-pin verification sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (second cycle of 2026-07-24): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

Cycle 1 today (`docs/backlog/2026-07-24-action-needed-cycle1-workflow-adr-sweep.md`)
covered GitHub Actions supply-chain pinning, the Loki `3.7.4` flip condition,
ADR-0014's missing Re-evaluation log (false alarm), and `:latest` image tags.
This cycle checked a different lens: **direct upstream chart-version
verification for three pins not covered by any prior dated sweep** —
External Secrets Operator, Trivy Operator, and KEDA — using the same
git-tag / raw-content technique prior cycles used for Envoy Gateway and
Kiali (`github.com`/`api.github.com` are proxy-blocked in this sandbox;
`raw.githubusercontent.com` and `git ls-remote` over HTTPS are not;
`*.github.io` Pages hosts are also proxy-blocked, discovered fresh this
cycle when `aquasecurity.github.io` and `kedacore.github.io` both returned
403 through the proxy — worked around via `raw.githubusercontent.com/<org>/
<repo>/gh-pages/index.yaml` and `git ls-remote --tags`, per ADR-0004: verify
before asserting, not training-data recall):

1. **External Secrets Operator** (`gitops/platform/external-secrets.yaml`,
   `targetRevision: 2.8.0`). `git ls-remote --tags
   https://github.com/external-secrets/external-secrets.git` — newest tag is
   `v2.8.0`. Pin is current. No gap.
2. **Trivy Operator** (`gitops/platform/trivy-operator.yaml`,
   `targetRevision: 0.34.0`). Fetched
   `raw.githubusercontent.com/aquasecurity/helm-charts/gh-pages/index.yaml`
   directly — newest `trivy-operator` chart entry is `0.34.0` (appVersion
   `0.32.0`), created 2026-07-08. Pin is current. No gap.
3. **KEDA** (`gitops/platform/keda.yaml`, `targetRevision: 2.20.1`).
   `git ls-remote --tags https://github.com/kedacore/charts.git` — the repo
   stopped tagging plain `vX.Y.Z` releases after `v2.9.4` for a stretch but
   resumes at `v2.20.0`/`v2.20.1` (lexicographic tail of the tag list is
   misleading — `v2.2.x` sorts after `v2.20.x` as plain strings; grepped
   explicitly for `2\.2` to find both clusters). Newest tag is `v2.20.1`.
   Pin is current. No gap.

All three were plausible candidates (none had a dated verification entry in
`docs/backlog/` or an ADR Re-evaluation log for their current pin) but all
three came back current — a real check, not a rubber stamp.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
