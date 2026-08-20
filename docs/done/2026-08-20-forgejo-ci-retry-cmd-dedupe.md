# Dedupe `retry_cmd()` in `.forgejo/workflows/build-sign-push.yml`

Janitor-fallback cleanup (`executor.prompt.md` STEP 6b), reached after the
"Now / next" lane was found fully gated (issue #633 and the two
un-picked-up GitLab→Forgejo migration items, re-checked) and this run's
PLANNER/ARCHITECT fallback passes found no ungroomed issues and no
un-RFC'd 🟡 items. This run's UPGRADE-DRAFTER fallback pass had already
delivered its one PR for the run (`upgrade/mimir-3-1-4-to-3-1-5`, #1279),
so this cycle moved on to the next role in the chain.

## The footgun

`.forgejo/workflows/build-sign-push.yml`'s `retry_cmd()` bash function was
duplicated byte-identically across three separate `run:` steps
(build-and-push's "Login to Harbor" and "Build, tag, and push", plus
sign-image's "Sign the pushed image") — the same shared-helper-worth-
extracting shape `scripts/lib/colors.sh`'s own extraction (issue #957)
already fixed for 15+ scripts. The duplication had already cost real
time once: PR #1276 bumped the retry budget (`max=6/delay=15` →
`max=14/delay=30`) and left stale commentary behind in one of the two
build-and-push copies, requiring a follow-up fix (PR #1277) to notice and
correct it.

## The fix

Extracted the function into `scripts/lib/retry_cmd.sh` (sourced, not
executed — same convention as `scripts/lib/colors.sh` /
`scripts/lib/yq.sh` / `scripts/lib/budget-check.sh`). Both of
build-and-push's steps now `. scripts/lib/retry_cmd.sh` instead of
redefining the function inline — that job already checks out the repo as
its first step, so the shared file is on disk by the time either step
runs. This makes the exact drift class that caused PR #1276→#1277's bug
structurally impossible for those two call sites: there is now only one
place the function body can be edited.

sign-image's copy is deliberately **left inline**: that job runs in a
separate container with no checkout step (it never needed repo files
before this), and adding one purely to source a shared helper would be a
behavior change to a pipeline still under active live-tuning (issue
#633) — out of scope for a bounded, behavior-preserving cleanup. Left a
comment cross-referencing `scripts/lib/retry_cmd.sh` and noting the
follow-up (give sign-image a checkout step, then it can source the same
file too) instead of attempting it blind.

## Validation

`make ci` green (structural/drift checks locally; `bats`/`kustomize`/
`terraform` run in GitHub Actions per this repo's convention).
`tests/forgejo-ci.bats` updated: the existing retry-budget assertion now
checks both the workflow file (1 remaining inline copy, sign-image's) and
the new shared lib file (1 copy), plus two new assertions confirming
build-and-push's two steps source the shared file and never redefine
`retry_cmd()` inline, and that the shared file's body matches the
original inline shape.

**ADR-0004 caveat:** this remote, clusterless session cannot run this
workflow against a live Forgejo instance — the `.` (dot) sourcing syntax
and the two steps' subsequent behavior are structurally verified (byte-
identical function body pre/post-extraction, working directory is the
checkout root per the job's own "Checkout" step) but not live-executed.
Rollback is reverting this one commit; the change touches no runtime
values (`max`/`delay` unchanged) and no command wrapped in `retry_cmd`
changed, only how the function itself is defined.

## PR

https://github.com/tooming/k8s-anywhere/pull/1280
