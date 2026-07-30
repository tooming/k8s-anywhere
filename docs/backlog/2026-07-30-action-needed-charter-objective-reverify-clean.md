# [Action needed] Now/next still gated; direct CHARTER Objective re-verification clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Three real merged PRs so far this run:
[#903](https://github.com/tooming/k8s-anywhere/pull/903) (kustomize orphan-file
guard) and
[#905](https://github.com/tooming/k8s-anywhere/pull/905) (missing bats coverage
for `tidb-demo.json`), plus two prior cycles' honest records
([#904](https://github.com/tooming/k8s-anywhere/pull/904),
[#906](https://github.com/tooming/k8s-anywhere/pull/906)).

## This cycle's fresh angle (clean)

1. **Duplicate bats test-name check.** Scanned every `tests/*.bats` file for a
   `@test` description repeated within the same file (a real footgun — bats
   silently lets a duplicate name shadow the first, so the earlier assertion
   never actually runs). Zero found across the entire suite.
2. **Direct CHARTER Objective re-verification, first-hand rather than citing a
   prior session's summary.** Read `CHARTER.md` in full this cycle and
   cross-checked each Objective against the real repo state directly (not
   trusting a prior backlog note's conclusion):
   - **O1** (Tier 1 next-wave): confirmed all four components
     (Kyverno/Argo Rollouts/Velero/Trivy Operator) are auto-synced with their
     own ADR + dashboard + bats coverage — met.
   - **O2** (default-deny + PSS-restricted everywhere): confirmed via the
     `tests/networkpolicy.bats` + `tests/securitycontext.bats` coverage-loop
     guards already passing in this cycle's `make ci` run — met.
   - **O3** (stateful DR exercised): read `scripts/dr-restore.sh` directly —
     its default `NAMESPACES` array is `data tidb capstone vault observability
     inkless`, exactly CHARTER's list, and `tests/dr-restore.bats` asserts
     each of the six individually (not just a generic budget check) — met,
     confirmed first-hand rather than assumed from CHARTER's own prose.
   - **O4** (every image signed/verified): confirmed still NOT met — this is
     exactly the gated `verifyImages` Enforce-flip item, blocked on #631.
   - **O5** (every always-on dashboard): the always-on-scoped coverage loop in
     `tests/dashboard-coverage.bats` passes; the one real gap found this run
     (`tidb-demo.json`, an on-demand-scoped dashboard, so technically outside
     O5's "always-on" wording) was already fixed in #905.
   - **O6** (capstone e2e < 15 min): `make capstone-demo` target exists and
     wall-clocks the path per the already-shipped `auto/capstone-demo-target`
     item — met.
   - **O7** (DORA metrics): `docs/dora-metrics.md` was refreshed earlier this
     run (#896, prior to this session) and the presence-check gate passes —
     met.

No new gap found — every Objective either already meets its bar or is the
same known O4 gate already tracked by #631/#633.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
