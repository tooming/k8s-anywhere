# readme-check / lab-ui-check — add the missing "passes on the real repo" sanity test

Continuing ROADMAP rule #9's coverage/hardening sweep: seven of the repo's drift-checker
scripts (`roadmap-check`, `securitycontext-tests-check`, `observability-tests-check`,
`networkpolicy-tests-check`, `yq-raw-check`, `routines-author-check`,
`rollouts-plugin-list-check`, `mimir-readonly-root-check`, and — as of the previous PR —
`routines-check`) each have a bats assertion that runs the script with no `ROOT` override
against the real repo tree and asserts it passes. `readme-check.sh` and `lab-ui-check.sh`
were the only two `tests/drift-detectors.bats` checkers still missing that assertion —
their coverage was fixture-only (in-sync + drift scenarios), never proving the check
actually holds for the tracked README.md / Lab UIs panel themselves.

## Changes

- `tests/drift-detectors.bats`: added `"readme-check: passes on the real repo README.md"`
  and `"lab-ui-check: passes on the real repo's Lab UIs panel + gitops HTTPRoutes"`,
  matching the existing pattern used by the other seven checkers.

No script changes — both scripts already passed against the real repo when run directly
(verified: `bash scripts/readme-check.sh` and `bash scripts/lab-ui-check.sh` both exit 0).
`make ci` passes (same 7 pre-existing environment-only failures as prior PRs this session
— missing `mikefarah/yq` / proxy-restricted Helm chart repo access in this sandbox).

## PR

(this session's branch)
