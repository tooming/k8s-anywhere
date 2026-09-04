# tests/routines-check.bats — close the last untested mechanical drift guard

ROADMAP rule #9's coverage/hardening fallback lane (added earlier the same day in
#399) named "a script under `scripts/` with no `tests/*.bats` coverage" as always-real,
always-available work. Re-swept `scripts/*.sh` for exactly that: excluding the
Makefile/tooling wrappers (`validate-manifests.sh`, `validate-kustomize.sh`,
`validate-terraform.sh` — thin wrappers around external binaries not present in this
sandbox) and the `*-sync-hook.sh` PostToolUse wrappers (which by established repo
convention stay thin/untested — the `*-check.sh` script they call carries the bats
coverage instead, e.g. `helm-chart-pin-check`, `argocd-crd-ssa-check`,
`mimir-readonly-root-check`, `idle-issue-guard-check` all have dedicated tests, while
their `*-sync-hook.sh` wrappers don't), exactly one genuine gap remained:
`scripts/routines-check.sh` — the drift guard behind `make routines-check` (also run by
`make ci`) that catches a `routines/*.prompt.md` or `routines.yaml` edit that was never
applied to the live claude.ai trigger. It's the pattern CLAUDE.md's own
bugfix-recurrence template names as the example to mirror (script + make target +
PostToolUse hook + bats coverage, alongside `readme-check`/`roadmap-check`/
`securitycontext-tests-check`) — yet was itself missing the bats leg.

## Changes

- `scripts/routines-check.sh`: added a `ROUTINESCHECK_ROOT` override (defaulting to the
  repo root), mirroring the `READMECHECK_ROOT`/`ROADMAPCHECK_ROOT` pattern already used
  by `readme-check.sh`/`roadmap-check.sh`, so the script is fixture-testable without
  touching the real `.routines-applied`.
- New `tests/fixtures/routines-check/{in-sync,drift,missing-snapshot,new-file,
  deleted-file}/` fixture trees covering every branch: clean pass, an edited-since-apply
  file, a missing snapshot file, a routine file with no snapshot entry, and a snapshot
  entry whose file was deleted.
- New `tests/routines-check.bats` (10 assertions): the five fixture scenarios above, the
  no-`routines/`-directory short-circuit (a throwaway `mktemp -d`, not a fixture — an
  empty directory can't be committed to git), a pass against the real repo tree, and
  Makefile wiring (`routines-check` target + `ci` invokes it).

`make routines-check` and `make ci` both still pass against the real repo tree
(unaffected by the `ROOT` override, which only takes effect when the env var is set).

## PR

https://github.com/tooming/k8s-anywhere/pull/400
