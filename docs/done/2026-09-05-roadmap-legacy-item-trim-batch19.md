# ROADMAP.md legacy `[x]` item trim — batch 19

Continuing the pilot batch, batch 2 through batch 18
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch18.md](2026-09-05-roadmap-legacy-item-trim-batch18.md)).

## What was done

Found and trimmed 4 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Bump `kro` chart `0.9.2` → `0.9.3`** →
  [docs/done/2026-07-30-kro-cve-bump-0-9-3.md](2026-07-30-kro-cve-bump-0-9-3.md)
  (PR #901)
- **GitHub Actions major-version bumps — `actions/checkout` v4.3.0→v7.0.0,
  `actions/cache` v4.3.0→v6.1.0, `actions/github-script` v7.0.1→v9.0.0,
  `hashicorp/setup-terraform` v3.1.2→v4.0.1** →
  [docs/done/2026-07-20-github-actions-node24-bump.md](2026-07-20-github-actions-node24-bump.md)
  (PR #614)
- **Bump Cilium chart `1.17.18` → `1.18.12`** →
  [docs/done/2026-07-30-cilium-1-18-12-bump.md](2026-07-30-cilium-1-18-12-bump.md)
  (PR #920)
- **`observability` readOnlyRootFilesystem tighten — Pyroscope** →
  [docs/done/2026-07-15-observability-readonlyrootfs-pyroscope.md](2026-07-15-observability-readonlyrootfs-pyroscope.md)
  (PR #415) — this item's trailing "Network-access note" blockquote (a
  standalone, still-useful finding about which hosts this sandbox's proxy
  allows — `raw.githubusercontent.com` and the git wire protocol work even
  when `github.com`/`api.github.com`/a chart's own index host are blocked)
  is **not** duplicated in its `docs/done/` mirror, so it was deliberately
  left in place in ROADMAP.md rather than trimmed away with the rest of the
  item — trimming it would have been real information loss.

No information lost — the full detail already lives in each linked
`docs/done/` file (or, for the Pyroscope item, in the retained blockquote),
confirmed equivalent by reading all four before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-18, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment; no
other open PRs exist. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16. One
candidate from this scan (`[Action needed] PR fallback — remaining five
routine prompts`) was checked and confirmed to have no `docs/done/` mirror at
all (same finding batch 11 made about its sibling item) — left untouched.

## Result

`ROADMAP.md`: 4032 → 3916 lines (116 lines saved from 4 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
