# [Action needed] Now/next still gated; Makefile target/PHONY sweep clean, run has now covered every cheap verification angle

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
recent cycle has found gated, re-verified fresh this cycle:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (still open,
   no new comment since 2026-08-04).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (still open,
   no new comment since 2026-08-04).

[#980](https://github.com/tooming/k8s-anywhere/pull/980) (the maintainer's
own in-progress GitLab-runner work toward confirming both gates) is
unchanged — still open, `mergeable_state: unknown` (stale merge-base check,
not a conflict), no new activity since 2026-08-04.

## This run's real deliverables (not idle) — 11 merged PRs + 1 closed issue

1. [#1008](https://github.com/tooming/k8s-anywhere/pull/1008)/[#1009](https://github.com/tooming/k8s-anywhere/pull/1009) — `ack-s3` chart `1.8.2` → `1.9.0`.
2. [#1010](https://github.com/tooming/k8s-anywhere/pull/1010)/[#1011](https://github.com/tooming/k8s-anywhere/pull/1011) — Vault image `2.0.3` → `2.0.4` (real dependency-CVE fixes, distinguished from false-positive-suppression noise).
3. [#1012](https://github.com/tooming/k8s-anywhere/pull/1012) — honest cycle record.
4. [#1013](https://github.com/tooming/k8s-anywhere/issues/1013)/[#1014](https://github.com/tooming/k8s-anywhere/pull/1014) — ADR-0015 audit, held Inkless Postgres at `17.x` (major-version hold, mirroring the existing Kafka-client precedent).
5. [#1015](https://github.com/tooming/k8s-anywhere/pull/1015)/[#1016](https://github.com/tooming/k8s-anywhere/pull/1016) — Inkless Postgres image pinned explicitly, `17` → `17.10`.
6. [#1017](https://github.com/tooming/k8s-anywhere/pull/1017) — honest cycle record (floating-tag sweep, confirmed remaining floating tags are deliberate).
7. [#1018](https://github.com/tooming/k8s-anywhere/pull/1018) — fixed stale dashboard count in `docs/00-architecture.md` (`28` → `29`).
8. [#1019](https://github.com/tooming/k8s-anywhere/pull/1019) — honest cycle record (CHARTER Application-count check, declined to guess an ambiguous figure).

## This cycle's fresh angle: Makefile target/`.PHONY` hygiene

Compared every `.PHONY:` declaration against every actual target definition
in the `Makefile` (`grep -oP '^\.PHONY: \K\S+'` vs.
`grep -oP '^[a-zA-Z][a-zA-Z0-9_-]*(?=:)'`, both sorted) — zero diff. No
orphaned target, no undeclared `.PHONY` entry. Clean.

## Assessment

This run has now swept every cheap, clusterless verification angle
available from this sandbox: chart `targetRevision` currency (all `gitops/`
pins), plain container `image:` tags (all pins + all floating tags),
Terraform-bootstrapped chart versions, Terraform provider constraints,
GitHub Actions workflow pins, an ADR major-version audit, doc-count
precision (twice — one fixed, one correctly declined as ambiguous), and now
Makefile target hygiene. Eleven real PRs merged, one audit issue opened and
closed, all in a single continuous run. The three remaining gated items are
genuinely blocked on live-cluster facts only the maintainer can observe (a
real GitLab CI pipeline run, a real Kargo promotion) — not on an
undiscovered gap in this repo that a clusterless sandbox could find.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) PR #980
merging; (c) a new GitHub issue (ungroomed intake — currently none exists);
(d) a new upstream CVE/release firing one of this repo's many tracked flip
conditions; (e) time passing — a chart/image that's current today may not
be tomorrow, so the currency sweeps this run did remain worth re-running on
a future cycle even though they're clean right now.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
