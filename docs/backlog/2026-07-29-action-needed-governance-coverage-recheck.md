# [Action needed] Now/next still gated; governance LimitRange coverage recheck clean (near-miss caught)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#836](https://github.com/tooming/k8s-anywhere/pull/836) (GitLab CI
tooling currency + moto ambiguity resolved).

## This cycle's fresh angle — and a near-miss worth recording

Cross-referenced every PSA-labeled namespace (`gitops/**/namespace.yaml`, 29
total) against `gitops/governance/`'s LimitRange leaf directories (24 total),
the same technique the `auto/governance-capstone-pipeline` item used to find
its own gap. Six namespaces had no governance leaf: `artifactory`, `inkless`,
`istio-system`, `longhorn-system`, `tidb`, `tidb-admin`.

Initial read: `tidb-admin` looked like a plausible real gap, distinct from
its five siblings — `tidb-operator.yaml`'s Helm values give the TiDB
Operator controller/scheduler pods **fixed**, small, explicit resource
requests/limits (controller `500m`/`512Mi` limit, scheduler `250m`/`256Mi`
limit), the same shape as `kargo`'s own on-demand operator (which DOES have
a governance leaf) — not the genuinely variable, user-configured shape of
the `tidb` namespace's own `TidbCluster` CR (PD/TiKV/TiDB replica counts and
storage sizing), which is the actual "too variable for static defaults"
case. On that reasoning alone, excluding `tidb-admin` looked inconsistent
with including `kargo`.

**Caught before writing any fix**, by re-reading ROADMAP.md's own already-
merged `capstone-pipeline governance LimitRange` item text (the one that
added `capstone-pipeline` to governance): it explicitly names **"the
documented on-demand-heavy exclusion list (`tidb`, `tidb-admin`,
`longhorn-system`, `istio-system`, `inkless`)"** as a fixed, deliberate unit
— `tidb-admin` is bundled with `tidb` intentionally (both are part of "the
TiDB on-demand component," excluded as a package, not independently
re-litigated per-namespace on a resource-shape technicality), not an
oversight. `artifactory`'s exclusion is separately documented in
`tests/governance.bats`'s own header comment (ADR-0024 supersession).

**Conclusion: no real gap.** All six "missing" namespaces are already
deliberately, documentedly excluded — confirmed by cross-referencing two
independent sources (ROADMAP.md's own prior item text and
`tests/governance.bats`'s comments) rather than trusting the raw
directory-diff alone. Filing this note specifically to record the near-miss
reasoning, so a future cycle running the same directory-diff technique
doesn't have to re-derive the `tidb-admin`-looks-inconsistent-with-`kargo`
analysis from scratch — this note settles it.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct check
(governance-coverage directory-diff cross-referenced against two independent
documentation sources) that correctly avoided a plausible-but-wrong fix. The
run continues to the next cycle per `executor.prompt.md` STEP 8; this is not
a stopping point.
