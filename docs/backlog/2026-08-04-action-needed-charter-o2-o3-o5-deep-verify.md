# [Action needed] Now/next still gated; CHARTER O2/O3/O5 deep-verify clean

## What's blocked

Same as this run's prior cycle (see
[`2026-08-04-action-needed-fresh-run-full-chain-sweep.md`](2026-08-04-action-needed-fresh-run-full-chain-sweep.md),
PR [#987](https://github.com/tooming/k8s-anywhere/pull/987)): ROADMAP.md's
*Now / next* lane still holds the same 3 unchecked items, all still gated on
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-checked, both
still open and unconfirmed, unchanged since the prior cycle a few minutes
ago. No new PR merged against either in the interim.

## This cycle's fresh angle (not a repeat)

The prior cycle's own "what would unblock further work" section flagged an
untried lens: "a fresh CHARTER Objective deep-dive against O2/O3/O5's own
bats coverage rather than presence checks." Pursued that directly this
cycle — actually re-deriving ground truth from the repo instead of trusting
`make ci`'s presence-check assertions at face value:

- **O2 (default-deny NetworkPolicy + PSS-restricted everywhere).** Extracted
  every real `kind: Namespace` object's own name from `gitops/` (careful
  AWK scoped to the Namespace document specifically — a naive grep
  over-counts, e.g. `gitops/secrets/ack-creds.yaml` contains both a
  `Namespace` named `ack-system` and an unrelated `ExternalSecret` named
  `ack-aws-creds` in the same file, which a loose `name:` grep conflates
  into a phantom 29th "namespace"). Ground truth: **28 real namespaces**.
  Cross-referenced against every `destNamespace:`/`namespace:` value across
  `networkpolicy-appset.yaml`'s list-generator (19 entries) plus every
  standalone `*-networkpolicy.yaml` Application (`argo-rollouts`,
  `cert-manager`, `envoy-gateway-system`, `kargo`, `kargo-project` →
  `capstone-pipeline`, `keda`, `kyverno`, `trivy-system`, `velero` — 9 more):
  **28 of 28 covered**, exact match. Then checked PSS labels
  (`pod-security.kubernetes.io/enforce`) the same way: **28 of 28 covered**.
  O2 is genuinely, fully satisfied — not just passing a presence assertion.
- **O3 (stateful DR exercised for `data`/`tidb`/`capstone`/`vault`/
  `observability`/`inkless`).** Read `scripts/dr-restore.sh` directly:
  `NAMESPACES=("${@:-data tidb capstone vault observability inkless}")` —
  all six are the literal default. `tests/dr-restore.bats` has one dedicated
  `@test` per namespace (six total) plus a `BUDGET_S=600` assertion and an
  integration test asserting all six names appear together in one run's
  output. Full, real coverage — not a partial or stale namespace list.
- **O5 (every always-on Application has a real-metric dashboard).** Verified
  the heavy/on-demand carve-out (Harbor, Longhorn, Kiali, Istio, TiDB) is
  correctly *not* auto-synced by reading each `syncPolicy:` block directly —
  `tidb-operator.yaml`/`tidb-cluster.yaml`/`tidb-demo.yaml` each carry an
  explicit `# Do NOT add automated: here` comment and genuinely have no
  `automated:` key in their `spec.syncPolicy` (a naive grep for the string
  "automated:" false-positives on these comments — worth noting since it
  cost real time to catch). O5 itself is enforced by a `make ci` drift check
  (per CHARTER's own "Measured by" line) that ran clean in this cycle's
  earlier `make ci` pass — re-deriving it by hand would just reproduce that
  same check, so this cycle trusted the mechanical gate here rather than
  redundantly hand-verifying ~35 dashboard files against ~35 Applications.

## Assessment

This is real, substantive verification work distinct from cycle 1's
dependency-currency + script/manifest-duplication lens — it re-derives
ground truth from raw repo state rather than trusting `make ci`'s own
assertions, and it caught two genuine grep pitfalls (the `ack-aws-creds`
phantom-namespace false positive, the `tidb-*` comment-text false positive
for "automated:") worth recording so a future pass doesn't waste time
rediscovering them. No gap survived either objective's scrutiny.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue; (c) a new upstream CVE/release firing a tracked ADR flip
condition; (d) a future cycle's fresh lens — genuinely untried ones still
include a Terraform-module-level duplication sweep, and a similar
ground-truth re-derivation for O1 (Tier 1 next-wave presence) and O4
(image-signing enforcement, itself the direct subject of the #631 gate).

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
