# [Action needed] Now/next lane exhausted; every remaining item gated on live-cluster confirmation (#631/#633)

Autonomous executor run, cycle 2 (`executor.prompt.md` STEP 6b, reached via the
PLANNER fallback role — `routines/planner.prompt.md`). Cycle 1 this run shipped a
real feature PR ([#1110](https://github.com/tooming/k8s-anywhere/pull/1110),
merged) — this cycle's honest outcome is different: a full sweep found nothing
further to build.

## What's blocked

Every unchecked `[ ]` item in the entirety of `ROADMAP.md` (grepped directly, not
assumed) is one of:

1. **The three remaining "GitLab → Forgejo migration" items** — the repoURL flip
   (split out of this run's own PR #1110 per rule #9), the `gitlab-*.sh` →
   `forgejo-*.sh` rename (prerequisite: the flip above, verified live), and the
   GitLab decommission (prerequisite: every prior migration item verified live).
   Sequentially gated on each other, ultimately on a live-cluster session pushing
   real content to Forgejo and verifying a real ArgoCD sync.
2. **`verifyImages ClusterPolicy` Audit → Enforce flip** (RFC #214 item 3) — gated
   on the standing `[Action required]` issue **#631** (confirm a real CI run signed
   and pushed an image to Harbor).
3. **O4 CI gate — `verify-image-rejection` job** (RFC #289) — explicitly
   sequenced behind item 2 above (`pick up ONLY after auto/cosign-enforce-flip
   merges`).
4. **Remove legacy capstone `Deployment`** — gated on the standing `[Action
   required]` issue **#633** (confirm a real Argo Rollouts canary + Kargo
   promotion has run end-to-end).

None of these six items has an extractable live-state-safe slice left to build
(ROADMAP rule #9's split-the-gate default): items 2–4 are each a single atomic
flip/deletion/CI-job-add whose entire content **is** the live-reconcile-affecting
action the gate exists to hold back — there is no "prep" portion left to peel off
(unlike this run's own cycle 1, which *did* find and build such a slice for the
migration's item 4). Item 1's three sub-items are correctly sequenced behind each
other and behind #631's confirmation, for the same reason.

## What was checked this cycle (real gap analysis, not just the gate list)

- `gh pr list`-equivalent: **zero open PRs** — nothing in flight to duplicate or
  wait on.
- `gh issue list --state open`-equivalent: **only #631 and #633** are open — both
  standing `[Action required]` confirmation issues (ROADMAP rule #11's mechanism,
  not planner intake). No ungroomed issue exists to size/split.
- Grepped `ROADMAP.md` for `🟡` outside a `~~...~~` (already-groomed) or the rules
  prose: **zero un-RFC'd 🟡 items** anywhere in the file.
- `docs/roadmap/incoming/` holds only its `README.md` — no pending architect items
  to absorb.
- CHARTER.md Objectives re-checked against the repo directly, not from memory:
  O1 (Tier 1 next-wave) and O2 (default-deny + PSS) — both already marked done in
  ROADMAP's own status note, re-confirmed by `make ci`'s green
  `securitycontext`/`networkpolicy` bats suites. O3 (stateful DR) — `make
  dr-restore` + its Objective-O3-enabler item both `[x]`. O5 (real-metric
  dashboards) — ran `tests/dashboard-coverage.bats` directly: **8/8 pass**, every
  always-on Mimir/Loki/Pyroscope/Tempo-backed dashboard present with a real
  datasource panel. O6 (`make capstone-demo` wall-clock) — target exists
  (`scripts/capstone-demo.sh`), item `[x]`. O7 (DORA metrics) —
  `scripts/dora-metrics.sh` + `docs/dora-metrics.md` + the `dora-metrics` Makefile
  target all present. **Only O4 (image signing enforcement) remains open**, and
  it's exactly items 2–3 above, gated on #631.
- Re-read `docs/decisions/` "Re-evaluation log" sections and the Cilium/chart-pin
  items already in ROADMAP — all current-generation bumps already landed (this
  run's own cycle 1 confirmed no drift on the ones it touched).

This is a genuinely different shape from the "every remaining item is 🟡, blocked
on an open RFC" case the executor/planner fallback text names explicitly — here
every remaining item is 🟢 (already architect-approved where relevant) but blocked
on **live-environment confirmation**, a category this clusterless session
structurally cannot resolve no matter how the search is angled.

## New, useful signal since #631/#633 were last touched (2026-08-07)

**Issue #1034 (k3d node disk pressure) closed 2026-08-10 22:46 UTC** — the node's
`DiskPressure` condition is confirmed `False` (74% overlay usage, 41G/59G, below
the eviction threshold), a real improvement over the 88%/`NodeNotReady`-flapping
state that blocked the last several attempts at #631/#633's Harbor CI signing
flow. Neither #631 nor #633 has been retried since. This is the single most
actionable thing a live-cluster session can do next: bring Harbor up **alone** (no
Kargo, no other on-demand unit — per #631's/#633's own most recent comments'
sequencing recommendation) now that the disk-pressure ceiling that repeatedly
interrupted prior attempts is gone, trigger the `sign-image` CI job, and verify
the `.sig` lands in Harbor. If that succeeds, #633's Kargo promotion check becomes
attemptable immediately after (the Warehouse itself already validates as of
#633's 2026-08-07 comment — only the signed-image precondition was missing).

## Maintainer / live-cluster-session action that would unblock everything above

Retry #631's confirmation now that #1034 is resolved: `make harbor-up` alone,
confirm `COSIGN_KEY`/`HARBOR_USER`/`HARBOR_PASSWORD` CI variables are current,
trigger the `sign-image` pipeline job, verify a `<digest>.sig` tag lands in
`harbor.127.0.0.1.nip.io/library/hello`. A single successful run there closes
#631, immediately unblocks items 2–3, and very likely unblocks #633/item 4 in the
same session (per the reasoning above).

## Note on this pattern

Per `executor.prompt.md` STEP 8, this is not a stopping point — the run continues
to the next fallback role / a fresh-angle sweep.
