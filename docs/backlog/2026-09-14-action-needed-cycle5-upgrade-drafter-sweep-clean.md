# [Action needed] Cycle 5 — full upgrade-drafter source enumeration clean

## This run so far

1. Cycle 1 ([#1588](https://github.com/tooming/k8s-anywhere/pull/1588)):
   backlog empty; refreshed the stale `docs/dora-metrics.md` snapshot.
2. Cycle 2 ([#1589](https://github.com/tooming/k8s-anywhere/pull/1589)):
   full Traefik GHSA re-sweep — found and analyzed 5 new advisories (one
   Critical), confirmed none exploitable, no fix available yet.
3. Cycle 3 ([#1590](https://github.com/tooming/k8s-anywhere/pull/1590)):
   honest record — k3s/ArgoCD/cert-manager GHSA re-checks and CI-tool-pin
   currency all clean.
4. Cycle 4 ([#1591](https://github.com/tooming/k8s-anywhere/pull/1591)):
   architect-fallback — wrote the mandatory `docs/industry/2026-W38-digest.md`
   (new ISO week), no RFC/audit work needed.

## This cycle's angle — UPGRADE-DRAFTER's own full enumeration

Previous cycles' currency checks all worked from
`docs/dependency-register.md`'s curated 7-row list. This cycle instead ran
`routines/upgrade-drafter.prompt.md` STEP 2's own enumeration method
directly against the repo — every `targetRevision:` in `gitops/**/*.yaml`,
every `image:` tag in a Deployment, and every Terraform `chart_version`
variable/`terragrunt.hcl` input — to catch anything the register's curated
list might not cover:

- `gitops/platform/cert-manager.yaml`'s `targetRevision: 1.21.2` — matches
  the register, already current.
- `gitops/apps/demo/deployment.yaml`'s `image:
  nginxinc/nginx-unprivileged:1.31.5-alpine` — **not previously tracked by
  any prior sweep** (it's a demo-app image, not a register row). Live-checked
  Docker Hub directly: `1.31.5-alpine` is still the current tag family (the
  underlying base image was re-pushed today under the same tag, a routine
  Alpine security rebuild that flows through automatically on next pull —
  not a version this manifest needs to bump).
- `infra/modules/argocd/variables.tf`'s `chart_version` default, set to
  `10.9.0` by both `infra/live/local/argocd/terragrunt.hcl` and
  `infra/live/oracle/argocd/terragrunt.hcl` — matches the register's ArgoCD
  row, already current.

No other `targetRevision:`, `image:`, or `chart_version` exists anywhere in
`gitops/` or `infra/` — Traefik has no independent pin (bundled via k3s,
ADR-0040), and k3s itself is pinned in `infra/modules/k3d-cluster/` /
`infra/modules/oracle-k3s-cluster/`, both already reconfirmed current in
cycle 3.

## Assessment

A genuinely different pass (full source enumeration, not the register's
curated summary) confirmed the same result: every pinned source in this
repo, register-tracked or not, is current. No upgrade is due.

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- A new upstream release/GHSA against any pinned or bundled source.
- A later cycle in this same run, trying yet another lens.

This is cycle 5's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
