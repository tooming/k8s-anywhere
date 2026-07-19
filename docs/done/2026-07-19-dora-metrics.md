# `scripts/dora-metrics.sh` + `make dora-metrics` — DORA metrics from git/CI history

(CHARTER new **Objective O7**; RFC #580 — architect decision 2026-07-19.) Implements
RFC #580's binding spec: all four DORA (DevOps Research and Assessment) metrics —
deployment frequency, lead time for changes, change failure rate, time to restore
service — computed from git/CI history, no live-cluster state involved.

**Implementation correction vs. RFC #580's original text** (the RFC's spec is
binding, but this genuine implementation-time finding overrides its literal
mechanism, per this repo's own "verify before forcing a broken RFC literally"
precedent — see e.g. the Kyverno PSA-restricted item's executor note): deployment
frequency and change failure rate use `git log --first-parent`, **not**
`--merges`. This repo's actual merge convention is squash-merge
(WAYS-OF-WORKING.md §3), which produces single-parent commits on `main`, not
2-parent merge commits — `--merges` finds **zero** deployments in any window that
postdates squash-merge adoption, even though real work landed (verified directly:
`git log --merges --oneline -10 main` only surfaces commits from before the
squash-merge convention took hold; every recent PR merge in this session's own
history has exactly one parent). `--first-parent` correctly counts one integration
event per PR regardless of merge style.

Lead time similarly can't use git-parent diffing against squash history — the
original branch's commit timestamps aren't preserved (author date == committer
date == merge time on every squash commit, verified empirically against this
repo's own recent commits). It uses the GitHub PR API's `createdAt` → `mergedAt`
instead (via `gh pr list --json createdAt,mergedAt`), which survives branch
deletion.

Deliverables:
- `scripts/dora-metrics.sh`: clusterless (`git log` only for metrics 1 + 3; `gh`
  CLI + `jq` for metrics 2 + 4, gracefully degrading to the literal string
  "insufficient data" — never a fabricated number, ADR-0004 — when either tool is
  absent, verified against this exact sandbox which has `jq` but no `gh`).
  Regenerates `docs/dora-metrics.md`.
- `make dora-metrics` `.PHONY` target under a new `##@ Metrics (on-demand,
  clusterless)` Makefile section — explicitly not wired into `up` or `ci`
  (verified: neither target's block references it).
- `docs/dora-metrics.md`: committed with a real generated snapshot from this
  repo's actual history (559 first-parent commits in the trailing 90 days →
  43.47 deployments/week; 8.2% change failure rate; lead time and restore time
  both "insufficient data" in this sandbox since `gh` isn't installed here — an
  honest result, not a stub).
- `tests/dora-metrics.bats`: structural coverage (script exists/executable,
  Makefile target wired and NOT in `up`/`ci`, doc has all four metric rows) plus
  behavioral coverage exercised for real against this repo (a synthetic
  zero-commit window renders "insufficient data" without crashing; the real
  90-day window computes genuine non-"insufficient data" deployment frequency;
  forcing `gh` off the `PATH` still degrades cleanly for metrics 2 + 4). Every
  assertion was hand-verified against the actual script output before committing.
- CHARTER.md's Objective O7 was already added by RFC #580's own architect PR
  (#581) — no further CHARTER edit needed here.

`make ci` passes. Closes #580.

## PR

https://github.com/tooming/k8s-anywhere/pull/584
