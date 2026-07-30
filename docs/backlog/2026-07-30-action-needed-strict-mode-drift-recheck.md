# [Action needed] Now/next still gated; strict-mode + live make ci drift recheck clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items
(`verifyImages ClusterPolicy — Audit → Enforce flip`, `O4 CI gate —
verify-image-rejection job`, `Remove legacy capstone Deployment`) — all gated
on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633). Re-checked this
cycle by reading both issues' full comment threads directly: both still open,
no comment since 2026-07-29/30, no confirmation. Rule #9's split-the-gate test
re-applied to each: item 1 is RFC #214's last atomic slice (the prior split
already carved out `auto/cosign-make-up-wiring` +
`auto/cosign-ci-sign-step`, non-cluster-mutating, both merged; only the
Enforce flip itself remains, and that flip is inherently a live-sync
enforcement change); item 2 is explicitly ordered after item 1 by its own
prerequisite check; item 3's only content is deleting a manifest ArgoCD
actively syncs, which is itself the live-cluster mutation the gate exists to
prevent. No further slice exists on any of the three.

## What this run already did

One real merged PR this run: finished a stale self-mergeable PR from a prior
cycle whose CI had gone green but whose self-review-then-merge step never
fired — [#907](https://github.com/tooming/k8s-anywhere/pull/907) (STEP 1b
recovery, per the mechanical-recovery-path precedent from PR #449).

## This cycle's fresh angles (all clean)

Re-entered the STEP 6b fallback chain. Planner lens: `list_issues` (open,
all states) returns exactly the 2 standing `[Action required]` issues — zero
ungroomed intake, zero `rfc`-labeled issues, `docs/roadmap/incoming/` holds
only its `README.md` placeholder. Architect lens: no un-RFC'd 🟡 item found
anywhere in ROADMAP.md. Then three checks distinct in method from every prior
sweep today (all six of which checked chart/image currency, ADR/RFC
follow-ups, securityContext key-nesting, orphan files, and toolchain pins —
this cycle instead ran the actual gates and audited code shape directly):

1. **A live, direct `make ci` run** (not citing a prior cycle's claim that it
   passes) — captured the full stdout/stderr. Every drift-detector gate that
   runs without extra tooling (readme-check, lab-ui-check, roadmap-check,
   markdown-links, ADR chart/image-pin sync, context.md version sync,
   kustomize-orphan-check, docs/done/ PR-link check, routines-check,
   routines-author-check, frozen-test-file guards) reported clean — zero
   drift signals, matching the doc-drift-author role's own "nothing to
   reconcile" outcome.
2. **Script/test monolith-size audit** (the janitor role's #1-priority
   footgun class — "a shared monolith multiple PRs append to"). Measured
   every `scripts/*.sh` and `tests/*.bats` file directly: largest test file
   is `tests/observability.bats` at 569 lines (already governed by its own
   "frozen, new scopes go in `observability-<scope>.bats`" CI guard — the
   split mechanism this class of footgun would need already exists and is
   enforced); largest script is `scripts/dora-metrics.sh` at 192 lines.
   Nothing large enough or un-guarded enough to justify a bounded janitor
   split this run.
3. **Script strict-mode coverage audit.** `grep -q '^set -' scripts/*.sh`
   across all 80 scripts — 100% coverage (every script sets `-uo pipefail`
   or stricter). A naive first pass with a `head -N` line-window falsely
   flagged scripts whose `set -` line sits past a long header-comment block;
   corrected to a whole-file grep before concluding — no real gap.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 (a real CI run
signing + pushing to Harbor) or #633 (a real Kargo promotion observed); (b) a
new GitHub issue of any size (ungroomed intake); (c) a new upstream
CVE/release firing a tracked ADR flip condition.

This note is this cycle's honest record — one real merged PR (finishing a
stranded prior-cycle self-merge) plus three fresh, previously-untried
verification angles that all came back clean. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
