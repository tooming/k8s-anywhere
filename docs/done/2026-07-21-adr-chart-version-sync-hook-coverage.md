# Bats coverage for `adr-chart-version-sync-hook.sh` (the one `*-sync-hook.sh` PostToolUse hook that had none)

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b after the executor's own "Now / next" lane came up
fully gated on maintainer-confirmation prerequisites (issues #631/#632/#633, none
confirmed), and the planner/architect/upgrade-drafter/doc-drift-author fallbacks all
came up with no further real deliverable this run — gap analysis found no CHARTER
gap, no un-RFC'd 🟡 item, no open `adr-audit` issue, a spot-check of upstream tags
(cert-manager, envoy-gateway, vault-helm) found nothing newer, and both drift checks
(`readme-check`, `lab-ui-check`) are clean.)

PR #622 (2026-07-20) added `scripts/adr-chart-version-sync-hook.sh` as an active
`PostToolUse` hook (wired in `.claude/settings.json`, reacting to edits under
`docs/decisions/` or `gitops/`) plus its underlying check script
(`scripts/adr-chart-version-sync-check.sh`, covered by `tests/drift-detectors.bats`)
— but never gave the *hook* itself bats coverage. `tests/hook-scripts-coverage.bats`
exists precisely to close this class of gap ("a broken case/esac filter or a wrong
jq path would silently stop nudging without `make ci` ever catching it, since
`make ci` only exercises the check scripts, not the hooks" — its own header) and
already covers every one of its 13 sibling `*-sync-hook.sh` scripts. The new hook
was the one exception: a recurrence guard that itself lacked a recurrence guard.

Added six assertions to `tests/hook-scripts-coverage.bats`, mirroring the existing
`adr-followup-sync-hook.sh` block's fixture-driven shape (that hook's check script
also honors a `ROOT`-override env var, `ADRCHARTVERSIONCHECK_ROOT`, inherited by the
child process the hook shells out to — no explicit passthrough needed):

- empty payload exits 0;
- an unrelated file path exits 0 (filtered out);
- both `docs/decisions/` and `gitops/` paths are matched by the `case`/`esac`
  filter (using the existing `tests/fixtures/adr-chart-version-sync/in-sync/`
  fixture tree);
- a self-tracking ADR matching its live pin exits 0;
- a self-tracking ADR that drifted from its live pin exits 2 and names the drift
  in its stderr (using the existing `tests/fixtures/adr-chart-version-sync/drift/`
  fixture tree — no new fixtures needed, reused `tests/drift-detectors.bats`'s own);
- the real repo's `docs/decisions/adr-0020-argo-rollouts-progressive-delivery.md`
  (currently in sync with its live pin) exits 0.

Behavior-preserving: no existing check's pass/fail set changed, and the hook script
itself was not touched — this only adds test coverage for existing, already-active
behavior. Verified directly (ADR-0004): all 60 assertions in
`tests/hook-scripts-coverage.bats` pass, including the 6 new ones, with the real
`mikefarah/yq` binary (the sandbox's default `/usr/bin/yq` is `kislyuk/python-yq`,
a different, jq-based implementation — `yq --version` prints `yq 0.0.0` under it and
several *other*, pre-existing bats assertions in this same file that shell out to
`resolver-stub.sh`/`renderer-stub.sh` fixtures fail under it; that mismatch predates
this change, reproduces identically on unmodified `main`, and is a local sandbox
tooling quirk — not a repo bug — so it is out of this bounded cleanup's scope).
`make ci` passes.

## PR

[#635](https://github.com/tooming/k8s-anywhere/pull/635)
