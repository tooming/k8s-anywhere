# ROADMAP.md legacy `[x]` item trim — batch 21

Continuing the pilot batch, batch 2 through batch 20
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch8.md](2026-09-05-roadmap-legacy-item-trim-batch8.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch9.md](2026-09-05-roadmap-legacy-item-trim-batch9.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch10.md](2026-09-05-roadmap-legacy-item-trim-batch10.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch11.md](2026-09-05-roadmap-legacy-item-trim-batch11.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch12.md](2026-09-05-roadmap-legacy-item-trim-batch12.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch13.md](2026-09-05-roadmap-legacy-item-trim-batch13.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch14.md](2026-09-05-roadmap-legacy-item-trim-batch14.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch15.md](2026-09-05-roadmap-legacy-item-trim-batch15.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch16.md](2026-09-05-roadmap-legacy-item-trim-batch16.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch17.md](2026-09-05-roadmap-legacy-item-trim-batch17.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch18.md](2026-09-05-roadmap-legacy-item-trim-batch18.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch19.md](2026-09-05-roadmap-legacy-item-trim-batch19.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch20.md](2026-09-05-roadmap-legacy-item-trim-batch20.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **`kyverno` PSA `baseline` → `restricted` flip** →
  [docs/done/2026-07-17-kyverno-psa-restricted.md](2026-07-17-kyverno-psa-restricted.md)
  (PR #486)
- **NetworkPolicy fan-out — `envoy-gateway-system` namespace** →
  [docs/done/2026-06-16-envoy-gateway-system-networkpolicy.md](2026-06-16-envoy-gateway-system-networkpolicy.md)
  (PR #219 — found via `search_pull_requests` on the branch name, since the
  mirror file itself only cited the branch, not a PR number)
- **Pin `gitlab-ce`/`gitlab-runner` to explicit versions** →
  [docs/done/2026-08-07-gitlab-version-pin.md](2026-08-07-gitlab-version-pin.md)
  (PR #1075)
- **Lab — Harbor OCI registry dashboard + observability metrics** →
  [docs/done/2026-07-01-auto-harbor-observability-dashboard.md](2026-07-01-auto-harbor-observability-dashboard.md)
  (PR #316) — **a real bug found and fixed in the same commit**: this
  mirror file's own `## PR` section cited `#318`, but PR #318 is an
  unrelated planner-grooming PR (`zz-dns-clusterip-bridge`), not the Harbor
  dashboard. Found the correct PR (#316, referenced inside #318's own body
  as "the harbor PR") via `search_pull_requests` on the branch name and
  independently confirmed it `merged: true` with matching content before
  using it. Corrected the mirror file's own stale PR link in this same
  commit — a real drift the mirror-PR-link check doesn't currently catch
  (it only asserts a `## PR` section resolves to *some* PR reference, not
  that the reference is the *correct* one).
- **Lab — Longhorn on-demand Alloy scrape + dashboard** →
  [docs/done/2026-07-05-auto-longhorn-dashboard.md](2026-07-05-auto-longhorn-dashboard.md)
  (PR #333)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-20, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment; no
other open PRs exist. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16, again
widening the mirror search with a content grep across `docs/done/*.md` and,
for one candidate, `search_pull_requests` on the branch name when the mirror
file carried no PR number at all.

## Result

`ROADMAP.md`: 3784 → 3650 lines (134 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1432
