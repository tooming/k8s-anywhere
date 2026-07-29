# [Action needed] Now/next still gated; self-corrected a counting bug from the prior cycle's finding

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#847](https://github.com/tooming/k8s-anywhere/pull/847) (filed issue
#846: CHARTER's "~28 ArgoCD Applications" figure is stale).

## This cycle's fresh angle — catching and fixing its own predecessor's bug

Started this cycle by trying to make issue #846 maximally useful for the
architect (attempting a first-pass categorization of the 68 auto-synced
Applications against CHARTER's four buckets). While doing that, found that
the **"68" count itself was wrong** — it was computed last cycle via a
plain substring match for the text `automated:`, which produces false
positives on files that only **mention** `automated:` inside an explanatory
comment (e.g. `tidb-operator.yaml`'s `# ON-DEMAND: no automated: block →...`).

Re-verified properly via `yq '.spec.syncPolicy.automated'` (reading the
actual field, not text-matching): the real count is **63**, not 68. Five
false positives dropped out: `tidb-operator.yaml`, `tidb-cluster.yaml`,
`tidb-demo.yaml`, `tidb-admin-extras.yaml` (genuinely on-demand, no
`automated:` at all) — and `cilium.yaml`, which also has no `automated:`
block but for a legitimate, different reason (CNI must bootstrap manually
before ArgoCD itself can run; "adopted" by ArgoCD afterward, per its own
header comment) — a case that arguably still belongs in "Always-on core"
conceptually despite lacking the mechanical flag.

**Posted a correction comment on issue #846** with the accurate 63(-or-64)
figure and the concrete Cilium nuance, rather than let a known-wrong number
sit uncorrected in the merged record (ADR-0004: catch and fix a factual
error the moment it's found, don't leave it for someone else to discover
later). The core finding from the prior cycle stands unchanged — CHARTER's
"~28" is still stale by more than 2× either way — but the raw data behind
it is now accurate, and the note to the architect explicitly explains why a
mechanical script (any single grep/yq pass) can't fully resolve this on its
own (both over- and under-counting failure modes exist), reinforcing why
this is a categorization call for a human/architect pass, not a script fix.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct executor fix this cycle. `make ci` is unaffected (no code/manifest
touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) issue #846
(architect categorized re-count + CHARTER/dora-audit-readiness update),
now carrying corrected raw data.

This note is this cycle's honest record — verifying, and where wrong,
correcting, its own predecessor's finding rather than compounding an error
forward. The run continues to the next cycle per `executor.prompt.md`
STEP 8; this is not a stopping point.
