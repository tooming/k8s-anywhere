# [Action needed] Cycle 2 — live-upstream currency re-verification lens also came up clean

Follow-up to cycle 1 of this run
([docs/done/2026-09-09-k3s-cert-manager-register-currency-refresh.md](../done/2026-09-09-k3s-cert-manager-register-currency-refresh.md),
PR #1540), which fixed a real gap: `docs/dependency-register.md`'s k3s and
cert-manager rows still showed a `2026-09-03` "Last reviewed" date despite
both already being re-verified current on 2026-09-08. That fix used live
`WebFetch`/`WebSearch` checks against real upstream GitHub Releases pages and
GHSA advisory listings — a genuinely different verification method than the
prior run's own currency sweeps, which relied on `git ls-remote --tags`
rather than reading release notes and security-advisory pages directly. This
cycle extended that same live-verification method across the rest of this
lab's dependency surface and found nothing further to fix.

## What this cycle checked (all came up clean)

- **ArgoCD** — `github.com/argoproj/argo-helm/releases`: `argo-cd-10.8.2` (this
  repo's current chart pin) is still the newest chart release.
  `github.com/argoproj/argo-cd/releases`: `v3.5.2` (this repo's current
  appVersion) is still the newest stable app release — `v3.5.1`, `v3.4.8`,
  `v3.4.7`, `v3.3.14` are all older/parallel maintenance-branch releases, not
  newer.
- **Traefik** — `github.com/traefik/traefik/releases`: upstream Traefik itself
  has moved to `v3.7.13`, but that's irrelevant to this lab's actual exposure
  — Traefik ships bundled inside k3s (ADR-0030), and k3s's own latest release
  (`v1.36.4+k3s1`, confirmed current below) still bundles Traefik `v3.7.8`.
  The register's existing flip condition ("re-check when k3s ships a newer
  bundled Traefik") is unmet; no action follows from Traefik's own upstream
  releases directly.
- **k3s** — `github.com/k3s-io/k3s/releases`: `v1.36.4+k3s1` (fixed in cycle 1)
  confirmed still the newest stable tag. Cross-checked two GHSA search hits
  from this cycle's live search: GHSA-jxr7-mqhw-9p98 (etcd-snapshot path
  traversal, fixed `1.33.10`/`1.34.6`/`1.35.3`) and GHSA-m4hf-6vgr-75r2
  (apiserver TLS-SAN-stuffing DoS, fixed `1.28.1`) — both fixed in versions
  far below the current `v1.36.4+k3s1` pin, so neither applies.
- **cert-manager** — `github.com/cert-manager/cert-manager/security/advisories`:
  live search for any advisory newer than the register's 2026-09-03 full
  sweep (`GHSA-r4pg-vg54-wxx4`, `GHSA-8rvj-mm4h-c258`, `GHSA-gx3x-vq4p-mhhv`)
  found no new entry.
- **Terraform / Terragrunt** — `github.com/hashicorp/terraform/releases`
  (`v1.16.1`) and `github.com/gruntwork-io/terragrunt/releases` (`v1.1.4`):
  both confirmed still the newest stable tags, matching this repo's current
  pins exactly (already bumped in an earlier cycle,
  `docs/done/2026-09-06-terraform-terragrunt-currency-bump.md`).
- **Terraform provider constraints** (`hashicorp/helm ~> 3.0`,
  `hashicorp/null ~> 3.2`, `hashicorp/local ~> 2.5`, `oracle/oci ~> 8.0`):
  all pessimistic (`~>`) constraints that float automatically at `terraform
  init` time — re-confirmed unchanged from cycle 18's own check earlier in
  the prior run.
- **`scripts/*.sh` `shellcheck disable=` sweep**: exactly one directive in the
  whole repo (`scripts/tfstate-oracle-bootstrap.sh`'s `SC1090`, a standard,
  expected suppression for a dynamically-sourced path) — nothing masking a
  real lint gap.
- **`make ci`'s own info-level (`·`) hints**: re-read the full local run —
  three are the expected "provider registry unreachable" local-sandbox skips
  (this remote session has no network path to the Terraform provider
  registry — a `terraform` job in GitHub Actions does), two are "helm not
  installed" local skips (same shape, GitHub Actions runs `helm`-dependent
  checks for real), and the "gitops apps not named in README: governance" hint
  is a known, already-accepted non-gap (the `governance` ApplicationSet has no
  user-facing UI, so it correctly doesn't belong in README's Endpoints
  table — the same reasoning already recorded for `cert-manager`/`lab-demo`'s
  absence from `docs/platform-products.md`'s catalog).

## What would open new work

- A new upstream release, GHSA, GitHub issue, or RFC against any of this
  lab's 6 live-verified components (k3s, ArgoCD, Traefik, cert-manager,
  Terraform, Terragrunt) — none pending as of this cycle.
- Issue [#1517](https://github.com/tooming/k8s-anywhere/issues/1517)
  (coredns-host-alias vestigial-step removal) resolving — still gated on
  live-cluster verification this remote session cannot perform.
- A future cycle finding a genuinely different angle — this run has now
  tried (across this run and the prior one): removed-component leftover
  rationale, incident-log follow-ups, ADR flip-condition staleness,
  docs-vs-manifest cross-checks, infra/CI tooling currency, CI-workflow
  concurrency-safety, ROADMAP legacy-item trimming, and — this cycle plus
  the last — live-upstream-release/GHSA re-verification (as opposed to
  internal-repo-only checks).

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
