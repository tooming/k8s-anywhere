# Bump kubeconform v0.6.7 → v0.8.0 (CI manifest-validation tool)

CHARTER **Core Values** §"Clusterless gates stay green" / general CI dependency
hygiene. `.github/workflows/ci.yml`'s `manifests` job pins `yannh/kubeconform`
(the schema validator behind `scripts/validate-manifests.sh`) by explicit
version — a pin that had never been checked by this routine before, since prior
sweeps focused on `gitops/` component versions and the `uses:` GitHub Actions
steps (`tests/github-actions-pins.bats`), not the CLI tools those steps install.
A fresh cycle-7 sweep of the three explicit CI-tool version pins in `ci.yml`
(kubeconform, kustomize, terraform) found kubeconform two minor releases behind.

- Component: `yannh/kubeconform` (GitHub releases, downloaded directly in CI —
  not a chart/image, no ADR involved)
- From → To: `v0.6.7` → `v0.8.0` (skips `v0.7.0`; both are real intervening
  stable releases per the project's own tag history, no pre-release skipped
  over)
- Why this version: highest stable release, same major line (`v0`), no
  version-pinning ADR. Verified the tag exists directly via
  `git ls-remote --tags https://github.com/yannh/kubeconform.git` (the
  `github.com` release-asset download itself 403s from this remote session's
  proxy scope — a known limitation this repo's ROADMAP.md already documents;
  the GitHub Actions runner that actually runs this job has full internet
  access and will fetch the real asset). `scripts/validate-manifests.sh`'s
  kubeconform invocation uses only long-standing, stable CLI flags
  (`-kubernetes-version`, `-ignore-missing-schemas`, `-strict`, `-summary`,
  `-cache`) present since well before `v0.6.7`, so no script change was needed
  — `make ci`'s `manifests` job itself is the live verification that the new
  binary still parses correctly.

Updated the download URL and the schema-cache key (both instances — the `key:`
and `restore-keys:` must stay in sync or a stale-versioned cache silently
persists) in `.github/workflows/ci.yml`. New `tests/ci-tool-pins.bats`
(kubeconform is pinned to v0.8.0; the cache key matches; no workflow still
references the pre-bump `v0.6.7` pin or cache key) — this pin category had zero
bats coverage before this change, unlike the `uses:` actions pins.

kustomize (`v5.4.3` → real latest `v5.8.1`) and terraform (`1.9.8` → real
latest `1.15.8`) were also found behind in this same sweep but are deliberately
**not** bumped in this PR — upgrade-drafter's own WIP cap is one `upgrade/*` PR
per cycle; they're left for a following cycle/run.

`make ci`-relevant checks: `bats tests/ci-tool-pins.bats` (3/3 ok),
`scripts/lint.sh` clean, `scripts/ci-parity-check.sh` green (no gate wiring
touched, only a tool-version pin + its cache key).

## PR

[#641](https://github.com/tooming/k8s-anywhere/pull/641)
