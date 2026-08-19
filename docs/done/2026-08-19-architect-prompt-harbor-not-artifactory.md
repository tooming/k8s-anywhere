# Fix the architect routine's own upstream-check list: Harbor, not the decommissioned Artifactory

JANITOR-fallback bounded cleanup (category 3: "dead or stale matter"),
reached via `executor.prompt.md` STEP 6b, cycle 18 this run — a direct
follow-on to cycle 17's Garage org-slug fix (PR #1264). While auditing every
`github.com/<owner>/<repo>` slug named in `docs/dependency-register.md` and
`routines/architect.prompt.md`'s STEP 1 upstream-check list for reachability
(the same lens that found the Garage bug), all 29 slugs in
`dependency-register.md` and 16 of 17 in `architect.prompt.md` resolved —
but one entry in `architect.prompt.md` was pointing at the wrong
*component*, not a dead URL.

## The finding

`routines/architect.prompt.md` STEP 1 still listed `Artifactory / JFrog:
jfrog/charts` in its weekly "check upstream for new releases" instruction.
ADR-0024 (2026-07-29, RFC #297) fully superseded ADR-0011 and decommissioned
Artifactory — its manifests, Make targets, and networkpolicy-appset entry
were all removed (`tests/no-artifactory.bats`), and Harbor has been the
lab's actual on-demand artifact registry ever since. The architect routine's
own operating instructions never caught up: every weekly run since
2026-07-29 has been checking release currency for a package (`jfrog/charts`)
this lab hasn't run in three weeks, while never once checking Harbor
(`goharbor/harbor-helm`) — the component actually deployed and already
correctly tracked in `docs/dependency-register.md`.

## The fix

- `routines/architect.prompt.md` STEP 1: `Artifactory / JFrog:
  jfrog/charts` → `Harbor: goharbor/harbor-helm`, matching
  `docs/dependency-register.md`'s existing Harbor row exactly.
- `tests/no-artifactory.bats`: extended with a new assertion (this file's
  existing purpose is exactly "no legacy-registry reference remains" —
  `routines/architect.prompt.md` is live operating instruction, not a
  historical decision record like `docs/decisions/`/`docs/done/`, so it's
  held to the same bar as `gitops/`/`Makefile`) asserting the routine's
  upstream-check list never re-mentions Artifactory/JFrog and does name
  Harbor.

No live manifest, ADR decision, or runtime config touched — this only fixes
which repo the architect routine's own weekly currency sweep looks at.
`make ci` (full suite, bats included) is green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1265
