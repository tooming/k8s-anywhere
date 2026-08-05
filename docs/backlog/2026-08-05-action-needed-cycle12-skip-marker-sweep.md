# [Action needed] Now/next still gated; bats skip-marker sweep clean, 11 PRs landed this run

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
recent cycle has found gated, re-verified fresh this cycle:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633).

Both issues re-checked: still open, no new comment since 2026-08-04.
[#980](https://github.com/tooming/k8s-anywhere/pull/980) (human-authored,
still open, `mergeable_state: unknown`) is the maintainer's own live
in-progress work toward both — its own test-plan checklist confirms a real
pipeline run reached `docker login` successfully this same day, with full
push+sign confirmation "still in progress in the same session."

## This cycle's fresh angle

Swept every `tests/*.bats` file for `skip "..."` markers — a different
"partially-done work" signal than the two prior cycles' TODO-comment and
ADR-index sweeps. Found four occurrences, all legitimate conditional
tool-not-installed guards (`python3`, `shellcheck`/`yamllint` availability
checks) plus one library's own self-test of its `skip()` helper — no stale
or permanently-skipped test exists anywhere in the suite.

## Assessment

This run has now landed 11 real merged PRs across five sweep angles (chart/
image currency across 14 components; a stale "waiting on upstream" TODO;
a missing ADR-index entry with a cascading stale scope-note; a repo-wide
generalization of the TODO-pattern; and this cycle's bats skip-marker sweep)
plus proper architect/planner governance for a real k3s security fix and a
standing maintainer-confirmation issue (#999) for a follow-up gated on live
cluster state. The remaining gated items are genuinely blocked on live facts
only the maintainer can observe, not on undiscovered repo gaps.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) PR #980
merging (the maintainer's own live in-progress work); (c) a new GitHub issue
of any size; (d) a new upstream CVE/release firing a tracked ADR flip
condition.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
