# [Action needed] Now/next still gated; CHARTER Objectives O3/O6/O7 status re-check clean

## What's blocked

The two remaining `[ ]` items in ROADMAP.md's *Now / next* (`verifyImages ClusterPolicy
— Audit → Enforce flip`, `Remove legacy capstone Deployment`) plus the dependent `O4 CI
gate` item are still gated on the standing maintainer-confirmation issues #631 and #633
— re-checked this cycle: both still open. #631's own thread (2026-07-29T22:10) confirms
the underlying blocker directly: no GitLab CI run has yet signed and pushed an image to
Harbor, and #633's thread confirms no Kargo Freight has ever been produced (the
Warehouse has nothing semver-tagged to discover). Both are genuinely unresolved, not
stale trackers.

## What this run already shipped (this cycle's own chain)

PR #783 (finished a stranded prior-run self-review+merge), #784 (planner: groomed issue
#781 into a parked 🟡 item), #786 (architect: RFC #785 decided — Approve, argo-cd chart
9.7.1→10.2.1 with a required NetworkPolicy override), #787 (planner: groomed RFC #785
into a 🟢 item), #788 (executor: shipped the argo-cd bump), #890 (janitor: found and
fixed a genuine 39-file recurrence — `docs/done/*.md`'s `## PR` placeholder was never
once backfilled after a PR opened, going back to 2026-07-11 — plus a new mechanical
guard, `scripts/docs-done-pr-link-check.sh`, wired into `make ci` + a PostToolUse hook).

## This cycle's fresh angle

Walked the STEP 6b fallback chain again for the cycle after #890: planner (only 2 open
issues, both standing `[Action required]` confirmation trackers, neither a groomable
work request — clean), architect (no open `adr-audit` issues; the one active 🟡 item,
argo-cd's major bump, already has its RFC #785 and was already groomed to 🟢 and built
this same run), upgrade-drafter (a prior cycle today already ran a `git ls-remote`-based
currency sweep across every chart with an unreachable Helm-repo host — Longhorn, Harbor,
Kargo, Cilium, RabbitMQ, cert-manager, KEDA — all confirmed current; nothing left
unchecked), doc-drift-author (`readme-check`/`lab-ui-check`/`markdown-links-check` all
green), triager (both open issues already fully labeled).

Rather than repeat any of those searches, this cycle instead **re-audited CHARTER.md's
Objectives section directly** — a lens not used by any of today's many `[Action needed]`
cycles (which have mostly targeted chart/image currency or ROADMAP-item gating). Findings:

- **O3** (stateful DR, due 2026-12-31): CHARTER's own text notes `observability` and
  `inkless` were added to scope 2026-07-29 after a gap audit found both held real PVCs
  with no Velero Schedule. Verified directly: `gitops/velero/schedules/` now contains
  `observability-daily.yaml` and `inkless-daily.yaml` alongside the four pre-existing
  schedules (`data`, `tidb`, `capstone`, `vault`) — all six O3-scoped namespaces have a
  real Schedule. **Already closed**, not a fresh gap.
- **O6** (capstone-demo wall-clock, due 2026-12-31): `make capstone-demo` target exists
  (`Makefile:509-511`) and calls `scripts/capstone-demo.sh`. **Built.**
- **O7** (DORA metrics, due 2026-10-31): `docs/dora-metrics.md` exists as a committed
  real snapshot; `scripts/dora-metrics.sh` exists, is executable, and the Makefile target
  is on-demand only (not wired into `up`/`ci`). **Built**, matches CHARTER's own
  "Measured by" clause exactly.
- **O1, O2, O5**: CHARTER's own status note already records these as met (O1 ahead of
  schedule; O2's namespace fan-out complete per the ROADMAP `### Now / next` header
  note; O5's dashboard coverage complete).
- **O4** (image signing, due 2026-12-31): the one Objective still genuinely in progress
  — directly coupled to the #631/#633 gate above, not a new finding.

No gap found. Every dated Objective is either met or blocked on the same live-cluster
fact #631/#633 already track.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631 (a real CI run signing + pushing to
Harbor) and #633 (a real Kargo promotion observed); (b) a new GitHub issue of any size;
(c) a new upstream CVE/release firing a tracked ADR flip condition; (d) O4's own
completion, which cascades to unblock both remaining ROADMAP items at once.

This note is this cycle's honest record — a CHARTER-Objectives-status lens, distinct
from every chart/image-currency and ROADMAP-gating check already run today — not a
stopping point. The run continues to the next cycle per `executor.prompt.md` STEP 8.
