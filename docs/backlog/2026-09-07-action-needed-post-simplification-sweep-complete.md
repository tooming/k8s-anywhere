# [Action needed] Post-simplification doc-consistency sweep complete

Follow-up to
[2026-09-07-action-needed-post-simplification-clean.md](2026-09-07-action-needed-post-simplification-clean.md)
(PR #1500). Two more real, small doc-accuracy fixes landed in this cycle's
continuation of the same sweep:

- [#1503](https://github.com/tooming/k8s-anywhere/pull/1503) —
  `docs/dora-resilience-mapping.md` still cited "Cilium-enforced" for
  ADR-0016's default-deny NetworkPolicy; corrected to name the real current
  enforcer (k3s's bundled Flannel + kube-router).
- [#1504](https://github.com/tooming/k8s-anywhere/pull/1504) —
  `docs/dora-audit-readiness.md`'s own description of what
  `tests/dora-audit-readiness.bats` checks still claimed the test asserts
  both "Cilium and Traefik"; the test itself only ever asserted Traefik —
  corrected the description to match the real test.

Also re-verified this cycle: every GHSA ID cited in the now-9-row
`docs/dependency-register.md` (7 unique IDs) is a subset of the 15 IDs this
run's earlier GHSA audit
([docs/done/2026-09-07-dependency-register-ghsa-audit-clean.md](../done/2026-09-07-dependency-register-ghsa-audit-clean.md))
already confirmed real against primary sources — no new citation was
introduced by the register's rewrite, so no further verification was
needed.

## What was checked this cycle, came up clean

- A broad re-grep for other "test coverage description" mismatches (a doc
  describing what a bats test checks, drifted from the real assertions) —
  the pattern #1504 fixed — across every `docs/*.md` file found no further
  instances.
- `make ci` fully green throughout (zero `not ok` lines at every step).
- `ROADMAP.md`'s "Now / next" lane: still genuinely empty (zero `- [ ]`
  items).
- Zero open GitHub issues.

## Where this leaves the repo

The post-simplification doc-consistency sweep (spanning #1498, #1499,
#1500, #1502, #1503, #1504) is now genuinely thorough — every ADR marked
"Removed 2026-09-07," every dependency doc, the industry digest, the two
DORA docs, and the incident log's live reference tables have all been
cross-checked against the real, current 6-component always-on core. The
one real open architectural question this simplification left (the Oracle
backend's own tfstate design) was already decided (#1502, Keep).

## What would open new work

- A new upstream release against the lab's 6-component core.
- A new GitHub issue, RFC, or CHARTER edit.
- A future architect/planner cycle finding a genuinely new gap this sweep's
  scope (doc-accuracy, not code/manifest review) didn't cover.

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
