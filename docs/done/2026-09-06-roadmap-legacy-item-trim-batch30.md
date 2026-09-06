# ROADMAP.md legacy `[x]` item trim — batch 30

JANITOR-fallback cleanup (STEP 6b), continuing the chain of prior batches:
[batch 15](2026-09-05-roadmap-legacy-item-trim-batch15.md) through
[batch 29](2026-09-05-roadmap-legacy-item-trim-batch29.md) (each links its own
predecessor).

## Why in scope

Re-walked the STEP 6b fallback chain fresh this cycle, after batch 29 merged
(PR #1443): issues #633 (Argo Rollouts canary + Kargo promotion end-to-end
confirmation) and #1229 (KUBECONFIG Forgejo Actions secret) both remain
open/unconfirmed, so the "Now / next" ROADMAP lane is still fully gated. No
open PLANNER/ARCHITECT/DOC-DRIFT-AUTHOR/TRIAGER work was found. Only one
other open PR exists this cycle: #1441 (a different executor session's
UPGRADE-DRAFTER KRO 0.9.3→0.9.4 bump) — left untouched per STEP 1b, and
rebased cleanly onto the new `main` via `make rebase-prs PUSH=1` after batch
29 merged. JANITOR falls through to the established ROADMAP.md
legacy-item-trim cleanup.

## Items trimmed this batch

- **PSA baseline + NetworkPolicy — `lab-demo` namespace** — mirror:
  [docs/done/2026-06-22-pss-np-lab-demo.md](2026-06-22-pss-np-lab-demo.md).
  The mirror cited only a branch name (`auto/pss-np-lab-demo`); found the real
  PR via `search_pull_requests` on that branch → PR #256 (verified
  `merged: true`).
- **Fix stale "Keeping this in sync" claims in `docs/dependency-register.md`,
  `docs/dependency-concentration.md`, and `docs/dependency-exit-runbooks.md`**
  — **a partial-trim leftover, same class of bug as batch 28's**: a prior
  pass had already added the "full verification writeup" pointer to
  [docs/done/2026-09-03-dependency-docs-sync-check-drift-fix.md](2026-09-03-dependency-docs-sync-check-drift-fix.md)
  (PR #1381, cited in the mirror's own `## PR` section) but left ~28 lines of
  the original verbose planner-fallback prose undeleted directly below the
  pointer. Removed the redundant trailing prose, keeping only the pointer +
  branch/PR citation. Found via the broader `grep`/manual-read scan
  established in batch 28 (the narrow `awk` presence-only scan misses these,
  since the pointer phrase is already present earlier in the same block).
- **`docs/00-architecture.md` — add learning-path steps for DR/blue-green and
  GitOps promotion (Kargo)** — mirror:
  [docs/done/2026-07-13-architecture-doc-learning-path-update.md](2026-07-13-architecture-doc-learning-path-update.md)
  — PR #385 (verified `merged: true`).
- **`docs/00-architecture.md` — add learning-path step 12 for cloud-agnostic
  infrastructure design** — mirror:
  [docs/done/2026-07-13-architecture-doc-cloud-agnostic-step.md](2026-07-13-architecture-doc-cloud-agnostic-step.md)
  — PR #387 (verified `merged: true`).
- **`tests/dr-bluegreen.bats` — structural test gate for zero-downtime
  blue/green DR scripts** — mirror:
  [docs/done/2026-07-14-dr-bluegreen-bats-bookkeeping.md](2026-07-14-dr-bluegreen-bats-bookkeeping.md)
  — PR #393 (verified `merged: true`; the actual implementation branch was
  `chore/dr-bluegreen-bats`, produced by an earlier JANITOR-fallback run —
  the mirror file itself is a later bookkeeping catch-up entry, not the
  implementation PR, but correctly documents and cites it).

## Verification

- `wc -l ROADMAP.md` — 2827 lines (down from 2873 before this batch).
- `make ci` — full local suite green, including `docs-done-pr-link-check`
  and `roadmap-check`.

## PR

https://github.com/tooming/k8s-anywhere/pull/1444
