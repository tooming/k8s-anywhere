# scripts/test.sh — bats coverage gap closed

**Coverage/hardening fallback run**, continuing the same lane as PRs #431 and #434.
ROADMAP.md's `Now / next` lane is fully gated this run (every item needs a live-cluster
maintainer confirmation, or a prerequisite that is itself gated the same way).

## Gap found

`scripts/test.sh` — the wrapper `make test` / `make ci` invoke to run the bats suite
itself — had zero coverage of its own local-skip-vs-CI-required behavior (`bats` not
installed): local exits 0 with a skip message, `CI=true` exits 1. Same class of gap as
`validate-kustomize.sh`/`validate-manifests.sh`/`validate-terraform.sh` (PR #431) and
`lint.sh` (PR #434) — every other script sharing this `${CI:-}` pattern now has
dedicated coverage of it (`scripts/argocd-crd-ssa-check.sh` and
`scripts/helm-chart-pin-check.sh` already did, via `tests/drift-detectors.bats`).

## What shipped

New `tests/test-script.bats` (8 assertions): existence/executable, real behavioral
coverage of the "bats not installed" branch (local skip vs. CI-required failure, via
the same shim-directory PATH technique `tests/lint-script.bats` introduced — `bats`
lives in `/usr/bin` alongside `bash` on this session's sandbox, so naively stripping
that whole directory breaks the script with an unrelated "command not found" instead of
testing the intended branch), and structural guards for the `exec bats tests/` handoff
and the `cd "$ROOT"` cwd-independence. Deliberately **not** exercised end-to-end
(unlike `lint.sh`'s real-pass assertion) — running the happy path would recursively
invoke the entire bats suite from within one of its own assertions.

## Verification

`make ci` passes (full toolchain installed this session — see PR #431's `docs/done/`
entry). `tests/test-script.bats` in isolation: 8/8 pass in ~9s.

## PR

https://github.com/tooming/k8s-anywhere/pull/435
