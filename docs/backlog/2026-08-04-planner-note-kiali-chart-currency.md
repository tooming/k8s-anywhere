# Planner note — 2026-08-04 (Kiali chart currency)

## What this run did

Reached the planner role via `executor.prompt.md` STEP 6b: the "Now / next" lane
held only the same 3 items every recent cycle has found gated (on standing
maintainer-confirmation issues [#631](https://github.com/tooming/k8s-anywhere/issues/631)
and [#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle, both still open, no new confirmation comment; the most recent comments on
each, from earlier today, describe an in-progress GitLab Runner setup but no
completed end-to-end confirmation yet). No ungroomed GitHub issues existed to
groom (only the two standing `[Action required]` issues above, which are not
intake). `docs/roadmap/incoming/` held no pending architect items.

Prior cycles (2026-08-03) already ran an exhaustive upstream sweep across the
architect's fixed 17-component checklist plus Harbor and found only one delta
(the Harbor `1.19.2` bump, already merged). Rather than repeat that identical
sweep one day later for near-certain diminishing returns, this cycle checked a
fresh angle: components with their own ADR but *not* on the architect's fixed
STEP 1 checklist — cert-manager, KEDA, Kiali, Kargo.

## What was found

Checked all four directly against real upstream sources (not training
knowledge, ADR-0004):

- **cert-manager** (`v1.21.1` pinned): `git ls-remote --tags` against
  `cert-manager/cert-manager` shows `v1.21.1` is still the newest stable tag.
  No gap.
- **Kargo** (`v1.11.0` pinned): `git ls-remote --tags` against `akuity/kargo`
  shows `v1.11.0` is still the newest stable tag. No gap.
- **KEDA** (`2.20.2` pinned): could not enumerate the `kedacore/charts` repo's
  tag scheme from this sandbox cleanly; deferred rather than guess (ADR-0004) —
  worth a follow-up sweep with more time, not asserted clean.
- **Kiali** (`2.29.0` pinned): **one real, verified delta.** A full clone of
  `github.com/kiali/helm-charts` shows `v2.30.0` as a genuine stable tag past
  the pinned `v2.29.0`. A full clone of the `kiali/kiali` app repo (versioning
  tracks 1:1, confirmed at the prior `1.89.8`→`2.29.0` Convert audit) shows
  `git log v2.29.0..v2.30.0` contains three named CVE fixes in Kiali's bundled
  frontend dependencies: CVE-2026-59877 (`protobufjs`), CVE-2026-49978
  (`dompurify`), CVE-2026-59869 (`js-yaml`) — each affects versions up to and
  including `2.29.0`, fixed in `2.30.0`. This is *exactly* the flip condition
  ADR-0012's own Re-evaluation log recorded at the prior audit ("revisit when a
  Kiali-specific CVE is published against `kiali-server` at or above `2.29.0`").

Added as a new 🟢 Now/next item (`auto/kiali-chart-2-30-0`) with full
implementation detail, following the same smallest-safe-delta pattern as the
Harbor/cert-manager/kro bumps already in `## Done`.

## Why no other action this cycle

Same reasoning as the 2026-08-03 planner note: the sweep found one real,
verified, CVE-backed delta — a single well-scoped ROADMAP item is this cycle's
honest deliverable, not manufactured additional churn. KEDA's tag scheme is
left as a genuinely open follow-up rather than asserted clean without
verification.

## What would unblock further Now/next work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing one of the tracked ADR flip conditions (KEDA's tag scheme still worth a
follow-up check).

This is this cycle's deliverable, not the run's stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8, which should pick
up the newly-added Kiali item directly.
