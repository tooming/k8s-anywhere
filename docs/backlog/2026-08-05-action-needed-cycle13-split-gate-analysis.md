# [Action needed] Now/next still gated; split-the-gate analysis confirms no safe slice, 12 PRs landed this run

## What's blocked

Same 3 unchecked `[ ]` items, re-verified fresh:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on #631.
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1.
3. `Remove legacy capstone Deployment` — gated on #633.

## This cycle's fresh angle: ROADMAP rule #9's "split the gate" test

Rather than another currency/staleness grep sweep, this cycle applied rule
#9's own default move directly to each of the three gated items — carve out
any part that doesn't mutate live-synced cluster state from the part that
does:

- **Item 1 (Enforce flip):** the entire diff is `validationFailureAction:
  Audit → Enforce` + `failurePolicy: Ignore → Fail` on an already
  auto-synced, live `ClusterPolicy`. There is no preparatory sub-slice — the
  whole point of the change *is* the live enforcement flip; any smaller edit
  would either be a no-op or would itself be the gated mutation. **Not
  splittable.**
- **Item 2 (O4 CI gate):** explicitly requires item 1 to have merged first,
  and its own content — a CI job that "asserts Kyverno blocks admission" of
  an unsigned image — is only meaningful once the policy is actually in
  Enforce mode. Scaffolding a CI job that can't yet perform its one real
  assertion would be a hollow placeholder, not real progress (ADR-0004: no
  fabricated/inert work presented as done). **Not splittable independently
  of item 1.**
- **Item 3 (capstone Deployment removal):** deleting
  `gitops/apps/capstone/deployment.yaml` from an auto-synced Application's
  `kustomization.yaml` prunes a live Deployment the moment it syncs — there
  is no partial-delete that stays safe until the Rollout's takeover is
  confirmed. **Not splittable.**

This matches (and re-confirms with fresh reasoning, not assumed) the
conclusion prior cycles reached from a currency-sweep angle rather than this
rule-#9-specific angle.

## Assessment

12 real merged PRs this run. Every fallback role in STEP 6b's chain
(planner, architect, executor, janitor) has been exercised productively at
least once, several more than once with genuinely different angles each
time. The three gated items are atomic live-cluster mutations by
construction, not items this repo's own doc/code state can unblock further.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) PR #980
merging; (c) a new GitHub issue; (d) a new upstream CVE/release.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
