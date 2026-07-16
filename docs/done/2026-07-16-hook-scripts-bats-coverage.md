# PostToolUse/SessionStart hook scripts — bats coverage gap closed

**JANITOR fallback run** (ROADMAP.md's `Now / next` lane was fully starved this run —
the six remaining unchecked items are all gated on a live-cluster maintainer
confirmation or an explicit "executor skips this item" note, and there were no open
issues to groom or `rfc`-labeled issues needing an architect decision. Per
ROADMAP.md rule #9's fallback chain / CLAUDE.md's routine-role escalation, the
coverage/hardening lane surfaced real, buildable, clusterless work instead of an idle
declaration.)

## Gap found

13 hook scripts under `scripts/` had **zero** bats coverage: `adr-context-hook.sh`
(SessionStart) and 12 PostToolUse scripts — `argocd-crd-ssa-sync-hook.sh`,
`helm-chart-pin-sync-hook.sh`, `lab-ui-sync-hook.sh`, `mimir-readonly-root-sync-hook.sh`,
`networkpolicy-tests-sync-hook.sh`, `observability-tests-sync-hook.sh`,
`readme-sync-hook.sh`, `roadmap-sync-hook.sh`, `rollouts-plugin-list-sync-hook.sh`,
`routines-sync-hook.sh`, `securitycontext-tests-sync-hook.sh`, `yq-raw-sync-hook.sh`.

Every one of these is the *local* companion to a `make ci`-wired drift-detector gate
(e.g. `readme-sync-hook.sh` mirrors `make readme-check`), but `make ci` only exercises
the underlying `*-check.sh` script — never the hook's own payload-parsing / file-path
filter logic. A broken `case`/`esac` pattern or a wrong `jq` path in the hook itself
would silently stop nudging at edit time without `make ci` ever catching it, since the
hook is not on the CI path. Four *other* hooks already had this coverage
(`tests/adr-guard.bats`, `tests/commit-reminder-hook.bats`, `tests/merge-ci-gate-hook.bats`,
`tests/drift-detectors.bats`'s `idle-issue-guard-hook` cases) — this PR closes the same
gap for the remaining 13, mirroring that established pattern (feed a JSON payload on
stdin via a `mk_payload()` helper, assert exit 0 = silent / exit 2 = nudge shown).

## What shipped

New `tests/hook-scripts-coverage.bats` (40 assertions):

- **Filter/no-op coverage** for every one of the 13 scripts: an empty payload or a
  file path outside the hook's guarded pattern exits 0 without invoking the
  underlying check.
- **Real-repo delegation coverage**: for each hook, a payload pointing at an actual
  in-repo file that currently satisfies its check (the repo is clean — `make ci` is
  green) exits 0, proving the hook actually wires through to its `*-check.sh` sibling
  and the delegation itself is not broken.
- **Negative-path coverage where hermetically possible**:
  - `rollouts-plugin-list-sync-hook.sh` — a fixture Application with a block-scalar
    (`|`) `trafficRouterPlugins` value (offline, no network dependency, since the
    underlying check is pure `yq` tag inspection) exits 2 with the expected
    "must be a YAML list" message.
  - `routines-sync-hook.sh` — its `ROOT` is `BASH_SOURCE`-relative (no env-var
    override, unlike the `*-check.sh` scripts), so the hook script is copied into an
    isolated `BATS_TEST_TMPDIR` fixture tree (mirrors the existing
    `tests/fixtures/routines-check/*` pattern) with a controlled `.routines-applied`
    snapshot, covering both the in-sync (exit 0) and drift (exit 2, message names the
    parsed `trigger_id`) branches.
  - `argocd-crd-ssa-sync-hook.sh` and `helm-chart-pin-sync-hook.sh` delegate to
    network-tolerant checks with no hook-level file-scoped override for injecting a
    broken fixture without touching the real repo state; both degrade to a guaranteed
    exit 0 (pass or network-unreachable skip) either way, so only their filter +
    real-repo happy-path is covered here — a full negative-path fixture-tree copy
    (mirroring the `routines-sync-hook` approach) is a reasonable following janitor
    pickup if ever wanted, not required for this gap to be closed.

`make ci` passes (fully green locally: `bats`, `shellcheck`, `yamllint`, `kustomize`,
`kubeconform`, `terraform`, and the correct `mikefarah/yq` build were all installed
into this session before validating — the session started with `python-yq`
(kislyuk) on `PATH`, which fails the `yq ... | tag` filter several existing bats
cases rely on; swapping in `mikefarah/yq` v4.53.3 via `go install` through the Go
module proxy fixed that pre-existing local-environment mismatch, unrelated to this
change).

## PR

Autonomous scheduled run — see the `chore/hook-scripts-bats-coverage` branch.
